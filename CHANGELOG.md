# Changelog

Tüm önemli değişiklikler bu dosyada belgelenir.
Format: [Keep a Changelog](https://keepachangelog.com/tr/1.0.0/) — Sürümleme: [Semantic Versioning](https://semver.org/lang/tr/)

iOS sürüm numarası: `CFBundleShortVersionString` (ör. 1.1.0)
Build numarası: `CFBundleVersion` (ör. 2) — Her dağıtımda artar, kullanıcıya gösterilmez.

---

## [Yayınlanmadı]

---

## [1.0] - 2026-10-26 (Build 7)

### Eklendi
- **iCloud senkronu:** Şablonlar ve antrenman geçmişi, aynı Apple hesabını kullanan cihazlar arasında kullanıcının özel iCloud veritabanı üzerinden senkronize ediliyor. Profil'den açılıp kapatılabiliyor (varsayılan açık); iCloud hesap durumu gösteriliyor.
- **JSON yedek / geri yükleme:** Profil > Veri bölümünden tüm şablonlar, antrenman geçmişi ve profil bilgileri tek bir JSON dosyası olarak dışa aktarılıyor; geri yüklerken mevcut kayıtlar korunup zaten var olanlar atlanıyor.
- **Antrenman süresi:** Antrenman eklendiği an süre başlıyor; Bugün kartında ve antrenman ekranının altında canlı sayaç gösteriliyor.
- **Bitir / Devam Et:** Antrenman ekranındaki "Bitir" ile süre durduruluyor ve toplam süre kaydediliyor; "Devam Et" ile geri alınabiliyor.
- **Apple Sağlık:** Bitirilen antrenmanlar isteğe bağlı olarak Sağlık uygulamasına kuvvet antrenmanı olarak yazılıyor; geçmiş antrenmanlar toplu aktarılabiliyor.
- **Set kaydırma işlemleri:** Antrenman ve şablon ekranında set sola kaydırılınca [Kopyala] [Sil] butonları çıkıyor (Sil en sağda). Kopya, aynı kg/tekrarla setin hemen altına ekleniyor. Antrenmanda kopyalanan set o güne özel; şablonu değiştirmiyor.
- **Sürüm notları:** Profil'deki sürüm satırına dokununca her build'de nelerin değiştiği uygulama dilinde listeleniyor (`ReleaseNotes.json`).
- **Seti geri al:** Antrenmanda yanlışlıkla tamamlanan bir set kaydırılıp "Geri Al" ile yeniden düzenlenebilir hale getiriliyor; tamamlanırken şablona yazılan ağırlık/tekrar da eski değerine dönüyor.
- **Kilit ekranı ve Dinamik Ada (Live Activity):** Çalışan antrenman kilit ekranında ve Dinamik Ada'da canlı süre, egzersiz adı, set ilerlemesi ve sıradaki set (kg × tekrar) ile gösteriliyor; Apple Watch Smart Stack'te de görünüyor. Karta dokununca antrenman açılıyor. Set tamamlanınca güncelleniyor, Bitir ya da silme ile kapanıyor.
- **Ayarlar:** Profil'e "Ayarlar" satırı eklendi. Altında üç başlık var: iCloud, Sağlık ve Veri; Kilit Ekranı ve Dinamik Ada (canlı antrenman kartını aç/kapa); Dil.

### Değiştirildi
- `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` proje düzeyine taşındı; uygulama ve `WorkoutWidgets` extension'ı aynı numaraları miras alıyor.
- Seans ↔ şablon bağlantısı store'a özel `PersistentIdentifier` yerine kalıcı `uuid` ile kuruluyor; mevcut veriler açılışta `DataMigrator` ile otomatik dönüştürülüyor.
- Modeller CloudKit kurallarına uygun hale getirildi (varsayılan değerler, opsiyonel ve iki yönlü ilişkiler).
- Antrenman süresi saniyesiyle gösteriliyor (ör. "23 dk 15 sn").

### Düzeltildi
- App Store Connect yüklemesi için zorunlu `NSHealthShareUsageDescription` izin metni eklendi (dört dilde).
- Bugün ekranında set kaydırırken yaşanan takılma ve sıçrama giderildi; butonlar şablon ekranındakiyle aynı görünümde.
- Xcode derlemesindeki "Multiple commands produce …/Info.plist" hatası giderildi (`Info.plist` → `Support/Info.plist`).

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
