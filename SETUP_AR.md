# خطوات التشغيل بالعربي

1. ثبّت Flutter 3.38.1 أو أحدث ثم شغّل `flutter doctor`.
2. افتح مجلد المشروع في Android Studio أو VS Code.
3. من Terminal داخل المشروع شغّل:
   - `flutter pub get`
   - `flutter gen-l10n`
   - `flutter run`
4. المشروع يستخدم إعلانات Google التجريبية فقط.
5. لا تضع معرفات AdMob الحقيقية قبل اكتمال سياسة الخصوصية وشاشة الموافقة UMP والاختبارات.
6. لإنشاء ملف النشر على Google Play شغّل `flutter build appbundle --release` بعد إعداد مفتاح التوقيع الحقيقي.
