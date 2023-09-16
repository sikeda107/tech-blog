import express from 'express';
import Multer from 'multer';
import { Storage } from '@google-cloud/storage';
import dotenv from 'dotenv';
import { setTimeout } from 'timers/promises';
dotenv.config();
const app = express();
const multer = Multer({ storage: Multer.memoryStorage() });

const storage = new Storage();
const bucket = storage.bucket(
  process.env.GCLOUD_STORAGE_BUCKET || 'upload-file-2023-09-03'
);
app.post('/upload', multer.single('file'), (req, res, next) => {
  const file = req.file;
  if (!file) {
    res.status(400).send('No file uploaded.');
    return;
  }
  const blob = bucket.file(file.originalname);
  const blobStream = blob.createWriteStream({
    resumable: false,
  });
  blobStream.on('error', (err) => {
    next(err);
  });
  blobStream.on('finish', () => {
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${blob.name}`;
    const msg = `File uploaded! ${publicUrl}`;
    console.log(msg);
    res.status(200).send(msg);
  });
  blobStream.end(file.buffer);
});

app.get('/sleep', async (req, res) => {
  console.log('Start sleep');
  await setTimeout(61000);
  res.send('END sleep');
});

app.get('/health', (req, res) => {
  console.log('health check');
  res.send('OK');
});

process.once('SIGTERM', async () => {
  console.log('SIGTERM received.');
  process.exit();
});

process.once('SIGINT', async () => {
  console.log('SIGINT received.');
  process.exit();
});
const port = parseInt(process.env.PORT || '8080');
app.listen(port, () => {
  console.log(`erver listening on port ${port}`);
});
