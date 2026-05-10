<?php
require_once __DIR__ . '/db.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']); exit;
}

$uploaderId  = $_POST['uploader_id']  ?? '';
$title       = trim($_POST['title']   ?? '');
$subject     = trim($_POST['subject'] ?? '');
$description = trim($_POST['description'] ?? '');
$authorName  = trim($_POST['author_name']  ?? '');

// ── Validation ─────────────────────────────────────────────────────────────
if (empty($uploaderId)) {
    echo json_encode(['success' => false, 'message' => 'Missing uploader ID']); exit;
}
if (empty($title)) {
    echo json_encode(['success' => false, 'message' => 'Title is required']); exit;
}
if (empty($subject)) {
    echo json_encode(['success' => false, 'message' => 'Subject is required']); exit;
}
if (empty($authorName)) {
    echo json_encode(['success' => false, 'message' => 'Author / Source is required']); exit;
}

// ── File handling ──────────────────────────────────────────────────────────
$uploadDir = __DIR__ . '/uploads/';
if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);

$fileName = null;
$filePath = null;
$fileType = 'link';

if (isset($_FILES['file']) && $_FILES['file']['error'] === UPLOAD_ERR_OK) {
    $origName = basename($_FILES['file']['name']);
    $ext      = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
    $allowed  = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'];

    if (!in_array($ext, $allowed)) {
        echo json_encode([
            'success' => false,
            'message' => 'File type not allowed. Use PDF, DOC, DOCX, PPT, PPTX, or TXT.'
        ]); exit;
    }

    $safeId   = preg_replace('/[^a-z0-9]/i', '_', $uploaderId);
    $fileName = $safeId . '_' . time() . '.' . $ext;
    $destPath = $uploadDir . $fileName;

    if (!move_uploaded_file($_FILES['file']['tmp_name'], $destPath)) {
        echo json_encode(['success' => false, 'message' => 'Failed to save file']); exit;
    }

    $filePath = 'uploads/' . $fileName;
    $fileType = $ext;
} else {
    // No file uploaded
    echo json_encode(['success' => false, 'message' => 'No file uploaded']); exit;
}

// ── Insert into DB ─────────────────────────────────────────────────────────
try {
    $pdo  = getDB();
    $id   = uniqid('res_', true);

    $stmt = $pdo->prepare('
        INSERT INTO resources
            (id, uploader_id, title, subject, description, author_name, file_name, file_path, file_type)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([
        $id,
        $uploaderId,
        $title,
        $subject,
        $description,
        $authorName,
        $fileName,
        $filePath,
        $fileType,
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Resource uploaded successfully',
        'id'      => $id,
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
    ]);
}