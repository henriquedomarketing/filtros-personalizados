const path = require("path");
const admin = require('firebase-admin');


const serviceAccount = require('../secrets/cameramarketing-91d5a-firebase-adminsdk-fbsvc-574e039fb2.json'); // Replace with your service account key path

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'cameramarketing-91d5a.firebasestorage.app' // Replace with your storage bucket URL
});


(async function () {
  // Bucket name
  const bucketName = 'filtros';
  // Get a reference to the bucket
  const bucket = admin.storage().bucket();
  console.log(" $ EXISTS? ", await bucket.exists());
  const [files, ..._] = await bucket.getFiles("*");
  console.log(" $ FILES? ", files.map((file) => file.id));
})();


// listFiles();