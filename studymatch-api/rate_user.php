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
$raterId  = trim($body['rater_id']  ?? '');
$ratedId  = trim($body['rated_id']  ?? '');
$score    = (int)($body['score']    ?? 0);

if (empty($raterId) || empty($ratedId) || $score < 1 || $score > 5) {
    echo json_encode(['success' => false, 'message' => 'Invalid input']); exit;
}
if ($raterId === $ratedId) {
    echo json_encode(['success' => false, 'message' => 'Cannot rate yourself']); exit;
}

try {
    $pdo = getDB();

    // Upsert rating
    $stmt = $pdo->prepare('
        INSERT INTO ratings (rater_id, rated_id, score)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE score = VALUES(score)
    ');
    $stmt->execute([$raterId, $ratedId, $score]);

    // Recalculate average rating
    $stmt = $pdo->prepare('
        SELECT AVG(score) as avg_score, COUNT(*) as cnt
        FROM ratings WHERE rated_id = ?
    ');
    $stmt->execute([$ratedId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    $pdo->prepare('
        UPDATE profiles SET rating = ?, rating_count = ? WHERE user_id = ?
    ')->execute([round($row['avg_score'], 2), $row['cnt'], $ratedId]);

    echo json_encode([
        'success'     => true,
        'newRating'   => round($row['avg_score'], 2),
        'ratingCount' => (int) $row['cnt'],
    ]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}