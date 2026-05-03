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

$body = json_decode(file_get_contents('php://input'), true);
$id   = trim($body['id'] ?? '');

if (empty($id)) {
    echo json_encode(['success' => false, 'message' => 'User ID is required']); exit;
}

try {
    $pdo = getDB();

    $stmt = $pdo->prepare('SELECT user_id FROM profiles WHERE user_id = ?');
    $stmt->execute([$id]);
    $exists = $stmt->fetch();

    if ($exists) {
        $stmt = $pdo->prepare('
            UPDATE profiles SET
                school              = ?,
                department          = ?,
                topic               = ?,
                year_level          = ?,
                date_of_birth       = ?,
                gender              = ?,
                subjects            = ?,
                learning_styles     = ?,
                study_styles        = ?,
                availability        = ?,
                strengths           = ?,
                weaknesses          = ?,
                profile_photo_url   = ?,
                bio                 = ?,
                onboarding_complete = ?
            WHERE user_id = ?
        ');
        $stmt->execute([
            $body['school']             ?? null,
            $body['department']         ?? null,
            $body['topic']              ?? null,
            $body['yearLevel']          ?? null,
            $body['dateOfBirth']        ?? null,
            $body['gender']             ?? null,
            json_encode($body['subjects']       ?? []),
            json_encode($body['learningStyles'] ?? []),
            json_encode($body['studyStyles']    ?? []),
            json_encode($body['availability']   ?? []),
            json_encode($body['strengths']      ?? []),
            json_encode($body['weaknesses']     ?? []),
            $body['profilePhotoUrl']    ?? null,
            $body['bio']                ?? null,
            ($body['onboardingComplete'] ?? false) ? 1 : 0,
            $id,
        ]);
    } else {
        $stmt = $pdo->prepare('
            INSERT INTO profiles (
                user_id, school, department, topic, year_level,
                date_of_birth, gender, subjects, learning_styles,
                study_styles, availability, strengths, weaknesses,
                profile_photo_url, bio, onboarding_complete
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ');
        $stmt->execute([
            $id,
            $body['school']             ?? null,
            $body['department']         ?? null,
            $body['topic']              ?? null,
            $body['yearLevel']          ?? null,
            $body['dateOfBirth']        ?? null,
            $body['gender']             ?? null,
            json_encode($body['subjects']       ?? []),
            json_encode($body['learningStyles'] ?? []),
            json_encode($body['studyStyles']    ?? []),
            json_encode($body['availability']   ?? []),
            json_encode($body['strengths']      ?? []),
            json_encode($body['weaknesses']     ?? []),
            $body['profilePhotoUrl']    ?? null,
            $body['bio']                ?? null,
            ($body['onboardingComplete'] ?? false) ? 1 : 0,
        ]);
    }

    if (!empty($body['fullName'])) {
        $pdo->prepare('UPDATE users SET full_name = ? WHERE id = ?')
            ->execute([$body['fullName'], $id]);
    }

    echo json_encode(['success' => true, 'message' => 'Profile updated successfully']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}