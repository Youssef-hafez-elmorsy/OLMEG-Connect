# Firestore Security Rules Fix for Notifications

## Issue: [cloud-firestore/failed-precondition]

The error occurs because Firestore security rules are not properly configured for the notifications collection.

## Solution: Update Firestore Security Rules

Add these rules to your Firestore console:

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

    // Notifications collection - FIX
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

    // Search history (if using Firestore)
    match /searchHistory/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

## Steps to Apply:

1. Go to Firebase Console
2. Select your project
3. Go to Firestore Database
4. Click on "Rules" tab
5. Replace the existing rules with the above
6. Click "Publish"

## Alternative: If you want to test without strict rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Note**: This is for development only. Use the strict rules above for production.

## Verification:

After updating the rules:
1. Restart the app
2. Try to view notifications
3. The error should be gone
4. Notification badge should display correctly

## If error persists:

1. Check that you're logged in (auth.uid exists)
2. Verify the notifications collection exists in Firestore
3. Check browser console for detailed error messages
4. Ensure the notification document has a `userId` field
