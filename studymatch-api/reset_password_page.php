<?php
require_once __DIR__ . '/db.php';

$token = trim($_GET['token'] ?? '');
$email = trim($_GET['email'] ?? '');
$msg   = '';
$success = false;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $token    = trim($_POST['token'] ?? '');
    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    $confirm  = $_POST['confirm']  ?? '';

    if (strlen($password) < 8) {
        $msg = 'Password must be at least 8 characters.';
    } elseif ($password !== $confirm) {
        $msg = 'Passwords do not match.';
    } else {
        try {
            $pdo  = getDB();
            $stmt = $pdo->prepare('SELECT * FROM password_resets WHERE token = ? AND email = ? AND used = 0');
            $stmt->execute([$token, $email]);
            $row  = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$row) {
                $msg = 'Invalid or already used reset link.';
            } elseif (time() > $row['expires_at']) {
                $msg = 'This reset link has expired. Please request a new one.';
            } else {
                $pdo->prepare('UPDATE users SET password = ? WHERE email = ?')
                    ->execute([password_hash($password, PASSWORD_BCRYPT), $email]);
                $pdo->prepare('UPDATE password_resets SET used = 1 WHERE token = ?')
                    ->execute([$token]);
                $success = true;
                $msg = 'Password reset successfully! You can now sign in.';
            }
        } catch (Exception $e) {
            $msg = 'Error: ' . $e->getMessage();
        }
    }
}
?>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Reset Password — StudyMatch</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: #0d0b1e; font-family: 'Segoe UI', Arial, sans-serif;
           display: flex; align-items: center; justify-content: center;
           min-height: 100vh; padding: 20px; }
    .card { background: linear-gradient(145deg,#120e2a,#1a1535);
            border: 1px solid #2e2850; border-radius: 20px;
            padding: 40px; width: 100%; max-width: 420px; }
    .logo { text-align: center; margin-bottom: 28px; }
    .logo h1 { color: #fff; font-size: 22px; }
    .logo p  { color: rgba(255,255,255,0.6); font-size: 13px; margin-top: 4px; }
    label { color: #c4b8ff; font-size: 13px; display: block; margin-bottom: 6px; }
    input { width: 100%; padding: 12px 16px; background: #1e1a3a;
            border: 1px solid #2e2850; border-radius: 10px;
            color: #fff; font-size: 14px; margin-bottom: 16px; }
    input:focus { outline: none; border-color: #6C63FF; }
    button { width: 100%; padding: 14px;
             background: linear-gradient(135deg,#6C63FF,#a78bfa);
             color: #fff; border: none; border-radius: 12px;
             font-size: 15px; font-weight: 700; cursor: pointer; margin-top: 8px; }
    button:hover { opacity: 0.9; }
    .msg { padding: 12px 16px; border-radius: 10px; margin-bottom: 20px;
           font-size: 13px; text-align: center; }
    .error   { background: rgba(239,68,68,0.15); color: #f87171;
                border: 1px solid rgba(239,68,68,0.3); }
    .success { background: rgba(34,197,94,0.15); color: #4ade80;
                border: 1px solid rgba(34,197,94,0.3); }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">
      <h1>🎓 StudyMatch</h1>
      <p>Reset your password</p>
    </div>
    <?php if ($msg): ?>
      <div class="msg <?= $success ? 'success' : 'error' ?>"><?= htmlspecialchars($msg) ?></div>
    <?php endif; ?>
    <?php if (!$success): ?>
    <form method="POST">
      <input type="hidden" name="token" value="<?= htmlspecialchars($token) ?>">
      <input type="hidden" name="email" value="<?= htmlspecialchars($email) ?>">
      <label>New Password</label>
      <input type="password" name="password" placeholder="At least 8 characters" required>
      <label>Confirm Password</label>
      <input type="password" name="confirm" placeholder="Re-enter password" required>
      <button type="submit">Reset Password</button>
    </form>
    <?php else: ?>
      <p style="color:#8b7fc7;text-align:center;font-size:14px;">
        You can now close this page and sign in to StudyMatch.
      </p>
    <?php endif; ?>
  </div>
</body>
</html>