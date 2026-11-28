import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging, Messaging } from 'firebase-admin/messaging';

let messaging: Messaging | undefined;

export function getFirebaseMessaging(): Messaging | null {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    if (!projectId || !clientEmail || !privateKey) return null;
    if (messaging) return messaging;

    const app = getApps().find((existing) => existing.name === 'wedapola-fcm') ?? initializeApp({
        credential: cert({ projectId, clientEmail, privateKey }),
        projectId,
    }, 'wedapola-fcm');

    messaging = getMessaging(app);
    return messaging;
}
