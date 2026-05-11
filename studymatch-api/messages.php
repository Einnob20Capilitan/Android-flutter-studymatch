<?php
require_once __DIR__ . '/db.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, X-API-Key');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

define('MSG_API_KEY', 'studymatch_api_key_2026');

// ── File upload config ────────────────────────────────────────────────────────
define('UPLOAD_DIR',      __DIR__ . '/uploads/messages/');
define('UPLOAD_URL_BASE', 'http://localhost/StudyMatch/studymatch-api/uploads/messages/');
define('MAX_FILE_SIZE',   10 * 1024 * 1024); // 10 MB
define('ALLOWED_MIME', [
    // images
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    // docs
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    // text / misc
    'text/plain',
    'application/zip',
]);

// ── Router ────────────────────────────────────────────────────────────────────
$action = trim($_GET['action'] ?? '');
$apiKey = trim($_GET['api_key'] ?? $_POST['api_key'] ?? '');
$body   = json_decode(file_get_contents('php://input'), true) ?? [];

if ($apiKey !== MSG_API_KEY) {
    respond(false, 'Invalid API key', null, 401);
}

try {
    $pdo = getDB();
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, true);
    $pdo->exec("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("SET character_set_connection = utf8mb4");
    $pdo->exec("SET collation_connection = utf8mb4_unicode_ci");

    switch ($action) {
        case 'send':         handleSend($pdo, $body);       break;
        case 'send_file':    handleSendFile($pdo);           break;  // ✅ NEW
        case 'get_messages': handleGetMessages($pdo);       break;
        case 'get_inbox':    handleGetInbox($pdo);          break;
        case 'mark_read':    handleMarkRead($pdo, $body);   break;
        case 'get_unread':   handleGetUnread($pdo);         break;
        default:
            respond(false, 'Unknown action', null, 404);
    }
} catch (PDOException $e) {
    error_log('Messages DB error: ' . $e->getMessage());
    respond(false, 'Database error: ' . $e->getMessage(), null, 500);
} catch (Exception $e) {
    error_log('Messages error: ' . $e->getMessage());
    respond(false, 'Server error: ' . $e->getMessage(), null, 500);
}

function respond(bool $success, string $message, $data = null, int $code = 200): void {
    http_response_code($code);
    $out = ['success' => $success, 'message' => $message];
    if ($data !== null) $out['data'] = $data;
    echo json_encode($out, JSON_UNESCAPED_UNICODE);
    exit();
}

