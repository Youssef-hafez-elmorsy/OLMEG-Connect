# Firebase Console - Visual Step-by-Step Guide

## 🎯 Goal: Apply Firestore Security Rules for Notifications

---

## STEP 1: Open Firebase Console

**URL**: https://console.firebase.google.com

```
┌─────────────────────────────────────────────────────────┐
│  Firebase Console                                       │
│  ┌─────────────────────────────────────────────────────┐│
│  │ Google Sign In                                      ││
│  │ [Sign in with your Google account]                 ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

---

## STEP 2: Select Your Project

After signing in, you'll see your projects list.

```
┌─────────────────────────────────────────────────────────┐
│  My Projects                                            │
│  ┌─────────────────────────────────────────────────────┐│
│  │ OLMEG Connect  [Click Here]                         ││
│  │ Other Project                                       ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

**Click on "OLMEG Connect"**

---

## STEP 3: Navigate to Firestore Database

In the left sidebar, find and click **"Firestore Database"**

```
Left Sidebar:
├── Build
│   ├── Authentication
│   ├── Firestore Database  ← CLICK HERE
│   ├── Realtime Database
│   ├── Storage
│   └── Hosting
├── Analyze
└── Settings
```

---

## STEP 4: Click on "Rules" Tab

Once in Firestore Database, you'll see tabs at the top:

```
┌─────────────────────────────────────────────────────────┐
│  Firestore Database                                     │
│  ┌─────────────────────────────────────────────────────┐│
│  │ [Data]  [Rules]  [Indexes]  [Usage]                ││
│  │         ↑ CLICK HERE                                ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

**Click on "Rules" tab**

---

## STEP 5: See Current Rules

You'll see the current rules in the editor:

```
┌─────────────────────────────────────────────────────────┐
│  Rules Editor                                           │
│  ┌─────────────────────────────────────────────────────┐│
│  │ rules_version = '2';                                ││
│  │ service cloud.firestore {                           ││
│  │   match /databases/{database}/documents {           ││
│  │     match /{document=**} {                          ││
│  │       allow read, write: if false;                  ││
│  │     }                                               ││
│  │   }                                                 ││
│  │ }                                                   ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

---

## STEP 6: Select All and Delete

1. **Click inside the editor**
2. **Press Ctrl+A** (or Cmd+A on Mac) to select all
3. **Press Delete** to remove old rules

```
┌─────────────────────────────────────────────────────────┐
│  Rules Editor (Empty)                                   │
│  ┌─────────────────────────────────────────────────────┐│
│  │                                                     ││
│  │                                                     ││
│  │                                                     ││
│  │                                                     ││
│  │                                                     ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

---

## STEP 7: Paste New Rules

**Copy this entire code:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Products collection
    match /products/{productId} {
      allow read: if true;
      allow create, update, delete: if request.auth != null && 
        request.resource.data.sellerId == request.auth.uid;
    }

    // Posts collection
    match /posts/{postId} {
      allow read: if true;
      allow create, update, delete: if request.auth != null;
    }

    // Chat collection
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.buyerId || 
         request.auth.uid == resource.data.sellerId);
    }

    // Notifications collection - IMPORTANT FOR YOUR FIX
    match /notifications/{notificationId} {
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }

    // Favorites collection
    match /favorites/{favoriteId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }

    // Ratings collection
    match /ratings/{ratingId} {
      allow read: if true;
      allow create, update, delete: if request.auth != null;
    }

    // Search history
    match /searchHistory/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

**Then:**
1. **Click inside the editor**
2. **Press Ctrl+V** (or Cmd+V on Mac) to paste

```
┌─────────────────────────────────────────────────────────┐
│  Rules Editor (With New Rules)                          │
│  ┌─────────────────────────────────────────────────────┐│
│  │ rules_version = '2';                                ││
│  │ service cloud.firestore {                           ││
│  │   match /databases/{database}/documents {           ││
│  │     // Users collection                             ││
│  │     match /users/{userId} {                         ││
│  │       allow read, write: if request.auth.uid == ... ││
│  │     }                                               ││
│  │     ...                                             ││
│  │     // Notifications collection                     ││
│  │     match /notifications/{notificationId} {         ││
│  │       allow read: if request.auth != null && ...    ││
│  │     }                                               ││
│  │     ...                                             ││
│  │ }                                                   ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

---

## STEP 8: Click "Publish" Button

Look for the **"Publish"** button (usually blue, top-right):

```
┌─────────────────────────────────────────────────────────┐
│  Rules Editor                                           │
│  ┌──────────────────────────────────────────────────────┐
│  │ [Publish]  [Cancel]                                 │
│  │     ↑ CLICK HERE                                    │
│  └──────────────────────────────────────────────────────┘
│  ┌─────────────────────────────────────────────────────┐│
│  │ rules_version = '2';                                ││
│  │ service cloud.firestore {                           ││
│  │   ...                                               ││
│  │ }                                                   ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

**Click "Publish"**

---

## STEP 9: Confirm Publication

A dialog will appear asking to confirm:

```
┌─────────────────────────────────────────────────────────┐
│  Confirm Publish                                        │
│  ┌─────────────────────────────────────────────────────┐│
│  │ Are you sure you want to publish these rules?       ││
│  │                                                     ││
│  │ [Cancel]  [Publish]                                ││
│  │            ↑ CLICK HERE                             ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

**Click "Publish" again to confirm**

---

## STEP 10: Wait for Publication

You'll see a loading message:

```
┌─────────────────────────────────────────────────────────┐
│  Publishing Rules...                                    │
│  ┌─────────────────────────────────────────────────────┐│
│  │ ⏳ Publishing security rules...                      ││
│  │ This may take a few moments                         ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

**Wait 1-2 minutes for completion**

---

## STEP 11: Success Message

You should see a success notification:

```
┌─────────────────────────────────────────────────────────┐
│  ✅ Rules Published Successfully                        │
│  ┌─────────────────────────────────────────────────────┐│
│  │ Your security rules have been published             ││
│  │ Changes may take a few moments to take effect       ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

---

## STEP 12: Restart Your App

1. **Close the Flutter app** (if running)
2. **Run it again**:
   ```bash
   flutter run
   ```

---

## STEP 13: Test Notifications

1. **Go to Home screen**
2. **Click Notifications tab** (bottom navigation)
3. **Check for:**
   - ✅ Notification badge with count
   - ✅ No [failed-precondition] error
   - ✅ Notification list displays

---

## ✅ Done!

Your Firestore security rules are now applied and notifications should work!

---

## 🆘 Troubleshooting

### Problem: Rules won't publish
**Solution**: 
- Check for syntax errors (red underlines in editor)
- Make sure all brackets are closed
- Try copying the rules again

### Problem: Still getting errors
**Solution**:
- Wait 2-3 minutes for rules to propagate
- Clear browser cache
- Restart the app
- Check that you're logged in

### Problem: Can't find Firestore Database
**Solution**:
- Make sure you're in the correct Firebase project
- Check left sidebar under "Build" section
- If not there, you may need to create a Firestore database first

---

**Status**: ✅ Rules Applied Successfully

Your notifications should now work without errors!
