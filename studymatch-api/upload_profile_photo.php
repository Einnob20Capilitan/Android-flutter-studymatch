<?php
require_once __DIR__ . '/db.php';

// ── CORS — must be FIRST, before any output ───────────────────────────────
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, Origin');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// ── Constants ─────────────────────────────────────────────────────────────
define('PROFILE_UPLOAD_DIR', __DIR__ . '/uploads/profiles/');
define('MAX_PHOTO_SIZE',      5 * 1024 * 1024);
define('ALLOWED_MIME', ['image/jpeg', 'image/png', 'image/gif', 'image/webp']);

// ── Auto-detect the server's host so the returned URL always works ─────────
// Uses the Host header the client sent (e.g. "192.168.1.5" or "localhost").
// This means the URL works on both LAN (native app) and localhost (web dev).
$host   = $_SERVER['HTTP_HOST'] ?? 'localhost'; // e.g. "192.168.1.5" or "localhost:8080"
$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
define('PROFILE_UPLOAD_URL_BASE', $scheme . '://' . $host . '/StudyMatch/studymatch-api/serve_photo.php?file=');

$newName = ''; // will be set in path A or B

// ── Detect whether this is JSON (base64) or multipart ─────────────────────
$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
$isJson      = strpos($contentType, 'application/json') !== false;

if ($isJson) {
    // ── PATH A: Flutter Web sends base64 JSON ─────────────────────────────
    $body = json_decode(file_get_contents('php://input'), true);
    if (!$body) {
        echo json_encode(['success' => false, 'message' => 'Invalid JSON body']);
        exit;
    }

    $userId      = trim($body['id']       ?? '');
    $base64Photo = trim($body['photo']    ?? '');
    $fileName    = trim($body['fileName'] ?? 'photo.jpg');
    $mimeType    = trim($body['mimeType'] ?? 'image/jpeg');

    if (empty($userId) || empty($base64Photo)) {
        echo json_encode(['success' => false, 'message' => 'Missing id or photo']);
        exit;
    }

    if (!in_array($mimeType, ALLOWED_MIME, true)) {
        echo json_encode(['success' => false, 'message' => "MIME type '$mimeType' not allowed"]);
        exit;
    }

    $photoBytes = base64_decode($base64Photo);
    if ($photoBytes === false) {
        echo json_encode(['success' => false, 'message' => 'Invalid base64 data']);
        exit;
    }

    if (strlen($photoBytes) > MAX_PHOTO_SIZE) {
        echo json_encode(['success' => false, 'message' => 'Photo too large. Max 5 MB.']);
        exit;
    }

    // Write to temp file so we can verify actual MIME
    $tmpPath = tempnam(sys_get_temp_dir(), 'sm_photo_');
    file_put_contents($tmpPath, $photoBytes);
    $detectedMime = mime_content_type($tmpPath);

    if (!in_array($detectedMime, ALLOWED_MIME, true)) {
        @unlink($tmpPath);
        echo json_encode(['success' => false, 'message' => "Detected type '$detectedMime' not allowed"]);
        exit;
    }

    if (!is_dir(PROFILE_UPLOAD_DIR)) mkdir(PROFILE_UPLOAD_DIR, 0755, true);

    // Delete old photo for this user
    $safeId     = preg_replace('/[^a-zA-Z0-9_\-]/', '', $userId);
    $oldPattern = PROFILE_UPLOAD_DIR . 'profile_' . $safeId . '_*';
    foreach (glob($oldPattern) ?: [] as $oldFile) @unlink($oldFile);

    $ext     = strtolower(pathinfo($fileName, PATHINFO_EXTENSION)) ?: 'jpg';
    $safeExt = preg_replace('/[^a-zA-Z0-9]/', '', $ext);
    $newName = 'profile_' . $safeId . '_' . time() . '.' . $safeExt;
    $dest    = PROFILE_UPLOAD_DIR . $newName;

    if (!rename($tmpPath, $dest)) {
        @unlink($tmpPath);
        echo json_encode(['success' => false, 'message' => 'Failed to save photo']);
        exit;
    }
    chmod($dest, 0644);

} else {
    // ── PATH B: Native app sends multipart/form-data ──────────────────────
    $userId = trim($_POST['id'] ?? '');
    if (empty($userId)) {
        echo json_encode(['success' => false, 'message' => 'User ID required']);
        exit;
    }
    if (!isset($_FILES['photo']) || $_FILES['photo']['error'] === UPLOAD_ERR_NO_FILE) {
        echo json_encode(['success' => false, 'message' => 'No photo uploaded']);
        exit;
    }

    $file    = $_FILES['photo'];
    $tmpPath = $file['tmp_name'];

    if ($file['error'] !== UPLOAD_ERR_OK) {
        echo json_encode(['success' => false, 'message' => 'Upload error code: ' . $file['error']]);
        exit;
    }
    if ($file['size'] > MAX_PHOTO_SIZE) {
        echo json_encode(['success' => false, 'message' => 'Photo too large. Max 5 MB.']);
        exit;
    }

    $mimeType = mime_content_type($tmpPath);
    if (!in_array($mimeType, ALLOWED_MIME, true)) {
        echo json_encode(['success' => false, 'message' => "Type '$mimeType' not allowed"]);
        exit;
    }

    if (!is_dir(PROFILE_UPLOAD_DIR)) mkdir(PROFILE_UPLOAD_DIR, 0755, true);

    $safeId     = preg_replace('/[^a-zA-Z0-9_\-]/', '', $userId);
    $oldPattern = PROFILE_UPLOAD_DIR . 'profile_' . $safeId . '_*';
    foreach (glob($oldPattern) ?: [] as $oldFile) @unlink($oldFile);

    $ext     = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION)) ?: 'jpg';
    $safeExt = preg_replace('/[^a-zA-Z0-9]/', '', $ext);
    $newName = 'profile_' . $safeId . '_' . time() . '.' . $safeExt;
    $dest    = PROFILE_UPLOAD_DIR . $newName;

    if (!move_uploaded_file($tmpPath, $dest)) {
        echo json_encode(['success' => false, 'message' => 'Failed to save photo']);
        exit;
    }
    chmod($dest, 0644);
}

// ── Build public URL and persist ──────────────────────────────────────────
$url = PROFILE_UPLOAD_URL_BASE . $newName;

try {
    $pdo = getDB();
    $pdo->prepare('UPDATE profiles SET profile_photo_url = ? WHERE user_id = ?')
        ->execute([$url, $userId]);
} catch (Exception $e) {
    error_log('Photo URL DB update failed: ' . $e->getMessage());
}

echo json_encode(['success' => true, 'url' => $url]);