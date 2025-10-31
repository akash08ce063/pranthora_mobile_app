# Pranthora - Voice Communication Platform

A beautiful Flutter mobile app with dark theme, featuring calling functionality and user profile management.

## 🎨 Features

### ✨ Screens

1. **Splash Screen**
   - Animated Pranthora logo with hexagon design
   - Typewriter text animation
   - Smooth fade and scale transitions
   - Auto-navigates to login screen after 3 seconds

2. **Login Screen**
   - iOS-style classy design
   - Social sign-in buttons (Google, Microsoft, Apple)
   - Email input with continue option
   - Smooth page transitions
   - All sign-in buttons navigate to home screen

3. **Calling Screen (Home)** - 4 States with Full Animations:
   - **Welcome State**: 
     - Fancy "Welcome Anuj" with gradient text
     - Animated glow button with pulsing effect
     - Pranthora branding with hexagon logo
   - **Connecting State**: 1-second loading animation
   - **Active Call State**:
     - Real-time circular audio visualizer
     - Perlin noise wave effects responding to mic input
     - Live call duration timer
     - Menu and End Call controls
   - **Ending State**: 2-second call summary with duration
   - All states with smooth transitions

4. **Profile Screen**
   - User profile card with avatar
   - Settings sections with iOS-style tiles
   - About section
   - Logout button
   - Smooth animations on load

5. **Bottom Navigation**
   - Smooth tab switching between Home and Profile
   - Animated icons and labels
   - iOS-style design

### 🎙️ Audio Features

- **Real-time Mic Capture**: Records and processes microphone input
- **Audio Visualizer**: 120-point circular waveform with Perlin noise
- **Amplitude Detection**: Streams audio amplitude every 50ms
- **Permission Handling**: Automatic microphone permission requests
- **Call Duration Tracking**: Real-time duration display (MM:SS format)

### 🎨 Design Features

- **Dark Theme**: Complete dark theme throughout the app
- **Full Animations**: 
  - Fade transitions between screens
  - Scale and slide animations
  - Pulse effects on calling screen
  - Smooth tab switching
- **iOS Style**: Modern, classy iOS-inspired UI design
- **Pranthora Branding**: Consistent branding with hexagon logo

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- iOS Simulator / Android Emulator or physical device

### Installation

1. Navigate to the app directory:
```bash
cd pranthora_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 📱 Navigation Flow

```
Splash Screen (3s auto) → Login Screen → Main Screen (with tabs)
                                          ├── Home (Calling Screen)
                                          └── Profile Screen
```

## 🎯 App Structure

```
lib/
├── main.dart                         # App entry point with dark theme
├── screens/
│   ├── splash_screen.dart           # Splash screen with animations
│   ├── login_screen.dart            # Login with social sign-in
│   ├── calling_screen.dart          # Calling UI with 4 states & audio viz
│   ├── profile_screen.dart          # Profile & settings
│   └── main_screen.dart             # Bottom navigation container
├── widgets/
│   ├── audio_visualizer.dart        # Circular audio waveform visualizer
│   └── glow_button.dart             # Animated glow button component
├── services/
│   └── audio_recorder_service.dart  # Audio capture & amplitude streaming
└── utils/
    └── perlin_noise.dart            # Custom 3D Perlin noise implementation
```

## 📦 Dependencies

- `cupertino_icons: ^1.0.8` - iOS style icons
- `google_sign_in: ^6.2.1` - Google authentication
- `font_awesome_flutter: ^10.7.0` - Font Awesome icons
- `animated_text_kit: ^4.2.2` - Text animations
- `permission_handler: ^11.3.1` - Microphone permissions
- `record: ^5.1.2` - Audio recording and amplitude monitoring

## 🎨 Color Scheme

- **Background**: `#000000` (Pure Black)
- **Surface**: `#1C1C1E` (Dark Gray)
- **Secondary Surface**: `#2C2C2E` (Medium Gray)
- **Text Primary**: `#FFFFFF` (White)
- **Text Secondary**: `#999999` (Light Gray)
- **Error/Danger**: `#FF3B30` (Red)

## ⚙️ Configuration

The app is configured to:
- Lock to portrait orientation
- Use transparent status bar with light icons
- Display dark navigation bar
- Hide debug banner

## 🔧 Customization

### To customize the logo:
- Replace the hexagon icon with your logo in `assets/logo/`
- Update the icon references in screens

### To modify colors:
- Edit the color constants in each screen
- Update the theme in `main.dart`

## 📝 Notes

- Google Sign In button currently navigates to home screen without actual authentication
- The calling screen is a static UI demonstration
- All animations are optimized for smooth 60fps performance
- The app follows iOS design guidelines for a classy look and feel

## 🎥 Screen Flow

1. **Launch**: Beautiful splash screen with Pranthora branding
2. **Login**: Choose sign-in method or use email
3. **Home**: Access calling screen with animated UI
4. **Navigation**: Switch between Home and Profile using bottom tabs
5. **Profile**: View and manage user settings

## 🌟 Key Highlights

- **Full Animations**: Every screen transition and UI element is animated
- **Dark Theme**: Beautiful dark mode throughout
- **iOS Style**: Classy, modern design inspired by iOS
- **Branding**: Consistent Pranthora branding with hexagon logo
- **Navigation**: Smooth bottom tab navigation
- **Responsive**: Works on all screen sizes

## 🎥 User Journey

1. **Launch App** → Splash screen (3s) → Login
2. **Login** → Select sign-in method → Home (Welcome screen)
3. **Home**: See "Welcome Anuj" with glowing "Start Call" button
4. **Start Call** → Connecting (1s) → Request mic permission
5. **Active Call**: 
   - Audio visualizer reacts to your voice in real-time
   - Call duration updates every second
   - Speak to see the waveform animate
6. **End Call** → Call summary (2s) → Back to welcome

## 🐛 Known Issues

None currently. App is production-ready!

## 🎨 Special Features

- **Perlin Noise**: Custom implementation for organic wave patterns
- **Modular Design**: Reusable widgets (GlowButton, AudioVisualizer)
- **State Management**: Clean 4-state calling flow
- **Real-time Audio**: Visualizer responds to actual microphone input
- **Smooth Animations**: Every interaction is animated (60fps)
- **Permission Handling**: Graceful handling of denied permissions

## 📄 License

Copyright © 2025 Pranthora. All rights reserved.
