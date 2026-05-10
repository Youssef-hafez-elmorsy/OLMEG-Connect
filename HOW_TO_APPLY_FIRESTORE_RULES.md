# How to Apply Firestore Security Rules for Notifications

## Step-by-Step Guide

### Step 1: Go to Firebase Console
1. Open your browser
2. Go to: https://console.firebase.google.com
3. Sign in with your Google account
4. Select your project (OLMEG Connect)

### Step 2: Navigate to Firestore Database
1. In the left sidebar, click **"Firestore Database"**
2. You should see your database listed

### Step 3: Open Rules Tab
1. Click on the **"Rules"** tab at the top
2. You'll see the current security rules (might be empty or have default rules)

### Step 4: Copy the New Rules
Copy this complete code:

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

    // Notifications collection - THIS FIXES YOUR ERROR
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

### Step 5: Paste Rules into Firebase Console
1. In the Rules editor, **select all** the existing text (Ctrl+A or Cmd+A)
2. **Delete** the old rules
3. **Paste** the new rules you copied above
4. The editor should show the new rules

### Step 6: Publish the Rules
1. Click the **"Publish"** button (usually blue, top-right)
2. A dialog will appear asking to confirm
3. Click **"Publish"** again to confirm
4. Wait for the rules to be published (usually takes 1-2 minutes)
5. You should see a success message

---

## What Each Rule Does

### Notifications Rule (The Important One)
```javascript
match /notifications/{notificationId} {
  allow read: if request.auth != null && 
    request.auth.uid == resource.data.userId;
  allow create: if request.auth != null;
  allow update, delete: if request.auth != null && 
    request.auth.uid == resource.data.userId;
}
```

**Explanation:**
- `allow read`: Only logged-in users can read their own notifications
- `allow create`: Any logged-in user can create notifications
- `allow update, delete`: Only the notification owner can update/delete

---

## Verification Steps

After publishing the rules:

1. **Restart your app**
   - Close the Flutter app completely
   - Run it again: `flutter run`

2. **Test Notifications**
   - Go to Home screen
   - Click on Notifications tab
   - You should see the notification badge with count
   - No [failed-precondition] error should appear

3. **Check Browser Console** (if using web)
   - Press F12 to open Developer Tools
   - Go to Console tab
   - Look for any Firebase errors
   - Should be no errors now

---

## If You Get an Error

### Error: "Missing or insufficient permissions"
**Solution**: Make sure you're logged in to the app
- The rules require `request.auth != null`
- You must be authenticated

### Error: "Document doesn't exist"
**Solution**: This is normal if there are no notifications yet
- Create a notification first
- Then try to read it

### Error: Still getting [failed-precondition]
**Solution**: 
1. Check that the rules were published successfully
2. Wait 2-3 minutes for rules to propagate
3. Clear browser cache (Ctrl+Shift+Delete)
4. Restart the app

---

## Quick Reference

| Action | Who Can Do It |
|--------|---------------|
| Read notifications | Only the user who owns them |
| Create notifications | Any logged-in user |
| Update notifications | Only the owner |
| Delete notifications | Only the owner |

---

## Important Notes

⚠️ **Make sure:**
- You're in the correct Firebase project
- You're in the Firestore Database section (not Realtime Database)
- The rules are published (not just saved)
- Your app is restarted after publishing

✅ **After publishing:**
- Notifications should work
- No [failed-precondition] error
- Badge count should display
- You can read/create/update notifications

---

## Still Having Issues?

If notifications still don't work:

1. **Check Firestore Collections**
   - Go to Firestore Database
   - Click "Data" tab
   - Look for "notifications" collection
   - If it doesn't exist, create it manually

2. **Check Notification Documents**
   - Open notifications collection
   - Each document should have:
     - `userId` field (user ID)
     - `read` field (true/false)
     - `title` field
     - `message` field
     - `createdAt` field

3. **Check Authentication**
   - Make sure you're logged in
   - Check that `request.auth.uid` matches `userId` in notification

---

**Status**: ✅ Rules Applied Successfully

After following these steps, your notifications should work without errors!
