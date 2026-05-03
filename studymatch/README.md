# StudyMatch Flutter App

A peer-to-peer educational platform connecting students for collaborative learning.

## 📱 Features

- **Landing Screen** - Marketing page with feature highlights and CTA
- **Authentication** - Sign up / Sign in with form validation
- **Onboarding Flow** - 6-step onboarding (profile photo, basic info, subjects, schedule, study style, how-to-swipe)
- **Dashboard** - Personalized home with stats, quick actions, top matches, and recent messages
- **Match Screen** - Tinder-style swipe cards with gesture support (drag + buttons)
- **Messages** - Conversation list + full real-time chat UI
- **Resource Library** - Browse/upload academic materials with filters
- **Profile** - User profile with stats, preferences, and account settings

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code with Flutter extension

### Setup

```bash
# Clone or download the project
cd studymatch

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run
```

### Adding Google Fonts (Poppins)

The app uses Poppins font. Add it via `google_fonts` package (already in pubspec.yaml).

Alternatively, download Poppins from Google Fonts and place in `assets/fonts/`:
```
assets/
  fonts/
    Poppins-Regular.ttf
    Poppins-Medium.ttf
    Poppins-SemiBold.ttf
    Poppins-Bold.ttf
```

Then update pubspec.yaml:
```yaml
fonts:
  - family: Poppins
    fonts:
      - asset: assets/fonts/Poppins-Regular.ttf
      - asset: assets/fonts/Poppins-Medium.ttf
        weight: 500
      - asset: assets/fonts/Poppins-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Poppins-Bold.ttf
        weight: 700
```

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry point + router
├── models/
│   └── models.dart              # Data models (UserModel, MatchProfile, Message, etc.)
├── services/
│   └── app_state.dart           # ChangeNotifier state management
├── utils/
│   └── app_theme.dart           # Theme, colors, constants
├── widgets/
│   └── shared_widgets.dart      # Reusable UI components
└── screens/
    ├── landing_screen.dart      # Welcome/marketing screen
    ├── auth/
    │   ├── login_screen.dart
    │   └── signup_screen.dart
    ├── onboarding/
    │   └── onboarding_flow.dart # Multi-step onboarding
    └── main/
        ├── main_shell.dart      # Bottom nav container
        ├── dashboard_screen.dart
        ├── match_screen.dart
        ├── messages_screen.dart
        ├── resources_screen.dart
        └── profile_screen.dart
```

## 🎨 Design System

- **Primary**: `#7C3AED` (Purple)
- **Accent**: `#AD46FF` (Violet)
- **Background**: `#0D0B1E` (Deep Navy)
- **Cards**: `#1A1730`
- **Font**: Poppins

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `shared_preferences` | Local storage |
| `google_fonts` | Poppins font |
| `image_picker` | Profile photo upload |
| `intl` | Date/time formatting |
| `uuid` | Unique ID generation |

## 🔒 Security Notes

- All sensitive operations should go through a backend API (Firebase, Supabase, etc.)
- Implement proper JWT token storage in `flutter_secure_storage`
- Add input sanitization for all user text fields
- Enable ProGuard/R8 for Android release builds

## 🔮 Next Steps

1. **Backend Integration**: Connect to Firebase Auth + Firestore for real data
2. **Real-time Chat**: Use Firebase Realtime Database or websockets
3. **Push Notifications**: Firebase Cloud Messaging
4. **Photo Upload**: Firebase Storage or AWS S3
5. **Matching Algorithm**: Server-side ML-based matching
6. **Video Calls**: WebRTC integration for study sessions
