import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// This screen is a temporary tool for diagnosing iOS notification issues.
/// It displays permission status, FCM token, and the critical APNs token.
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String _permissionStatus = 'Checking...';
  String? _fcmToken;
  String? _apnsToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Automatically check permissions when the screen loads.
    _checkPermissionsAndTokens();
  }

  /// Requests notification permission and fetches both FCM and APNs tokens.
  Future<void> _checkPermissionsAndTokens() async {
    setState(() {
      _isLoading = true;
      _permissionStatus = 'Requesting permission...';
      _fcmToken = null;
      _apnsToken = null;
    });

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission from the user.
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Update the UI with the permission status.
    setState(() {
      _permissionStatus = settings.authorizationStatus.name.toUpperCase();
    });

    // If permission is granted, fetch the tokens.
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      try {
        setState(() => _fcmToken = 'Fetching FCM Token...');
        String? fcmToken = await messaging.getToken();
        setState(() => _fcmToken = fcmToken ?? '== Failed to get FCM Token ==');
      } catch (e) {
        setState(() => _fcmToken = 'Error: ${e.toString()}');
      }

      // This is the most critical step for iOS diagnostics.
      try {
        setState(() => _apnsToken = 'Fetching APNs Token...');
        String? apnsToken = await messaging.getAPNSToken();
        setState(() => _apnsToken = apnsToken ?? '== FAILED TO GET APNs TOKEN (CRITICAL!) ==');
      } catch (e) {
        setState(() => _apnsToken = 'Error: ${e.toString()}');
      }
    } else {
      setState(() {
        _fcmToken = 'Permission not granted.';
        _apnsToken = 'Permission not granted.';
      });
    }

    setState(() => _isLoading = false);
  }

  /// Copies the fetched tokens to the clipboard.
  void _copyTokensToClipboard() {
    if (_fcmToken == null && _apnsToken == null) return;
    final allTokens = """
    --- Diagnostic Info ---
    Permission: $_permissionStatus
    FCM Token: $_fcmToken
    APNs Token: $_apnsToken
    """;
    Clipboard.setData(ClipboardData(text: allTokens)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('تم نسخ معلومات التشخيص!'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Diagnostics'),
        backgroundColor: Colors.blueGrey[900],
      ),
      backgroundColor: Colors.blueGrey[800],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(
              '1. Permission Status',
              _permissionStatus,
              _permissionStatus == 'AUTHORIZED' ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              '2. Firebase Token (FCM)',
              _fcmToken ?? 'Not available',
              _fcmToken != null && !_fcmToken!.contains('Failed') ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              '3. Apple Token (APNs)',
              _apnsToken ?? 'Not available',
              _apnsToken != null && !_apnsToken!.contains('FAILED') ? Colors.green : Colors.red,
            ),
            const Spacer(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Re-check Permissions & Tokens'),
                onPressed: _checkPermissionsAndTokens,
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Info to Clipboard'),
              onPressed: _copyTokensToClipboard,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color statusColor) {
    return Card(
      color: Colors.blueGrey[700],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                value,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}