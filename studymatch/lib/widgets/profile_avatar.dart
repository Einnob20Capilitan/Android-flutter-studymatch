import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Drop-in replacement for any profile photo circle in the app.
/// Handles Flutter Web CORS correctly by appending a cache-buster to the URL,
/// which forces the browser to treat it as a fresh request that goes through
/// the CORS-enabled PHP response headers.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color gradientStart;
  final Color gradientEnd;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.size = 88,
    this.borderColor,
    this.borderWidth = 0,
    this.gradientStart = const Color(0xFF6C63FF),
    this.gradientEnd   = const Color(0xFFa78bfa),
  });

  String? get _safeUrl {
    if (photoUrl == null || photoUrl!.isEmpty) return null;
    // On Flutter Web, append a cache-buster so the browser always sends
    // a fresh request — this bypasses cached CORS-blocked responses.
    if (kIsWeb) {
      final uri = Uri.tryParse(photoUrl!);
      if (uri == null) return photoUrl;
      // Replace the host with 'localhost' when running on web dev so that
      // Image.network doesn't try to load from a LAN IP (cross-origin).
      final webUri = uri.replace(
        host: 'localhost',
        queryParameters: {
          ...uri.queryParameters,
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      return webUri.toString();
    }
    return photoUrl;
  }

  String get _initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

  @override
  Widget build(BuildContext context) {
    final url = _safeUrl;
    final hasPhoto = url != null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: hasPhoto
            ? null
            : LinearGradient(colors: [gradientStart, gradientEnd]),
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // ✅ Tell the browser to include CORS headers on the request
                headers: kIsWeb
                    ? const {'Access-Control-Allow-Origin': '*'}
                    : const {},
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: gradientStart.withOpacity(0.2),
                    child: Center(
                      child: SizedBox(
                        width: size * 0.3,
                        height: size * 0.3,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: gradientStart,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() => Center(
        child: Text(
          _initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.42,
            fontFamily: 'Poppins',
          ),
        ),
      );
}