@echo off
echo Building Investment Tracker for Web...
flutter build web --release

echo.
echo Build complete! 
echo Upload the 'build\web' folder to:
echo - Firebase Hosting
echo - Netlify
echo - GitHub Pages
echo - Any web hosting service

pause