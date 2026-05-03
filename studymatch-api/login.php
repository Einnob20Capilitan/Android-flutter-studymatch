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

$body     = json_decode(file_get_contents('php://input'), true);
$email    = strtolower(trim($body['email']    ?? ''));
$password = $body['password'] ?? '';

if (empty($email) || empty($password)) {
    echo json_encode(['success' => false, 'message' => 'Email and password are required']); exit;
}

try {
    $pdo = getDB();

    // JOIN users with profiles
    $stmt = $pdo->prepare('
        SELECT u.*, p.school, p.department, p.topic, p.year_level,
               p.date_of_birth, p.gender, p.subjects, p.learning_styles,
               p.study_styles, p.availability, p.strengths, p.weaknesses,
               p.profile_photo_url, p.onboarding_complete
        FROM users u
        LEFT JOIN profiles p ON u.id = p.user_id
        WHERE u.email = ?
    ');
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode(['success' => false, 'message' => 'Invalid email or password']); exit;
    }
    if (!password_verify($password, $user['password'])) {
        echo json_encode(['success' => false, 'message' => 'Invalid email or password']); exit;
    }
    if (!$user['email_verified']) {
        echo json_encode(['success' => false, 'message' => 'Please verify your email first']); exit;
    }

    echo json_encode([
        'success' => true,
        'user' => [
            'id'                 => $user['id'],
            'fullName'           => $user['full_name'],
            'email'              => $user['email'],
            'profilePhotoUrl'    => $user['profile_photo_url'],
            'school'             => $user['school'],
            'department'         => $user['department'],
            'topic'              => $user['topic'],
            'yearLevel'          => $user['year_level'],
            'dateOfBirth'        => $user['date_of_birth'],
            'gender'             => $user['gender'],
            'subjects'           => json_decode($user['subjects']        ?? '[]'),
            'learningStyles'     => json_decode($user['learning_styles'] ?? '[]'),
            'studyStyles'        => json_decode($user['study_styles']    ?? '[]'),
            'availability'       => json_decode($user['availability']    ?? '{}', true),
            'strengths'          => json_decode($user['strengths']       ?? '[]'),
            'weaknesses'         => json_decode($user['weaknesses']      ?? '[]'),
            'onboardingComplete' => (bool)($user['onboarding_complete']  ?? false),
        ]
    ]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}