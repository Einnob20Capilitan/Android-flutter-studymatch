<?php
require_once __DIR__ . '/PHPMailer-master/src/Exception.php';
require_once __DIR__ . '/PHPMailer-master/src/PHPMailer.php';
require_once __DIR__ . '/PHPMailer-master/src/SMTP.php';
require_once __DIR__ . '/db.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

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
$name  = trim($body['name']  ?? 'User');

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['success' => false, 'message' => 'Invalid email address']); exit;
}

$otp     = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$expires = time() + 600;

try {
    $pdo = getDB();
    // Delete old OTPs for this email
    $pdo->prepare('DELETE FROM otp_tokens WHERE email = ?')->execute([$email]);
    // Insert new OTP
    $stmt = $pdo->prepare('INSERT INTO otp_tokens (email, otp, expires_at, used) VALUES (?, ?, ?, 0)');
    $stmt->execute([$email, password_hash($otp, PASSWORD_BCRYPT), $expires]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]); exit;
}

$mail = new PHPMailer(true);
try {
    $mail->isSMTP();
    $mail->Host       = 'smtp.gmail.com';
    $mail->SMTPAuth   = true;
    $mail->Username   = 'carlosbonnie07@gmail.com';
    $mail->Password   = 'ugyhlpejnfdadtkx';
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = 587;

    $mail->setFrom('carlosbonnie07@gmail.com', 'StudyMatch');
    $mail->addAddress($email, $name);
    $mail->isHTML(true);
    $mail->Subject = 'Your StudyMatch Verification Code';
    $mail->Body    = buildEmailHtml($name, $otp);
    $mail->AltBody = "Hi $name,\n\nYour OTP is: $otp\nExpires in 10 minutes.";

    $mail->send();
    echo json_encode(['success' => true, 'message' => 'OTP sent successfully']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Email error: ' . $mail->ErrorInfo]);
}

function buildEmailHtml(string $name, string $otp): string {
    $digits = implode('', array_map(
        fn($d) => "<span style='display:inline-block;width:48px;height:56px;line-height:56px;margin:0 4px;
                    background:#1e1a3a;border:2px solid #6C63FF;border-radius:10px;
                    font-size:28px;font-weight:700;color:#ffffff;text-align:center;'>$d</span>",
        str_split($otp)
    ));
    return <<<HTML
<!DOCTYPE html><html><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#0d0b1e;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:40px 16px;">
    <table width="520" cellpadding="0" cellspacing="0"
           style="background:linear-gradient(145deg,#120e2a,#1a1535);border-radius:20px;border:1px solid #2e2850;">
      <tr><td style="background:linear-gradient(135deg,#6C63FF,#a78bfa);padding:32px;text-align:center;">
        <h1 style="color:#fff;margin:0;font-size:24px;">StudyMatch</h1>
        <p style="color:rgba(255,255,255,0.8);margin:6px 0 0;font-size:13px;">Email Verification</p>
      </td></tr>
      <tr><td style="padding:36px 40px;text-align:center;">
        <p style="color:#c4b8ff;">Hi <strong style="color:#fff;">$name</strong>,</p>
        <p style="color:#8b7fc7;">Your verification code expires in <strong style="color:#a78bfa;">10 minutes</strong>.</p>
        <div style="margin:0 auto 32px;">$digits</div>
        <p style="color:#6b6490;font-size:12px;">🔒 Never share this code with anyone.</p>
      </td></tr>
      <tr><td style="border-top:1px solid #2e2850;padding:20px;text-align:center;">
        <p style="color:#3d3660;font-size:11px;">© 2026 StudyMatch</p>
      </td></tr>
    </table>
  </td></tr></table>
</body></html>
HTML;
}