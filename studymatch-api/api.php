<?php
/**
 * StudyMatch Unified REST API
 * Base URL: http://localhost/StudyMatch/studymatch-api/api.php
 */

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/PHPMailer-master/src/Exception.php';
require_once __DIR__ . '/PHPMailer-master/src/PHPMailer.php';
require_once __DIR__ . '/PHPMailer-master/src/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception as MailException;

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS, DELETE, PUT');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, X-API-Key');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200); exit();
}

define('API_KEY', 'studymatch_api_key_2026');

$action = trim($_GET['action'] ?? '');
$method = $_SERVER['REQUEST_METHOD'];
$body   = json_decode(file_get_contents('php://input'), true) ?? [];
$apiKey = $_GET['api_key'] ?? '';

$publicRoutes = ['login', 'register', 'send_otp', 'verify_otp', 'forgot_password'];
if (!in_array($action, $publicRoutes) && $apiKey !== API_KEY) {
    respond(false, 'Invalid or missing API key', null, 401); exit;
}

try {
    $pdo = getDB();

    // ✅ Fix collation mismatch for all queries in this connection
    $pdo->exec("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("SET collation_connection = utf8mb4_unicode_ci");

    switch ($action) {
        case 'register':         handleRegister($pdo, $body);        break;
        case 'login':            handleLogin($pdo, $body);           break;
        case 'send_otp':         handleSendOtp($pdo, $body);         break;
        case 'verify_otp':       handleVerifyOtp($pdo, $body);       break;
        case 'forgot_password':  handleForgotPassword($pdo, $body);  break;
        case 'update_profile':   handleUpdateProfile($pdo, $body);   break;
        case 'get_users':        handleGetUsers($pdo);               break;
        case 'get_user':         handleGetUser($pdo);                break;
        case 'get_profile':      handleGetProfile($pdo);             break;
        case 'rate_user':        handleRateUser($pdo, $body);        break;
        case 'get_resources':    handleGetResources($pdo);           break;
        case 'upload_resource':  handleUploadResource($pdo);         break;
        default:
            respond(false, 'Unknown action', null, 404);
    }
} catch (Exception $e) {
    respond(false, 'Server error: ' . $e->getMessage(), null, 500);
}

// ── Helper ────────────────────────────────────────────────────────────────────
function respond(bool $success, string $message, $data = null, int $code = 200): void {
    http_response_code($code);
    $out = ['success' => $success, 'message' => $message];
    if ($data !== null) $out['data'] = $data;
    echo json_encode($out, JSON_UNESCAPED_UNICODE);
    exit;
}

// ── Handlers ──────────────────────────────────────────────────────────────────

function handleRegister(PDO $pdo, array $b): void {
    $id       = trim($b['id'] ?? uniqid('u_', true));
    $name     = trim($b['fullName'] ?? '');
    $email    = strtolower(trim($b['email'] ?? ''));
    $password = $b['password'] ?? '';

    if (empty($name) || empty($email) || empty($password))
        respond(false, 'Name, email and password are required', null, 400);
    if (!filter_var($email, FILTER_VALIDATE_EMAIL))
        respond(false, 'Invalid email address', null, 400);

    $stmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $stmt->execute([$email]);
    if ($stmt->fetch()) respond(false, 'Email already registered', null, 409);

    $pdo->prepare('INSERT INTO users (id, full_name, email, password) VALUES (?,?,?,?)')
        ->execute([$id, $name, $email, password_hash($password, PASSWORD_BCRYPT)]);

    respond(true, 'Account created successfully', ['id' => $id]);
}

function handleLogin(PDO $pdo, array $b): void {
    $email    = strtolower(trim($b['email'] ?? ''));
    $password = $b['password'] ?? '';

    if (empty($email) || empty($password))
        respond(false, 'Email and password are required', null, 400);

    $stmt = $pdo->prepare('
        SELECT u.*, p.school, p.department, p.topic, p.year_level,
               p.date_of_birth, p.gender, p.subjects, p.learning_styles,
               p.study_styles, p.availability, p.strengths, p.weaknesses,
               p.profile_photo_url, p.bio, p.onboarding_complete,
               p.rating, p.rating_count
        FROM users u
        LEFT JOIN profiles p ON u.id = p.user_id
        WHERE u.email = ?
    ');
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user || !password_verify($password, $user['password']))
        respond(false, 'Invalid email or password', null, 401);
    if (!$user['email_verified'])
        respond(false, 'Please verify your email first', null, 403);

    respond(true, 'Login successful', formatUser($user));
}

function handleSendOtp(PDO $pdo, array $b): void {
    $email = strtolower(trim($b['email'] ?? ''));
    $name  = trim($b['name'] ?? 'User');

    if (!filter_var($email, FILTER_VALIDATE_EMAIL))
        respond(false, 'Invalid email', null, 400);

    $otp     = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
    $expires = time() + 600;

    $pdo->prepare('DELETE FROM otp_tokens WHERE email = ?')->execute([$email]);
    $pdo->prepare('INSERT INTO otp_tokens (email, otp, expires_at, used) VALUES (?,?,?,0)')
        ->execute([$email, password_hash($otp, PASSWORD_BCRYPT), $expires]);

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
        $mail->Body    = buildOtpEmail($name, $otp);
        $mail->AltBody = "Hi $name, your OTP is: $otp. Expires in 10 minutes.";
        $mail->send();
        respond(true, 'OTP sent successfully');
    } catch (MailException $e) {
        respond(false, 'Email error: ' . $mail->ErrorInfo);
    }
}

