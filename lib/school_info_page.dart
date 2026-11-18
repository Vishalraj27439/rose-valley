import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rose_valley/api_service.dart';

class SchoolInfoPage extends StatefulWidget {
  const SchoolInfoPage({super.key});

  @override
  State<SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<SchoolInfoPage> {
  static const Color navy = Colors.black;
  static const Color muted = Colors.black54;
  static const Color background = Color(0xFFF7F8FA);
  static const Color borderColor = Color(0xFFEEEEEE);
  String schoolName = 'My School';
  String schoolLogo = '';
  String qrCode = '';

  Map<String, String> schoolDetails = {};

  bool isLoading = true;
  bool isDownloading = false;
  bool hasError = false;

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
        setState(() {
          isLoading = false;
          hasError = true;
        });
        return;
      }

      if (response.statusCode != 200) {
        debugPrint('School API failed: ${response.statusCode}');
        setState(() {
          isLoading = false;
          hasError = true;
        });
        return;
      }

      final data = jsonDecode(response.body);

      setState(() {
        schoolLogo = data['SchoolLogo']?.toString() ?? '';
        qrCode = data['QRCode']?.toString() ?? '';
        schoolName = data['SchoolName']?.toString() ?? 'My School';

        schoolDetails = {
          'Email': data['SchEmail']?.toString() ?? '',
          'Website': data['Website']?.toString() ?? '',
          'Address': data['Address']?.toString() ?? '',
          'Principal': data['PrincipalName']?.toString() ?? '',
          'Contact': data['ContactNo']?.toString() ?? '',
        };

        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      debugPrint('School info exception: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  // ---------------- IMAGE HANDLING ----------------

  String _imageUrl(String url) {
    if (url.isEmpty) return '';

    if (url.startsWith('http')) return url;

    return '${ApiService.Url}/$url';
  }

  Widget _schoolLogo({double size = 82}) {
    return Container(
      height: size,
      width: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: schoolLogo.isEmpty
            ? Image.asset('assets/images/logo.png', fit: BoxFit.contain)
            : Image.network(
                _imageUrl(schoolLogo),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
      ),
    );
  }

  // ---------------- DOWNLOAD QR ----------------

  Future<void> downloadQrCode() async {
    if (qrCode.isEmpty) {
      _showMessage('QR code not available');
      return;
    }

    try {
      setState(() => isDownloading = true);

      final response = await http.get(Uri.parse(_imageUrl(qrCode)));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('Download failed');
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

        _showMessage('QR saved to Downloads folder');

        await OpenFile.open(file.path);
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();

        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!mounted) return;

        _showMessage('QR saved in Files app');

        await OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint('QR download error: $e');

      if (mounted) {
        _showMessage('Failed to download QR Code');
      }
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

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

  // ---------------- DETAIL ICONS ----------------

  IconData _detailIcon(String key) {
    switch (key) {
      case 'Email':
        return Icons.mail_outline_rounded;
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

  Color _detailColor(String key) {
    switch (key) {
      case 'Email':
        return const Color(0xFF5279E8);
      case 'Website':
        return const Color(0xFF8B63D9);
      case 'Address':
        return const Color(0xFFEC8C48);
      case 'Principal':
        return const Color(0xFF10A879);
      case 'Contact':
        return const Color(0xFF16A6B6);
      default:
        return navy;
    }
  }

  // ---------------- HEADER ----------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2455A4).withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -25,
            top: -55,
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.055),
              ),
            ),
          ),

          Positioned(
            right: 40,
            bottom: -65,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.045),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _schoolLogo(size: 82),

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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'MY SCHOOL',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      schoolName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'School Profile & Information',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 10,
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

  // ---------------- SECTION HEADER ----------------

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2856A2), size: 19),
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
                  color: navy,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        if (trailing != null) trailing,
      ],
    );
  }

  // ---------------- SCHOOL DETAILS ----------------

  Widget _buildDetailTile(String title, String value) {
    final color = _detailColor(title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(_detailIcon(title), color: color, size: 18),
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
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  SelectableText(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: navy,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final details = schoolDetails.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF253858).withOpacity(0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: details.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'No school details available',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
            )
          : Column(
              children: details.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Column(
                  children: [
                    _buildDetailTile(item.key, item.value),

                    if (index != details.length - 1) const SizedBox(height: 1),
                  ],
                );
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
            color: const Color(0xFF253858).withOpacity(0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: Image.network(
              _imageUrl(qrCode),
              height: 175,
              width: 175,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 175,
                width: 175,
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 100,
                  color: Color(0xFFB5C0D0),
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Scan the QR code to pay school fees',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 17),

          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton(
              onPressed: isDownloading ? null : downloadQrCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isDownloading)
                    const SizedBox(
                      height: 17,
                      width: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.download_rounded,
                      size: 19,
                      color: Colors.white,
                    ),

                  const SizedBox(width: 9),

                  Text(
                    isDownloading ? 'Downloading...' : 'Download QR Code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- ERROR STATE ----------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 75,
              width: 75,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FB),
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 35,
                color: Color(0xFF5279B7),
              ),
            ),

            const SizedBox(height: 17),

            const Text(
              'Unable to load school information',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: muted),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                fetchSchoolInfo();
              },
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2455A4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- MAIN BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 55,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),

        title: const Text(
          'My School',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              tooltip: 'Refresh',
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() {
                        isLoading = true;
                        hasError = false;
                      });
                      fetchSchoolInfo();
                    },
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ),
        ],
      ),

      body: isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: navy, strokeWidth: 2.5),
                  const SizedBox(height: 13),
                  const Text(
                    'Loading school information...',
                    style: TextStyle(
                      fontSize: 11,
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : hasError
          ? _buildErrorState()
          : RefreshIndicator(
              color: const Color(0xFF2455A4),
              onRefresh: fetchSchoolInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 17, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School Profile Header
                    _buildHeader(),

                    const SizedBox(height: 25),

                    // Details Heading
                    _sectionHeader(
                      title: 'School Information',
                      subtitle: 'Contact details and school address',
                      icon: Icons.apartment_rounded,
                    ),

                    const SizedBox(height: 13),

                    // Details Card
                    _buildDetailsCard(),

                    // Payment QR
                    if (qrCode.isNotEmpty) ...[
                      const SizedBox(height: 25),

                      _buildQrCard(),
                    ],

                    const SizedBox(height: 25),

                    // Footer
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 1,
                            width: 45,
                            color: const Color(0xFFDCE3EE),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'POWERED BY TechinnovationApp',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF9AA6B7),
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Text(
                            'School Information',
                            style: TextStyle(fontSize: 10, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
