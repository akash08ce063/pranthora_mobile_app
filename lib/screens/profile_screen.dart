import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/pranthora_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _titleAnimationStarted = false;
  String? _displayName;
  String? _email;

  Future<void> _openAbout() async {
    const url = 'https://pranthora.firstpeak.ai';
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // If external open fails, try in-app webview
      await launchUrlString(url, mode: LaunchMode.inAppWebView);
    }
  }

  Future<void> _logout() async {
    // Show blocking loader while logging out
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: PranthoraLoader(size: 80, showLabel: true),
        );
      },
    );

    // Sign out from Supabase and clear all stored auth tokens
    await SupabaseService().signOut();

    if (!mounted) return;

    // Close loader dialog
    Navigator.of(context).pop();

    // Navigate to login
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
    
    // Start title animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _titleAnimationStarted = true;
        });
      }
    });

    // Fetch Supabase user metadata for display
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata ?? {};
      final name = (meta['full_name'] as String?) ?? (meta['name'] as String?);
      setState(() {
        _displayName = name ?? user.email?.split('@').first;
        _email = user.email;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _titleAnimationStarted
                      ? AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'Profile',
                              textStyle: const TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              speed: const Duration(milliseconds: 150),
                              cursor: '_',
                            ),
                          ],
                          totalRepeatCount: 1,
                        )
                      : const Text(
                          '',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                  const SizedBox(height: 30),
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F0F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName ?? 'No name',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _email ?? 'No email',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0x99FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                 
                  // About Section
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsGroup([
                    _SettingItem(
                      icon: CupertinoIcons.info_circle_fill,
                      title: 'Help & Support',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF666666),
                      ),
                    ),
                    _SettingItem(
                      icon: CupertinoIcons.doc_text_fill,
                      title: 'Terms of Service',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF666666),
                      ),
                    ),
                    _SettingItem(
                      icon: CupertinoIcons.heart_fill,
                      title: 'About Pranthora',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F0F0F),
                        foregroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Version
                  const Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0x66FFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildSettingTile(
                icon: item.icon,
                title: item.title,
                trailing: item.trailing,
              ),
              if (index < items.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 60),
                  child: Divider(
                    height: 1,
                    color: Color(0x1AFFFFFF),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (title == 'About Pranthora') {
            _openAbout();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final Widget trailing;

  _SettingItem({
    required this.icon,
    required this.title,
    required this.trailing,
  });
}