function handleVerifyOtp(PDO $pdo, array $b): void {
    $email = strtolower(trim($b['email'] ?? ''));
    $otp   = trim($b['otp'] ?? '');

    if (empty($email) || empty($otp))
        respond(false, 'Email and OTP required', null, 400);

    $stmt = $pdo->prepare('
        SELECT * FROM otp_tokens
        WHERE email = ? AND used = 0
        ORDER BY expires_at DESC LIMIT 1
    ');
    $stmt->execute([$email]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) respond(false, 'OTP not found', null, 404);
    if (time() > $row['expires_at']) {
        $pdo->prepare('DELETE FROM otp_tokens WHERE email = ?')->execute([$email]);
        respond(false, 'OTP expired', null, 410);
    }
    if (!password_verify($otp, $row['otp']))
        respond(false, 'Invalid OTP', null, 401);

    $pdo->prepare('UPDATE otp_tokens SET used = 1 WHERE id = ?')
        ->execute([$row['id']]);
    $pdo->prepare('UPDATE users SET email_verified = 1 WHERE email = ?')
        ->execute([$email]);

    respond(true, 'Email verified successfully');
}

function handleForgotPassword(PDO $pdo, array $b): void {
    $email = strtolower(trim($b['email'] ?? ''));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL))
        respond(false, 'Invalid email', null, 400);

    $stmt = $pdo->prepare('SELECT id, full_name FROM users WHERE email = ?');
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        respond(true, 'If this email exists, a reset link was sent'); return;
    }

    $token   = bin2hex(random_bytes(32));
    $expires = time() + 3600;
    $pdo->prepare('DELETE FROM password_resets WHERE email = ?')->execute([$email]);
    $pdo->prepare('INSERT INTO password_resets (email, token, expires_at) VALUES (?,?,?)')
        ->execute([$email, $token, $expires]);

    $resetLink = 'http://localhost/StudyMatch/studymatch-api/reset_password_page.php'
               . '?token=' . $token . '&email=' . urlencode($email);
    $name      = $user['full_name'];

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
        $mail->Subject = 'Reset Your StudyMatch Password';
        $mail->Body    = buildResetEmail($name, $resetLink);
        $mail->AltBody = "Hi $name, reset link: $resetLink (expires in 1 hour)";
        $mail->send();
        respond(true, 'If this email exists, a reset link was sent');
    } catch (MailException $e) {
        respond(false, 'Email error: ' . $mail->ErrorInfo);
    }
}

