<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit();
}

// Veritabanı bağlantısı
$host = 'localhost';
$username = 'root';
$password = '';
$database = 'acil_durum_db';

$mysqli = new mysqli($host, $username, $password, $database);

// Bağlantı kontrolü
if ($mysqli->connect_error) {
    echo json_encode(['error' => 'Database connection failed: ' . $mysqli->connect_error]);
    exit();
}

// Karakter seti
$mysqli->set_charset("utf8mb4");

$action = $_GET['action'] ?? '';

switch($action) {
    case 'admin_login':
        $input = json_decode(file_get_contents('php://input'), true);
        $username = $mysqli->real_escape_string($input['username']);
        $password = $mysqli->real_escape_string($input['password']);
        
        $stmt = $mysqli->prepare("SELECT id FROM admins WHERE username = ? AND password = ?");
        $stmt->bind_param("ss", $username, $password);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false]);
        }
        $stmt->close();
        break;
        
    case 'send_emergency':
        $input = json_decode(file_get_contents('php://input'), true);
        
        // Validasyon
        if (empty($input['tc']) || empty($input['ad']) || empty($input['soyad']) || 
            empty($input['mesaj']) || !isset($input['lat']) || !isset($input['lng'])) {
            echo json_encode(['success' => false, 'error' => 'Eksik veri']);
            break;
        }
        
        $tc = $mysqli->real_escape_string($input['tc']);
        $ad = $mysqli->real_escape_string($input['ad']);
        $soyad = $mysqli->real_escape_string($input['soyad']);
        $mesaj = $mysqli->real_escape_string($input['mesaj']);
        $lat = floatval($input['lat']);
        $lng = floatval($input['lng']);
        
        $stmt = $mysqli->prepare("INSERT INTO emergency_calls (tc_kimlik, ad, soyad, mesaj, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("ssssdd", $tc, $ad, $soyad, $mesaj, $lat, $lng);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'id' => $mysqli->insert_id]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Insert failed']);
        }
        $stmt->close();
        break;
        
    case 'get_announcements':
        $result = $mysqli->query("SELECT * FROM announcements WHERE status = 'aktif' ORDER BY created_at DESC LIMIT 50");
        $announcements = [];
        
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $announcements[] = $row;
            }
        }
        
        echo json_encode($announcements);
        break;
        
    case 'get_all_announcements':
        $result = $mysqli->query("SELECT * FROM announcements ORDER BY created_at DESC LIMIT 100");
        $announcements = [];
        
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $announcements[] = $row;
            }
        }
        
        echo json_encode($announcements);
        break;
        
    case 'get_emergency_calls':
        $result = $mysqli->query("SELECT * FROM emergency_calls WHERE status = 'aktif' ORDER BY created_at DESC LIMIT 100");
        $calls = [];
        
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $calls[] = $row;
            }
        }
        
        echo json_encode($calls);
        break;
        
    case 'get_archived_emergency_calls':
        $result = $mysqli->query("SELECT * FROM emergency_calls WHERE status = 'arsivlendi' ORDER BY created_at DESC LIMIT 100");
        $calls = [];
        
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $calls[] = $row;
            }
        }
        
        echo json_encode($calls);
        break;
        
    case 'create_announcement':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['baslik']) || empty($input['icerik'])) {
            echo json_encode(['success' => false, 'error' => 'Başlık ve içerik gerekli']);
            break;
        }
        
        $baslik = $mysqli->real_escape_string($input['baslik']);
        $icerik = $mysqli->real_escape_string($input['icerik']);
        $oncelik = in_array($input['oncelik'], ['Düşük', 'Orta', 'Yüksek']) ? $input['oncelik'] : 'Orta';
        
        $stmt = $mysqli->prepare("INSERT INTO announcements (baslik, icerik, oncelik) VALUES (?, ?, ?)");
        $stmt->bind_param("sss", $baslik, $icerik, $oncelik);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'id' => $mysqli->insert_id]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Insert failed']);
        }
        $stmt->close();
        break;
        
    case 'update_announcement':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['id']) || empty($input['baslik']) || empty($input['icerik'])) {
            echo json_encode(['success' => false, 'error' => 'ID, başlık ve içerik gerekli']);
            break;
        }
        
        $id = intval($input['id']);
        $baslik = $mysqli->real_escape_string($input['baslik']);
        $icerik = $mysqli->real_escape_string($input['icerik']);
        $oncelik = in_array($input['oncelik'], ['Düşük', 'Orta', 'Yüksek']) ? $input['oncelik'] : 'Orta';
        
        $stmt = $mysqli->prepare("UPDATE announcements SET baslik = ?, icerik = ?, oncelik = ? WHERE id = ?");
        $stmt->bind_param("sssi", $baslik, $icerik, $oncelik, $id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Update failed']);
        }
        $stmt->close();
        break;
        
    case 'delete_announcement':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['id'])) {
            echo json_encode(['success' => false, 'error' => 'ID gerekli']);
            break;
        }
        
        $id = intval($input['id']);
        
        $stmt = $mysqli->prepare("DELETE FROM announcements WHERE id = ?");
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Delete failed']);
        }
        $stmt->close();
        break;
        
    case 'archive_announcement':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['id'])) {
            echo json_encode(['success' => false, 'error' => 'ID gerekli']);
            break;
        }
        
        $id = intval($input['id']);
        
        $stmt = $mysqli->prepare("UPDATE announcements SET status = 'arsivlendi' WHERE id = ?");
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Archive failed']);
        }
        $stmt->close();
        break;
        
    case 'activate_announcement':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['id'])) {
            echo json_encode(['success' => false, 'error' => 'ID gerekli']);
            break;
        }
        
        $id = intval($input['id']);
        
        $stmt = $mysqli->prepare("UPDATE announcements SET status = 'aktif' WHERE id = ?");
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Activate failed']);
        }
        $stmt->close();
        break;
        
    case 'archive_emergency_call':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['id'])) {
            echo json_encode(['success' => false, 'error' => 'ID gerekli']);
            break;
        }
        
        $id = intval($input['id']);
        
        $stmt = $mysqli->prepare("UPDATE emergency_calls SET status = 'arsivlendi' WHERE id = ?");
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Archive failed']);
        }
        $stmt->close();
        break;
        
    case 'activate_emergency_call':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['id'])) {
            echo json_encode(['success' => false, 'error' => 'ID gerekli']);
            break;
        }
        
        $id = intval($input['id']);
        
        $stmt = $mysqli->prepare("UPDATE emergency_calls SET status = 'aktif' WHERE id = ?");
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Activate failed']);
        }
        $stmt->close();
        break;
        
    case 'get_toplanma_alanlari':
        // İzmir Belediyesi API'sini çağır
        $context = stream_context_create([
            'http' => [
                'timeout' => 10,
                'user_agent' => 'Mozilla/5.0 (compatible; AcilDurumApp/1.0)'
            ]
        ]);
        
        $response = @file_get_contents('https://openapi.izmir.bel.tr/api/ibb/cbs/afetaciltoplanmaalani', false, $context);
        
        if ($response !== false) {
            $data = json_decode($response, true);
            if (json_last_error() === JSON_ERROR_NONE) {
                echo json_encode($data);
            } else {
                echo json_encode([]);
            }
        } else {
            echo json_encode([]);
        }
        break;
        
    case 'health':
        echo json_encode([
            'status' => 'OK',
            'timestamp' => date('Y-m-d H:i:s'),
            'database' => 'connected'
        ]);
        break;
        
    default:
        echo json_encode(['error' => 'Invalid action']);
}

$mysqli->close();
?>