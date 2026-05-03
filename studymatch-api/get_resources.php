<?php
require_once __DIR__ . '/db.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

$subject = trim($_GET['subject'] ?? '');
$search  = trim($_GET['search']  ?? '');

try {
    $pdo    = getDB();
    $sql    = 'SELECT r.*, u.full_name as uploader_name FROM resources r
               JOIN users u ON r.uploader_id = u.id WHERE 1=1';
    $params = [];

    if (!empty($subject) && $subject !== 'All') {
        $sql     .= ' AND r.subject = ?';
        $params[] = $subject;
    }
    if (!empty($search)) {
        $sql     .= ' AND (r.title LIKE ? OR r.subject LIKE ?)';
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
        'uploaderName' => $r['uploader_name'],
        'fileName'     => $r['file_name'],
        'fileUrl'      => $r['file_path']
            ? 'http://localhost/StudyMatch/studymatch-api/' . $r['file_path']
            : null,
        'fileType'     => $r['file_type'],
        'uploadedAt'   => $r['uploaded_at'],
    ], $rows);

    echo json_encode(['success' => true, 'resources' => $resources]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}