<?php
require_once __DIR__ . '/db.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

$subject      = trim($_GET['subject']      ?? '');
$search       = trim($_GET['search']       ?? '');
$exclude_id   = trim($_GET['exclude_id']   ?? '');
$my_strengths = trim($_GET['my_strengths'] ?? '');
$my_weaknesses= trim($_GET['my_weaknesses']?? '');

try {
    $pdo = getDB();

    $sql = '
        SELECT u.id, u.full_name, u.email,
               p.school, p.department, p.subjects, p.learning_styles,
               p.study_styles, p.profile_photo_url, p.rating, p.rating_count,
               p.strengths, p.weaknesses, p.bio
        FROM users u
        INNER JOIN profiles p ON u.id = p.user_id
        WHERE u.email_verified = 1
          AND p.onboarding_complete = 1
    ';

    $params = [];

    if (!empty($exclude_id)) {
        $sql     .= ' AND u.id != ?';
        $params[] = $exclude_id;
    }
    if (!empty($subject)) {
        $sql     .= ' AND JSON_CONTAINS(p.subjects, ?)';
        $params[] = json_encode($subject);
    }
    if (!empty($search)) {
        $sql     .= ' AND (u.full_name LIKE ? OR p.department LIKE ?)';
        $params[] = "%$search%";
        $params[] = "%$search%";
    }

    $sql .= ' ORDER BY p.rating DESC';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Compute compatibility score if current user's data provided
    $myWeakArr = !empty($my_weaknesses) ? json_decode($my_weaknesses, true) : [];
    $myStrArr  = !empty($my_strengths)  ? json_decode($my_strengths, true)  : [];

    $users = [];
    foreach ($rows as $r) {
        $theirStr  = json_decode($r['strengths']  ?? '[]', true) ?: [];
        $theirWeak = json_decode($r['weaknesses'] ?? '[]', true) ?: [];

        // Compatibility: their strengths match my weaknesses + my strengths match their weaknesses
        $score = 0;
        if (!empty($myWeakArr) && !empty($theirStr)) {
            $score += count(array_intersect($myWeakArr, $theirStr));
        }
        if (!empty($myStrArr) && !empty($theirWeak)) {
            $score += count(array_intersect($myStrArr, $theirWeak));
        }

        $users[] = [
            'id'              => $r['id'],
            'fullName'        => $r['full_name'],
            'email'           => $r['email'],
            'school'          => $r['school'],
            'department'      => $r['department'],
            'subjects'        => json_decode($r['subjects']        ?? '[]'),
            'learningStyles'  => json_decode($r['learning_styles'] ?? '[]'),
            'studyStyles'     => json_decode($r['study_styles']    ?? '[]'),
            'profilePhotoUrl' => $r['profile_photo_url'],
            'rating'          => (float) $r['rating'],
            'ratingCount'     => (int)   $r['rating_count'],
            'strengths'       => $theirStr,
            'weaknesses'      => $theirWeak,
            'bio'             => $r['bio'],
            'compatibilityScore' => $score,
        ];
    }

    // Sort by compatibility score descending
    usort($users, fn($a, $b) => $b['compatibilityScore'] - $a['compatibilityScore']);

    echo json_encode(['success' => true, 'users' => $users]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}