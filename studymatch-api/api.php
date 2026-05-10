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
        case 'get_reviews':      handleGetReviews($pdo);             break; // ✅ NEW
        case 'get_resources':    handleGetResources($pdo);           break;
        case 'upload_resource':  handleUploadResource($pdo);         break;
        case 'save_match':       handleSaveMatch($pdo, $body);       break;
        case 'get_matches':      handleGetMatches($pdo);             break;
        case 'remove_match':     handleRemoveMatch($pdo, $body);     break;
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

function safeJsonArray($val): array {
    if (empty($val)) return [];
    $decoded = json_decode($val, true);
    return is_array($decoded) ? $decoded : [];
}

function safeJsonObject($val): array {
    if (empty($val)) return [];
    $decoded = json_decode($val, true);
    return is_array($decoded) ? $decoded : [];
}

// ── Attribute check ───────────────────────────────────────────────────────────
function hasAttributes(array $strengths, array $weaknesses, array $subjects): bool {
    return !empty($strengths) || !empty($weaknesses) || !empty($subjects);
}

// ── Compatibility score ───────────────────────────────────────────────────────
function computeCompatibility(
    string $myRole,
    array  $myStrengths,
    array  $myWeaknesses,
    string $theirRole,
    array  $theirStrengths,
    array  $theirWeaknesses
): int {
    if ($theirRole === 'tutor') {
        return count(array_intersect($myWeaknesses, $theirStrengths));
    } else {
        return count(array_intersect($myStrengths, $theirWeaknesses));
    }
}

// ── Auth Handlers ─────────────────────────────────────────────────────────────

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

    $pdo->prepare('INSERT INTO profiles (user_id, role, onboarding_complete) VALUES (?,?,?)')
        ->execute([$id, 'student', 0]);

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
               p.rating, p.rating_count, p.role
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

    $pdo->prepare('UPDATE otp_tokens SET used = 1 WHERE id = ?')->execute([$row['id']]);
    $pdo->prepare('UPDATE users SET email_verified = 1 WHERE email = ?')->execute([$email]);

    respond(true, 'Email verified successfully');
}

function handleForgotPassword(PDO $pdo, array $b): void {
    $email = strtolower(trim($b['email'] ?? ''));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL))
        respond(false, 'Invalid email', null, 400);

    $stmt = $pdo->prepare('SELECT id, full_name FROM users WHERE email = ?');
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) { respond(true, 'If this email exists, a reset link was sent'); return; }

    $token   = bin2hex(random_bytes(32));
    $expires = time() + 3600;
    $pdo->prepare('DELETE FROM password_resets WHERE email = ?')->execute([$email]);
    $pdo->prepare('INSERT INTO password_resets (email, token, expires_at) VALUES (?,?,?)')
        ->execute([$email, $token, $expires]);

    $resetLink = 'http://localhost/StudyMatch/studymatch-api/reset_password_page.php'
               . '?token=' . $token . '&email=' . urlencode($email);
    $name = $user['full_name'];

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

// ── Profile ───────────────────────────────────────────────────────────────────