function handleUpdateProfile(PDO $pdo, array $b): void {
    $id = trim($b['id'] ?? '');
    if (empty($id)) respond(false, 'User ID required', null, 400);

    $stmt = $pdo->prepare('SELECT user_id FROM profiles WHERE user_id = ?');
    $stmt->execute([$id]);
    $exists = $stmt->fetch();

    if ($exists) {
        $pdo->prepare('
            UPDATE profiles SET
                school=?, department=?, topic=?, year_level=?,
                date_of_birth=?, gender=?, subjects=?, learning_styles=?,
                study_styles=?, availability=?, strengths=?, weaknesses=?,
                profile_photo_url=?, bio=?, onboarding_complete=?
            WHERE user_id=?
        ')->execute([
            $b['school']      ?? null,
            $b['department']  ?? null,
            $b['topic']       ?? null,
            $b['yearLevel']   ?? null,
            $b['dateOfBirth'] ?? null,
            $b['gender']      ?? null,
            json_encode($b['subjects']       ?? []),
            json_encode($b['learningStyles'] ?? []),
            json_encode($b['studyStyles']    ?? []),
            json_encode($b['availability']   ?? []),
            json_encode($b['strengths']      ?? []),
            json_encode($b['weaknesses']     ?? []),
            $b['profilePhotoUrl'] ?? null,
            $b['bio']             ?? null,
            ($b['onboardingComplete'] ?? false) ? 1 : 0,
            $id,
        ]);
    } else {
        $pdo->prepare('
            INSERT INTO profiles (
                user_id, school, department, topic, year_level,
                date_of_birth, gender, subjects, learning_styles,
                study_styles, availability, strengths, weaknesses,
                profile_photo_url, bio, onboarding_complete
            ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        ')->execute([
            $id,
            $b['school']      ?? null,
            $b['department']  ?? null,
            $b['topic']       ?? null,
            $b['yearLevel']   ?? null,
            $b['dateOfBirth'] ?? null,
            $b['gender']      ?? null,
            json_encode($b['subjects']       ?? []),
            json_encode($b['learningStyles'] ?? []),
            json_encode($b['studyStyles']    ?? []),
            json_encode($b['availability']   ?? []),
            json_encode($b['strengths']      ?? []),
            json_encode($b['weaknesses']     ?? []),
            $b['profilePhotoUrl'] ?? null,
            $b['bio']             ?? null,
            ($b['onboardingComplete'] ?? false) ? 1 : 0,
        ]);
    }

    if (!empty($b['fullName'])) {
        $pdo->prepare('UPDATE users SET full_name=? WHERE id=?')
            ->execute([$b['fullName'], $id]);
    }

    respond(true, 'Profile updated');
}

