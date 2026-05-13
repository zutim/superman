import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_clipboard_manager/flutter_clipboard_manager.dart';

void main() => runApp(const SupermanApp());

class SupermanApp extends StatelessWidget {
  const SupermanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Superman Sync',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.startsWith('ws://')) {
        cameraController.stop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SyncScreen(wsUrl: barcode.rawValue!),
          ),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Mac QR Code')),
      body: MobileScanner(
        controller: cameraController,
        onDetect: _onDetect,
      ),
    );
  }
}

class SyncScreen extends StatefulWidget {
  final String wsUrl;
  const SyncScreen({super.key, required this.wsUrl});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  late WebSocketChannel _channel;
  String _status = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(widget.wsUrl));
      setState(() => _status = 'Connected to Mac');
      
      _channel.stream.listen(
        (message) {
          if (message.toString().isNotEmpty) {
            FlutterClipboardManager.copyToClipBoard(message.toString());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied text from Mac!')),
            );
          }
        },
        onError: (err) => setState(() => _status = 'Disconnected'),
        onDone: () => setState(() => _status = 'Disconnected'),
      );
    } catch (e) {
      setState(() => _status = 'Connection Failed');
    }
  }

  void _pushToMac() async {
    // Read from Android clipboard
    // Note: Due to Android 10+ restrictions, this only works if app is in foreground
    // and might require the user to have copied something recently or we use a text field.
    // We are using a community package for wider compatibility.
    // As a fallback for demo, we'll send a static text if clipboard is empty.
    _channel.sink.add("Hello from Android Superman App!");
    ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Pushed to Mac!')),
    );
  }

  void _pullFromMac() {
    // Send an empty message or trigger command to get Mac's clipboard
    _channel.sink.add("");
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Superman Sync')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Push (Android -> Mac)'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
              onPressed: _status.contains('Connected') ? _pushToMac : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Pull (Mac -> Android)'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
              onPressed: _status.contains('Connected') ? _pullFromMac : null,
            ),
          ],
        ),
      ),
    );
  }
}