function handleUpdateProfile(PDO $pdo, array $b): void {
    $id = trim($b['id'] ?? '');
    if (empty($id)) respond(false, 'User ID required', null, 400);

    $role = $b['role'] ?? 'student';

    $stmt = $pdo->prepare('SELECT user_id FROM profiles WHERE user_id = ?');
    $stmt->execute([$id]);
    $exists = $stmt->fetch();

    if ($exists) {
        $pdo->prepare('
            UPDATE profiles SET
                role=?, school=?, department=?, topic=?, year_level=?,
                date_of_birth=?, gender=?, subjects=?, learning_styles=?,
                study_styles=?, availability=?, strengths=?, weaknesses=?,
                profile_photo_url=?, bio=?, onboarding_complete=?
            WHERE user_id=?
        ')->execute([
            $role,
            $b['school']      ?? null,
            $b['department']  ?? null,
            $b['topic']       ?? null,
            $b['yearLevel']   ?? null,
            $b['dateOfBirth'] ?? null,
            $b['gender']      ?? null,
            json_encode($b['subjects']       ?? []),
            json_encode($b['learningStyles'] ?? []),
            json_encode($b['studyStyles']    ?? []),
            json_encode($b['availability']   ?? (object)[]),
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
                user_id, role, school, department, topic, year_level,
                date_of_birth, gender, subjects, learning_styles,
                study_styles, availability, strengths, weaknesses,
                profile_photo_url, bio, onboarding_complete
            ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        ')->execute([
            $id, $role,
            $b['school']      ?? null,
            $b['department']  ?? null,
            $b['topic']       ?? null,
            $b['yearLevel']   ?? null,
            $b['dateOfBirth'] ?? null,
            $b['gender']      ?? null,
            json_encode($b['subjects']       ?? []),
            json_encode($b['learningStyles'] ?? []),
            json_encode($b['studyStyles']    ?? []),
            json_encode($b['availability']   ?? (object)[]),
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

    cleanStaleMatches($pdo, $id);
    respond(true, 'Profile updated');
}

// ── Clean stale matches ───────────────────────────────────────────────────────
function cleanStaleMatches(PDO $pdo, string $userId): void {
    $stmt = $pdo->prepare('SELECT role, strengths, weaknesses FROM profiles WHERE user_id = ?');
    $stmt->execute([$userId]);
    $myProfile = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$myProfile) return;

    $myRole  = $myProfile['role'] ?? 'student';
    $myStr   = safeJsonArray($myProfile['strengths']  ?? null);
    $myWeak  = safeJsonArray($myProfile['weaknesses'] ?? null);

    $stmt = $pdo->prepare('
        SELECT m.id as match_id, p.role as their_role,
               p.strengths as their_str, p.weaknesses as their_weak,
               p.subjects as their_subj
        FROM matches m
        JOIN profiles p ON p.user_id = m.matched_id
        WHERE m.user_id = ?
    ');
    $stmt->execute([$userId]);
    $myMatches = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $staleMatchIds = [];
    foreach ($myMatches as $row) {
        $theirStr  = safeJsonArray($row['their_str']  ?? null);
        $theirWeak = safeJsonArray($row['their_weak'] ?? null);
        $theirSubj = safeJsonArray($row['their_subj'] ?? null);
        $theirRole = $row['their_role'] ?? 'student';

        if (!hasAttributes($myStr, $myWeak, []) || !hasAttributes($theirStr, $theirWeak, $theirSubj)) {
            $staleMatchIds[] = $row['match_id'];
            continue;
        }

        $score = computeCompatibility($myRole, $myStr, $myWeak, $theirRole, $theirStr, $theirWeak);
        if ($score === 0) {
            $staleMatchIds[] = $row['match_id'];
        }
    }

    if (!empty($staleMatchIds)) {
        $placeholders = implode(',', array_fill(0, count($staleMatchIds), '?'));
        $pdo->prepare("DELETE FROM matches WHERE id IN ($placeholders)")
            ->execute($staleMatchIds);
    }

    $stmt = $pdo->prepare('
        SELECT m.id as match_id, p.role as their_role,
               p.strengths as their_str, p.weaknesses as their_weak,
               p.subjects as their_subj
        FROM matches m
        JOIN profiles p ON p.user_id = m.user_id
        WHERE m.matched_id = ?
    ');
    $stmt->execute([$userId]);
    $inboundMatches = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $staleInboundIds = [];
    foreach ($inboundMatches as $row) {
        $theirStr  = safeJsonArray($row['their_str']  ?? null);
        $theirWeak = safeJsonArray($row['their_weak'] ?? null);
        $theirSubj = safeJsonArray($row['their_subj'] ?? null);
        $theirRole = $row['their_role'] ?? 'student';

        if (!hasAttributes($theirStr, $theirWeak, []) || !hasAttributes($myStr, $myWeak, $theirSubj)) {
            $staleInboundIds[] = $row['match_id'];
            continue;
        }

        $score = computeCompatibility($theirRole, $theirStr, $theirWeak, $myRole, $myStr, $myWeak);
        if ($score === 0) {
            $staleInboundIds[] = $row['match_id'];
        }
    }

    if (!empty($staleInboundIds)) {
        $placeholders = implode(',', array_fill(0, count($staleInboundIds), '?'));
        $pdo->prepare("DELETE FROM matches WHERE id IN ($placeholders)")
            ->execute($staleInboundIds);
    }
}

// ── Users / Matching ──────────────────────────────────────────────────────────

function handleGetUsers(PDO $pdo): void {
    $subject      = trim($_GET['subject']       ?? '');
    $search       = trim($_GET['search']        ?? '');
    $excludeId    = trim($_GET['exclude_id']    ?? '');
    $myStrengths  = trim($_GET['my_strengths']  ?? '');
    $myWeaknesses = trim($_GET['my_weaknesses'] ?? '');
    $myRole       = trim($_GET['my_role']       ?? '');

    $sql = '
        SELECT u.id, u.full_name, u.email,
               p.school, p.department, p.subjects, p.learning_styles,
               p.study_styles, p.profile_photo_url, p.rating, p.rating_count,
               p.strengths, p.weaknesses, p.bio, p.role
        FROM users u
        INNER JOIN profiles p ON u.id = p.user_id
        WHERE u.email_verified = 1 AND p.onboarding_complete = 1
    ';
    $params = [];

    if (!empty($excludeId)) {
        $sql .= ' AND u.id != ?';
        $params[] = $excludeId;
        $sql .= ' AND u.id NOT IN (SELECT matched_id FROM matches WHERE user_id = ?)';
        $params[] = $excludeId;
    }

    if ($myRole === 'student') {
        $sql .= " AND p.role = 'tutor'";
    } elseif ($myRole === 'tutor') {
        $sql .= " AND p.role = 'student'";
    }

    if (!empty($subject)) {
        $sql .= ' AND JSON_CONTAINS(p.subjects, ?)';
        $params[] = json_encode($subject);
    }

    if (!empty($search)) {
        $sql .= ' AND (u.full_name LIKE ? OR p.department LIKE ?)';
        $params[] = "%$search%";
        $params[] = "%$search%";
    }

    $sql .= ' ORDER BY p.rating DESC';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $myWeakArr = !empty($myWeaknesses) ? json_decode($myWeaknesses, true) : [];
    $myStrArr  = !empty($myStrengths)  ? json_decode($myStrengths,  true) : [];
    if (!is_array($myWeakArr)) $myWeakArr = [];
    if (!is_array($myStrArr))  $myStrArr  = [];

    $users = [];
    foreach ($rows as $r) {
        $theirStr  = safeJsonArray($r['strengths']);
        $theirWeak = safeJsonArray($r['weaknesses']);
        $theirSubj = safeJsonArray($r['subjects']);
        $theirRole = $r['role'] ?? 'student';

        $score = computeCompatibility(
            $myRole, $myStrArr, $myWeakArr,
            $theirRole, $theirStr, $theirWeak
        );

        $users[] = [
            'id'                 => $r['id'],
            'fullName'           => $r['full_name'],
            'email'              => $r['email'],
            'school'             => $r['school'],
            'department'         => $r['department'],
            'role'               => $theirRole,
            'subjects'           => $theirSubj,
            'learningStyles'     => safeJsonArray($r['learning_styles']),
            'studyStyles'        => safeJsonArray($r['study_styles']),
            'profilePhotoUrl'    => $r['profile_photo_url'],
            'rating'             => (float)($r['rating'] ?? 0),
            'ratingCount'        => (int)($r['rating_count'] ?? 0),
            'strengths'          => $theirStr,
            'weaknesses'         => $theirWeak,
            'bio'                => $r['bio'],
            'compatibilityScore' => $score,
        ];
    }

    usort($users, function($a, $b) {
        if ($b['compatibilityScore'] !== $a['compatibilityScore'])
            return $b['compatibilityScore'] - $a['compatibilityScore'];
        return $b['rating'] <=> $a['rating'];
    });

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
               p.rating, p.rating_count, p.role
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

// ── Rate user (with optional review text) ─────────────────────────────────────
/**
 * SQL migration required — run this once on your database:
 *
 *   ALTER TABLE ratings
 *     ADD COLUMN review TEXT NULL AFTER score,
 *     ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
 *
 * The ON DUPLICATE KEY UPDATE will update score+review if the same rater
 * rates the same person again (one rating per rater-ratee pair).
 */
function handleRateUser(PDO $pdo, array $b): void {
    $raterId = trim($b['rater_id'] ?? '');
    $ratedId = trim($b['rated_id'] ?? '');
    $score   = (int)($b['score']   ?? 0);
    $review  = trim($b['review']   ?? ''); // ✅ optional review text

    if (empty($raterId) || empty($ratedId) || $score < 1 || $score > 5)
        respond(false, 'Invalid input', null, 400);
    if ($raterId === $ratedId)
        respond(false, 'Cannot rate yourself', null, 400);

    // Only tutors can be reviewed — verify the rated user is a tutor
    $stmt = $pdo->prepare('SELECT role FROM profiles WHERE user_id = ?');
    $stmt->execute([$ratedId]);
    $profile = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$profile || $profile['role'] !== 'tutor') {
        respond(false, 'Only tutors can be rated', null, 422);
    }

    // Upsert: one rating+review per rater per tutor
    $pdo->prepare('
        INSERT INTO ratings (rater_id, rated_id, score, review)
        VALUES (?,?,?,?)
        ON DUPLICATE KEY UPDATE score = VALUES(score), review = VALUES(review)
    ')->execute([$raterId, $ratedId, $score, $review ?: null]);

    // Recalculate aggregate rating
    $stmt = $pdo->prepare('SELECT AVG(score) as avg, COUNT(*) as cnt FROM ratings WHERE rated_id = ?');
    $stmt->execute([$ratedId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    $pdo->prepare('UPDATE profiles SET rating=?, rating_count=? WHERE user_id=?')
        ->execute([round($row['avg'], 2), $row['cnt'], $ratedId]);

    respond(true, 'Rating submitted', [
        'newRating'   => round($row['avg'], 2),
        'ratingCount' => (int)$row['cnt'],
    ]);
}

// ── Get reviews for a tutor ───────────────────────────────────────────────────
/**
 * GET ?action=get_reviews&api_key=...&tutor_id=<id>&rater_id=<optional>
 *
 * Returns all reviews for the given tutor, newest first.
 * Optionally pass rater_id to include a flag showing the caller's own review.
 */
function handleGetReviews(PDO $pdo): void {
    $tutorId  = trim($_GET['tutor_id']  ?? '');
    $raterId  = trim($_GET['rater_id']  ?? ''); // optional — to flag own review
    if (empty($tutorId)) respond(false, 'tutor_id required', null, 400);

    $stmt = $pdo->prepare('
        SELECT r.rater_id, r.score, r.review, r.created_at,
               u.full_name as rater_name
        FROM ratings r
        JOIN users u ON u.id = r.rater_id
        WHERE r.rated_id = ?
        ORDER BY r.created_at DESC
    ');
    $stmt->execute([$tutorId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch the caller's own existing rating (if any)
    $myRating = null;
    $myReview = null;
    if (!empty($raterId)) {
        $own = $pdo->prepare('SELECT score, review FROM ratings WHERE rater_id = ? AND rated_id = ?');
        $own->execute([$raterId, $tutorId]);
        $ownRow = $own->fetch(PDO::FETCH_ASSOC);
        if ($ownRow) {
            $myRating = (int)$ownRow['score'];
            $myReview = $ownRow['review'];
        }
    }

    $reviews = array_map(fn($r) => [
        'raterId'    => $r['rater_id'],
        'raterName'  => $r['rater_name'],
        'score'      => (int)$r['score'],
        'review'     => $r['review'] ?? '',
        'createdAt'  => $r['created_at'],
        'isOwn'      => $r['rater_id'] === $raterId,
    ], $rows);

    respond(true, 'Reviews fetched', [
        'reviews'  => $reviews,
        'myRating' => $myRating,
        'myReview' => $myReview,
    ]);
}

// ── Match Handlers ────────────────────────────────────────────────────────────

function handleSaveMatch(PDO $pdo, array $b): void {
    $userId    = trim($b['user_id']    ?? '');
    $matchedId = trim($b['matched_id'] ?? '');

    if (empty($userId) || empty($matchedId))
        respond(false, 'user_id and matched_id required', null, 400);
    if ($userId === $matchedId)
        respond(false, 'Cannot match with yourself', null, 400);

    $stmtMe = $pdo->prepare('SELECT role, strengths, weaknesses, subjects FROM profiles WHERE user_id = ?');
    $stmtMe->execute([$userId]);
    $me = $stmtMe->fetch(PDO::FETCH_ASSOC);

    if (!$me) respond(false, 'Your profile not found', null, 404);

    $myRole  = $me['role'] ?? 'student';
    $myStr   = safeJsonArray($me['strengths']  ?? null);
    $myWeak  = safeJsonArray($me['weaknesses'] ?? null);
    $mySubj  = safeJsonArray($me['subjects']   ?? null);

    $stmtThem = $pdo->prepare('SELECT role, strengths, weaknesses, subjects FROM profiles WHERE user_id = ?');
    $stmtThem->execute([$matchedId]);
    $them = $stmtThem->fetch(PDO::FETCH_ASSOC);

    if (!$them) respond(false, 'Matched user profile not found', null, 404);

    $theirRole = $them['role'] ?? 'student';
    $theirStr  = safeJsonArray($them['strengths']  ?? null);
    $theirWeak = safeJsonArray($them['weaknesses'] ?? null);
    $theirSubj = safeJsonArray($them['subjects']   ?? null);

    if (!hasAttributes($myStr, $myWeak, $mySubj)) {
        respond(false, 'Cannot match: your profile has no attributes set. Please complete your profile first.', null, 422);
    }

    if (!hasAttributes($theirStr, $theirWeak, $theirSubj)) {
        respond(false, 'Cannot match: this user has no profile attributes set.', null, 422);
    }

    if ($myRole === $theirRole) {
        respond(false, 'Cannot match: both users have the same role (' . $myRole . '). Students match with tutors only.', null, 422);
    }

    $score = computeCompatibility($myRole, $myStr, $myWeak, $theirRole, $theirStr, $theirWeak);
    if ($score === 0) {
        respond(false, 'Cannot match: no overlapping subjects between your profile and this user. Update your weaknesses/strengths to find compatible partners.', null, 422);
    }

    $pdo->prepare('INSERT IGNORE INTO matches (user_id, matched_id) VALUES (?,?)')
        ->execute([$userId, $matchedId]);

    respond(true, 'Match saved', ['compatibilityScore' => $score]);
}

function handleGetMatches(PDO $pdo): void {
    $userId = trim($_GET['user_id'] ?? '');
    if (empty($userId)) respond(false, 'user_id required', null, 400);

    $stmtMe = $pdo->prepare('SELECT role, strengths, weaknesses FROM profiles WHERE user_id = ?');
    $stmtMe->execute([$userId]);
    $me = $stmtMe->fetch(PDO::FETCH_ASSOC);

    $myRole = $me['role'] ?? 'student';
    $myStr  = safeJsonArray($me['strengths']  ?? null);
    $myWeak = safeJsonArray($me['weaknesses'] ?? null);

    $stmt = $pdo->prepare('
        SELECT u.id, u.full_name, u.email,
               p.school, p.department, p.subjects, p.learning_styles,
               p.study_styles, p.profile_photo_url, p.rating, p.rating_count,
               p.strengths, p.weaknesses, p.bio, p.role,
               m.id as match_row_id,
               m.created_at as matched_at
        FROM matches m
        JOIN users u ON u.id = m.matched_id
        LEFT JOIN profiles p ON p.user_id = u.id
        WHERE m.user_id = ?
        ORDER BY m.created_at DESC
    ');
    $stmt->execute([$userId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $matches  = [];
    $staleIds = [];

    foreach ($rows as $r) {
        $theirStr  = safeJsonArray($r['strengths']);
        $theirWeak = safeJsonArray($r['weaknesses']);
        $theirSubj = safeJsonArray($r['subjects']);
        $theirRole = $r['role'] ?? 'student';

        if (!hasAttributes($myStr, $myWeak, []) || !hasAttributes($theirStr, $theirWeak, $theirSubj)) {
            $staleIds[] = $r['match_row_id'];
            continue;
        }

        $score = computeCompatibility($myRole, $myStr, $myWeak, $theirRole, $theirStr, $theirWeak);
        if ($score === 0) {
            $staleIds[] = $r['match_row_id'];
            continue;
        }

        $matches[] = [
            'id'                 => $r['id'],
            'fullName'           => $r['full_name'],
            'email'              => $r['email'],
            'school'             => $r['school'],
            'department'         => $r['department'],
            'role'               => $theirRole,
            'subjects'           => $theirSubj,
            'learningStyles'     => safeJsonArray($r['learning_styles']),
            'studyStyles'        => safeJsonArray($r['study_styles']),
            'profilePhotoUrl'    => $r['profile_photo_url'],
            'rating'             => (float)($r['rating'] ?? 0),
            'ratingCount'        => (int)($r['rating_count'] ?? 0),
            'strengths'          => $theirStr,
            'weaknesses'         => $theirWeak,
            'bio'                => $r['bio'],
            'matchedAt'          => $r['matched_at'],
            'compatibilityScore' => $score,
        ];
    }

    if (!empty($staleIds)) {
        $placeholders = implode(',', array_fill(0, count($staleIds), '?'));
        $pdo->prepare("DELETE FROM matches WHERE id IN ($placeholders)")
            ->execute($staleIds);
    }

    respond(true, 'Matches fetched', $matches);
}

function handleRemoveMatch(PDO $pdo, array $b): void {
    $userId    = trim($b['user_id']    ?? '');
    $matchedId = trim($b['matched_id'] ?? '');

    if (empty($userId) || empty($matchedId))
        respond(false, 'user_id and matched_id required', null, 400);

    $pdo->prepare('DELETE FROM matches WHERE user_id=? AND matched_id=?')
        ->execute([$userId, $matchedId]);

    respond(true, 'Match removed');
}

// ── Resources ─────────────────────────────────────────────────────────────────

function handleGetResources(PDO $pdo): void {
    $subject = trim($_GET['subject'] ?? '');
    $search  = trim($_GET['search']  ?? '');

    $sql    = 'SELECT r.*, u.full_name as uploader_name FROM resources r
               JOIN users u ON r.uploader_id = u.id WHERE 1=1';
    $params = [];

    if (!empty($subject) && $subject !== 'All') {
        $sql .= ' AND r.subject = ?';
        $params[] = $subject;
    }
    if (!empty($search)) {
        $sql .= ' AND (r.title LIKE ? OR r.subject LIKE ? OR r.author_name LIKE ?)';
        $params[] = "%$search%";
        $params[] = "%$search%";
        $params[] = "%$search%";
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
        'authorName'   => $r['author_name'] ?? null,
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
    $authorName  = trim($_POST['author_name'] ?? '');

    if (empty($uploaderId) || empty($title) || empty($subject))
        respond(false, 'Missing required fields', null, 400);

    $uploadDir = __DIR__ . '/uploads/';
    if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);

    $fileName = null; $filePath = null; $fileType = 'link';

    if (isset($_FILES['file']) && $_FILES['file']['error'] === UPLOAD_ERR_OK) {
        $ext = strtolower(pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION));
        if (!in_array($ext, ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt']))
            respond(false, 'File type not allowed', null, 400);

        $fileName = preg_replace('/[^a-z0-9]/i', '_', $uploaderId) . '_' . time() . '.' . $ext;
        if (!move_uploaded_file($_FILES['file']['tmp_name'], $uploadDir . $fileName))
            respond(false, 'Failed to save file', null, 500);

        $filePath = 'uploads/' . $fileName;
        $fileType = $ext;
    }

    $id = uniqid('res_', true);
    $pdo->prepare('
        INSERT INTO resources
            (id, uploader_id, title, subject, description, author_name, file_name, file_path, file_type)
        VALUES (?,?,?,?,?,?,?,?,?)
    ')->execute([$id, $uploaderId, $title, $subject, $description, $authorName, $fileName, $filePath, $fileType]);

    respond(true, 'Resource uploaded', ['id' => $id]);
}

// ── Format helpers ────────────────────────────────────────────────────────────
function formatUser(array $u): array {
    $avail = null;
    if (!empty($u['availability'])) {
        $decoded = json_decode($u['availability'], true);
        $avail   = is_array($decoded) ? $decoded : (object)[];
    } else {
        $avail = (object)[];
    }

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
        'role'               => $u['role']               ?? 'student',
        'subjects'           => safeJsonArray($u['subjects']        ?? null),
        'learningStyles'     => safeJsonArray($u['learning_styles'] ?? null),
        'studyStyles'        => safeJsonArray($u['study_styles']    ?? null),
        'availability'       => $avail,
        'strengths'          => safeJsonArray($u['strengths']  ?? null),
        'weaknesses'         => safeJsonArray($u['weaknesses'] ?? null),
        'onboardingComplete' => (bool)($u['onboarding_complete'] ?? false),
        'rating'             => (float)($u['rating']      ?? 0),
        'ratingCount'        => (int)($u['rating_count']  ?? 0),
    ];
}

function buildOtpEmail(string $name, string $otp): string {
    $digits = implode('', array_map(
        fn($d) => "<span style='display:inline-block;width:44px;height:52px;line-height:52px;margin:0 3px;background:#1e1a3a;border:2px solid #6C63FF;border-radius:8px;font-size:24px;font-weight:700;color:#fff;text-align:center;'>$d</span>",
        str_split($otp)
    ));
    return <<<HTML
<body style="background:#0d0b1e;font-family:'Segoe UI',sans-serif;padding:40px 16px;">
  <div style="max-width:480px;margin:0 auto;background:linear-gradient(145deg,#120e2a,#1a1535);border-radius:20px;border:1px solid #2e2850;overflow:hidden;">
    <div style="background:linear-gradient(135deg,#6C63FF,#a78bfa);padding:28px;text-align:center;">
      <h1 style="color:#fff;margin:0;font-size:22px;">🎓 StudyMatch</h1>
      <p style="color:rgba(255,255,255,0.8);margin:4px 0 0;font-size:13px;">Email Verification</p>
    </div>
    <div style="padding:32px;text-align:center;">
      <p style="color:#c4b8ff;">Hi <strong style="color:#fff;">$name</strong>,</p>
      <p style="color:#8b7fc7;font-size:14px;margin-bottom:28px;">Your verification code expires in <strong style="color:#a78bfa;">10 minutes</strong>.</p>
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
  <div style="max-width:480px;margin:0 auto;background:linear-gradient(145deg,#120e2a,#1a1535);border-radius:20px;border:1px solid #2e2850;overflow:hidden;">
    <div style="background:linear-gradient(135deg,#6C63FF,#a78bfa);padding:28px;text-align:center;">
      <h1 style="color:#fff;margin:0;font-size:22px;">🎓 StudyMatch</h1>
      <p style="color:rgba(255,255,255,0.8);margin:4px 0 0;font-size:13px;">Password Reset</p>
    </div>
    <div style="padding:32px;text-align:center;">
      <p style="color:#c4b8ff;">Hi <strong style="color:#fff;">$name</strong>,</p>
      <p style="color:#8b7fc7;font-size:14px;margin-bottom:24px;">Click below to reset your password. Expires in <strong style="color:#a78bfa;">1 hour</strong>.</p>
      <a href="$link" style="display:inline-block;padding:14px 32px;background:linear-gradient(135deg,#6C63FF,#a78bfa);color:#fff;text-decoration:none;border-radius:12px;font-weight:700;font-size:15px;">Reset Password</a>
      <p style="color:#6b6490;font-size:12px;margin-top:24px;">Didn't request this? Ignore this email.</p>
    </div>
    <div style="border-top:1px solid #2e2850;padding:16px;text-align:center;">
      <p style="color:#3d3660;font-size:11px;margin:0;">© 2026 StudyMatch</p>
    </div>
  </div>
</body>
HTML;
}