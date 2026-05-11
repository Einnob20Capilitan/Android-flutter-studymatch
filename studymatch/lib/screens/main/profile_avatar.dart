import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Drop-in replacement for any profile photo circle in the app.
///
/// Handles Flutter Web image loading by using WebHtmlElementStrategy.allow,
/// which renders a native <img> tag in the browser. This bypasses CORS XHR
/// restrictions entirely — no statusCode: 0, no preflight failures.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color gradientStart;
  final Color gradientEnd;

  // ── Change this to match your XAMPP path ─────────────────────────────────
  static const _apiBase = 'http://localhost/StudyMatch/studymatch-api';
  // ─────────────────────────────────────────────────────────────────────────

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.size        = 88,
    this.borderColor,
    this.borderWidth = 0,
    this.gradientStart = const Color(0xFF6C63FF),
    this.gradientEnd   = const Color(0xFFa78bfa),
  });

  String? get _safeUrl {
    if (photoUrl == null || photoUrl!.isEmpty) return null;

    String url = photoUrl!;

    // ── Step 1: Normalise whatever the DB stored ──────────────────────────
    // The DB may contain any of these three formats:
    //   A) Bare filename:   "profile_123_456.png"
    //   B) Relative path:   "uploads/profiles/profile_123_456.png"
    //   C) Full URL:        "http://192.168.1.5/.../serve_photo.php?file=..."
    //
    // All three are normalised to a localhost serve_photo.php URL.

    if (!url.startsWith('http')) {
      // Format A or B — extract the filename and build a serve URL.
      final fileName = url.split('/').last;
      url = '$_apiBase/serve_photo.php?file=$fileName';
    } else if (kIsWeb) {
      // Format C on web — rewrite the host to localhost so the browser
      // doesn't treat a LAN IP as a different (blocked) origin.
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final file = uri.queryParameters['file'] ?? uri.pathSegments.last;
        url = '$_apiBase/serve_photo.php?file=$file';
      }
    }

    // ── Step 2: Cache-buster on web ───────────────────────────────────────
    // Forces a fresh request, avoiding a previously CORS-blocked response
    // being served from the browser's disk cache.
    if (kIsWeb) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        url = uri.replace(queryParameters: {
          ...uri.queryParameters,
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        }).toString();
      }
    }

    return url;
  }

  String get _initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

  @override
  Widget build(BuildContext context) {
    final url      = _safeUrl;
    final hasPhoto = url != null;

    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        gradient: hasPhoto
            ? null
            : LinearGradient(colors: [gradientStart, gradientEnd]),
        shape:  BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: hasPhoto ? _buildImage(url!) : _initials(),
      ),
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      width:  size,
      height: size,
      fit:    BoxFit.cover,

      // ── THE KEY FIX ───────────────────────────────────────────────────────
      // WebHtmlElementStrategy.allow renders a native browser <img> tag.
      // Native <img> tags are NOT subject to CORS XHR restrictions, so the
      // image loads without needing preflight or Access-Control headers.
      //
      // The default (WebHtmlElementStrategy.never) forces XHR/fetch, which
      // the browser's CORS policy blocks → statusCode: 0.
      // ─────────────────────────────────────────────────────────────────────
      webHtmlElementStrategy: WebHtmlElementStrategy.allow,

      // Do NOT pass custom headers on web — any custom header triggers a
      // CORS preflight (OPTIONS) request. With the <img> strategy there
      // are no headers to send anyway.
      headers: const {},

      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: gradientStart.withOpacity(0.2),
          child: Center(
            child: SizedBox(
              width:  size * 0.3,
              height: size * 0.3,
              child:  CircularProgressIndicator(
                strokeWidth: 2,
                color:       gradientStart,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _initials(),
    );
  }

  Widget _initials() => Center(
        child: Text(
          _initial,
          style: TextStyle(
            color:      Colors.white,
            fontWeight: FontWeight.bold,
            fontSize:   size * 0.42,
            fontFamily: 'Poppins',
          ),
        ),
      );
}