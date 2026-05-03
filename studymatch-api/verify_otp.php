<?php
require_once __DIR__ . '/db.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']); exit;
}

$body  = json_decode(file_get_contents('php://input'), true);
$email = trim($body['email'] ?? '');
$otp   = trim($body['otp']   ?? '');

if (empty($email) || empty($otp)) {
    echo json_encode(['success' => false, 'message' => 'Email and OTP are required']); exit;
}

try {
    $pdo  = getDB();
    $stmt = $pdo->prepare('SELECT * FROM otp_tokens WHERE email = ? AND used = 0 ORDER BY expires_at DESC LIMIT 1');
    $stmt->execute([$email]);
    $row  = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        echo json_encode(['success' => false, 'message' => 'OTP not found. Please request a new one.']); exit;
    }
    if (time() > $row['expires_at']) {
        $pdo->prepare('DELETE FROM otp_tokens WHERE email = ?')->execute([$email]);
        echo json_encode(['success' => false, 'message' => 'OTP expired. Please request a new one.']); exit;
    }
    if (!password_verify($otp, $row['otp'])) {
        echo json_encode(['success' => false, 'message' => 'Invalid OTP. Please try again.']); exit;
    }

    // Mark OTP as used
    $pdo->prepare('UPDATE otp_tokens SET used = 1 WHERE id = ?')->execute([$row['id']]);
    // Mark user as verified
    $pdo->prepare('UPDATE users SET email_verified = 1 WHERE email = ?')->execute([$email]);

    echo json_encode(['success' => true, 'message' => 'Email verified successfully! You can now sign in.']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}