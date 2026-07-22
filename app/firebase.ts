import { getApp, getApps, initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// Firebase web configuration identifies the BalokKosong project; it is not a
// secret and is intentionally safe to ship to the browser.
const firebaseConfig = {
  apiKey: "AIzaSyDKoq7dAGmE4ToatRZKMjZrDw86vmIR-8Y",
  authDomain: "balokkosong-54afe.firebaseapp.com",
  projectId: "balokkosong-54afe",
  storageBucket: "balokkosong-54afe.firebasestorage.app",
  messagingSenderId: "456475995990",
  appId: "1:456475995990:web:9b9fc069f4c819dc17b0f7",
};

const app = getApps().length ? getApp() : initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const googleProvider = new GoogleAuthProvider();
googleProvider.setCustomParameters({ prompt: "select_account" });
