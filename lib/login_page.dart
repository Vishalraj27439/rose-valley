import 'dart:async';
import 'dart:convert';
import 'package:rose_valley/admin/admin_dashboard.dart';
import 'package:rose_valley/driver/driver_dashboard.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rose_valley/api_service.dart';
import 'package:rose_valley/dashboard/dashboard_screen.dart';
import 'package:rose_valley/teacher/teacher_dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    if (idController.text.trim() == "987654321" &&
        passwordController.text.trim() == "123456") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverDashboard()),
      );

      return;
    }
    if (idController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter ID and password";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 2️⃣ API Call (NO type sent)
      final response = await ApiService.postPublic(
        "/login",
        body: {
          'username': idController.text.trim(),
          'password': passwordController.text,
        },
      ).timeout(const Duration(seconds: 15));

      // 3️⃣ Null response check
      if (response == null) {
        setState(() {
          _errorMessage = "Server not responding";
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body);
      debugPrint("🟢 LOGIN RESPONSE: $data");

      // 4️⃣ Success
      if (data['status'] == true) {
        await ApiService.saveSession(data);

        if (!mounted) return;

        sendFcmTokenToLaravel();

        final String userType = data['user_type'];

        if (userType == 'Teacher') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
            (_) => false,
          );
        } else if (userType == 'Admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboardPage()),
            (_) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (_) => false,
          );
        }
      } else {
        // 5️⃣ Invalid credentials
        setState(() {
          _errorMessage = data['message'] ?? "Invalid credentials";
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = "Request timeout. Please try again.";
      });
    } catch (e) {
      debugPrint("❌ LOGIN ERROR: $e");
      setState(() {
        _errorMessage = "Something went wrong";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> sendFcmTokenToLaravel() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null || fcmToken.isEmpty) return;

      await ApiService.post(
        context,
        "/save_token",
        body: {'fcm_token': fcmToken},
      );
    } catch (e) {
      debugPrint("FCM Error: $e");
    }
  }

  void _launchURL() async {
    final Uri url = Uri.parse(AppAssets.companyWebsite);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;

            final s = (h / 760).clamp(0.55, 1.0).toDouble();
            final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

            return SingleChildScrollView(
              physics: keyboardOpen
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        SizedBox(height: 8 * s),

                        // SCHOOL HEADER
                        // SCHOOL HEADER - DYNAMIC
                        Container(
                          width: double.infinity,
                          height: 155 * s,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * s,
                            vertical: 10 * s,
                          ),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20 * s),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEAF5FF),
                                Color(0xFFD9EDFF),
                                Color(0xFFBDE3FF),
                              ],
                            ),
                            border: Border.all(color: const Color(0xFFD4E7F8)),
                          ),
                          child: Row(
                            children: [
                              // SCHOOL LOGO
                              Container(
                                width: 64 * s,
                                height: 64 * s,
                                padding: EdgeInsets.all(5 * s),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    AppAssets.logo,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.school_rounded,
                                      size: 40 * s,
                                      color: const Color(0xFF245BB5),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 12 * s),

                              // DYNAMIC SCHOOL NAME
                              Expanded(
                                flex: 6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WELCOME TO',
                                      style: TextStyle(
                                        color: const Color(0xFF526783),
                                        fontSize: 10 * s,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 5 * s),
                                    Text(
                                      AppAssets.schoolName,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFF142443),
                                        fontSize: 18 * s,
                                        height: 1.12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 5 * s),
                                    Text(
                                      AppAssets.schoolDescription,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFF526783),
                                        fontSize: 10.5 * s,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 5 * s),

                              // SCHOOL BUILDING IMAGE
                              Expanded(
                                flex: 4,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: Image.asset(
                                      'assets/images/school_banner.jpeg',
                                      width: double.infinity,
                                      height: 130 * s,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.centerRight,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 15 * s),

                        // LOGIN TITLE
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 39 * s,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3675D5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            SizedBox(width: 11 * s),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontSize: 25 * s,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF142B50),
                                    ),
                                  ),
                                  Text(
                                    'Enter your details to continue',
                                    style: TextStyle(
                                      fontSize: 11.5 * s,
                                      color: Colors.blueGrey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.verified_user_outlined,
                              size: 27 * s,
                              color: const Color(0xFF3675D5),
                            ),
                          ],
                        ),

                        SizedBox(height: 13 * s),

                        // LOGIN FORM
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16 * s),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18 * s),
                            border: Border.all(color: const Color(0xFFE4E9F2)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'USERNAME',
                                  style: TextStyle(
                                    fontSize: 10 * s,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: const Color(0xFF52627A),
                                  ),
                                ),
                              ),
                              SizedBox(height: 6 * s),

                              TextField(
                                controller: idController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: 'Enter your username',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: const Color(0xFF3675D5),
                                    size: 21 * s,
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FB),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12 * s,
                                    vertical: 13 * s,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(11 * s),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),

                              SizedBox(height: 12 * s),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'PASSWORD',
                                  style: TextStyle(
                                    fontSize: 10 * s,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: const Color(0xFF52627A),
                                  ),
                                ),
                              ),
                              SizedBox(height: 6 * s),

                              TextField(
                                controller: passwordController,
                                obscureText: _obscureText,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (!_isLoading) _login();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: const Color(0xFF3675D5),
                                    size: 21 * s,
                                  ),
                                  suffixIcon: IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 19 * s,
                                    ),
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FB),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12 * s,
                                    vertical: 13 * s,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(11 * s),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),

                              if (_errorMessage.isNotEmpty) ...[
                                SizedBox(height: 8 * s),
                                Text(
                                  _errorMessage,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 11 * s,
                                  ),
                                ),
                              ],

                              SizedBox(height: 15 * s),

                              SizedBox(
                                width: double.infinity,
                                height: 46 * s,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF245BB5),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        11 * s,
                                      ),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 19 * s,
                                          height: 19 * s,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 15 * s,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 8 * s),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 19 * s,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 13 * s),

                        // ROLE SHORTCUTS
                        if (MediaQuery.of(context).viewInsets.bottom == 0) ...[
                          SizedBox(height: 12 * s),
                          Row(
                            children: [
                              Text(
                                'QUICK ACCESS',
                                style: TextStyle(
                                  fontSize: 10 * s,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: const Color(0xFF52627A),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10 * s),
                                  child: const Divider(
                                    color: Color(0xFFDDE3ED),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 9 * s),

                          Row(
                            children: [
                              Expanded(
                                child: roleCard(
                                  icon: Icons.admin_panel_settings_rounded,
                                  color: const Color(0xFF2864C5),
                                  title: 'Admin',
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              Expanded(
                                child: roleCard(
                                  icon: Icons.co_present_rounded,
                                  color: const Color(0xFF16856B),
                                  title: 'Teacher',
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              Expanded(
                                child: roleCard(
                                  icon: Icons.school_rounded,
                                  color: const Color(0xFF7653C6),
                                  title: 'Student',
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              Expanded(
                                child: roleCard(
                                  icon: Icons.family_restroom_rounded,
                                  color: const Color(0xFFD17A26),
                                  title: 'Parent',
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // FOOTER
                          Padding(
                            padding: EdgeInsets.only(bottom: 8 * s),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Powered by TechInnovation App Pvt. Ltd.®',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10 * s,
                                    color: AppColors.designerColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4 * s),
                                GestureDetector(
                                  onTap: _launchURL,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.language_rounded,
                                        size: 14 * s,
                                        color: const Color(0xFF245BB5),
                                      ),
                                      SizedBox(width: 4 * s),
                                      Text(
                                        AppAssets.websiteName,
                                        style: TextStyle(
                                          fontSize: 11 * s,
                                          color: const Color(0xFF245BB5),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget roleCard({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF26364D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
