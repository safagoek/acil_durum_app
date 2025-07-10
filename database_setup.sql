-- Veritabanı oluşturma
CREATE DATABASE IF NOT EXISTS acil_durum_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE acil_durum_db;

-- Admin kullanıcıları tablosu
CREATE TABLE admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Acil çağrılar tablosu
CREATE TABLE emergency_calls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tc_kimlik VARCHAR(11) NOT NULL,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100) NOT NULL,
    mesaj TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    status ENUM('aktif', 'arsivlendi') DEFAULT 'aktif',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created_at (created_at),
    INDEX idx_status (status)
);

-- Duyurular tablosu
CREATE TABLE announcements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    baslik VARCHAR(255) NOT NULL,
    icerik TEXT NOT NULL,
    oncelik ENUM('Düşük', 'Orta', 'Yüksek') DEFAULT 'Orta',
    status ENUM('aktif', 'arsivlendi') DEFAULT 'aktif',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_created_at (created_at),
    INDEX idx_status (status)
);

-- Admin kullanıcısı (şifre: 123)
INSERT INTO admins (username, password) VALUES ('admin', '123');

-- Test duyurusu
INSERT INTO announcements (baslik, icerik, oncelik) VALUES 
('Sistem Aktif', 'Acil durum sistemi şu anda aktif olarak çalışmaktadır.', 'Orta'),
('Test Duyurusu', 'Bu bir test duyurusudur. Sistem düzgün çalışıyor.', 'Düşük'),
('Önemli Güvenlik Uyarısı', 'Sahil kesimlerde güçlü rüzgar bekleniyor. Vatandaşlarımızın dikkatli olması rica olunur.', 'Yüksek');

-- Mevcut verilere status sütunu ekleme (bu komutlar veritabanında zaten veri varsa çalıştırılacak)
-- ALTER TABLE announcements ADD COLUMN status ENUM('aktif', 'arsivlendi') DEFAULT 'aktif';
-- ALTER TABLE announcements ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
-- ALTER TABLE emergency_calls ADD COLUMN status ENUM('aktif', 'arsivlendi') DEFAULT 'aktif';