function handleGetUsers(PDO $pdo): void {
    $subject      = trim($_GET['subject']       ?? '');
    $search       = trim($_GET['search']        ?? '');
    $excludeId    = trim($_GET['exclude_id']    ?? '');
    $myStrengths  = trim($_GET['my_strengths']  ?? '');
    $myWeaknesses = trim($_GET['my_weaknesses'] ?? '');

    $sql    = '
        SELECT u.id, u.full_name, u.email,
               p.school, p.department, p.subjects, p.learning_styles,
               p.study_styles, p.profile_photo_url, p.rating, p.rating_count,
               p.strengths, p.weaknesses, p.bio
        FROM users u
        INNER JOIN profiles p ON u.id = p.user_id
        WHERE u.email_verified = 1 AND p.onboarding_complete = 1
    ';
    $params = [];

    if (!empty($excludeId)) {
        $sql .= ' AND u.id != ?'; $params[] = $excludeId;
    }
    if (!empty($subject)) {
        $sql .= ' AND JSON_CONTAINS(p.subjects, ?)';
        $params[] = json_encode($subject);
    }
    if (!empty($search)) {
        $sql .= ' AND (u.full_name LIKE ? OR p.department LIKE ?)';
        $params[] = "%$search%"; $params[] = "%$search%";
    }
    $sql .= ' ORDER BY p.rating DESC';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $myWeakArr = !empty($myWeaknesses) ? json_decode($myWeaknesses, true) : [];
    $myStrArr  = !empty($myStrengths)  ? json_decode($myStrengths,  true) : [];

    $users = [];
    foreach ($rows as $r) {
        $theirStr  = json_decode($r['strengths']  ?? '[]', true) ?: [];
        $theirWeak = json_decode($r['weaknesses'] ?? '[]', true) ?: [];

        // ✅ Compatibility: my weak = their strong, my strong = their weak
        $score = count(array_intersect($myWeakArr, $theirStr))
               + count(array_intersect($myStrArr,  $theirWeak));

        $users[] = [
            'id'                 => $r['id'],
            'fullName'           => $r['full_name'],
            'email'              => $r['email'],
            'school'             => $r['school'],
            'department'         => $r['department'],
            'subjects'           => json_decode($r['subjects']        ?? '[]') ?: [],
            'learningStyles'     => json_decode($r['learning_styles'] ?? '[]') ?: [],
            'studyStyles'        => json_decode($r['study_styles']    ?? '[]') ?: [],
            'profilePhotoUrl'    => $r['profile_photo_url'],
            'rating'             => (float) $r['rating'],
            'ratingCount'        => (int)   $r['rating_count'],
            'strengths'          => $theirStr,
            'weaknesses'         => $theirWeak,
            'bio'                => $r['bio'],
            'compatibilityScore' => $score,
        ];
    }

    // ✅ Highest compatibility first
    usort($users, fn($a, $b) => $b['compatibilityScore'] - $a['compatibilityScore']);
    respond(true, 'Users fetched', $users);
}

