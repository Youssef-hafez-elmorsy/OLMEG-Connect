# Quick Reference - Apply Firestore Rules in 5 Minutes

## 🚀 Quick Steps

### 1️⃣ Open Firebase Console
```
https://console.firebase.google.com
```

### 2️⃣ Select Your Project
Click on **OLMEG Connect**

### 3️⃣ Go to Firestore Database
Left sidebar → **Firestore Database**

### 4️⃣ Click Rules Tab
Top tabs → **Rules**

### 5️⃣ Copy & Paste Rules

**Delete old rules** (Ctrl+A, Delete)

**Paste this code:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /products/{productId} {
      allow read: if true;
      allow create, update, delete: if request.auth != null && request.resource.data.sellerId == request.auth.uid;
    }
    match /posts/{postId} {
      allow read: if true;
      allow create, update, delete: if request.auth != null;
    }
    match /chats/{chatId} {
      allow read, write: if request.auth != null && (request.auth.uid == resource.data.buyerId || request.auth.uid == resource.data.sellerId);
    }
    match /notifications/{notificationId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    match /favorites/{favoriteId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    match /ratings/{ratingId} {
      allow read: if true;
      allow create, update, delete: if request.auth != null;
    }
    match /searchHistory/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 6️⃣ Click Publish
Blue **Publish** button → Confirm

### 7️⃣ Wait 1-2 Minutes
Rules are being published...

### 8️⃣ Restart App
```bash
flutter run
```

### 9️⃣ Test Notifications
- Go to Home
- Click Notifications tab
- Should see badge with count
- No errors!

---

## ✅ What Gets Fixed

| Issue | Fixed |
|-------|-------|
| [failed-precondition] error | ✅ Yes |
| Notification badge not showing | ✅ Yes |
| Can't read notifications | ✅ Yes |
| Can't create notifications | ✅ Yes |

---

## 📋 Checklist

- [ ] Opened Firebase Console
- [ ] Selected OLMEG Connect project
- [ ] Went to Firestore Database
- [ ] Clicked Rules tab
- [ ] Deleted old rules
- [ ] Pasted new rules
- [ ] Clicked Publish
- [ ] Confirmed publication
- [ ] Waited for completion
- [ ] Restarted app
- [ ] Tested notifications
- [ ] ✅ All working!

---

## 🆘 If Something Goes Wrong

### Error: "Syntax error"
→ Copy rules again, make sure all brackets match

### Error: "Still getting [failed-precondition]"
→ Wait 2-3 minutes, clear cache, restart app

### Error: "Can't find Firestore Database"
→ Check you're in correct project, look under "Build" in sidebar

### Error: "Rules won't publish"
→ Check for red underlines in editor, fix syntax errors

---

## 📞 Need Help?

1. Check `HOW_TO_APPLY_FIRESTORE_RULES.md` for detailed steps
2. Check `FIREBASE_CONSOLE_VISUAL_GUIDE.md` for visual guide
3. Make sure you're logged in to Firebase Console
4. Make sure you're in the correct project

---

**Time to Complete**: 5 minutes  
**Difficulty**: Easy  
**Result**: ✅ Notifications working!
