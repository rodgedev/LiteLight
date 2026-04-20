import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show SystemNavigator;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  bool _isFlashlightOn = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  final Battery _battery = Battery();
  int _batteryLevel = 0;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(_glowController);
    _getBatteryInfo();
  }

  Future<void> _getBatteryInfo() async {
    try {
      int level = await _battery
          .batteryLevel; // This returns the percentage [citation:6][citation:7]

      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    } catch (e) {
      debugPrint('Error getting battery level: $e');
      // In case of error, you can set a default value or leave it as 0.
      if (mounted) {
        setState(() {
          _batteryLevel = -1; // Indicate an error
        });
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted && mounted) {
      _showPermissionDialog();
    }
  }

  Future<void> _openAboutPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutPage()),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1919),
        title: const Text(
          'Camera Permission Needed',
          style: TextStyle(color: Color(0xFFEBFF00)),
        ),
        content: const Text(
          'Lite Light needs camera permission to control the flashlight LED.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFEBFF00))),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlashlight() async {
    try {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
      });
    } catch (e) {
      debugPrint('Error toggling flashlight: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0e0e0e),
      drawer: Drawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header stays at top
            _buildHeader(),

            // Main Content - takes remaining space and centers vertically
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: _buildPowerButton()),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFAB() {
    if (_isFlashlightOn) {
      // Show Exit FAB when flashlight is ON
      return FloatingActionButton.extended(
        onPressed: _exitAndTurnOff,
        backgroundColor: const Color(0xFFEBFF00),
        foregroundColor: const Color(0xFF5c6400),
        icon: const Icon(Icons.exit_to_app),
        label: const Text(
          'EXIT',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      );
    } else {
      // Show About FAB when flashlight is OFF
      return FloatingActionButton(
        onPressed: _openAboutPage,
        backgroundColor: const Color(0xFF1a1919),
        foregroundColor: const Color(0xFFEBFF00),
        child: const Icon(Icons.help_outline, size: 36),
      );
    }
  }

  Future<void> _exitAndTurnOff() async {
    try {
      // Turn off flashlight if it's on
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
      }
    } catch (e) {
      debugPrint('Error turning off flashlight: $e');
    } finally {
      // Exit the app
      // For Android:
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Alternative exit methods
        SystemNavigator.pop(); // This works on both Android and iOS
      }
    }
  }

  Widget _buildHeader() {
    final String displayPercentage = _batteryLevel == -1
        ? '--'
        : _batteryLevel.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.flashlight_on,
                color: const Color(0xFFEBFF00),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'LITELIGHT',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEBFF00),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Battery Level',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$displayPercentage%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00e3fd),
                  fontFamily: 'Space Grotesk',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPowerButton() {
    return GestureDetector(
      onTap: _toggleFlashlight,
      child: AnimatedScale(
        scale: _isFlashlightOn ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            if (_isFlashlightOn)
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFEBFF00,
                          ).withOpacity(_glowAnimation.value * 0.5),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            // Main button
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEBFF00),
                boxShadow: _isFlashlightOn
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEBFF00).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.power_settings_new,
                      size: 64,
                      color: const Color(0xFF5c6400),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isFlashlightOn ? 'ON' : 'OFF',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5c6400),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0e0e0e),
      appBar: AppBar(
        title: const Text(
          'About LiteLight',
          style: TextStyle(
            color: Color(0xFFEBFF00),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1a1919),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFEBFF00)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon and Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset('images/icon.png'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'LiteLight',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEBFF00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: Colors.grey),
            const SizedBox(height: 24),

            // Description
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEBFF00),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'LiteLight is a free, simple illumination companion for Android. '
              'Clean interface with one-tap flashlight control and real-time battery status.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 24),

            // Features
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEBFF00),
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.flash_on, 'One-tap flashlight control'),
            _buildFeatureItem(
              Icons.battery_std,
              'Real-time battery percentage',
            ),
            _buildFeatureItem(Icons.privacy_tip, 'No data collection'),
            _buildFeatureItem(Icons.dark_mode, 'Dark theme interface'),

            const SizedBox(height: 24),

            // Privacy Policy Link
            const Text(
              'Legal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEBFF00),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF1a1919),
              child: InkWell(
                onTap: () => _openPrivacyPolicy(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip, color: Color(0xFFEBFF00)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Developer Info
            const Text(
              'Developer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEBFF00),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF1a1919),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildContactItem(
                      Icons.email,
                      'Email',
                      'devrodge@gmail.com',
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      Icons.code,
                      'GitHub',
                      'github.com/rodgedev/litelight',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                '©2026 LiteLight. All rights reserved.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFEBFF00)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFEBFF00)),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1a1919),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Color(0xFFEBFF00)),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LiteLight does not collect, store, or share any personal information.\n\n'
                'Permissions Used:\n'
                '• Camera: Required only to control the flashlight LED\n\n'
                'No internet permission is requested. The app functions entirely offline.',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFEBFF00)),
            ),
          ),
        ],
      ),
    );
  }
}
