@echo off
echo ========================================
echo   Investment Tracker - Firebase Deploy
echo ========================================
echo.

echo Step 1: Installing Firebase CLI...
npm install -g firebase-tools

echo.
echo Step 2: Building Flutter Web App...
flutter build web --release

echo.
echo Step 3: Firebase Login...
firebase login

echo.
echo Step 4: Initialize Firebase Project...
firebase init hosting

echo.
echo Step 5: Deploy to Firebase...
firebase deploy

echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo Your app is now live at the URL shown above
echo Share this URL with your friends for feedback
echo.
pause