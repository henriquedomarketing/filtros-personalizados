"use strict";

const { onRequest } = require("firebase-functions/v2/https");
const functions = require('firebase-functions');
const { Storage } = require('@google-cloud/storage');
const ffmpeg = require('fluent-ffmpeg');
const ffmpegPath = require('ffmpeg-static'); // Path to FFmpeg binary
const os = require('os');
const path = require('path');
const fs = require('fs');
const logger = require("firebase-functions/logger");
const { defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');

const bucketNameConfig = defineString("BUCKET_NAME");

admin.initializeApp();
ffmpeg.setFfmpegPath(ffmpegPath);

const storage = new Storage();

// Helper function to download a file from a URL to a local path
async function downloadFile(url, localPath) {
    const fileOptions = { destination: localPath };
    // Assuming url is a publicly accessible URL
    const file = storage.bucket().fileFromURL(url);
    await file.download(fileOptions);
    logger.info(`Downloaded ${url} to ${localPath}`);
}

exports.processVideo = onRequest(
    { timeoutSeconds: 1200, region: ["us-west1", "us-east1"],  },
    async (req, res) => {
        const videoUrl = req.body.videoUrl;
        const filterUrl = req.body.filterUrl;

        // Get and download input files
        const timestamp = new Date().getTime();
        const tmpDir = os.tmpdir();
        const localVideoPath = path.join(tmpDir, `input_video_${timestamp}.mp4`);
        const localFilterPath = path.join(tmpDir, `filter_video_${timestamp}.png`);
        await downloadFile(videoUrl, localVideoPath);
        await downloadFile(filterUrl, localFilterPath);

        const outputFileName = `processed_${fileName}`;
        const tempOutputPath = path.join(os.tmpdir(), outputFileName);
        const outputStoragePath = `processed_videos/${outputFileName}`;
        // Assuming bucket is initialized somewhere
        const bucket = storage.bucket(bucketNameConfig.value());

        // Process the video with FFmpeg
        await new Promise((resolve, reject) => {
            ffmpeg(localVideoPath)
                .input(localFilterPath)
                .complexFilter(['overlay=0:0'])
                .outputOptions('-c:a copy') // Copy audio without re-encoding
                .save(tempOutputPath)
                .on('end', () => {
                    console.log('Video processing complete.');
                    resolve();
                })
                .on('error', (err) => {
                    console.error('Error during video processing:', err);
                    reject(err);
                });
        });

        // Upload the processed video back to Firebase Storage
        await bucket.upload(tempOutputPath, {
            destination: outputStoragePath,
            public: true, // Make the file publicly accessible
        });
        console.log('Processed video uploaded to', outputStoragePath);

        const resultVideoUrl = `https://storage.googleapis.com/${bucket.name}/${outputStoragePath}`;

        // Clean up temporary files
        fs.unlinkSync(localVideoPath);
        fs.unlinkSync(localFilterPath);
        fs.unlinkSync(tempOutputPath);

        res.status(200).send({ videoUrl: resultVideoUrl });
    },
);
