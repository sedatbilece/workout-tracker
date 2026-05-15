# Changelog

Tüm önemli değişiklikler bu dosyada belgelenir.
Format: [Keep a Changelog](https://keepachangelog.com/tr/1.0.0/) — Sürümleme: [Semantic Versioning](https://semver.org/lang/tr/)

iOS sürüm numarası: `CFBundleShortVersionString` (ör. 1.1.0)
Build numarası: `CFBundleVersion` (ör. 2) — Her dağıtımda artar, kullanıcıya gösterilmez.

---

## [1.3.0] - 2026-05-15 (Build 4)

### Eklendi
- **Çoklu dil desteği:** Türkçe, İngilizce, İspanyolca ve Rusça dil seçeneği; sistem dili otomatik algılanıyor.
- **Dil ayarları ekranı:** Profil sekmesinden uygulama dili anında değiştirilebiliyor (`LanguageSettingsView`).
- **Lokalizasyon altyapısı:** `LocalizationManager` + `Localizable.xcstrings` ile tüm kullanıcıya yönelik metinler lokalize edildi.

### Değiştirildi
- Profil ekranı yeniden düzenlendi; dil ayarları bölümü eklendi.
- `AppLanguage` enum'u ile desteklenen diller ve bayrak emojileri merkezi olarak yönetiliyor.
- `AppTheme` ve `DateHelper` lokalizasyon sistemine uyumlu hale getirildi.

---

## [1.2.0] - 2026-05-14 (Build 3)

### Eklendi
- **Dumbbell uygulama ikonu:** Koyu arka plan üzerinde mavi dumbbell tasarımı; light, dark ve tinted varyantları eklendi.

### Değiştirildi
- **Set / kg girişi stepper'a dönüştürüldü:** Tekrar sayısı 1–20 aralığında 1'er adımla, ağırlık 2,5 kg adımlarla `−` / `+` butonlarıyla ayarlanır. Klavye artık açılmaz.

---

## [1.1.0] - 2026-05-13 (Build 2)

### Eklendi
- **Set kopyalama:** Antrenman sırasında bir sete sağa kaydırınca "Kopyala" butonu çıkar; aynı kg ve tekrar değerleriyle yeni set eklenir. Şablona yansımaz.
- **Set silme (antrenman):** Sola kaydırınca "Sil" butonu; seti sadece o günkü seansdan kaldırır, şablona dokunmaz.
- **Egzersiz silme (antrenman):** Egzersiz kartına uzun basınca "Egzersizi Sil" seçeneği çıkar. Cascade ile altındaki tüm setler de silinir; şablon etkilenmez.

### Düzeltildi
- **Kg / tekrar girişi:** Alana tıklanınca varsayılan değer temizlenir, yeni değer doğrudan girilebilir. Geçersiz giriş yapılırsa önceki değer geri yüklenir.
- **Set silme (şablon düzenleme):** Şablonda set silinince UI'dan kalkıp geri gelmesi sorunu giderildi. (SwiftData ilişki dizisinden önce çıkar, sonra siler.)

---

## [1.0.0] - 2026-05-13 (Build 1)

### Eklendi
- Şablon tabanlı antrenman yönetimi (WorkoutTemplate → ExerciseTemplate → SetTemplate)
- Günlük antrenman seansı oluşturma ve set tamamlama
- Tamamlanan setin kg/tekrar değerleri bir sonraki antrenman için şablona otomatik yansıtılır
- İkon seçici ile egzersiz kişiselleştirme
- Bugün / Şablonlar / İstatistikler (yakında) sekme yapısı
