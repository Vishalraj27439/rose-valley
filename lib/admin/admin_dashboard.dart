import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rose_valley/admin/AllDue/alldue.dart';
import 'package:rose_valley/admin/alert/alert.dart';
import 'package:rose_valley/admin/bar_garph.dart';
import 'package:rose_valley/admin/birthday.dart';
import 'package:rose_valley/admin/gatepass/list_gatepass.dart';
import 'package:rose_valley/admin/more.dart';
import 'package:rose_valley/admin/profile/fees.dart';
import 'package:rose_valley/school_info_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rose_valley/admin/Attendance/emp_attendance.dart';
import 'package:rose_valley/admin/Receipt/list_receipt.dart';
import 'package:rose_valley/admin/admin_sidebar.dart';
import 'package:rose_valley/admin/admissions/admission_list.dart';
import 'package:rose_valley/admin/profile/admin_profile.dart';
import 'package:rose_valley/admin/complaint/list_complaint.dart';
import 'package:rose_valley/admin/day%20book/day_book.dart';
import 'package:rose_valley/admin/employee/list_employee.dart';
import 'package:rose_valley/admin/enquiry/list_enquiry.dart';
import 'package:rose_valley/admin/fees/fee_due.dart';
import 'package:rose_valley/admin/income/list_income.dart';
import 'package:rose_valley/admin/ledger/stu_ledger.dart';
import 'package:rose_valley/admin/ledger/teacher_ledger.dart';
import 'package:rose_valley/admin/payment/list_payment.dart';
import 'package:rose_valley/admin/result/stu_result.dart';
import 'package:rose_valley/admin/Attendance/stu_attendance.dart';
import 'package:rose_valley/api_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;
  String schoolName = '';
  String schoolLogo = '';

  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
  }

  final List<Widget> _pages = [
    const _DashboardBody(),
    DashboardPage(),
    AdminFeesPage(),
    EarningExpenseChart(),
    const MorePage(),
  ];

  Future<void> _loadSchoolInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      schoolName = prefs.getString('school_name') ?? '';
      schoolLogo = prefs.getString('admin_photo') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FE),
      drawer: Adminsidebar(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          scrolledUnderElevation: 0,

          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
          titleSpacing: 0,
          leadingWidth: 50,

          iconTheme: const IconThemeData(color: Colors.white),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, size: 25),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),

          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      schoolName.isNotEmpty
                          ? schoolName
                          : 'Rose Valley Public School',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Admin Panel',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AlertPage()),
              ),
              icon: const Icon(Icons.notifications_none_rounded, size: 25),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  _showProfileBottomSheet(context);
                },
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: schoolLogo.isNotEmpty
                        ? Image.network(
                            schoolLogo,
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/logo.png',
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF1D4ED8),
                                    size: 22,
                                  );
                                },
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/logo.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 22,
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickCreate(context),
        backgroundColor: const Color(0xFF1479F6),
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: SizedBox(
              height: 62,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home_rounded, 'Dashboard', 0),
                  _navItem(Icons.groups_rounded, 'Students', 1),
                  const SizedBox(width: 52),
                  _navItem(Icons.bar_chart_rounded, 'Reports', 3),
                  _navItem(Icons.grid_view_rounded, 'More', 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected
                  ? const Color(0xFF1479F6)
                  : const Color(0xFF7C879D),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF1479F6)
                    : const Color(0xFF7C879D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact drag handle
                Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE3ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Compact profile header
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: schoolLogo.isNotEmpty
                            ? Image.network(
                                schoolLogo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF2457C5),
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF2457C5),
                              ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account & Settings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF17233F),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            schoolName.isNotEmpty
                                ? schoolName
                                : 'School Administration',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF7B879C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: Color(0xFF7B879C),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEDF0F5)),
                const SizedBox(height: 5),

                _profileSheetItem(
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  subtitle: 'Personal account details',
                  color: const Color(0xFF356AE6),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminProfilePage(),
                      ),
                    );
                  },
                ),

                _profileSheetItem(
                  icon: Icons.school_outlined,
                  title: 'My School',
                  subtitle: 'School information',
                  color: const Color(0xFF0E9F78),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SchoolInfoPage()),
                    );
                  },
                ),

                _profileSheetItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update login credentials',
                  color: const Color(0xFF805AD5),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    // Add Change Password page navigation here.
                  },
                ),

                const SizedBox(height: 5),

                // Separate logout action
                InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    // Call your existing logout method here.
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE1DE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 19,
                          color: Color(0xFFDC4545),
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC4545),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Color(0xFFDC4545),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17233F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8490A4),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: Color(0xFF9AA5B5),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create new',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111B3C),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _createAction(
                  sheetContext,
                  Icons.payments_rounded,
                  'Payment',
                  Colors.orange,
                  () => PaymentListPage(),
                ),
                _createAction(
                  sheetContext,
                  Icons.receipt_long_rounded,
                  'Receipt',
                  Colors.purple,
                  () => AdminReceiptPage(),
                ),
                _createAction(
                  sheetContext,
                  Icons.notifications_active_rounded,
                  'Alert',
                  Colors.pink,
                  () => AlertPage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _createAction(
    BuildContext sheetContext,
    IconData icon,
    String label,
    Color color,
    Widget Function() page,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.pop(sheetContext);
          Navigator.push(context, MaterialPageRoute(builder: (_) => page()));
        },
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  bool isLoading = true;
  Map<String, dynamic> dashboard = {};

  static const navy = Color(0xFF111B3C);
  static const blue = Color(0xFF1479F6);
  static const muted = Color(0xFF68738B);
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBanner = 0;
  String selectedCollectionFilter = 'Today';
  final List<String> _banners = [
    'assets/images/school_banner.jpeg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
    'assets/images/banner4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_bannerController.hasClients) return;

      final nextPage = (_currentBanner + 1) % _banners.length;

      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  String getPreviousMonthName() {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[prevMonth.month - 1];
  }

  Future<void> _loadDashboard() async {
    debugPrint('========== ADMIN DASHBOARD API START ==========');

    try {
      debugPrint('API: /admin/dashboard');

      final response = await ApiService.post(context, "/admin/dashboard");

      if (!mounted) return;

      if (response != null) {
        debugPrint('STATUS CODE: ${response.statusCode}');
        debugPrint('RAW RESPONSE: ${response.body}');

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);

          debugPrint('DECODED TYPE: ${decoded.runtimeType}');

          final responseData =
              decoded is Map<String, dynamic> && decoded['data'] is Map
              ? Map<String, dynamic>.from(decoded['data'])
              : Map<String, dynamic>.from(decoded);

          debugPrint('========== PARSED DASHBOARD DATA ==========');

          responseData.forEach((key, value) {
            debugPrint('$key : $value');
          });

          debugPrint('============================================');

          setState(() {
            dashboard = responseData;
            isLoading = false;
          });

          debugPrint('Dashboard data successfully updated.');
        } else {
          debugPrint('API ERROR: ${response.statusCode}');
          debugPrint('ERROR BODY: ${response.body}');

          setState(() {
            isLoading = false;
          });
        }
      } else {
        debugPrint('API RESPONSE IS NULL');

        setState(() {
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('========== DASHBOARD EXCEPTION ==========');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('==========================================');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }

    debugPrint('========== ADMIN DASHBOARD API END ==========');
  }

  int _number(String key) =>
      int.tryParse(dashboard[key]?.toString() ?? '0') ?? 0;
  double _amount(String key) =>
      double.tryParse(dashboard[key]?.toString() ?? '0') ?? 0;
  String _money(num value) =>
      '₹ ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  List<Map<String, dynamic>> _items(String key) {
    final value = dashboard[key];

    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  double get _collectionPercentage {
    return (_amount('collection_percentage') / 100).clamp(0.0, 1.0);
  }

  double get _attendancePercentage {
    return (_amount('attendance_percentage') / 100).clamp(0.0, 1.0);
  }

  double get _calculatedDues {
    final totalFees = _amount('total_fees_amount');
    return totalFees * (1 - _collectionPercentage);
  }

  double get _selectedCollection {
    switch (selectedCollectionFilter) {
      case 'Week':
        return _amount('weekly_collection');
      case 'Month':
        return _amount('monthly_collection');
      case 'Year':
        return _amount('yearly_collection');
      default:
        return _amount('today_collection');
    }
  }

  void onFilterChanged(String filter) {
    switch (filter) {
      case 'Today':
        // Today's collection API
        break;

      case 'Week':
        // This week's collection API
        break;

      case 'Month':
        // This month's collection API
        break;

      case 'Year':
        // This year's collection API
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Center(child: CircularProgressIndicator(color: blue));

    final collection = _selectedCollection;
    final fees = _amount('total_fees_amount');
    final progress = _collectionPercentage;
    final today = DateTime.now();

    return RefreshIndicator(
      color: blue,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeBanner(today),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _compactStat(
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF1479F6),
                    label: 'Students',
                    value: _number('students').toString(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdmissionListPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _compactStat(
                    icon: Icons.currency_rupee_rounded,
                    color: const Color(0xFFF59E0B),
                    label: 'Collections',
                    value: _money(_amount('collection')),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminFeesPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _compactStat(
                    icon: Icons.currency_rupee_sharp,
                    color: const Color(0xFF10B981),
                    label: 'Dues',
                    value: _number('dues').toString(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmployeeListPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _peopleSummaryCard(),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF142B50).withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading + View All
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _showAllActions(context);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  color: Color(0xFF1479F6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF1479F6),
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Quick Action Grid
                  GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.90,
                    children: _quickActions(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _attendanceCard()),
                  const SizedBox(width: 10),
                  Expanded(child: _collectionCard(collection, fees, progress)),
                ],
              ),
            ),

            const SizedBox(height: 14),

            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _recentAdmissionsCard()),
                    const SizedBox(width: 10),
                    Expanded(child: _noticeCircularCard()),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1E3A8A).withOpacity(.045),
        blurRadius: 18,
        offset: const Offset(0, 5),
      ),
    ],
  );

  Widget _welcomeBanner(DateTime date) {
    return Container(
      height: 125,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E7FC)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Automatic image slider
            Positioned.fill(
              child: PageView.builder(
                controller: _bannerController,
                itemCount: _banners.length,
                onPageChanged: (index) {
                  if (!mounted) return;

                  setState(() {
                    _currentBanner = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.asset(
                    _banners[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFEAF2FF),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF1479F6),
                          size: 30,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom gradient for indicators
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.30),
                    ],
                  ),
                ),
              ),
            ),

            // Slider indicators
            Positioned(
              left: 0,
              right: 0,
              bottom: 9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (index) {
                  final isActive = _currentBanner == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _panelDecoration(),
    child: child,
  );

  Widget _peopleSummaryCard() {
    final maleStudents = _number('male_students');
    final femaleStudents = _number('female_students');
    final parents = _number('parents');
    final maleEmployees = _number('male_employees');
    final femaleEmployees = _number('female_employees');

    final totalEmployees = maleEmployees + femaleEmployees;

    Widget item(String title, int value, Color color, IconData icon) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: muted),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142B50).withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'People Overview',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              item('Male Students', maleStudents, blue, Icons.boy_rounded),
              item(
                'Female Students',
                femaleStudents,
                Colors.pink,
                Icons.girl_rounded,
              ),
              item(
                'Parents',
                parents,
                Colors.orange,
                Icons.family_restroom_rounded,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0F2F6)),
          ),
          Row(
            children: [
              item(
                'Male Employees',
                maleEmployees,
                Colors.teal,
                Icons.man_rounded,
              ),
              item(
                'Female Employees',
                femaleEmployees,
                Colors.purple,
                Icons.woman_rounded,
              ),
              item(
                'Total Employees',
                totalEmployees,
                Colors.indigo,
                Icons.groups_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactStat({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isCollection = label == 'Collections';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 85,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFF0F3F8), width: 0.7),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 27,
                width: 27,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF68758B),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: const Color(0xFF142B50),
                          fontSize: isCollection ? 16 : 17,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _quickActions(BuildContext context) => [
    _actionTile(
      context,
      Icons.groups_rounded,
      'Students',
      const Color(0xFF0EA5E9),
      () => AdmissionListPage(),
    ),
    _actionTile(
      context,
      Icons.fact_check_rounded,
      'Attendance',
      const Color(0xFF10B981),
      () => StudentAttendancePage(),
    ),
    _actionTile(
      context,
      Icons.currency_rupee_rounded,
      'Fee Due',
      const Color(0xFFF59E0B),
      () => FeeDuePage(),
    ),
    _actionTile(
      context,
      Icons.person_add_rounded,
      'Employee',
      const Color(0xFF8B5CF6),
      () => EmployeeListPage(),
    ),
    _actionTile(
      context,
      Icons.menu_book_rounded,
      'Result',
      const Color(0xFFEC4899),
      () => AdminResultPage(),
    ),
    _actionTile(
      context,
      Icons.receipt_long_rounded,
      'Receipt',
      const Color(0xFF0EA5E9),
      () => AdminReceiptPage(),
    ),
    _actionTile(
      context,
      Icons.payments_rounded,
      'Payment',
      const Color(0xFF10B981),
      () => PaymentListPage(),
    ),
    _actionTile(
      context,
      Icons.notifications_active_rounded,
      'Alert',
      const Color(0xFFEF4444),
      () => AlertPage(),
    ),
    _actionTile(
      context,
      Icons.warning_amber_rounded,
      'Complaints',
      const Color(0xFF6366F1),
      () => AdminComplaintList(),
    ),
    _actionTile(
      context,
      Icons.exit_to_app,
      'Gate Pass',
      const Color(0xFFEF4444),
      () => GatePassListPage(),
    ),
  ];

  Widget _actionTile(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    Widget Function() page,
  ) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page()));
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 43,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _attendanceCard() {
    final present = _number('present_students');
    final absent = _number('absent_students');
    final leave = _number('leave_students');
    final percentage = _attendancePercentage;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Attendance",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFFE8F0FC),
                    color: blue,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: navy,
                        ),
                      ),
                      const Text(
                        'Present',
                        style: TextStyle(fontSize: 9, color: muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LegendDot(
            color: const Color(0xFF10B981),
            label: 'Present',
            value: present.toString(),
          ),
          const SizedBox(height: 7),
          _LegendDot(
            color: const Color(0xFFEF476F),
            label: 'Absent',
            value: absent.toString(),
          ),
          const SizedBox(height: 7),
          _LegendDot(
            color: const Color(0xFF60A5FA),
            label: 'Leave',
            value: leave.toString(),
          ),
        ],
      ),
    );
  }

  Widget _collectionCard(double collection, double fees, double progress) {
    final filters = ['Today', 'Week', 'Month', 'Year'];
    final percentage = (progress.clamp(0.0, 1.0) * 100);

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                height: 29,
                width: 29,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Fee Collection',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
              ),
              Icon(
                Icons.trending_up_rounded,
                size: 17,
                color: const Color(0xFF10A879),
              ),
            ],
          ),

          const SizedBox(height: 11),

          // Filter
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: filters.map((filter) {
                final selected = selectedCollectionFilter == filter;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (selected) return;

                      setState(() {
                        selectedCollectionFilter = filter;
                      });

                      onFilterChanged(filter);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.18),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF718096),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Collection amount
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(collection),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: navy,
                letterSpacing: -0.6,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 11, color: muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'of ${_money(fees)} total fees',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Progress header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Collection progress',
                  style: TextStyle(
                    fontSize: 9,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF10A879),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  color: const Color(0xFF10A879),
                  backgroundColor: const Color(0xFFE8F0FC),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeCircularCard() {
    final notices = _items('notices');

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142B50).withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notice & Circular',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AlertPage()),
                  );
                },
                child: const Text(
                  'All',
                  style: TextStyle(
                    color: blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (notices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No notices available',
                  style: TextStyle(fontSize: 10, color: muted),
                ),
              ),
            )
          else
            ...notices.asMap().entries.map((entry) {
              final notice = entry.value;

              final title = notice['NoticeTitle']?.toString() ?? '';
              final description = notice['Description']?.toString() ?? '';
              final date = notice['Date']?.toString() ?? '';
              final attachment = notice['Attachment']?.toString();

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1479F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: navy,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                height: 1.3,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: muted,
                                  ),
                                ),
                                if (attachment != null &&
                                    attachment.isNotEmpty &&
                                    attachment != 'null') ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.attach_file_rounded,
                                    size: 12,
                                    color: blue,
                                  ),
                                  const Text(
                                    'Attachment',
                                    style: TextStyle(fontSize: 8, color: blue),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: Color(0xFF8793A8),
                      ),
                    ],
                  ),
                  if (entry.key != notices.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 9),
                      child: Divider(height: 1, color: Color(0xFFF0F2F6)),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _recentAdmissionsCard() {
    final admissions = _items('recent_admissions');

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142B50).withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Admissions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdmissionListPage()),
                  );
                },
                child: const Text(
                  'All',
                  style: TextStyle(
                    color: blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (admissions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No recent admissions',
                  style: TextStyle(fontSize: 10, color: muted),
                ),
              ),
            )
          else
            ...admissions.asMap().entries.map((entry) {
              final student = entry.value;

              final name = student['StudentName']?.toString() ?? '';
              final studentClass = student['Class']?.toString() ?? '';
              final section = student['Section']?.toString() ?? '';
              final date = student['AdmissionDate']?.toString() ?? '';
              final photo = student['Photo']?.toString() ?? '';

              final initials = name.trim().isEmpty
                  ? '?'
                  : name
                        .trim()
                        .split(RegExp(r'\s+'))
                        .take(2)
                        .map((e) => e[0])
                        .join()
                        .toUpperCase();

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: const Color(0xFFE5F1FF),
                        child: photo.isNotEmpty && photo != 'null'
                            ? ClipOval(
                                child: Image.network(
                                  photo,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: blue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Text(
                                initials,
                                style: const TextStyle(
                                  color: blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: navy,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$studentClass${section.isNotEmpty ? ' - $section' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9, color: muted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 8, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (entry.key != admissions.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 9),
                      child: Divider(height: 1, color: Color(0xFFF0F2F6)),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  void _showAllActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: .85,
                children: _quickActions(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF68738B)),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111B3C),
        ),
      ),
    ],
  );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = true;

  int maleCount = 0;
  int femaleCount = 0;
  List birthdays = [];

  @override
  void initState() {
    super.initState();
    fetchStudentAnalysis();
  }

  Future<void> fetchStudentAnalysis() async {
    final response = await ApiService.post(context, "/admin/student/analysis");

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        maleCount = data["male_students"] ?? 0;
        femaleCount = data["female_students"] ?? 0;
        birthdays = data["birthdays"] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          /// 🔹 Student Graph
          CircleGraphWidget(maleCount: maleCount, femaleCount: femaleCount),

          const SizedBox(height: 16),

          /// 🔹 Upcoming Birthday
          UpcomingBirthdayWidget(birthdays: birthdays),
        ],
      ),
    );
  }
}
