/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// import { Storage } from '@google-cloud/storage';
import ffmpegPath from 'ffmpeg-static'; // Path to FFmpeg binary
import ffprobePath from 'ffprobe-static'; // Path to FFmpeg binary
import admin from 'firebase-admin';
// import * as logger from "firebase-functions/logger";
import { onInit } from 'firebase-functions/v2/core';
import { onRequest } from "firebase-functions/v2/https";
import ffmpeg, { ffprobe, FfprobeData } from 'fluent-ffmpeg';
import fs from 'fs';
import os from 'os';
import path from 'path';

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// const FILTERS_BUCKET = "filtros";
// const VIDEOS_INPUT_BUCKET = "videos_input";
const VIDEOS_OUTPUT_FOLDER = "videos_output";

// let storage: Storage;

onInit(() => {
  admin.initializeApp({
    storageBucket: 'cameramarketing-91d5a.firebasestorage.app' // Replace with your storage bucket URL
  });
  ffmpeg.setFfmpegPath(ffmpegPath || "");
  ffmpeg.setFfprobePath(ffprobePath.path || "");
  // storage = new Storage();
  console.log(`>>> FUNCTION INITIALIZED!! ffmpegPath = ${ffmpegPath} ffprobePath = ${ffprobePath}`);
})


// Helper function to download a file from a URL to a local path
async function downloadFileFromBucket(fileName: string, localPath: string): Promise<void> {
    try {
      const fileOptions = { destination: localPath };
      // Assuming url is a publicly accessible URL
      const file = admin.storage().bucket().file(fileName);
      await file.download(fileOptions);
      console.info(`Downloaded ${fileName} to ${localPath}`);
    } catch (e) {
      console.error(`[MY ERROR] AT DOWNLOAD FILE ${fileName} ${localPath}`);
      throw e;
    }
}

async function downloadFileFromUrl(url: string, localPath: string) {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch image: ${response.status} ${response.statusText}`);
    }
    const buffer = await response.bytes();
    fs.writeFileSync(localPath, buffer);
    console.log('Image downloaded successfully!');
  } catch (error) {
    console.error('Error downloading image:', error);
  }
}

async function processVideoFill(videoInputPath: string, filterPath: string, outputPath: string): Promise<void> {
  const metadata = await new Promise<FfprobeData>((resolve, reject) => {
    ffprobe(videoInputPath, (err, metadata) => {
      if (err) reject(err)
      else resolve(metadata);
    });
  });
  await new Promise<void>((resolve, reject) => {
    const videoStream = metadata.streams.find(s => s.codec_type === 'video');
    if (!videoStream) {
      throw new Error('[MY ERROR] No video stream found.');
    }

    const width = videoStream.width;
    const height = videoStream.height;

    ffmpeg()
      .input(videoInputPath)
      .input(filterPath)
      .complexFilter([
        `[1:v]scale=${height}:${width}[overlay]`,
        `[0:v][overlay]overlay=0:0`
      ])
      .outputOptions('-c:a aac')
      // .outputOptions('-c:a copy') // Copy audio without re-encoding
      .save(outputPath)
      .on('end', () => {
        console.log('Video processing complete.');
        resolve();
      })
      .on('error', (err) => {
        console.error('Error during video processing:', err);
        reject(err);
      });
  });
}


async function processVideo(videoInputPath: string, filterPath: string, outputPath: string): Promise<void> {
  // const metadata = await new Promise<FfprobeData>((resolve, reject) => {
  //   ffprobe(videoInputPath, (err, metadata) => {
  //     if (err) reject(err)
  //     else resolve(metadata);
  //   });
  // });
  // console.log(` >>>>>>>> VIDEO FORMAT --> ${metadata.format} ~~~~~~~~~~~~~~`);
  await new Promise<void>((resolve, reject) => {
    ffmpeg(videoInputPath)
      .input(filterPath)
      .complexFilter(['overlay=0:0'])
      .outputOptions('-c:a aac')
      // .outputOptions('-c:a copy') // Copy audio without re-encoding
      .save(outputPath)
      .on('end', () => {
        console.log('Video processing complete.');
        resolve();
      })
      .on('error', (err, stdout, stderr) => {
        console.log(err.message);
        console.log("stdout:\n" + stdout);
        console.log("stderr:\n" + stderr);
        reject(err);
      });
  });
}

exports.processVideo = onRequest(
  { timeoutSeconds: 1200, region: ["us-east1"], },
  async (req, res) => {
    // if (!storage) throw Error("FirebaseStorage not available. var was no initted (my code)")
    const videoName = req.body.videoName;
    const filterUrl = req.body.filterUrl;

    const videoRef = `videos_input/${videoName}`;

    const resizeMode = "fill";

    // Get and download input files
    const timestamp = new Date().getTime();
    const tmpDir = os.tmpdir();
    const localVideoPath = path.join(tmpDir, `input_video_${timestamp}.mp4`);
    const localFilterPath = path.join(tmpDir, `filter_video_${timestamp}.png`);
    // await downloadFileFromUrl(videoName, localVideoPath);
    await downloadFileFromUrl(filterUrl, localFilterPath);
    await downloadFileFromBucket(videoRef, localVideoPath);

    const outputFileName = `processed_${new Date().getTime()}.mp4`;
    const tempOutputPath = path.join(os.tmpdir(), outputFileName);
    const outputStoragePath = `${VIDEOS_OUTPUT_FOLDER}/${outputFileName}`;

    // Process the video with FFmpeg
    if (resizeMode == "fill") {
      await processVideoFill(localVideoPath, localFilterPath, tempOutputPath);
    } else {
      await processVideo(localVideoPath, localFilterPath, tempOutputPath);
    }

    let outputUrl = "";
    try {
      // Upload the processed video back to Firebase Storage
      const [uploaded, ..._] = await admin.storage().bucket().upload(tempOutputPath, {
        destination: outputStoragePath,
        public: true, // Make the file publicly accessible
      });
      await uploaded.makePublic();
      outputUrl = uploaded.publicUrl();
    } catch (e) {
      console.error(`[MY ERROR] AT UPLOAD FILE ${VIDEOS_OUTPUT_FOLDER} ${tempOutputPath} ${outputStoragePath}`);
      throw e;
    }
    console.log('Processed video uploaded to', outputStoragePath);

    try {
      admin.storage().bucket().file(videoRef).delete();
    } catch (e) {
      console.error(`[MY ERROR] AT REMOVE INPUT FILE ${VIDEOS_OUTPUT_FOLDER} ${tempOutputPath} ${outputStoragePath}`);
      throw e;
    }

    // Clean up temporary files
    fs.unlinkSync(localVideoPath);
    fs.unlinkSync(localFilterPath);
    fs.unlinkSync(tempOutputPath);

    res.status(200).send({ videoUrl: outputUrl });
  },
);
