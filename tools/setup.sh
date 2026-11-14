#!/usr/bin/env bash
# Android/iOS platform klasörlerini oluşturur ve gerekli ayarları ekler.
set -e
cd "$(dirname "$0")/.."
flutter create --platforms=android,ios --org com.muba14 --project-name facefit .
flutter pub get

# iOS: kamera ve galeri izin açıklamaları
PLIST=ios/Runner/Info.plist
if [ -f "$PLIST" ] && ! grep -q NSCameraUsageDescription "$PLIST"; then
  sed -i.bak 's#<dict>#<dict>\n\t<key>NSCameraUsageDescription</key>\n\t<string>Yüz şeklini analiz etmek için selfie çekilir.</string>\n\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>Yüz şeklini analiz etmek için galeriden fotoğraf seçilir.</string>#' "$PLIST" && rm -f "$PLIST.bak"
fi

# Uygulama adı
for f in android/app/src/main/AndroidManifest.xml; do
  [ -f "$f" ] && sed -i.bak 's/android:label="facefit"/android:label="FaceFit"/' "$f" && rm -f "$f.bak"
done

dart run flutter_launcher_icons
echo "Hazır! Çalıştırmak için: flutter run   |   APK için: flutter build apk --release"
