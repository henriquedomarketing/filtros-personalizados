/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { Storage } from '@google-cloud/storage';
import ffmpegPath from 'ffmpeg-static'; // Path to FFmpeg binary
import admin from 'firebase-admin';
import * as logger from "firebase-functions/logger";
import { defineString } from 'firebase-functions/params';
import { onRequest } from "firebase-functions/v2/https";
import ffmpeg from 'fluent-ffmpeg';
import fs from 'fs';
import os from 'os';
import path from 'path';

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


const FILTERS_BUCKET = defineString("FILTERS_BUCKET");
const VIDEOS_INPUT_BUCKET = defineString("VIDEOS_INPUT_BUCKET");
const VIDEOS_OUTPUT_BUCKET = defineString("VIDEOS_OUTPUT_BUCKET");

admin.initializeApp();
ffmpeg.setFfmpegPath(ffmpegPath || "");

const storage = new Storage();

// Helper function to download a file from a URL to a local path
async function downloadFile(bucket: string, url: string, localPath: string): Promise<void> {
    const fileOptions = { destination: localPath };
    // Assuming url is a publicly accessible URL
    const file = storage.bucket(bucket).file(url);
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
        await downloadFile(VIDEOS_INPUT_BUCKET.value(), videoUrl, localVideoPath);
        await downloadFile(FILTERS_BUCKET.value(), filterUrl, localFilterPath);

        const outputFileName = `processed_${new Date().getTime()}.mp4`;
        const tempOutputPath = path.join(os.tmpdir(), outputFileName);
        const outputStoragePath = `processed_videos/${outputFileName}`;
        // Assuming bucket is initialized somewhere
        const bucket = storage.bucket(VIDEOS_OUTPUT_BUCKET.value());

        // Process the video with FFmpeg
        await new Promise<void>((resolve, reject) => {
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
