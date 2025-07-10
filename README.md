# acil_durum_app

A new Flutter project.

````markdown
# İzmir Acil Durum Uygulaması

**Dokuz Eylül Üniversitesi - Yönetim Bilişim Sistemleri Lisans Projesi**

Bu proje, afet ve acil durum anlarında vatandaşlar ile yetkililer arasında **hızlı, güvenilir ve konum tabanlı iletişim** kurulmasını amaçlayan dijital bir acil durum yönetim sistemidir.

## 🚀 Özellikler

### 📱 Mobil Uygulama (Flutter)
- Vatandaşlar için:
  - Acil durum çağrısı oluşturma (konum bilgisi ile birlikte)
  - Harita üzerinden en yakın toplanma alanlarını görüntüleme
  - Yayınlanan duyuruları takip etme
- Yöneticiler için:
  - Aktif çağrıları listeleme, arşivleme
  - Yeni duyuru oluşturma ve yönetme

### 🖥️ Web Yönetici Paneli (PHP + AJAX)
- Çağrı yönetimi (arşivleme, görüntüleme)
- Duyuru yayınlama ve canlı önizleme
- Sistem istatistikleri ve genel görünüm

### 🌐 Backend API (PHP RESTful)
- Tüm istemcilerle veri iletişimi (CRUD işlemleri)
- Güvenlik önlemleri (SQL Injection koruması)
- Harici servis (İzmir Açık Veri Portalı) entegrasyonu

### 🗄️ Veritabanı (MySQL)
- Acil çağrılar, kullanıcılar ve duyuruların yönetimi
- Temiz, ölçeklenebilir ve normalize edilmiş yapılar

## 🧱 Kullanılan Teknolojiler

| Katman | Teknoloji |
|--------|-----------|
| Mobil Uygulama | Flutter (Dart) |
| Backend API | PHP 7.x (RESTful) |
| Veritabanı | MySQL |
| Web Panel | HTML5, CSS3, JavaScript, jQuery (AJAX) |
| Harita | OpenStreetMap, flutter_map paketi |
| Lokasyon | geolocator, permission_handler |
| Diğer | İzmir Açık Veri Portalı API entegrasyonu |

## 📷 Ekran Görüntüleri

> 📌 Ekran görüntüleri klasörü içerisinde bulunmaktadır.  
> Örnek: `screenshots/`

## ⚙️ Kurulum

```bash
git clone https://github.com/kullanici-adi/acil-durum-uygulamasi.git
````

### Backend

* `htdocs/` altına backend klasörünü taşıyın
* MySQL veritabanını içe aktarın (`database.sql` dosyası)
* `config.php` içinde bağlantı bilgilerini düzenleyin

### Mobil

* Flutter SDK kurulu olmalıdır
* `lib/` klasöründen projeyi çalıştırın:

```bash
flutter pub get
flutter run
```


## 🧑‍💻 Katkıda Bulunanlar

* Safa Gök
* Aliyenur Özüağ
* Nurhak Bakıcı

