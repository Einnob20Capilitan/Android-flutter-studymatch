<?php
// ── serve_photo.php ───────────────────────────────────────────────────────
// Place at: studymatch-api/serve_photo.php
// Usage:    serve_photo.php?file=profile_123_456.jpg

// ── CORS headers — must come first ───────────────────────────────────────
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Origin, Accept');
header('Vary: Origin');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ── Validate the requested filename ──────────────────────────────────────
$file = basename($_GET['file'] ?? '');

if (empty($file) || !preg_match('/^[a-zA-Z0-9_\-]+\.(jpg|jpeg|png|gif|webp)$/i', $file)) {
    http_response_code(400);
    header('Content-Type: text/plain');
    echo 'Invalid file name';
    exit;
}

// ── Resolve path relative to THIS file ───────────────────────────────────
// serve_photo.php lives at: studymatch-api/serve_photo.php
// uploads live at:          studymatch-api/uploads/profiles/
$path = __DIR__ . '/uploads/profiles/' . $file;

// ── Debug helper (remove after confirming it works) ───────────────────────
// Uncomment these two lines if you still get "File not found":
// error_log('[serve_photo] __DIR__ = ' . __DIR__);
// error_log('[serve_photo] full path = ' . $path);

if (!is_file($path)) {
    http_response_code(404);
    header('Content-Type: text/plain');
    echo 'File not found';
    exit;
}

// ── Verify MIME type ──────────────────────────────────────────────────────
$mime    = mime_content_type($path);
$allowed = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

if (!in_array($mime, $allowed, true)) {
    http_response_code(403);
    header('Content-Type: text/plain');
    echo 'Forbidden file type';
    exit;
}

// ── Serve the file ────────────────────────────────────────────────────────
header('Cache-Control: public, max-age=86400');
header('Content-Type: ' . $mime);
header('Content-Length: ' . filesize($path));

readfile($path);
exit;