function handleGetUser(PDO $pdo): void {
    $id = trim($_GET['id'] ?? '');
    if (empty($id)) respond(false, 'User ID required', null, 400);

    $stmt = $pdo->prepare('
        SELECT u.*, p.school, p.department, p.topic, p.year_level,
               p.date_of_birth, p.gender, p.subjects, p.learning_styles,
               p.study_styles, p.availability, p.strengths, p.weaknesses,
               p.profile_photo_url, p.bio, p.onboarding_complete,
               p.rating, p.rating_count
        FROM users u
        LEFT JOIN profiles p ON u.id = p.user_id
        WHERE u.id = ?
    ');
    $stmt->execute([$id]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) respond(false, 'User not found', null, 404);
    respond(true, 'User fetched', formatUser($user));
}

function handleGetProfile(PDO $pdo): void {
    handleGetUser($pdo);
}

function handleRateUser(PDO $pdo, array $b): void {
    $raterId = trim($b['rater_id'] ?? '');
    $ratedId = trim($b['rated_id'] ?? '');
    $score   = (int)($b['score']   ?? 0);

    if (empty($raterId) || empty($ratedId) || $score < 1 || $score > 5)
        respond(false, 'Invalid input', null, 400);
    if ($raterId === $ratedId)
        respond(false, 'Cannot rate yourself', null, 400);

    $pdo->prepare('
        INSERT INTO ratings (rater_id, rated_id, score) VALUES (?,?,?)
        ON DUPLICATE KEY UPDATE score = VALUES(score)
    ')->execute([$raterId, $ratedId, $score]);

    $stmt = $pdo->prepare('
        SELECT AVG(score) as avg, COUNT(*) as cnt
        FROM ratings WHERE rated_id = ?
    ');
    $stmt->execute([$ratedId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    $pdo->prepare('UPDATE profiles SET rating=?, rating_count=? WHERE user_id=?')
        ->execute([round($row['avg'], 2), $row['cnt'], $ratedId]);

    respond(true, 'Rating submitted', [
        'newRating'   => round($row['avg'], 2),
        'ratingCount' => (int) $row['cnt'],
    ]);
}

function handleGetResources(PDO $pdo): void {
    $subject = trim($_GET['subject'] ?? '');
    $search  = trim($_GET['search']  ?? '');

    $sql    = '
        SELECT r.*, u.full_name as uploader_name
        FROM resources r
        JOIN users u ON r.uploader_id = u.id
        WHERE 1=1
    ';
    $params = [];

    if (!empty($subject) && $subject !== 'All') {
        $sql .= ' AND r.subject = ?'; $params[] = $subject;
    }
    if (!empty($search)) {
        $sql .= ' AND (r.title LIKE ? OR r.subject LIKE ?)';
        $params[] = "%$search%"; $params[] = "%$search%";
    }
    $sql .= ' ORDER BY r.uploaded_at DESC';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $resources = array_map(fn($r) => [
        'id'           => $r['id'],
        'title'        => $r['title'],
        'subject'      => $r['subject'],
        'description'  => $r['description'],
        'uploaderName' => $r['uploader_name'],
        'fileUrl'      => $r['file_path']
            ? 'http://localhost/StudyMatch/studymatch-api/' . $r['file_path']
            : null,
        'fileType'     => $r['file_type'],
        'uploadedAt'   => $r['uploaded_at'],
    ], $rows);

    respond(true, 'Resources fetched', $resources);
}

function handleUploadResource(PDO $pdo): void {
    $uploaderId  = $_POST['uploader_id']  ?? '';
    $title       = trim($_POST['title']   ?? '');
    $subject     = trim($_POST['subject'] ?? '');
    $description = trim($_POST['description'] ?? '');

    if (empty($uploaderId) || empty($title) || empty($subject))
        respond(false, 'Missing required fields', null, 400);

    $uploadDir = __DIR__ . '/uploads/';
    if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);

    $fileName = null; $filePath = null; $fileType = 'link';

    if (isset($_FILES['file']) && $_FILES['file']['error'] === UPLOAD_ERR_OK) {
        $ext = strtolower(pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION));
        if (!in_array($ext, ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt']))
            respond(false, 'File type not allowed', null, 400);

        $fileName = preg_replace('/[^a-z0-9]/i', '_', $uploaderId)
                  . '_' . time() . '.' . $ext;
        if (!move_uploaded_file($_FILES['file']['tmp_name'], $uploadDir . $fileName))
            respond(false, 'Failed to save file', null, 500);

        $filePath = 'uploads/' . $fileName;
        $fileType = $ext;
    }

    $id = uniqid('res_', true);
    $pdo->prepare('
        INSERT INTO resources
            (id, uploader_id, title, subject, description, file_name, file_path, file_type)
        VALUES (?,?,?,?,?,?,?,?)
    ')->execute([$id, $uploaderId, $title, $subject, $description,
                 $fileName, $filePath, $fileType]);

    respond(true, 'Resource uploaded', ['id' => $id]);
}

// ── Format helpers ────────────────────────────────────────────────────────────
function formatUser(array $u): array {
    return [
        'id'                 => $u['id'],
        'fullName'           => $u['full_name'],
        'email'              => $u['email'],
        'profilePhotoUrl'    => $u['profile_photo_url'] ?? null,
        'school'             => $u['school']             ?? null,
        'department'         => $u['department']         ?? null,
        'topic'              => $u['topic']              ?? null,
        'yearLevel'          => $u['year_level']         ?? null,
        'dateOfBirth'        => $u['date_of_birth']      ?? null,
        'gender'             => $u['gender']             ?? null,
        'bio'                => $u['bio']                ?? null,
        'subjects'           => json_decode($u['subjects']        ?? '[]'),
        'learningStyles'     => json_decode($u['learning_styles'] ?? '[]'),
        'studyStyles'        => json_decode($u['study_styles']    ?? '[]'),
        'availability'       => json_decode($u['availability']    ?? '{}', true) ?: (object)[],
        'strengths'          => json_decode($u['strengths']       ?? '[]'),
        'weaknesses'         => json_decode($u['weaknesses']      ?? '[]'),
        'onboardingComplete' => (bool)($u['onboarding_complete']  ?? false),
        'rating'             => (float)($u['rating']              ?? 0),
        'ratingCount'        => (int)($u['rating_count']          ?? 0),
    ];
}

function buildOtpEmail(string $name, string $otp): string {
    $digits = implode('', array_map(
        fn($d) => "<span style='display:inline-block;width:44px;height:52px;
                    line-height:52px;margin:0 3px;background:#1e1a3a;
                    border:2px solid #6C63FF;border-radius:8px;
                    font-size:24px;font-weight:700;color:#fff;
                    text-align:center;'>$d</span>",
        str_split($otp)
    ));
    return <<<HTML
<body style="background:#0d0b1e;font-family:'Segoe UI',sans-serif;padding:40px 16px;">
  <div style="max-width:480px;margin:0 auto;background:linear-gradient(145deg,#120e2a,#1a1535);
              border-radius:20px;border:1px solid #2e2850;overflow:hidden;">
    <div style="background:linear-gradient(135deg,#6C63FF,#a78bfa);padding:28px;text-align:center;">
      <h1 style="color:#fff;margin:0;font-size:22px;">🎓 StudyMatch</h1>
      <p style="color:rgba(255,255,255,0.8);margin:4px 0 0;font-size:13px;">Email Verification</p>
    </div>
    <div style="padding:32px;text-align:center;">
      <p style="color:#c4b8ff;">Hi <strong style="color:#fff;">$name</strong>,</p>
      <p style="color:#8b7fc7;font-size:14px;margin-bottom:28px;">
        Your verification code expires in <strong style="color:#a78bfa;">10 minutes</strong>.
      </p>
      <div style="margin-bottom:28px;">$digits</div>
      <p style="color:#6b6490;font-size:12px;">🔒 Never share this code with anyone.</p>
    </div>
    <div style="border-top:1px solid #2e2850;padding:16px;text-align:center;">
      <p style="color:#3d3660;font-size:11px;margin:0;">© 2026 StudyMatch</p>
    </div>
  </div>
</body>
HTML;
}

function buildResetEmail(string $name, string $link): string {
    return <<<HTML
<body style="background:#0d0b1e;font-family:'Segoe UI',sans-serif;padding:40px 16px;">
  <div style="max-width:480px;margin:0 auto;background:linear-gradient(145deg,#120e2a,#1a1535);
              border-radius:20px;border:1px solid #2e2850;overflow:hidden;">
    <div style="background:linear-gradient(135deg,#6C63FF,#a78bfa);padding:28px;text-align:center;">
      <h1 style="color:#fff;margin:0;font-size:22px;">🎓 StudyMatch</h1>
      <p style="color:rgba(255,255,255,0.8);margin:4px 0 0;font-size:13px;">Password Reset</p>
    </div>
    <div style="padding:32px;text-align:center;">
      <p style="color:#c4b8ff;">Hi <strong style="color:#fff;">$name</strong>,</p>
      <p style="color:#8b7fc7;font-size:14px;margin-bottom:24px;">
        Click below to reset your password. Expires in
        <strong style="color:#a78bfa;">1 hour</strong>.
      </p>
      <a href="$link" style="display:inline-block;padding:14px 32px;
         background:linear-gradient(135deg,#6C63FF,#a78bfa);
         color:#fff;text-decoration:none;border-radius:12px;
         font-weight:700;font-size:15px;">Reset Password</a>
      <p style="color:#6b6490;font-size:12px;margin-top:24px;">
        Didn't request this? Ignore this email.
      </p>
    </div>
    <div style="border-top:1px solid #2e2850;padding:16px;text-align:center;">
      <p style="color:#3d3660;font-size:11px;margin:0;">© 2026 StudyMatch</p>
    </div>
  </div>
</body>
HTML;
}