// ── Send text message ─────────────────────────────────────────────────────────
function handleSend(PDO $pdo, array $b): void {
    $senderId   = trim($b['sender_id']   ?? '');
    $receiverId = trim($b['receiver_id'] ?? '');
    $content    = trim($b['content']     ?? '');

    if (empty($senderId) || empty($receiverId) || empty($content))
        respond(false, 'sender_id, receiver_id and content are required', null, 400);
    if ($senderId === $receiverId)
        respond(false, 'Cannot message yourself', null, 400);
    if (mb_strlen($content) > 2000)
        respond(false, 'Message too long', null, 400);

    $id = uniqid('msg_', true);
    $pdo->prepare('
        INSERT INTO messages (id, sender_id, receiver_id, content, message_type, file_url, file_name, file_size)
        VALUES (?, ?, ?, ?, \'text\', NULL, NULL, NULL)
    ')->execute([$id, $senderId, $receiverId, $content]);

    respond(true, 'Message sent', [
        'id'          => $id,
        'senderId'    => $senderId,
        'receiverId'  => $receiverId,
        'content'     => $content,
        'messageType' => 'text',
        'fileUrl'     => null,
        'fileName'    => null,
        'fileSize'    => null,
        'isRead'      => false,
        'createdAt'   => date('Y-m-d H:i:s'),
        'senderName'  => '',
    ]);
}

// ── Send file / image message ─────────────────────────────────────────────────
function handleSendFile(PDO $pdo): void {
    $senderId   = trim($_POST['sender_id']   ?? '');
    $receiverId = trim($_POST['receiver_id'] ?? '');

    if (empty($senderId) || empty($receiverId))
        respond(false, 'sender_id and receiver_id are required', null, 400);
    if ($senderId === $receiverId)
        respond(false, 'Cannot message yourself', null, 400);
    if (!isset($_FILES['file']))
        respond(false, 'No file uploaded', null, 400);

    $file     = $_FILES['file'];
    $tmpPath  = $file['tmp_name'];
    $origName = basename($file['name']);
    $fileSize = $file['size'];
    $mimeType = mime_content_type($tmpPath);

    // Validate
    if ($file['error'] !== UPLOAD_ERR_OK)
        respond(false, 'Upload error code: ' . $file['error'], null, 400);
    if ($fileSize > MAX_FILE_SIZE)
        respond(false, 'File too large. Max 10 MB.', null, 400);
    if (!in_array($mimeType, ALLOWED_MIME, true))
        respond(false, 'File type not allowed: ' . $mimeType, null, 400);

    // Create upload dir if needed
    if (!is_dir(UPLOAD_DIR)) {
        mkdir(UPLOAD_DIR, 0755, true);
    }

    // Build a safe unique filename
    $ext      = pathinfo($origName, PATHINFO_EXTENSION);
    $safeExt  = preg_replace('/[^a-zA-Z0-9]/', '', $ext);
    $fileName = uniqid('file_', true) . ($safeExt ? '.' . $safeExt : '');
    $destPath = UPLOAD_DIR . $fileName;

    if (!move_uploaded_file($tmpPath, $destPath))
        respond(false, 'Failed to save file', null, 500);

    $fileUrl     = UPLOAD_URL_BASE . $fileName;
    $messageType = str_starts_with($mimeType, 'image/') ? 'image' : 'file';
    $content     = $messageType === 'image' ? '📷 Image' : '📎 ' . $origName;

    $id = uniqid('msg_', true);
    $pdo->prepare('
        INSERT INTO messages (id, sender_id, receiver_id, content, message_type, file_url, file_name, file_size)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ')->execute([$id, $senderId, $receiverId, $content, $messageType, $fileUrl, $origName, $fileSize]);

    respond(true, 'File sent', [
        'id'          => $id,
        'senderId'    => $senderId,
        'receiverId'  => $receiverId,
        'content'     => $content,
        'messageType' => $messageType,
        'fileUrl'     => $fileUrl,
        'fileName'    => $origName,
        'fileSize'    => $fileSize,
        'isRead'      => false,
        'createdAt'   => date('Y-m-d H:i:s'),
        'senderName'  => '',
    ]);
}

// ── Get messages between two users ────────────────────────────────────────────
function handleGetMessages(PDO $pdo): void {
    $userId  = trim($_GET['user_id']  ?? '');
    $otherId = trim($_GET['other_id'] ?? '');
    $limit   = min((int)($_GET['limit']  ?? 100), 200);
    $offset  = max((int)($_GET['offset'] ?? 0), 0);

    if (empty($userId) || empty($otherId))
        respond(false, 'user_id and other_id are required', null, 400);

    $sql = "
        SELECT
            m.id,
            m.sender_id,
            m.receiver_id,
            m.content,
            m.message_type,
            m.file_url,
            m.file_name,
            m.file_size,
            m.is_read,
            m.created_at,
            u.full_name
        FROM messages m
        JOIN users u ON m.sender_id COLLATE utf8mb4_unicode_ci = u.id COLLATE utf8mb4_unicode_ci
        WHERE (m.sender_id = ? AND m.receiver_id = ?)
           OR (m.sender_id = ? AND m.receiver_id = ?)
        ORDER BY m.created_at ASC
        LIMIT $limit OFFSET $offset
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId, $otherId, $otherId, $userId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Mark messages from other user as read
    $pdo->prepare('
        UPDATE messages
        SET is_read = 1
        WHERE sender_id = ? AND receiver_id = ? AND is_read = 0
    ')->execute([$otherId, $userId]);

    $messages = array_map(fn($r) => [
        'id'          => $r['id'],
        'senderId'    => $r['sender_id'],
        'receiverId'  => $r['receiver_id'],
        'content'     => $r['content'],
        'messageType' => $r['message_type'] ?? 'text',
        'fileUrl'     => $r['file_url'],
        'fileName'    => $r['file_name'],
        'fileSize'    => $r['file_size'] !== null ? (int)$r['file_size'] : null,
        'isRead'      => (bool)(int)$r['is_read'],
        'createdAt'   => $r['created_at'],
        'senderName'  => $r['full_name'],
    ], $rows);

    respond(true, 'Messages fetched', $messages);
}

// ── Get inbox ─────────────────────────────────────────────────────────────────
function handleGetInbox(PDO $pdo): void {
    $userId = trim($_GET['user_id'] ?? '');
    if (empty($userId))
        respond(false, 'user_id is required', null, 400);

    $stmt = $pdo->prepare('
        SELECT DISTINCT
            CASE
                WHEN sender_id = ? THEN receiver_id
                ELSE sender_id
            END AS other_id
        FROM messages
        WHERE sender_id = ? OR receiver_id = ?
    ');
    $stmt->execute([$userId, $userId, $userId]);
    $partners = $stmt->fetchAll(PDO::FETCH_COLUMN);

    if (empty($partners)) {
        respond(true, 'Inbox fetched', []);
    }

    $conversations = [];

    foreach ($partners as $otherId) {
        $stmt = $pdo->prepare('
            SELECT
                m.id, m.sender_id, m.receiver_id,
                m.content, m.message_type, m.file_url, m.file_name, m.file_size,
                m.is_read, m.created_at
            FROM messages m
            WHERE (m.sender_id = ? AND m.receiver_id = ?)
               OR (m.sender_id = ? AND m.receiver_id = ?)
            ORDER BY m.created_at DESC
            LIMIT 1
        ');
        $stmt->execute([$userId, $otherId, $otherId, $userId]);
        $lastMsg = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$lastMsg) continue;

        $stmt = $pdo->prepare('
            SELECT COUNT(*) FROM messages
            WHERE sender_id = ? AND receiver_id = ? AND is_read = 0
        ');
        $stmt->execute([$otherId, $userId]);
        $unread = (int)$stmt->fetchColumn();

        $stmt = $pdo->prepare('
            SELECT
                u.id, u.full_name, u.email,
                p.role, p.department, p.school, p.bio,
                p.rating, p.rating_count,
                p.subjects, p.strengths, p.weaknesses,
                p.learning_styles, p.study_styles
            FROM users u
            LEFT JOIN profiles p ON p.user_id COLLATE utf8mb4_unicode_ci = u.id COLLATE utf8mb4_unicode_ci
            WHERE u.id = ?
        ');
        $stmt->execute([$otherId]);
        $other = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$other) continue;

        // Compose preview label for file messages
        $lastContent = $lastMsg['content'];
        $lastMsgType = $lastMsg['message_type'] ?? 'text';

        $conversations[] = [
            'participantId'             => $other['id'],
            'participantName'           => $other['full_name'],
            'participantEmail'          => $other['email'],
            'participantRole'           => $other['role'] ?? 'student',
            'participantDept'           => $other['department'],
            'participantSchool'         => $other['school'],
            'participantBio'            => $other['bio'],
            'participantRating'         => (float)($other['rating']       ?? 0),
            'participantRatingCount'    => (int)($other['rating_count']   ?? 0),
            'participantSubjects'       => json_decode($other['subjects']        ?? '[]') ?: [],
            'participantStrengths'      => json_decode($other['strengths']       ?? '[]') ?: [],
            'participantWeaknesses'     => json_decode($other['weaknesses']      ?? '[]') ?: [],
            'participantLearningStyles' => json_decode($other['learning_styles'] ?? '[]') ?: [],
            'participantStudyStyles'    => json_decode($other['study_styles']    ?? '[]') ?: [],
            'lastMessage'               => $lastContent,
            'lastMessageType'           => $lastMsgType,
            'lastMessageSenderId'       => $lastMsg['sender_id'],
            'lastMessageTime'           => $lastMsg['created_at'],
            'unreadCount'               => $unread,
        ];
    }

    usort($conversations, fn($a, $b) =>
        strcmp($b['lastMessageTime'], $a['lastMessageTime']));

    respond(true, 'Inbox fetched', $conversations);
}

// ── Mark read ─────────────────────────────────────────────────────────────────
function handleMarkRead(PDO $pdo, array $b): void {
    $userId  = trim($b['user_id']  ?? '');
    $otherId = trim($b['other_id'] ?? '');

    if (empty($userId) || empty($otherId))
        respond(false, 'user_id and other_id are required', null, 400);

    $pdo->prepare('
        UPDATE messages SET is_read = 1
        WHERE sender_id = ? AND receiver_id = ? AND is_read = 0
    ')->execute([$otherId, $userId]);

    respond(true, 'Marked as read');
}

// ── Get unread count ──────────────────────────────────────────────────────────
function handleGetUnread(PDO $pdo): void {
    $userId = trim($_GET['user_id'] ?? '');
    if (empty($userId))
        respond(false, 'user_id is required', null, 400);

    $stmt = $pdo->prepare('
        SELECT COUNT(*) as total FROM messages
        WHERE receiver_id = ? AND is_read = 0
    ');
    $stmt->execute([$userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    respond(true, 'Unread count', ['count' => (int)($row['total'] ?? 0)]);
}