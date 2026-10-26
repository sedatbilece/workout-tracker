# Sürüm ve Build Numarası

Uygulamada Apple'ın iki ayrı numarası kullanılır. İkisi de **proje düzeyinde** tanımlıdır (Xcode'da **Project → Build Settings**; pbxproj'da proje konfigürasyonlarında Debug ve Release için ayrı ayrı). Uygulama ve `WorkoutWidgets` extension'ı bu değerleri miras alır; extension'ın numaraları uygulamayla aynı olmak zorundadır. Target → General → Identity'den değiştirmek sadece o hedefe yazar ve numaraları ayırır, bu yüzden orayı kullanma.

| Xcode alanı | pbxproj anahtarı | Ne işe yarar |
|---|---|---|
| **Version** | `MARKETING_VERSION` | Kullanıcının App Store'da gördüğü sürüm (ör. `1.1`) |
| **Build** | `CURRENT_PROJECT_VERSION` | İç sayaç, kullanıcı görmez |

## Apple kuralları

- **Version**: her yeni App Store sürümünde bir öncekinden büyük olmalı. En fazla 3 parça (`1`, `1.2`, `1.2.3`).
- **Build**: App Store Connect'e **her yüklemede benzersiz** olmalı. Reddedilen ya da işlenemeyen yüklemeler de numarayı "yakar"; aynı numara tekrar kullanılamaz.

## Projedeki şema

| Olay | Version | Build | Git tag |
|---|---|---|---|
| `dev` → `main` merge | değişmez | **+1** | `build-<N>` |
| App Store'a yeni sürüm | **artar** (1.0 → 1.1 → 1.2) | +1 | `v<version>` |

- Build numarası **asla geri gitmez ve sıfırlanmaz**, version değişse bile artmaya devam eder.
- Version küçük güncellemelerde ikinci haneyle (`1.1`, `1.2`), büyük değişikliklerde ilk haneyle (`2.0`) artırılır. Sadece hata düzeltmesi içeren acil sürümlerde üçüncü hane kullanılabilir (`1.1.1`).
- Version ve Build Debug **ve** Release konfigürasyonlarında aynı tutulur.

### `dev` → `main` merge adımları

1. `dev` üzerinde Build'i 1 artır (Xcode → Project → Build Settings → Current Project Version, ya da pbxproj'daki iki proje düzeyi `CURRENT_PROJECT_VERSION` satırı).
2. Sürüm notlarını güncelle: `workout-tracker/ReleaseNotes.json` dosyasının en üstüne yeni build için kayıt ekle (`version`, `build`, `date`, `notes`). Notlar önceki merge'den bu yana yapılanlardan çıkarılır (`git log build-<önceki N>..dev`; henüz `build-*` tag'i yoksa `origin/main..dev`). Kullanıcıya yönelik kısa maddeler, dört dilde (`tr`, `en`, `es`, `ru`); sadece iç/refactor değişiklikleri yazılmaz. `CHANGELOG.md`'deki `[Yayınlanmadı]` bölümü de yeni sürüm/build başlığına taşınır.
3. Build artışı ve notları tek commit'te at: `bump build to <N>`
4. `dev`'i `main`'e merge et.
5. Merge commit'ine tag at ve gönder:

```bash
git tag build-<N>
git push origin build-<N>
```

### App Store sürümü adımları

1. Version'ı artır, Build'i 1 artır, `ReleaseNotes.json`'a kaydı ekle (yukarıdaki 2. adım gibi), commit at: `release <version> (<N>)`
2. `main`'e merge et, Archive al ve App Store Connect'e yükle.
3. Tag at ve gönder:

```bash
git tag v<version>
git push origin v<version>
```

## Xcode Cloud notu

Projede Xcode Cloud kurulu (`workout-tracker.xcodeproj/xcshareddata/xcodecloud/`). **Xcode Cloud ile arşivlenen build'lerde Build numarasını Xcode Cloud kendi sayacıyla ezer**; pbxproj'daki `CURRENT_PROJECT_VERSION` dikkate alınmaz.

- Yükleme **Xcode'dan elle** (Product → Archive → Distribute) yapılıyorsa yukarıdaki şema aynen geçerli.
- Yükleme **Xcode Cloud** ile yapılıyorsa: Version yine elle yönetilir, Build numarası Xcode Cloud'a bırakılır. Başlangıç değeri App Store Connect → Xcode Cloud → Settings → Build Number'dan, en son kullanılan numaranın üstüne ayarlanmalı. Bu durumda `build-<N>` tag'leri Xcode Cloud'un verdiği numarayla atılır.

## Geçmiş

| Tarih | Version | Build | Not |
|---|---|---|---|
| Ekim 2026 | 1.0 | 5 | App Store Connect'e ilk yükleme. Önceki `1.3.0` geliştirme sırasında kullanılan değerdi, App Store Connect'e hiç yüklenmedi. |
| Ekim 2026 | 1.0 | 6 | `build-6` etiketi atıldı ama yükleme `NSHealthShareUsageDescription` eksik olduğu için reddedildi; numara yandı. |
| Ekim 2026 | 1.0 | 7 | TestFlight'a giden ilk `dev` → `main` build'i. |
