# Design Spec: Superman Clipboard Sync (Mac <-> Android)

**Date**: 2026-05-13
**Topic**: Local Network Manual Clipboard Synchronization
**Status**: Approved

## 1. Executive Summary
"Superman" is a privacy-focused, local-network clipboard synchronization tool designed for seamless text transfer between a macOS computer and an Android device. It avoids cloud dependency by using direct local connections (WebSocket), ensuring data privacy and high speed.

## 2. Goals & Success Criteria
- **Goal**: Enable manual pushing and pulling of clipboard text between Mac and Android.
- **Success Criteria**: 
    - Latency < 500ms on a standard home Wi-Fi.
    - Zero cloud data storage.
    - Successful compilation of the Android client via GitHub Actions.

## 3. Architecture

### 3.1 Components
1.  **Mac Server (Go)**:
    - **Host**: Runs on macOS.
    - **Discovery**: Generates a QR code in the terminal containing the local IP and a unique session token.
    - **Communication**: Acts as a WebSocket server.
    - **System Integration**: Uses a Go library to read/write the macOS clipboard.
2.  **Android Client (Flutter)**:
    - **Host**: Android device.
    - **Discovery**: Scans the QR code to obtain connection details.
    - **Communication**: Acts as a WebSocket client.
    - **UI**: Simple dashboard with "Send to Mac" and "Pull from Mac" buttons.
3.  **GitHub Actions**:
    - **Role**: CI/CD pipeline to compile the Flutter code into an APK.

### 3.2 Data Flow
- **Pairing**: Android scans QR -> Extracts IP & Token -> Establishes WebSocket.
- **Push (Mac -> Android)**: User interacts with Mac CLI -> Server sends message via WS -> Android client receives and updates local clipboard.
- **Push (Android -> Mac)**: User taps "Send to Mac" -> Client reads Android clipboard -> Sends via WS -> Mac server receives and updates macOS clipboard.

## 4. Technical Details

### 4.1 Networking
- **Protocol**: WebSocket (over HTTP).
- **Security**: 
    - Session Token: A random string generated per session, required in the WS handshake.
    - Local-only: No external ports opened on the router (LAN only).

### 4.2 Implementation Stack
- **Mac**: Go (v1.20+) with `atotto/clipboard` or similar for clipboard access and `gorilla/websocket`.
- **Android**: Flutter (Latest Stable) for UI and system clipboard access.
- **Build**: GitHub Actions with `subosito/flutter-action`.

## 5. Error Handling
- **Connection Lost**: Android client will show a "Disconnected" status and offer a "Reconnect" button.
- **IP Change**: If the Mac's local IP changes, the user must re-scan the QR code.
- **Clipboard Permissions**: Handled gracefully within Flutter (Android 10+ specificities).

## 6. Testing Strategy
- **Unit Tests**: Test the message parsing logic in Go.
- **Integration Tests**: Verify WS handshake with valid/invalid tokens.
- **Manual Verification**: End-to-end test of copying on Mac and seeing it on Android.

## 7. Future Scope (Non-Goals for V1)
- Automatic background sync.
- File transfer support.
- Support for multiple devices simultaneously.
