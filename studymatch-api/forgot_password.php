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
$email = strtolower(trim($body['email'] ?? ''));

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['success' => false, 'message' => 'Invalid email address']); exit;
}

try {
    $pdo  = getDB();
    $stmt = $pdo->prepare('SELECT id, full_name FROM users WHERE email = ?');
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // Always return success to prevent email enumeration
    if (!$user) {
        echo json_encode(['success' => true,
            'message' => 'If this email exists, a reset link has been sent.']); exit;
    }

    $token   = bin2hex(random_bytes(32));
    $expires = time() + 3600; // 1 hour

    // Delete old tokens for this email
    $pdo->prepare('DELETE FROM password_resets WHERE email = ?')->execute([$email]);

    // Insert new token
    $pdo->prepare('INSERT INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)')
        ->execute([$email, $token, $expires]);

    $resetLink = "http://localhost/StudyMatch/studymatch-api/reset_password_page.php?token=$token&email=" . urlencode($email);
    $name      = $user['full_name'];

    $mail = new PHPMailer(true);
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
    $mail->Subject = 'Reset Your StudyMatch Password';
    $mail->Body    = buildResetEmail($name, $resetLink);
    $mail->AltBody = "Hi $name,\n\nClick this link to reset your password:\n$resetLink\n\nExpires in 1 hour.";
    $mail->send();

    echo json_encode(['success' => true,
        'message' => 'If this email exists, a reset link has been sent.']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Failed to send email: ' . $mail->ErrorInfo]);
} catch (\Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}

function buildResetEmail(string $name, string $link): string {
    return <<<HTML
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#0d0b1e;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:40px 16px;">
    <table width="520" cellpadding="0" cellspacing="0"
           style="background:linear-gradient(145deg,#120e2a,#1a1535);border-radius:20px;border:1px solid #2e2850;">
      <tr><td style="background:linear-gradient(135deg,#6C63FF,#a78bfa);padding:32px;text-align:center;">
        <h1 style="color:#fff;margin:0;font-size:24px;">StudyMatch</h1>
        <p style="color:rgba(255,255,255,0.8);margin:6px 0 0;font-size:13px;">Password Reset</p>
      </td></tr>
      <tr><td style="padding:36px 40px;text-align:center;">
        <p style="color:#c4b8ff;font-size:15px;">Hi <strong style="color:#fff;">$name</strong>,</p>
        <p style="color:#8b7fc7;font-size:14px;line-height:1.6;">
          You requested to reset your StudyMatch password.<br>
          Click the button below. This link expires in <strong style="color:#a78bfa;">1 hour</strong>.
        </p>
        <a href="$link"
           style="display:inline-block;margin:24px 0;padding:14px 36px;
                  background:linear-gradient(135deg,#6C63FF,#a78bfa);
                  color:#fff;text-decoration:none;border-radius:12px;
                  font-weight:700;font-size:15px;">
          Reset Password
        </a>
        <p style="color:#6b6490;font-size:12px;">
          If you didn't request this, you can safely ignore this email.
        </p>
      </td></tr>
      <tr><td style="border-top:1px solid #2e2850;padding:20px;text-align:center;">
        <p style="color:#3d3660;font-size:11px;">© 2026 StudyMatch</p>
      </td></tr>
    </table>
  </td></tr></table>
</body></html>
HTML;
}