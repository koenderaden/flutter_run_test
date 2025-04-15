# FitQuest Test App

## Overview
FitQuest is a social fitness app that enables users to walk or run together with a buddy. The app focuses on step counting, real-time synchronization between users, and motivational audio feedback. Users can create or join walking sessions, track their progress, and stay motivated through audio cues.

⚠️ **Currently, the app is only available for Android. iPhone support is coming soon!**

## Features
- **Social Walking Sessions**: Create or join walking sessions with a unique session ID
- **Real-time Step Tracking**: Uses the Pedometer package to count steps and sync them between buddies
- **Audio Motivation System**: 
  - Automatic motivational audio clips that play during the session
  - Custom audio feedback at specific intervals
  - Calling feature for direct communication
- **Weather Integration**: Shows current weather conditions in Tilburg
- **Firebase Backend**: 
  - Real-time synchronization of steps between buddies
  - Session management and tracking
  - User data storage
- **Session Management**:
  - Create new walking sessions
  - Join existing sessions with a session ID
  - Pause and resume functionality
  - Step goal setting
- **User Interface**:
  - Modern, dark-themed design
  - Intuitive session creation and joining process
  - Real-time step counter display
  - Session status indicators

## Technologies
- **Flutter**: Cross-platform mobile development framework
- **Dart**: The programming language used for the app
- **Firebase**:
  - Cloud Firestore for real-time data synchronization
  - Authentication for user management
- **Pedometer Package**: For accurate step tracking
- **Audio Players**: For playing motivational audio clips
- **Permission Handler**: Manages activity recognition permissions
- **HTTP**: For weather API integration
- **OpenWeatherMap API**: For weather data

## Installation
To run the app locally, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/koenderaden/flutter_run_test.git
   cd flutter_run_test
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## 📱 Platform Availability:
- ✅ **Android** – The app currently works on Android devices.
- 🚧 **iPhone (iOS)** – Coming soon! Future updates will include iOS support.

## Usage
1. **Starting a Session**:
   - Open the app and tap "Samen Rennen"
   - A new session will be created with a unique ID
   - Share the session ID with your buddy
   - Tap "Start als Host" to begin the session

2. **Joining a Session**:
   - Enter the session ID provided by the host
   - Tap "Sessie joinen" to join the walking session

3. **During the Session**:
   - Steps are automatically tracked and synced between buddies
   - Motivational audio clips play at regular intervals
   - Use the pause/resume button to control the session
   - Set step goals for the session
   - View real-time weather information

## Future Features
- iOS support
- Enhanced audio feedback system with customizable intervals
- More weather locations
- User profiles and history
- Achievement system
- Social features and friend system
- Custom audio clip uploads

## License
This project is licensed under the MIT License. See the LICENSE file for more information.

## Contact
For questions or comments, please contact [koenderaden@gmail.com](mailto:koenderaden@gmail.com).