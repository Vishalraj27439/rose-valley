import 'dart:io';
import 'dart:convert';

import 'package:rose_valley/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  static const Color pageBg = Color(0xFFF6ECFB);
  static const Color textColor = Colors.black;
  static const Color secondaryText = Colors.black54;
  static const Color borderColor = Color(0xFFEDE7F1);

  String schoolName = "My School";
  String schoolLogo = "";
  String qrCode = "";

  Map<String, String> schoolDetails = {};

  bool isLoading = true;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    fetchSchoolInfo();
  }

  // ---------------- SCHOOL API ----------------

  Future<void> fetchSchoolInfo() async {
    try {
      final response = await ApiService.post(context, '/school');

      if (!mounted) return;

      if (response == null) {
        setState(() => isLoading = false);
        return;
      }

      if (response.statusCode != 200) {
        debugPrint("School API failed: ${response.statusCode}");
        setState(() => isLoading = false);
        return;
      }

      final data = jsonDecode(response.body);

      setState(() {
        schoolLogo = data['SchoolLogo'] ?? '';
        qrCode = data['QRCode'] ?? '';
        schoolName = data['SchoolName'] ?? 'My School';

        schoolDetails = {
          "Email": data['SchEmail'] ?? '',
          "Website": data['Website'] ?? '',
          "Address": data['Address'] ?? '',
          "Principal": data["PrincipalName"] ?? '',
          "Contact": data["ContactNo"]?.toString() ?? '',
        };

        isLoading = false;
      });
    } catch (e) {
      debugPrint("School info exception: $e");

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ---------------- IMAGE ----------------

  ImageProvider _safeImage(String url) {
    if (url.isEmpty) {
      return const AssetImage("assets/images/logo.png");
    }

    return NetworkImage(
      url.startsWith('http') ? url : '${ApiService.baseUrl}/$url',
    );
  }

  // ---------------- DOWNLOAD QR ----------------

  Future<void> downloadQrCode() async {
    if (qrCode.isEmpty) {
      _showMessage("QR code not available");
      return;
    }

    try {
      setState(() => isDownloading = true);

      final normalizedUrl = qrCode.startsWith('http')
          ? qrCode
          : '${ApiService.baseUrl}/$qrCode';

      final response = await http.get(Uri.parse(normalizedUrl));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

      final fileName = 'School_QR_${DateTime.now().millisecondsSinceEpoch}.png';

      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');

        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final file = File('${downloadsDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!mounted) return;

        _showMessage("QR saved to Downloads folder");
      }

      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();

        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!mounted) return;

        _showMessage("QR saved in Files app");
      }
    } catch (e) {
      debugPrint("QR download error: $e");

      if (mounted) {
        _showMessage("Failed to download QR Code");
      }
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ---------------- DETAIL ICON ----------------

  IconData _detailIcon(String key) {
    switch (key) {
      case 'Email':
        return Icons.email_outlined;
      case 'Website':
        return Icons.language_rounded;
      case 'Address':
        return Icons.location_on_outlined;
      case 'Principal':
        return Icons.person_outline_rounded;
      case 'Contact':
        return Icons.call_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  // ---------------- SECTION HEADER ----------------

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          height: 39,
          width: 39,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 19),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- SCHOOL HEADER ----------------

  Widget _buildSchoolHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.20),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -50,
            child: Container(
              height: 135,
              width: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                height: 83,
                width: 83,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image(
                    image: _safeImage(schoolLogo),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.17),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'SCHOOL PROFILE',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      schoolName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'School Information',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- DETAIL TILE ----------------

  Widget _buildDetailTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 39,
            width: 39,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_detailIcon(title), color: AppColors.primary, size: 19),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DETAILS CARD ----------------

  Widget _buildDetailsCard() {
    final details = schoolDetails.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: details.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No school details available',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ),
            )
          : Column(
              children: details.map((e) {
                return _buildDetailTile(e.key, e.value);
              }).toList(),
            ),
    );
  }

  // ---------------- QR CARD ----------------

  Widget _buildQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Payment QR Code',
            subtitle: 'Quick and easy fee payments',
            icon: Icons.qr_code_2_rounded,
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: pageBg.withOpacity(0.65),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderColor),
            ),
            child: Image(
              image: _safeImage(qrCode),
              height: 170,
              width: 170,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const SizedBox(
                  height: 170,
                  width: 170,
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 95,
                    color: Colors.black26,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Scan this QR code for payment',
            style: TextStyle(
              fontSize: 11,
              color: secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 17),

          SizedBox(
            height: 47,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDownloading ? null : downloadQrCode,
              icon: isDownloading
                  ? const SizedBox(
                      height: 17,
                      width: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
              label: Text(
                isDownloading ? 'Downloading...' : 'Download QR Code',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LOADING ----------------

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          const SizedBox(height: 13),
          const Text(
            'Loading school information...',
            style: TextStyle(
              fontSize: 11,
              color: secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MAIN BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,

      body: isLoading
          ? _buildLoading()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: fetchSchoolInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 15,
                  16,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSchoolHeader(),

                    const SizedBox(height: 23),

                    _sectionHeader(
                      title: 'School Details',
                      subtitle: 'Contact and school information',
                      icon: Icons.apartment_rounded,
                    ),

                    const SizedBox(height: 13),

                    _buildDetailsCard(),

                    if (qrCode.isNotEmpty) ...[
                      const SizedBox(height: 23),
                      _buildQrCard(),
                    ],

                    const SizedBox(height: 25),

                    Center(
                      child: Text(
                        'SCHOOL PROFILE',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: Colors.black54,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
