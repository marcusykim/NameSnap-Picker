import { getApp, getApps, initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyBmXhDc-R-uWrwiXslbNGZGmxBxSXo8cAA",
  authDomain: "namesnap-picker-6759588637.firebaseapp.com",
  projectId: "namesnap-picker-6759588637",
  storageBucket: "namesnap-picker-6759588637.firebasestorage.app",
  messagingSenderId: "885899146114",
  appId: "1:885899146114:web:cbf9475121476a9876959b",
};

const app = getApps().length ? getApp() : initializeApp(firebaseConfig);

export const namesnapAuth = getAuth(app);
