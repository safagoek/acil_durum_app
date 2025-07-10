<?php
session_start();

// Veritabanı bağlantısı
$host = "localhost";
$dbname = "acil_durum_db";
$username = "root";
$password = "";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Bağlantı hatası: " . $e->getMessage());
}

// Login kontrolü
if (!isset($_SESSION['admin_logged_in'])) {
    if ($_POST && isset($_POST['login'])) {
        $user = $_POST['username'] ?? '';
        $pass = $_POST['password'] ?? '';
        
        $stmt = $pdo->prepare("SELECT * FROM admins WHERE username = ?");
        $stmt->execute([$user]);
        $admin = $stmt->fetch();
        
        if ($admin && $pass === '123') { // Güvenlik için gerçek bir projede parola hashlenmeli!
            $_SESSION['admin_logged_in'] = true;
            $_SESSION['admin_username'] = $admin['username'];
            header("Location: " . $_SERVER['PHP_SELF']);
            exit;
        } else {
            $login_error = "Geçersiz kullanıcı adı veya şifre!";
        }
    }
    
    // Login formu göster
    ?>
    <!DOCTYPE html>
    <html lang="tr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Admin Girişi - Acil Durum Sistemi</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
        <style>
            body {
                background: linear-gradient(135deg, #dc3545 0%, #c82333 50%, #bd2130 100%);
                min-height: 100vh;
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                display: flex; /* Added for centering */
                align-items: center; /* Added for centering */
                justify-content: center; /* Added for centering */
            }
            .login-container { /* Removed min-height and centering from here */
                width: 100%;
            }
            .login-card {
                background: rgba(255, 255, 255, 0.98); /* Slightly more opaque */
                backdrop-filter: blur(10px);
                border: none;
                border-radius: 25px; /* More rounded */
                box-shadow: 0 25px 50px rgba(0,0,0,0.35); /* Deeper shadow */
                overflow: hidden;
            }
            .login-header {
                background: linear-gradient(45deg, #dc3545, #c82333);
                padding: 2.5rem; /* Increased padding */
                text-align: center;
                border: none;
            }
            .login-header i {
                font-size: 3.5rem; /* Larger icon */
                margin-bottom: 1.2rem;
                opacity: 0.9;
                color: white; /* Ensure icon is white */
            }
             .login-header h3 {
                font-weight: 700; /* Bolder title */
            }
            .login-body {
                padding: 2.5rem 3rem; /* More padding */
            }
            .form-control {
                border-radius: 12px; /* Consistent rounding */
                border: 1px solid #ced4da; /* Standard border */
                padding: 14px 20px; /* Increased padding */
                transition: all 0.3s ease;
                box-shadow: inset 0 1px 3px rgba(0,0,0,0.05);
            }
            .form-control:focus {
                border-color: #dc3545;
                box-shadow: 0 0 0 0.25rem rgba(220, 53, 69, 0.25), inset 0 1px 3px rgba(0,0,0,0.05);
            }
            .btn-login {
                background: linear-gradient(45deg, #dc3545, #c82333);
                border: none;
                border-radius: 12px; /* Consistent rounding */
                padding: 14px 0;
                font-weight: 600;
                transition: all 0.3s ease;
                box-shadow: 0 4px 10px rgba(220, 53, 69, 0.2);
            }
            .btn-login:hover {
                transform: translateY(-3px); /* More pronounced hover */
                box-shadow: 0 8px 15px rgba(220, 53, 69, 0.35);
            }
            .emergency-icons {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                pointer-events: none;
                z-index: -1;
                overflow: hidden; /* Prevent icons from causing scroll */
            }
            .emergency-icon {
                position: absolute;
                color: rgba(255,255,255,0.08); /* More subtle */
                animation: float 8s ease-in-out infinite; /* Slower animation */
                opacity: 0.7;
            }
            @keyframes float {
                0%, 100% { transform: translateY(0px) rotate(0deg); }
                50% { transform: translateY(-25px) rotate(5deg); }
            }
            .alert-danger { /* Custom styling for login error */
                background-color: #f8d7da;
                border-color: #f5c6cb;
                color: #721c24;
                border-radius: 10px;
                padding: 1rem 1.25rem;
            }
        </style>
    </head>
    <body>
        <div class="emergency-icons">
            <i class="fas fa-ambulance emergency-icon" style="top: 10%; left: 5%; font-size: 4rem; animation-delay: 0s;"></i>
            <i class="fas fa-fire-extinguisher emergency-icon" style="top: 15%; right: 8%; font-size: 3.5rem; animation-delay: 1.5s;"></i>
            <i class="fas fa-heartbeat emergency-icon" style="bottom: 15%; left: 10%; font-size: 3rem; animation-delay: 2.5s;"></i>
            <i class="fas fa-shield-alt emergency-icon" style="bottom: 25%; right: 5%; font-size: 4rem; animation-delay: 3.5s;"></i>
            <i class="fas fa-bell emergency-icon" style="top: 50%; left: 45%; font-size: 3rem; animation-delay: 0.5s;"></i>
            <i class="fas fa-briefcase-medical emergency-icon" style="bottom: 5%; left: 60%; font-size: 3.5rem; animation-delay: 4s;"></i>
        </div>
        
        <div class="login-container">
            <div class="container">
                <div class="row justify-content-center">
                    <div class="col-md-6 col-lg-5 col-xl-4"> {/* Adjusted column size for better centering */}
                        <div class="card login-card">
                            <div class="card-header login-header text-white">
                                <i class="fas fa-shield-virus"></i> {/* Changed icon */}
                                <h3 class="mb-0">ACİL DURUM SİSTEMİ</h3>
                                <p class="mb-0 opacity-75">Admin Paneli Girişi</p>
                            </div>
                            <div class="card-body login-body">
                                <?php if (isset($login_error)): ?>
                                    <div class="alert alert-danger border-0 rounded-3">
                                        <i class="fas fa-times-circle me-2"></i><?= $login_error ?>
                                    </div>
                                <?php endif; ?>
                                <form method="POST">
                                    <div class="mb-4">
                                        <label class="form-label fw-bold text-secondary"> {/* Softer text color */}
                                            <i class="fas fa-user-circle me-2 text-danger"></i>Kullanıcı Adı
                                        </label>
                                        <input type="text" class="form-control" name="username" required placeholder="Kullanıcı adınızı girin">
                                    </div>
                                    <div class="mb-4">
                                        <label class="form-label fw-bold text-secondary"> {/* Softer text color */}
                                            <i class="fas fa-key me-2 text-danger"></i>Şifre
                                        </label>
                                        <input type="password" class="form-control" name="password" required placeholder="Şifrenizi girin">
                                    </div>
                                    <input type="hidden" name="login" value="1"> {/* Ensure login value is always sent */}
                                    <button type="submit" class="btn btn-danger btn-login w-100 mt-3"> {/* Added margin top */}
                                        <i class="fas fa-sign-in-alt me-2"></i>SİSTEME GİRİŞ YAP
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    </body>
    </html>
    <?php
    exit;
}

// Logout
if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: " . $_SERVER['PHP_SELF']);
    exit;
}

// Yeni duyuru ekleme
if ($_POST && isset($_POST['add_announcement'])) {
    $baslik = $_POST['baslik'] ?? '';
    $icerik = $_POST['icerik'] ?? '';
    $oncelik = $_POST['oncelik'] ?? 'Orta';
    
    if (!empty($baslik) && !empty($icerik)) {
        $stmt = $pdo->prepare("INSERT INTO announcements (baslik, icerik, oncelik) VALUES (?, ?, ?)");
        if ($stmt->execute([$baslik, $icerik, $oncelik])) {
            $_SESSION['flash_message'] = ['type' => 'success', 'text' => 'Duyuru başarıyla eklendi!'];
        } else {
            $_SESSION['flash_message'] = ['type' => 'danger', 'text' => 'Duyuru eklenirken hata oluştu!'];
        }
    } else {
        $_SESSION['flash_message'] = ['type' => 'warning', 'text' => 'Lütfen tüm alanları doldurun!'];
    }
    header("Location: " . $_SERVER['PHP_SELF'] . "#pills-add-announcement-tab"); // Redirect to clear POST and show message
    exit;
}


// AJAX işlemleri
if ($_POST && isset($_POST['action'])) {
    header('Content-Type: application/json');
    
    switch ($_POST['action']) {
        case 'update_call_status':
            $stmt = $pdo->prepare("UPDATE emergency_calls SET status = ? WHERE id = ?");
            $result = $stmt->execute([$_POST['status'], $_POST['id']]);
            echo json_encode(['success' => $result]);
            break;
            
        case 'update_call_note':
            $stmt = $pdo->prepare("UPDATE emergency_calls SET admin_note = ? WHERE id = ?");
            $result = $stmt->execute([$_POST['note'], $_POST['id']]);
            echo json_encode(['success' => $result]);
            break;
            
        case 'update_announcement_status':
            $stmt = $pdo->prepare("UPDATE announcements SET status = ? WHERE id = ?");
            $result = $stmt->execute([$_POST['status'], $_POST['id']]);
            echo json_encode(['success' => $result]);
            break;
            
        case 'update_announcement_note':
            $stmt = $pdo->prepare("UPDATE announcements SET admin_note = ? WHERE id = ?");
            $result = $stmt->execute([$_POST['note'], $_POST['id']]);
            echo json_encode(['success' => $result]);
            break;

        case 'delete_announcement':
            $stmt = $pdo->prepare("DELETE FROM announcements WHERE id = ?");
            $result = $stmt->execute([$_POST['id']]);
            echo json_encode(['success' => $result]);
            break;
    }
    exit;
}

// Flash mesajlarını al ve temizle
$flash_message = null;
if (isset($_SESSION['flash_message'])) {
    $flash_message = $_SESSION['flash_message'];
    unset($_SESSION['flash_message']);
}


// Verileri çek - SADECE AKTİFLERİ
$calls = $pdo->query("SELECT * FROM emergency_calls WHERE status = 'aktif' ORDER BY created_at DESC")->fetchAll();
$announcements = $pdo->query("SELECT * FROM announcements WHERE status = 'aktif' ORDER BY created_at DESC")->fetchAll();

// Arşiv verileri ayrı çek
$archived_calls = $pdo->query("SELECT * FROM emergency_calls WHERE status = 'arsivlendi' ORDER BY created_at DESC")->fetchAll();
$archived_announcements = $pdo->query("SELECT * FROM announcements WHERE status = 'arsivlendi' ORDER BY created_at DESC")->fetchAll();

// İstatistikler
$active_calls_count = $pdo->query("SELECT COUNT(*) FROM emergency_calls WHERE status = 'aktif'")->fetchColumn();
$active_announcements_count = $pdo->query("SELECT COUNT(*) FROM announcements WHERE status = 'aktif'")->fetchColumn();
$archived_calls_count = $pdo->query("SELECT COUNT(*) FROM emergency_calls WHERE status = 'arsivlendi'")->fetchColumn();
$archived_announcements_count = $pdo->query("SELECT COUNT(*) FROM announcements WHERE status = 'arsivlendi'")->fetchColumn();
?>

<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Acil Durum Admin Paneli</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        :root {
            --emergency-red: #d90429; /* Daha canlı bir kırmızı */
            --emergency-dark-red: #a4001e; /* Daha koyu kırmızı */
            --emergency-light-red: #fee2e7; /* Çok açık kırmızı */
            --emergency-orange: #f77f00; /* Canlı turuncu */
            --emergency-yellow: #ffca2c; /* Canlı sarı */
            --emergency-green: #008000; /* Standart yeşil */
            --emergency-blue: #0077b6; /* Profesyonel mavi */
            --emergency-gray: #6c757d;
            --light-gray: #f8f9fa;
            --medium-gray: #e9ecef;
            --dark-gray: #343a40;
            --text-muted-light: #adb5bd;

            --primary-font: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            --border-radius-sm: 0.5rem; /* 8px */
            --border-radius-md: 0.75rem; /* 12px */
            --border-radius-lg: 1.25rem; /* 20px */
            --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            --shadow-md: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
            --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.175);
        }

        body {
            background-color: var(--light-gray);
            font-family: var(--primary-font);
            min-height: 100vh;
            color: var(--dark-gray);
        }

        /* Navbar Styling */
        .navbar-emergency {
            background: linear-gradient(135deg, var(--emergency-red) 0%, var(--emergency-dark-red) 100%);
            box-shadow: var(--shadow-md);
            padding-top: 0.75rem;
            padding-bottom: 0.75rem;
        }

        .navbar-brand {
            font-weight: 700;
            font-size: 1.6rem; /* Biraz daha büyük */
            text-shadow: 1px 1px 2px rgba(0,0,0,0.2);
        }

        .navbar-brand i {
            margin-right: 12px; /* Daha fazla boşluk */
            animation: pulse 2.5s infinite ease-in-out;
        }

        @keyframes pulse { /* Geliştirilmiş pulse animasyonu */
            0% { transform: scale(1); opacity: 0.8; }
            50% { transform: scale(1.15); opacity: 1; }
            100% { transform: scale(1); opacity: 0.8; }
        }
        .navbar-text { color: rgba(255,255,255,0.9) !important; }
        .btn-logout {
            background-color: rgba(255,255,255,0.15);
            border: 1px solid rgba(255,255,255,0.3);
            color: white;
            transition: all 0.3s ease;
        }
        .btn-logout:hover {
            background-color: rgba(255,255,255,0.3);
            border-color: white;
            color: white;
        }

        /* İstatistik Kartları */
        .stat-card {
            border: none;
            border-radius: var(--border-radius-lg);
            overflow: hidden;
            transition: all 0.35s cubic-bezier(0.25, 0.8, 0.25, 1); /* Yumuşak geçiş */
            box-shadow: var(--shadow-sm);
            background-size: 200% 200%; /* Gradient animasyonu için */
            color: white;
        }

        .stat-card:hover {
            transform: translateY(-8px) scale(1.02); /* Daha belirgin hover */
            box-shadow: var(--shadow-lg);
            background-position: right center; /* Gradient animasyonu */
        }

        .stat-card.danger { background-image: linear-gradient(to right, #ef233c, #d90429, #a4001e); }
        .stat-card.secondary { background-image: linear-gradient(to right, #8d99ae, #6c757d, #495057); }
        .stat-card.success { background-image: linear-gradient(to right, #2a9d8f, #008000, #006400); }
        .stat-card.info { background-image: linear-gradient(to right, #00b4d8, #0077b6, #023e8a); }


        .stat-icon {
            font-size: 3rem; /* Biraz küçültüldü */
            margin-bottom: 0.75rem;
            opacity: 0.8;
            text-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }

        .stat-number {
            font-size: 2.75rem; /* Biraz küçültüldü */
            font-weight: 700;
        }
        .stat-card .card-body { padding: 1.75rem; } /* Daha iyi iç boşluk */
        .stat-card .fw-bold { font-size: 1.1rem; }
        .stat-card small { font-size: 0.85rem; opacity: 0.85; }


        /* Tab Styling */
        .nav-pills {
            background: white;
            border-radius: var(--border-radius-lg); /* Daha yuvarlak */
            padding: 0.75rem; /* Hafifçe ayarlandı */
            box-shadow: var(--shadow-sm);
            margin-bottom: 2.5rem; /* Daha fazla boşluk */
            display: inline-flex; /* İçeriğe göre sığdır */
        }
        .nav-pills .nav-link {
            border-radius: var(--border-radius-md); /* Daha yuvarlak */
            font-weight: 600;
            color: var(--emergency-gray);
            transition: all 0.3s ease;
            margin: 0 0.3rem;
            padding: 0.85rem 1.5rem; /* Daha iyi tıklama alanı */
            font-size: 0.95rem;
        }
        .nav-pills .nav-link:hover {
            background-color: var(--emergency-light-red);
            color: var(--emergency-red);
            transform: translateY(-2px);
        }
        .nav-pills .nav-link.active {
            background: linear-gradient(135deg, var(--emergency-red), var(--emergency-dark-red));
            color: white;
            box-shadow: 0 4px 12px rgba(217, 4, 41, 0.35);
        }
        .nav-pills .nav-link i { margin-right: 0.6rem; }

        /* Card Styling */
        .custom-card {
            border: none;
            border-radius: var(--border-radius-lg);
            box-shadow: var(--shadow-md);
            overflow: hidden;
            background: white;
            margin-bottom: 2rem; /* Kartlar arası boşluk */
        }
        .custom-card-header {
            background: linear-gradient(135deg, var(--emergency-red) 0%, var(--emergency-dark-red) 100%);
            color: white;
            padding: 1.25rem 1.75rem; /* Ayarlanmış padding */
            border: none;
            border-bottom: 3px solid var(--emergency-dark-red); /* Ekstra vurgu */
        }
        .custom-card-header h5, .custom-card-header h6 {
            margin: 0;
            font-weight: 600;
            text-shadow: 1px 1px 1px rgba(0,0,0,0.15);
        }
        .custom-card-header i { margin-right: 0.5rem; }

        /* Table Styling */
        .table-custom { margin: 0; }
        .table-custom thead th {
            background-color: var(--light-gray); /* Daha açık header */
            border: none;
            color: var(--dark-gray); /* Daha koyu yazı */
            font-weight: 700; /* Daha kalın */
            text-transform: uppercase;
            font-size: 0.8rem; /* Biraz daha küçük */
            letter-spacing: 0.5px;
            padding: 1rem 1.25rem;
            border-bottom: 2px solid var(--medium-gray); /* Ayırıcı çizgi */
        }
        .table-custom tbody tr { transition: all 0.25s ease-in-out; }
        .table-custom tbody tr:hover {
            background-color: var(--emergency-light-red) !important; /* Hover rengi önceliği */
            transform: scale(1.005); /* Çok hafif ölçeklenme */
            box-shadow: 0 4px 8px rgba(0,0,0,0.05);
            z-index: 1;
            position: relative;
        }
        .table-custom td {
            padding: 1rem 1.25rem;
            vertical-align: middle;
            border-top: 1px solid var(--medium-gray) !important; /* Her satır arası çizgi */
        }
        .table-custom td:first-child { border-left: 3px solid transparent; }
        .table-custom tr:hover td:first-child { border-left: 3px solid var(--emergency-red); }


        /* Badge Styling */
        .status-badge {
            padding: 0.5rem 1rem; /* Daha iyi oran */
            border-radius: var(--border-radius-sm);
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-transform: uppercase;
            font-size: 0.7rem; /* Daha küçük */
            letter-spacing: 0.5px;
            display: inline-flex; /* İkonla hizalama */
            align-items: center;
        }
        .status-badge i { margin-right: 0.4rem; font-size: 0.8em; }
        .status-badge:hover { transform: translateY(-2px) scale(1.05); box-shadow: var(--shadow-sm); }

        .priority-badge {
            padding: 0.4rem 0.8rem; /* Daha iyi oran */
            border-radius: var(--border-radius-sm);
            font-weight: 700; /* Daha kalın */
            font-size: 0.7rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: white; /* Genelde beyaz yazı */
        }
        .priority-badge.bg-danger, .priority-badge.bg-warning, .priority-badge.bg-info,
        .priority-badge.bg-success, .priority-badge.bg-primary {
             color: white !important; /* Ensure text is white for colored badges */
        }
        .priority-badge.bg-warning { color: var(--dark-gray) !important; } /* Sarı için koyu yazı */


        /* Form Styling */
        .form-control-custom, .form-select-custom {
            border: 1px solid #ced4da; /* Standart border */
            border-radius: var(--border-radius-md);
            padding: 0.85rem 1.15rem; /* Rahat padding */
            transition: all 0.3s ease;
            box-shadow: var(--shadow-sm);
        }
        .form-control-custom:focus, .form-select-custom:focus {
            border-color: var(--emergency-red);
            box-shadow: 0 0 0 0.2rem rgba(217, 4, 41, 0.2), var(--shadow-sm);
        }
        .form-label { font-weight: 600; color: #495057; margin-bottom: 0.75rem; }
        .form-label i { color: var(--emergency-red); }

        /* Button Styling */
        .btn-emergency, .btn-secondary-custom {
            border: none;
            border-radius: var(--border-radius-md);
            padding: 0.85rem 1.75rem; /* Geniş butonlar */
            font-weight: 600;
            color: white;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            font-size: 0.9rem;
        }
        .btn-emergency {
            background: linear-gradient(135deg, var(--emergency-red), var(--emergency-dark-red));
            box-shadow: 0 4px 10px rgba(217, 4, 41, 0.25);
        }
        .btn-emergency:hover {
            transform: translateY(-3px);
            box-shadow: 0 7px 15px rgba(217, 4, 41, 0.35);
            color: white;
        }
        .btn-secondary-custom {
            background: linear-gradient(135deg, var(--emergency-gray), #545b62);
            box-shadow: 0 4px 10px rgba(108, 117, 125, 0.2);
        }
        .btn-secondary-custom:hover {
            transform: translateY(-3px);
            box-shadow: 0 7px 15px rgba(108, 117, 125, 0.3);
            color: white;
        }
        .btn-sm-action {
            padding: 0.35rem 0.7rem;
            font-size: 0.75rem;
            border-radius: var(--border-radius-sm);
        }
        .btn-success.btn-sm-action { background-color: var(--emergency-green); border-color: var(--emergency-green); }
        .btn-success.btn-sm-action:hover { background-color: #006300; border-color: #006300; }


        /* Coordinates Link */
        .coordinates {
            color: var(--emergency-blue);
            text-decoration: none;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            padding: 0.5rem 0.75rem;
            border-radius: var(--border-radius-sm);
            background: rgba(0, 119, 182, 0.08);
            display: inline-flex;
            align-items: center;
        }
        .coordinates i { margin-right: 0.4rem; }
        .coordinates:hover {
            background: rgba(0, 119, 182, 0.15);
            color: #005f88;
            transform: scale(1.03);
        }

        /* Note Area */
        .note-area {
            border: 1px solid #ced4da;
            border-radius: var(--border-radius-sm);
            transition: all 0.3s ease;
            resize: vertical;
            min-height: 50px; /* Minimal yükseklik */
            font-size: 0.9rem;
            padding: 0.5rem 0.75rem;
        }
        .note-area:focus {
            border-color: var(--emergency-red);
            box-shadow: 0 0 0 0.15rem rgba(217, 4, 41, 0.15);
        }

        /* Delete Button */
        .delete-btn {
            color: var(--emergency-red);
            cursor: pointer;
            transition: all 0.3s ease;
            padding: 0.5rem; /* Tıklama alanı */
            border-radius: 50%;
            background: rgba(217, 4, 41, 0.08);
            font-size: 0.9rem; /* İkon boyutu */
            line-height: 1; /* Hizalama */
        }
        .delete-btn:hover {
            background: var(--emergency-red);
            color: white;
            transform: scale(1.15) rotate(10deg); /* Hafif animasyon */
        }

        /* Preview Box */
        .preview-box {
            border: 2px dashed var(--medium-gray);
            border-radius: var(--border-radius-md);
            padding: 1.5rem;
            background: var(--light-gray);
            transition: all 0.3s ease;
            min-height: 150px; /* Minimal yükseklik */
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        .preview-box.has-content {
            border-style: solid;
            border-color: var(--emergency-red);
            background: white;
            box-shadow: var(--shadow-sm);
            padding: 1.75rem; /* İçerik varken daha fazla padding */
        }
        .preview-box-title {
            font-size: 1.3rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
        }
        .preview-box-meta {
            font-size: 0.8rem;
            color: var(--emergency-gray);
            margin-bottom: 1rem;
        }
        .preview-box-meta i { margin-right: 0.3rem; }
        .preview-box-content { font-size: 0.95rem; line-height: 1.6; }

        /* Alert Styling */
        .alert-custom {
            border: none;
            border-radius: var(--border-radius-md);
            padding: 1.25rem 1.75rem; /* Daha geniş */
            font-weight: 500;
            box-shadow: var(--shadow-sm);
            border-left: 5px solid; /* Sol kenar vurgusu */
        }
        .alert-custom .btn-close { filter: brightness(0.5); }

        .alert-success-custom {
            background-color: #e6fffa; color: #004d33; border-color: var(--emergency-green);
        }
        .alert-danger-custom {
            background-color: var(--emergency-light-red); color: #58151c; border-color: var(--emergency-red);
        }
        .alert-warning-custom {
            background-color: #fff8e1; color: #664d03; border-color: var(--emergency-yellow);
        }

        /* Message Button */
        .message-btn {
            background: rgba(0, 119, 182, 0.08);
            color: var(--emergency-blue);
            border: 1px solid rgba(0, 119, 182, 0.2);
            border-radius: var(--border-radius-sm);
            padding: 0.5rem 0.85rem;
            font-size: 0.8rem;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
        }
        .message-btn i { margin-right: 0.4rem; }
        .message-btn:hover {
            background: rgba(0, 119, 182, 0.15);
            transform: scale(1.03);
            color: #005f88;
        }

        /* Modal Styling */
        .modal-content {
            border: none;
            border-radius: var(--border-radius-lg);
            box-shadow: var(--shadow-lg);
        }
        .modal-header {
            background: linear-gradient(135deg, var(--emergency-red), var(--emergency-dark-red));
            color: white;
            border: none;
            border-radius: var(--border-radius-lg) var(--border-radius-lg) 0 0;
            padding: 1.5rem 2rem; /* Daha ferah başlık */
        }
        .modal-header .btn-close-white { filter: brightness(2) contrast(0.5); }
        .modal-title { font-weight: 600; }
        .modal-body { padding: 2rem; }
        .modal-body label { color: var(--emergency-gray); font-size: 0.9rem; }
        #messageTitle { color: var(--emergency-red); font-weight: 700; }
        #messageContent {
            background-color: var(--light-gray);
            border-left: 4px solid var(--emergency-red);
            font-size: 1rem;
            line-height: 1.7;
        }
        .modal-footer {
            background-color: var(--light-gray);
            border-top: 1px solid var(--medium-gray);
            border-radius: 0 0 var(--border-radius-lg) var(--border-radius-lg);
            padding: 1rem 2rem;
        }
        .modal-footer .btn-secondary {
            background-color: var(--emergency-gray);
            border-color: var(--emergency-gray);
            color: white;
            padding: 0.6rem 1.2rem;
        }
        .modal-footer .btn-secondary:hover {
            background-color: #5a6268;
            border-color: #545b62;
        }


        /* Responsive */
        @media (max-width: 768px) {
            .stat-number { font-size: 2rem; }
            .stat-icon { font-size: 2.5rem; }
            .nav-pills { flex-direction: column; display: block; }
            .nav-pills .nav-link { margin: 0.3rem 0; width: 100%; text-align: center; }
            .navbar-brand { font-size: 1.3rem; }
            .navbar-text { display: none; } /* Küçük ekranlarda kullanıcı adını gizle */
            .custom-card-header h5, .custom-card-header h6 { font-size: 1rem; }
            .table-custom thead { display: none; } /* Stackable table for mobile */
            .table-custom tbody, .table-custom tr, .table-custom td { display: block; width: 100%; }
            .table-custom tr { margin-bottom: 1rem; border: 1px solid var(--medium-gray); border-radius: var(--border-radius-md); }
            .table-custom td { text-align: right; padding-left: 50%; position: relative; border-bottom: 1px solid var(--medium-gray); }
            .table-custom td:last-child { border-bottom: 0; }
            .table-custom td::before {
                content: attr(data-label); /* JavaScript ile eklenecek */
                position: absolute;
                left: 0.75rem;
                width: calc(50% - 1.5rem);
                padding-right: 0.75rem;
                font-weight: bold;
                text-align: left;
                white-space: nowrap;
                color: var(--emergency-red);
            }
            .archive-table td::before { color: var(--emergency-blue); }
        }
        .text-center-md-up { text-align: center; }
         @media (min-width: 768px) {
            .text-center-md-up { text-align: left; } /* Geri al */
         }

         /* Helper for toast-like messages */
        .toast-container {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1090;
        }
        
        .toast {
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
            border-radius: 10px;
            min-width: 300px;
            border-left: 5px solid;
            opacity: 0;
            animation: fadeInRight 0.5s ease forwards;
        }
        
        @keyframes fadeInRight {
            0% {
                opacity: 0;
                transform: translateX(30px);
            }
            100% {
                opacity: 1;
                transform: translateX(0);
            }
        }
        
        .toast.bg-success {
            border-color: #155724;
        }
        
        .toast.bg-danger {
            border-color: #721c24;
        }
        
        .toast.bg-warning {
            border-color: #856404;
        }
    </style>
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg navbar-dark navbar-emergency">
        <div class="container-fluid">
            <span class="navbar-brand">
                <i class="fas fa-shield-alt"></i>ACİL DURUM SİSTEMİ
            </span>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNavAltMarkup" aria-controls="navbarNavAltMarkup" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNavAltMarkup">
                <div class="navbar-nav ms-auto align-items-center">
                    <span class="navbar-text me-3 fw-bold">
                        <i class="fas fa-user-shield me-2"></i>Hoş geldin, <?= htmlspecialchars($_SESSION['admin_username']) ?>
                    </span>
                    <a href="?logout=1" class="btn btn-logout btn-sm rounded-pill">
                        <i class="fas fa-sign-out-alt me-1"></i>Güvenli Çıkış
                    </a>
                </div>
            </div>
        </div>
    </nav>

    <div class="container-fluid py-4 px-md-4 main-container">
        <!-- Flash Mesajları için Alan -->
        <div class="toast-container">
            <?php if ($flash_message): ?>
            <div class="toast show align-items-center text-white bg-<?= $flash_message['type'] == 'success' ? 'success' : ($flash_message['type'] == 'danger' ? 'danger' : 'warning') ?> border-0" role="alert" aria-live="assertive" aria-atomic="true" data-bs-autohide="true" data-bs-delay="5000">
                <div class="d-flex">
                    <div class="toast-body">
                        <i class="fas <?= $flash_message['type'] == 'success' ? 'fa-check-circle' : ($flash_message['type'] == 'danger' ? 'fa-times-circle' : 'fa-exclamation-triangle') ?> me-2"></i>
                        <?= htmlspecialchars($flash_message['text']) ?>
                    </div>
                    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
                </div>
            </div>
            <?php endif; ?>
        </div>


        <!-- İstatistik Kartları -->
        <div class="row mb-4">
            <div class="col-xl-3 col-md-6 mb-4">
                <div class="card stat-card danger text-white h-100">
                    <div class="card-body text-center p-4 d-flex flex-column justify-content-center">
                        <i class="fas fa-siren-on stat-icon"></i> <!-- Değişik ikon -->
                        <div class="stat-number"><?= $active_calls_count ?></div>
                        <div class="fw-bold">Aktif Acil Çağrılar</div>
                        <small class="opacity-75">Anında müdahale gerekli</small>
                    </div>
                </div>
            </div>
            
            <div class="col-xl-3 col-md-6 mb-4">
                <div class="card stat-card secondary text-white h-100">
                    <div class="card-body text-center p-4 d-flex flex-column justify-content-center">
                        <i class="fas fa-history stat-icon"></i> <!-- Değişik ikon -->
                        <div class="stat-number"><?= $archived_calls_count ?></div>
                        <div class="fw-bold">Arşivlenen Çağrılar</div>
                        <small class="opacity-75">Tamamlanan müdahaleler</small>
                    </div>
                </div>
            </div>
            
            <div class="col-xl-3 col-md-6 mb-4">
                <div class="card stat-card success text-white h-100">
                    <div class="card-body text-center p-4 d-flex flex-column justify-content-center">
                        <i class="fas fa-megaphone stat-icon"></i> <!-- Değişik ikon -->
                        <div class="stat-number"><?= $active_announcements_count ?></div>
                        <div class="fw-bold">Aktif Duyurular</div>
                        <small class="opacity-75">Yayında olan duyurular</small>
                    </div>
                </div>
            </div>
            
            <div class="col-xl-3 col-md-6 mb-4">
                <div class="card stat-card info text-white h-100">
                    <div class="card-body text-center p-4 d-flex flex-column justify-content-center">
                        <i class="fas fa-archive stat-icon"></i> <!-- Değişik ikon -->
                        <div class="stat-number"><?= $archived_announcements_count ?></div>
                        <div class="fw-bold">Arşivlenen Duyurular</div>
                        <small class="opacity-75">Geçmiş duyurular</small>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tab Navigation -->
        <div class="text-center-md-up"> <!-- Tabletlere kadar ortala, sonra sola al -->
             <ul class="nav nav-pills justify-content-center" id="pills-tab" role="tablist">
                <li class="nav-item" role="presentation">
                    <button class="nav-link active" id="pills-calls-tab" data-bs-toggle="pill" data-bs-target="#pills-calls" type="button">
                        <i class="fas fa-phone-volume"></i>Acil Çağrılar
                    </button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="pills-announcements-tab" data-bs-toggle="pill" data-bs-target="#pills-announcements" type="button">
                        <i class="fas fa-bullhorn"></i>Duyurular
                    </button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="pills-add-announcement-tab" data-bs-toggle="pill" data-bs-target="#pills-add-announcement" type="button">
                        <i class="fas fa-plus-circle"></i>Duyuru Ekle
                    </button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="pills-archived-tab" data-bs-toggle="pill" data-bs-target="#pills-archived" type="button">
                        <i class="fas fa-folder-open"></i>Arşiv
                    </button>
                </li>
            </ul>
        </div>


        <!-- Tab Content -->
        <div class="tab-content" id="pills-tabContent">
            <!-- Acil Çağrılar -->
            <div class="tab-pane fade show active" id="pills-calls" role="tabpanel">
                <div class="card custom-card">
                    <div class="card-header custom-card-header">
                        <h5><i class="fas fa-exclamation-triangle me-2"></i>Aktif Acil Durum Çağrıları</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-custom table-hover align-middle">
                                <thead>
                                    <tr>
                                        <th><i class="fas fa-id-badge me-1"></i>TC Kimlik</th>
                                        <th><i class="fas fa-user-injured me-1"></i>Ad Soyad</th>
                                        <th><i class="fas fa-envelope-open-text me-1"></i>Mesaj</th>
                                        <th><i class="fas fa-location-arrow me-1"></i>Konum</th>
                                        <th><i class="far fa-clock me-1"></i>Tarih</th>
                                        <th class="text-center"><i class="fas fa-cogs me-1"></i>İşlemler</th>
                                        <th><i class="fas fa-clipboard-check me-1"></i>Admin Notu</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php if (empty($calls)): ?>
                                        <tr><td colspan="7" class="text-center py-5 text-muted"><i class="fas fa-info-circle me-2"></i>Aktif acil çağrı bulunmamaktadır.</td></tr>
                                    <?php endif; ?>
                                    <?php foreach ($calls as $call): ?>
                                        <tr>
                                            <td data-label="TC Kimlik" class="fw-bold"><?= htmlspecialchars($call['tc_kimlik']) ?></td>
                                            <td data-label="Ad Soyad"><?= htmlspecialchars($call['ad'] . ' ' . $call['soyad']) ?></td>
                                            <td data-label="Mesaj">
                                                <button class="btn message-btn" onclick="showMessage('<?= htmlspecialchars(addslashes($call['mesaj']), ENT_QUOTES) ?>', '<?= htmlspecialchars(addslashes($call['ad'] . ' ' . $call['soyad']), ENT_QUOTES) ?>')">
                                                    <i class="fas fa-eye me-1"></i>Mesajı Gör
                                                </button>
                                            </td>
                                            <td data-label="Konum">
                                                <span class="coordinates" onclick="openMap(<?= $call['latitude'] ?>, <?= $call['longitude'] ?>)">
                                                    <i class="fas fa-map-marked-alt me-1"></i>Konuma Git
                                                </span>
                                            </td>
                                            <td data-label="Tarih"><?= date('d.m.Y H:i', strtotime($call['created_at'])) ?></td>
                                            <td data-label="İşlemler" class="text-center">
                                                <button class="btn status-badge bg-warning text-dark" 
                                                      onclick="toggleCallStatus(<?= $call['id'] ?>, 'aktif')" title="Bu çağrıyı arşivle">
                                                    <i class="fas fa-archive"></i>Arşivle
                                                </button>
                                            </td>
                                            <td data-label="Admin Notu">
                                                <textarea class="form-control note-area" rows="1"
                                                          onblur="updateCallNote(<?= $call['id'] ?>, this.value)"
                                                          placeholder="Not ekle..."><?= htmlspecialchars($call['admin_note'] ?? '') ?></textarea>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Duyurular -->
            <div class="tab-pane fade" id="pills-announcements" role="tabpanel">
                <div class="card custom-card">
                    <div class="card-header custom-card-header">
                        <h5><i class="fas fa-bullhorn me-2"></i>Aktif Sistem Duyuruları</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-custom table-hover align-middle">
                                <thead>
                                    <tr>
                                        <th><i class="fas fa-heading me-1"></i>Başlık</th>
                                        <th><i class="fas fa-file-alt me-1"></i>İçerik</th>
                                        <th><i class="fas fa-exclamation-circle me-1"></i>Öncelik</th>
                                        <th><i class="far fa-calendar-alt me-1"></i>Tarih</th>
                                        <th class="text-center"><i class="fas fa-cogs me-1"></i>İşlemler</th>
                                        <th><i class="fas fa-user-edit me-1"></i>Admin Notu</th>
                                    </tr>
                                </thead>
                                <tbody>
                                     <?php if (empty($announcements)): ?>
                                        <tr><td colspan="6" class="text-center py-5 text-muted"><i class="fas fa-info-circle me-2"></i>Aktif duyuru bulunmamaktadır.</td></tr>
                                    <?php endif; ?>
                                    <?php foreach ($announcements as $announcement): ?>
                                        <tr>
                                            <td data-label="Başlık" class="fw-bold"><?= htmlspecialchars($announcement['baslik']) ?></td>
                                            <td data-label="İçerik">
                                                <button class="btn message-btn" onclick="showMessage('<?= htmlspecialchars(addslashes($announcement['icerik']), ENT_QUOTES) ?>', '<?= htmlspecialchars(addslashes($announcement['baslik']), ENT_QUOTES) ?>')">
                                                    <i class="fas fa-eye me-1"></i>İçeriği Gör
                                                </button>
                                            </td>
                                            <td data-label="Öncelik">
                                                <?php
                                                    $priority_class = 'bg-info'; // Düşük
                                                    if ($announcement['oncelik'] == 'Yüksek') $priority_class = 'bg-danger';
                                                    else if ($announcement['oncelik'] == 'Orta') $priority_class = 'bg-warning';
                                                ?>
                                                <span class="badge priority-badge <?= $priority_class ?>">
                                                    <?= htmlspecialchars($announcement['oncelik']) ?>
                                                </span>
                                            </td>
                                            <td data-label="Tarih"><?= date('d.m.Y H:i', strtotime($announcement['created_at'])) ?></td>
                                            <td data-label="İşlemler" class="text-center">
                                                <button class="btn status-badge bg-success me-2" 
                                                      onclick="toggleAnnouncementStatus(<?= $announcement['id'] ?>, 'aktif')" title="Bu duyuruyu arşivle">
                                                    <i class="fas fa-archive"></i>Arşivle
                                                </button>
                                                <button class="btn delete-btn" 
                                                   onclick="deleteAnnouncement(<?= $announcement['id'] ?>)" 
                                                   title="Duyuruyu Sil">
                                                   <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </td>
                                            <td data-label="Admin Notu">
                                                <textarea class="form-control note-area" rows="1"
                                                          onblur="updateAnnouncementNote(<?= $announcement['id'] ?>, this.value)"
                                                          placeholder="Not ekle..."><?= htmlspecialchars($announcement['admin_note'] ?? '') ?></textarea>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Duyuru Ekle -->
            <div class="tab-pane fade" id="pills-add-announcement" role="tabpanel">
                <div class="card custom-card">
                    <div class="card-header custom-card-header">
                        <h5><i class="fas fa-plus-square me-2"></i>Yeni Duyuru Oluştur</h5>
                    </div>
                    <div class="card-body p-4">
                        <form method="POST" id="addAnnouncementForm">
                            <div class="row">
                                <div class="col-lg-7 mb-4 mb-lg-0">
                                    <div class="mb-4">
                                        <label for="baslik" class="form-label">
                                            <i class="fas fa-heading me-2"></i>Duyuru Başlığı *
                                        </label>
                                        <input type="text" class="form-control form-control-custom" id="baslik" name="baslik" required 
                                               placeholder="Etkileyici bir başlık girin...">
                                    </div>
                                    <div class="mb-4">
                                        <label for="icerik" class="form-label">
                                            <i class="fas fa-paragraph me-2"></i>Duyuru İçeriği *
                                        </label>
                                        <textarea class="form-control form-control-custom" id="icerik" name="icerik" rows="8" required 
                                                  placeholder="Duyurunuzun detaylarını buraya yazın..."></textarea>
                                    </div>
                                     <div class="mb-4">
                                        <label for="oncelik" class="form-label">
                                            <i class="fas fa-stream me-2"></i>Öncelik Seviyesi
                                        </label>
                                        <select class="form-select form-select-custom" id="oncelik" name="oncelik">
                                            <option value="Düşük" data-icon-class="fas fa-thumbs-up text-success">🟢 Düşük Öncelik</option>
                                            <option value="Orta" selected data-icon-class="fas fa-info-circle text-warning">🟡 Orta Öncelik</option>
                                            <option value="Yüksek" data-icon-class="fas fa-exclamation-triangle text-danger">🔴 Yüksek Öncelik</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-lg-5">
                                    <div class="sticky-top" style="top: 20px;">
                                        <label class="form-label mb-3">
                                            <i class="fas fa-tv me-2"></i>Canlı Önizleme
                                        </label>
                                        <div class="preview-box" id="preview">
                                            <div class="text-center text-muted">
                                                <i class="fas fa-pencil-alt fa-2x mb-2"></i>
                                                <p>Başlık ve içerik yazarken önizleme burada görünecektir.</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="row mt-4">
                                <div class="col-12">
                                    <hr class="my-4">
                                    <button type="submit" name="add_announcement" class="btn btn-emergency me-2">
                                        <i class="fas fa-paper-plane me-2"></i>Duyuruyu Yayınla
                                    </button>
                                    <button type="button" class="btn btn-secondary-custom" onclick="clearForm()">
                                        <i class="fas fa-undo me-2"></i>Formu Temizle
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>

            <!-- Arşiv -->
            <div class="tab-pane fade" id="pills-archived" role="tabpanel">
                <div class="row">
                    <div class="col-lg-6 mb-4">
                        <div class="card custom-card h-100">
                            <div class="card-header custom-card-header">
                                <h6><i class="fas fa-inbox me-2"></i>Arşivlenen Acil Çağrılar (<?= count($archived_calls) ?>)</h6>
                            </div>
                            <div class="card-body p-0">
                                <div class="table-responsive">
                                    <table class="table table-custom table-hover table-sm align-middle archive-table">
                                        <thead>
                                            <tr>
                                                <th>Ad Soyad</th>
                                                <th>Mesaj (Kısa)</th>
                                                <th>Tarih</th>
                                                <th class="text-center">İşlem</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php if (empty($archived_calls)): ?>
                                                <tr><td colspan="4" class="text-center py-4 text-muted"><i class="fas fa-info-circle me-2"></i>Arşivlenmiş çağrı bulunmuyor.</td></tr>
                                            <?php endif; ?>
                                            <?php foreach ($archived_calls as $call): ?>
                                                <tr>
                                                    <td data-label="Ad Soyad"><?= htmlspecialchars($call['ad'] . ' ' . $call['soyad']) ?></td>
                                                    <td data-label="Mesaj">
                                                        <small class="text-muted" title="<?= htmlspecialchars($call['mesaj']) ?>"><?= htmlspecialchars(mb_substr($call['mesaj'], 0, 25)) ?>...</small>
                                                    </td>
                                                    <td data-label="Tarih"><small><?= date('d.m.Y', strtotime($call['created_at'])) ?></small></td>
                                                    <td data-label="İşlem" class="text-center">
                                                        <button class="btn btn-sm-action btn-success rounded-pill" onclick="toggleCallStatus(<?= $call['id'] ?>, 'arsivlendi')" title="Bu çağrıyı aktifleştir">
                                                            <i class="fas fa-undo-alt me-1"></i>Aktifleştir
                                                        </button>
                                                    </td>
                                                </tr>
                                            <?php endforeach; ?>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-6 mb-4">
                        <div class="card custom-card h-100">
                            <div class="card-header custom-card-header">
                                <h6><i class="fas fa-folder-minus me-2"></i>Arşivlenen Duyurular (<?= count($archived_announcements) ?>)</h6>
                            </div>
                             <div class="card-body p-0">
                                <div class="table-responsive">
                                    <table class="table table-custom table-hover table-sm align-middle archive-table">
                                        <thead>
                                            <tr>
                                                <th>Başlık</th>
                                                <th>Öncelik</th>
                                                <th>Tarih</th>
                                                <th class="text-center">İşlem</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php if (empty($archived_announcements)): ?>
                                                <tr><td colspan="4" class="text-center py-4 text-muted"><i class="fas fa-info-circle me-2"></i>Arşivlenmiş duyuru bulunmuyor.</td></tr>
                                            <?php endif; ?>
                                            <?php foreach ($archived_announcements as $announcement): ?>
                                                <tr>
                                                    <td data-label="Başlık"><?= htmlspecialchars($announcement['baslik']) ?></td>
                                                    <td data-label="Öncelik">
                                                        <?php
                                                            $priority_class_arch = 'bg-info';
                                                            if ($announcement['oncelik'] == 'Yüksek') $priority_class_arch = 'bg-danger';
                                                            else if ($announcement['oncelik'] == 'Orta') $priority_class_arch = 'bg-warning';
                                                        ?>
                                                        <span class="badge priority-badge <?= $priority_class_arch ?>">
                                                            <?= htmlspecialchars($announcement['oncelik']) ?>
                                                        </span>
                                                    </td>
                                                    <td data-label="Tarih"><small><?= date('d.m.Y', strtotime($announcement['created_at'])) ?></small></td>
                                                    <td data-label="İşlem" class="text-center">
                                                        <button class="btn btn-sm-action btn-success rounded-pill" onclick="toggleAnnouncementStatus(<?= $announcement['id'] ?>, 'arsivlendi')" title="Bu duyuruyu aktifleştir">
                                                            <i class="fas fa-undo-alt me-1"></i>Aktifleştir
                                                        </button>
                                                    </td>
                                                </tr>
                                            <?php endforeach; ?>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Message Modal -->
    <div class="modal fade" id="messageModal" tabindex="-1" aria-labelledby="messageModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered"> <!-- modal-dialog-centered eklendi -->
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="messageModalLabel">
                        <i class="fas fa-envelope-open-text me-2"></i>Mesaj / Duyuru Detayı
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label fw-bold text-muted">Gönderen / Başlık:</label>
                        <div id="messageModalTitle" class="h5 text-danger"></div> <!-- messageTitle -> messageModalTitle -->
                    </div>
                    <hr>
                    <div>
                        <label class="form-label fw-bold text-muted">Mesaj / İçerik:</label>
                        <div id="messageModalContent" class="p-3 bg-light rounded border-start border-4 border-danger"></div> <!-- messageContent -> messageModalContent -->
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times-circle me-1"></i>Kapat
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Toast'ları başlat
        var toastElList = [].slice.call(document.querySelectorAll('.toast'))
        var toastList = toastElList.map(function (toastEl) {
          return new bootstrap.Toast(toastEl)
        });
        toastList.forEach(toast => toast.show()); // Sayfa yüklendiğinde flash mesajları göster

        function showMessage(message, title) {
            document.getElementById('messageModalTitle').textContent = title;
            document.getElementById('messageModalContent').innerHTML = message.replace(/\n/g, '<br>'); // Satır sonlarını <br> ile değiştir
            
            var messageModal = new bootstrap.Modal(document.getElementById('messageModal'));
            messageModal.show();
        }

        function openMap(lat, lng) {
            window.open(`https://www.google.com/maps?q=${lat},${lng}`, '_blank');
        }

        function showToast(message, type = 'success') {
            const toastContainer = document.querySelector('.toast-container');
            if (!toastContainer) return;

            const toastId = 'toast-' + Date.now();
            const iconClass = type === 'success' ? 'fa-check-circle' : (type === 'danger' ? 'fa-times-circle' : 'fa-exclamation-triangle');
            const bgClass = type === 'success' ? 'bg-success' : (type === 'danger' ? 'bg-danger' : 'bg-warning');

            const toastHTML = `
                <div id="${toastId}" class="toast align-items-center text-white ${bgClass} border-0" role="alert" aria-live="assertive" aria-atomic="true" data-bs-delay="5000">
                    <div class="d-flex">
                        <div class="toast-body">
                            <i class="fas ${iconClass} me-2"></i>
                            ${message}
                        </div>
                        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
                    </div>
                </div>
            `;
            toastContainer.insertAdjacentHTML('beforeend', toastHTML);
            const newToastEl = document.getElementById(toastId);
            const newToast = new bootstrap.Toast(newToastEl);
            newToast.show();
            
            // Toast animasyonu için sınıfları ekle
            setTimeout(() => {
                newToastEl.classList.add('fade-in');
            }, 50);
            
            newToastEl.addEventListener('hidden.bs.toast', () => {
                newToastEl.classList.add('fade-out');
                setTimeout(() => newToastEl.remove(), 500);
            });
        }
        
        async function handleAction(action, bodyData, successMessage, errorMessage) {
            try {
                const response = await fetch(window.location.pathname, { // window.location.href -> window.location.pathname
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: `action=${action}&${new URLSearchParams(bodyData).toString()}`
                });
                if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                const data = await response.json();
                
                if (data.success) {
                    showToast(successMessage, 'success');
                    setTimeout(() => location.reload(), 1500); // Reload after showing toast
                } else {
                    showToast(errorMessage, 'danger');
                }
            } catch (error) {
                console.error('Fetch error:', error);
                showToast('İşlem sırasında bir hata oluştu: ' + error.message, 'danger');
            }
        }


        function toggleCallStatus(id, currentStatus) {
            const newStatus = currentStatus === 'aktif' ? 'arsivlendi' : 'aktif';
            const successMsg = newStatus === 'arsivlendi' ? 'Çağrı başarıyla arşivlendi!' : 'Çağrı başarıyla aktifleştirildi!';
            handleAction('update_call_status', {id, status: newStatus}, successMsg, 'Çağrı durumu güncellenirken hata.');
        }

        function toggleAnnouncementStatus(id, currentStatus) {
            const newStatus = currentStatus === 'aktif' ? 'arsivlendi' : 'aktif';
            const successMsg = newStatus === 'arsivlendi' ? 'Duyuru başarıyla arşivlendi!' : 'Duyuru başarıyla aktifleştirildi!';
            handleAction('update_announcement_status', {id, status: newStatus}, successMsg, 'Duyuru durumu güncellenirken hata.');
        }

        async function updateNote(action, id, note, type) { // type: 'çağrı' or 'duyuru'
            try {
                const response = await fetch(window.location.pathname, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: `action=${action}&id=${id}&note=${encodeURIComponent(note)}` // "¬e=" yerine "&note="
                });
                if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                const data = await response.json();
                
                if (data.success) {
                    showToast(`${type.charAt(0).toUpperCase() + type.slice(1)} notu başarıyla güncellendi.`, 'success');
                } else {
                    showToast(`${type.charAt(0).toUpperCase() + type.slice(1)} notu güncellenirken hata.`, 'danger');
                }
            } catch (error) {
                console.error('Fetch error:', error);
                showToast('Not güncellenirken bir hata oluştu: ' + error.message, 'danger');
            }
        }

        function updateCallNote(id, note) {
            updateNote('update_call_note', id, note, 'çağrı');
        }

        function updateAnnouncementNote(id, note) {
            updateNote('update_announcement_note', id, note, 'duyuru');
        }

        function deleteAnnouncement(id) {
            if (confirm('Bu duyuruyu kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.')) {
                handleAction('delete_announcement', {id}, 'Duyuru başarıyla silindi!', 'Duyuru silinirken hata.');
            }
        }

        function clearForm() {
            const form = document.getElementById('addAnnouncementForm');
            if (form) {
                form.reset(); // Formu sıfırla
            }
            // select elementini manuel olarak sıfırla, reset bazen custom selectlerde işe yaramayabilir
            const oncelikSelect = document.getElementById('oncelik');
            if (oncelikSelect) {
                oncelikSelect.value = 'Orta';
            }
            updatePreview(); // Önizlemeyi temizle
            document.getElementById('baslik').focus(); // Başlık alanına odaklan
        }


        function updatePreview() {
            const baslikInput = document.getElementById('baslik');
            const icerikInput = document.getElementById('icerik');
            const oncelikSelect = document.getElementById('oncelik');
            
            const baslik = baslikInput ? baslikInput.value : '';
            const icerik = icerikInput ? icerikInput.value : '';
            const oncelik = oncelikSelect ? oncelikSelect.value : 'Orta';
            
            let preview = document.getElementById('preview');
            if (!preview) return;
            
            if (baslik || icerik) {
                preview.classList.add('has-content');
                let priorityClass = 'text-info';
                let priorityIcon = 'fas fa-info-circle'; // Düşük
                let priorityBorderClass = 'border-info';

                if (oncelik === 'Yüksek') {
                    priorityClass = 'text-danger';
                    priorityIcon = 'fas fa-exclamation-triangle';
                    priorityBorderClass = 'border-danger';
                } else if (oncelik === 'Orta') {
                    priorityClass = 'text-warning';
                    priorityIcon = 'fas fa-exclamation-circle';
                    priorityBorderClass = 'border-warning';
                }
                
                preview.innerHTML = `
                    <div class="d-flex align-items-center mb-2">
                        <i class="${priorityIcon} ${priorityClass} fa-2x me-3"></i>
                        <div>
                            <h5 class="preview-box-title ${priorityClass} mb-0">${baslik || 'Duyuru Başlığı'}</h5>
                            <small class="preview-box-meta text-muted">
                                <i class="fas fa-flag"></i> Öncelik: ${oncelik} | 
                                <i class="far fa-calendar-alt"></i> Tarih: ${new Date().toLocaleDateString('tr-TR')}
                            </small>
                        </div>
                    </div>
                    <hr class="my-2">
                    <div class="preview-box-content">
                        ${(icerik || 'Duyuru içeriği buraya yazılacak...').replace(/\n/g, '<br>')}
                    </div>
                `;
                preview.style.borderColor = `var(--emergency-${oncelik.toLowerCase()})`; // Renk değişkeniyle
                 if(oncelik === 'Yüksek') preview.style.borderColor = 'var(--emergency-red)';
                 else if(oncelik === 'Orta') preview.style.borderColor = 'var(--emergency-yellow)';
                 else preview.style.borderColor = 'var(--emergency-blue)';

            } else {
                preview.classList.remove('has-content');
                preview.style.borderColor = 'var(--medium-gray)';
                preview.innerHTML = `
                    <div class="text-center text-muted p-3">
                        <i class="fas fa-pencil-ruler fa-3x mb-3 text-black-50"></i>
                        <p class="mb-0">Duyurunuzun başlık ve içeriğini girdikçe, burada canlı bir önizlemesini göreceksiniz.</p>
                        <small class="d-block mt-2">Öncelik seviyesini de seçmeyi unutmayın!</small>
                    </div>
                `;
            }
        }

        // Önizleme için event listener'lar
        const baslikInput = document.getElementById('baslik');
        const icerikInput = document.getElementById('icerik');
        const oncelikSelect = document.getElementById('oncelik');

        if (baslikInput) baslikInput.addEventListener('input', updatePreview);
        if (icerikInput) icerikInput.addEventListener('input', updatePreview);
        if (oncelikSelect) oncelikSelect.addEventListener('change', updatePreview);

        // Sayfa yüklendiğinde ve tab değiştiğinde önizlemeyi güncelle
        document.addEventListener('DOMContentLoaded', function() {
            updatePreview();
            // Mobil için tablo başlıklarını ayarla
            setupMobileTableLabels();

            // Eğer URL'de bir hash varsa ve bu bir tab ID ise, o tabı aktifleştir
            if(window.location.hash) {
                var triggerEl = document.querySelector('button[data-bs-target="' + window.location.hash.replace('-tab', '') + '"]');
                if (triggerEl) {
                    var tab = new bootstrap.Tab(triggerEl);
                    tab.show();
                    // Eğer "Duyuru Ekle" tabına gelindiyse, başlık alanına odaklan
                    if (window.location.hash === '#pills-add-announcement-tab' || window.location.hash === '#pills-add-announcement') {
                       const titleInput = document.getElementById('baslik');
                       if (titleInput) titleInput.focus();
                    }
                }
            }
        });

        // Mobil tablolar için data-label ayarlama
        function setupMobileTableLabels() {
            document.querySelectorAll('.table-custom tbody tr').forEach(row => {
                const headers = Array.from(row.closest('table').querySelectorAll('thead th')).map(th => 
                    th.innerText.trim() || (th.querySelector('i') ? th.querySelector('i').getAttribute('title') || th.querySelector('i').className.split(' ')[1].replace('fa-', '') : '')
                );
                
                row.querySelectorAll('td').forEach((cell, index) => {
                    if (headers[index]) {
                        cell.setAttribute('data-label', headers[index]);
                    }
                });
            });
        }
        
        // Sekme geçişleri için animasyon
        document.querySelectorAll('#pills-tab button').forEach(button => {
        button.addEventListener('click', function() {
            document.querySelectorAll('.tab-pane').forEach(pane => {
                pane.style.animation = 'none';
            });
            
            setTimeout(() => {
                const targetId = this.getAttribute('data-bs-target');
                const targetPane = document.querySelector(targetId);
                if (targetPane) {
                    targetPane.style.animation = 'fadeIn 0.4s ease forwards';
                }
            }, 50);
        });
    });

    // Sayfa yüklendiğinde
    document.addEventListener('DOMContentLoaded', function() {
        // Tüm fontawesome ikonları için tooltip başlık
        document.querySelectorAll('thead th i').forEach(icon => {
            const title = icon.className.split(' ')[1].replace('fa-', '').replace('-', ' ');
            icon.setAttribute('title', title.charAt(0).toUpperCase() + title.slice(1));
        });
        
        updatePreview();
        setupMobileTableLabels();
        
        // Animasyon sınıfı ekle
        document.querySelector('.main-container').classList.add('fade-in');
        
        // İstatistik kartları için animasyon
        document.querySelectorAll('.stat-card').forEach((card, index) => {
            setTimeout(() => {
                card.style.animation = 'fadeInUp 0.5s ease forwards';
                card.style.opacity = '1';
            }, index * 150);
        });

        // URL hash kontrol
        if(window.location.hash) {
            var triggerEl = document.querySelector('button[data-bs-target="' + window.location.hash.replace('-tab', '') + '"]');
            if (triggerEl) {
                var tab = new bootstrap.Tab(triggerEl);
                tab.show();
                
                // "Duyuru Ekle" tabına gelindiyse, başlık alanına odaklan
                if (window.location.hash === '#pills-add-announcement-tab' || window.location.hash === '#pills-add-announcement') {
                   const titleInput = document.getElementById('baslik');
                   if (titleInput) setTimeout(() => titleInput.focus(), 500);
                }
            }
        }
    });
    </script>
</body>
</html>