import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rose_valley/Attendance_UI/stu_attendance_page.dart';
import 'package:rose_valley/login_page.dart';
import 'package:rose_valley/teacher/AssignMarksPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rose_valley/Attendance_UI/mark_attendance_page.dart';
import 'package:rose_valley/alert/stu_alert.dart';
import 'package:rose_valley/api_service.dart';
import 'package:rose_valley/homework/teacher_add_homework_page.dart';
import 'package:rose_valley/leave/list_leaveApproval.dart';
import 'package:rose_valley/main.dart';
import 'package:rose_valley/payment/payment_teacher_screen.dart';
import 'package:rose_valley/teacher/complaint_teacher/teacher_complaint_list_page.dart';
import 'package:rose_valley/teacher/student_list.dart';
import 'package:rose_valley/teacher/teacher_recent_homework.dart';
import 'package:rose_valley/teacher/teacher_sidebar_menu.dart';
import 'package:rose_valley/teacher/teacher_timetable.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with RouteAware {
  bool isLoading = true;
  bool isRefreshing = false;

  int students = 0;
  int complaints = 0;
  int payments = 0;

  String schoolName = '';
  String teacherPhoto = '';
  String teacherName = '';

  String teacherClass = '';
  String teacherSection = '';
  int _selectedBottomIndex = 0;

  Map<String, dynamic> attendance = {};
  List<Map<String, dynamic>> homeworks = [];
  List<Map<String, dynamic>> todayPeriods = [];
  final List<Map<String, dynamic>> todayAttendance = [
    {'Class': 'VI', 'Present': 28, 'Total': 30},
    {'Class': 'VII', 'Present': 32, 'Total': 32},
    {'Class': 'VIII', 'Present': 31, 'Total': 32},
    {'Class': 'IX', 'Present': 30, 'Total': 30},
  ];
  GestureTapCallback? get _onAddButtonTap => null;
  int getTodayDayCode() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 1;
      case DateTime.tuesday:
        return 2;
      case DateTime.wednesday:
        return 3;
      case DateTime.thursday:
        return 4;
      case DateTime.friday:
        return 5;
      case DateTime.saturday:
        return 6;
      default:
        return 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshDashboard();
  }

  @override
  void initState() {
    super.initState();
    _refreshDashboard(); // first time
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;

    if (!isLoading) {
      // back / refresh case
      setState(() => isRefreshing = true);
    }

    await loadTeacherInfo();
    await fetchDashboardData();
    await fetchTeacherHomeworks();
    await fetchTodayTimetable();

    if (!mounted) return;

    setState(() {
      isLoading = false;
      isRefreshing = false;
    });
  }

  // ---------------- TEACHER INFO ----------------
  Future<void> loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      schoolName = prefs.getString('school_name') ?? '';
      teacherPhoto = prefs.getString('teacher_photo') ?? '';
      teacherName = prefs.getString('teacher_name') ?? '';
      teacherClass = prefs.getString('teacher_class') ?? '';
      teacherSection = prefs.getString('teacher_section') ?? '';
    });
  }

  Future<void> fetchTodayTimetable() async {
    try {
      final response = await ApiService.post(
        context,
        '/teacher/timetable',
        body: {'Day': getTodayDayCode()},
      );

      if (response == null || !mounted) return;

      debugPrint('Timetable status: ${response.statusCode}');
      debugPrint('Timetable response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> result = decoded is List ? decoded : [];

        if (!mounted) return;

        setState(() {
          todayPeriods = result
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });

        debugPrint('Today periods loaded: ${todayPeriods.length}');
      } else {
        if (!mounted) return;
        setState(() => todayPeriods = []);
      }
    } catch (e) {
      debugPrint('Timetable API error: $e');
      if (!mounted) return;
      setState(() => todayPeriods = []);
    }
  }

  // ---------------- DASHBOARD DATA ----------------
  Future<void> fetchDashboardData() async {
    try {
      final response = await ApiService.post(context, '/teacher/dashboard');

      if (response == null) return;

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        students = data['students'] ?? 0;
        complaints = data['complaints'] ?? 0;
        payments = int.tryParse(data['payments'].toString()) ?? 0;
        attendance = {
          'present': data['attendances']?['present'] ?? 0,
          'absent': data['attendances']?['absent'] ?? 0,
          'leave': data['attendances']?['leave'] ?? 0,
          'half_day': data['attendances']?['half_day'] ?? 0,
          'working_days': data['attendances']?['working_days'] ?? 0,
        };
      });
    } catch (_) {
      // silent
    }
  }

  // ---------------- HOMEWORK ----------------
  Future<void> fetchTeacherHomeworks() async {
    try {
      final response = await ApiService.post(context, '/teacher/homework');

      if (response == null) return;

      final decoded = jsonDecode(response.body);
      if (decoded is List && mounted) {
        setState(() {
          homeworks = List<Map<String, dynamic>>.from(decoded);
        });
      }
    } catch (_) {
      // silent
    }
  }

  Future<void> _showLogoutDialog() async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // 1. Backend logout API
      try {
        final response = await ApiService.post(context, '/logout', body: {});

        debugPrint('Logout API response: $response');
      } catch (e) {
        debugPrint('Logout API error: $e');
      }

      // 3. Local session clear karein
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      // 4. Login screen par redirect karein
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout nahi ho paya. Dobara try karein.'),
        ),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      drawer: TeacherSidebarMenu(),

      appBar: AppBar(
        toolbarHeight: 58,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,

        automaticallyImplyLeading: false,
        titleSpacing: 0,

        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Sidebar Menu Button
              Builder(
                builder: (context) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  );
                },
              ),

              const SizedBox(width: 8),

              // School Logo
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE3EAF4), width: 1),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF1976E8),
                      size: 24,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // School Name
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      schoolName.isEmpty
                          ? 'Rose Valley Public School'
                          : schoolName,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Teacher App',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Notifications
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentAlertPage()),
                  );
                },
                tooltip: 'Notifications',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 3),

              // Teacher Avatar
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFEFF6FF),
                child: ClipOval(
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: teacherPhoto.isNotEmpty
                        ? Image.network(
                            teacherPhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                AppAssets.logo_new,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF1D4ED8),
                                  size: 23,
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            AppAssets.logo_new,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF1D4ED8),
                              size: 23,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(width: 2),

              // Logout
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Logout',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
                onPressed: _showLogoutDialog,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (isRefreshing) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 118,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3FF),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFFD4E6FC),
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/images/school_banner.jpeg',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerRight,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: const Color(0xFFE8F3FF)),
                                ),

                                // Light overlay to keep text readable
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFF0F7FF),
                                        Color(0xE6F0F7FF),
                                        Color(0x80F0F7FF),
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.43, 0.66, 1.0],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),

                                // Student details
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 10,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: 0.72,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _greeting(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF142B50),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            teacherName.isEmpty
                                                ? 'Teacher'
                                                : teacherName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF142B50),
                                              fontSize: 19,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                                  if (teacherClass.isNotEmpty)
                                                    'Class $teacherClass',
                                                  if (teacherSection.isNotEmpty)
                                                    'Section $teacherSection',
                                                ].join('  |  ').isEmpty
                                                ? 'Welcome to your student portal'
                                                : [
                                                    if (teacherClass.isNotEmpty)
                                                      'Class $teacherClass',
                                                    if (teacherSection
                                                        .isNotEmpty)
                                                      'Section $teacherSection',
                                                  ].join('  |  '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF536783),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          const Text(
                                            'Have a great learning day!',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Color(0xFF536783),
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          GridView.count(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 0,
                            childAspectRatio: 0.68,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            children: [
                              // 1. My Classes
                              _compactStat(
                                icon: Icons.groups_rounded,
                                color: const Color(0xFF2783E8),
                                label: 'My Classes',
                                value: '88',
                                detail: 'No.of classes',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TeacherTimeTablePage(),
                                    ),
                                  );
                                },
                              ),

                              // 2. Total Students
                              _compactStat(
                                icon: Icons.people_alt_rounded,
                                color: const Color(0xFF10A987),
                                label: 'Students',
                                value: '88',
                                detail: 'All students',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudentListPage(),
                                    ),
                                  );
                                },
                              ),

                              // 3. Attendance Marked
                              _compactStat(
                                icon: Icons.event_available_rounded,
                                color: const Color(0xFFFFB52E),
                                label: 'Attendance',
                                value: '899',
                                detail: 'Marked today',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AttendanceAnalyticsPage(),
                                    ),
                                  );
                                },
                              ),

                              // 4. Pending Homework
                              _compactStat(
                                icon: Icons.description_rounded,
                                color: const Color(0xFFEF476F),
                                label: 'Homeworks',
                                value: '${homeworks.length}',
                                detail: 'To review',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TeacherAddHomeworkPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Compact Quick Actions
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.035),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Quick Actions',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF172554),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Scaffold.of(context).openDrawer();
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                        ),
                                        minimumSize: const Size(40, 28),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'View All',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                GridView.count(
                                  crossAxisCount: 4,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 4,
                                  childAspectRatio: 1.12,
                                  children: [
                                    QuickAction(
                                      icon: Icons.fact_check_rounded,
                                      title: 'Attendance',
                                      color: const Color(0xFFF43F5E),
                                      page: const MarkAttendancePage(),
                                    ),
                                    QuickAction(
                                      icon: Icons.menu_book_rounded,
                                      title: 'Homework',
                                      color: const Color(0xFF1685E8),
                                      page: const TeacherAddHomeworkPage(),
                                    ),
                                    QuickAction(
                                      icon: Icons.approval_rounded,
                                      title: 'Leave',
                                      color: const Color(0xFF10B981),
                                      page: const LeaveApprovalListPage(),
                                    ),
                                    QuickAction(
                                      icon: Icons.groups_rounded,
                                      title: 'Students',
                                      color: const Color(0xFF8B5CF6),
                                      page: const StudentListPage(),
                                    ),
                                    QuickAction(
                                      icon: Icons.report_gmailerrorred_rounded,
                                      title: 'Complaint',
                                      color: const Color(0xFFF43F5E),
                                      page: TeacherComplaintListPage(),
                                    ),
                                    QuickAction(
                                      icon: Icons.payments_rounded,
                                      title: 'Payments',
                                      color: const Color(0xFF0D9488),
                                      page: const PaymentTeacherScreen(),
                                    ),
                                    QuickAction(
                                      icon: Icons.grade,
                                      title: 'Marks',
                                      color: const Color(0xFF6366F1),
                                      page: const AssignMarksPage(),
                                    ),
                                    QuickAction(
                                      icon: Icons.notifications_active_rounded,
                                      title: 'Alerts',
                                      color: AppColors.primary,
                                      page: const StudentAlertPage(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 350,
                                  child: _buildTodayTimetable(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 350,
                                  child: TodayAttendanceWidget(
                                    attendance: todayAttendance
                                        .take(4)
                                        .toList(),
                                    onMarkAll: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MarkAttendancePage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          TeacherRecentHomeworks(homeworks: homeworks),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              _bottomNavItem(
                icon: Icons.home_rounded,
                label: 'Dashboard',
                index: 0,
              ),
              _bottomNavItem(
                icon: Icons.groups_rounded,
                label: 'My Classes',
                index: 1,
              ),

              _bottomNavItem(
                icon: Icons.event_available_rounded,
                label: 'Attendance',
                index: 2,
              ),
              _bottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'More',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = _selectedBottomIndex == index;
    const Color activeColor = Color(0xFF1677F2);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (_selectedBottomIndex != index) {
            setState(() {
              _selectedBottomIndex = index;
            });
          }

          switch (index) {
            case 0:
              // Dashboard already open
              break;

            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherTimeTablePage()),
              );
              break;

            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarkAttendancePage()),
              );
              break;

            case 3:
              Scaffold.of(context).openDrawer();
              break;
          }
        },
        child: SizedBox(
          height: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 27,
                color: selected ? activeColor : const Color(0xFF7B8499),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : const Color(0xFF697386),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: selected ? 25 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayTimetable() {
    final periods = todayPeriods.take(4).toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 300),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 7, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFF0F3F8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Today's Classes",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172554),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherTimeTablePage(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      'View All ›',
                      style: TextStyle(
                        color: Color(0xFF1677F2),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: periods.isEmpty
                  ? const Center(
                      child: Text(
                        'No classes today',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  : Column(
                      children: List.generate(periods.length, (index) {
                        return Expanded(
                          child: _periodTile(
                            periods[index],
                            index: index,
                            isLast: index == periods.length - 1,
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

  Widget _periodTile(
    Map<String, dynamic> period, {
    required int index,
    required bool isLast,
  }) {
    final String slot = period['Slot']?.toString() ?? '';
    final String periodName = period['Period']?.toString() ?? '';

    final bool isLunch = slot == '2' || periodName.toUpperCase() == 'LUNCH';

    final String subject = period['Subject']?.toString().trim() ?? '';
    final String className = period['Class']?.toString() ?? '';
    final String section = period['Section']?.toString() ?? '';
    final String fromTime = period['FromTime']?.toString() ?? '--';
    final String toTime = period['ToTime']?.toString() ?? '--';

    final bool notScheduled = !isLunch && subject.isEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 29,
            child: Column(
              children: [
                Container(
                  width: 23,
                  height: 23,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? const Color(0xFF1685F8)
                        : const Color(0xFFE8EDF5),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: index == 0
                          ? Colors.white
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: const Color(0xFFE3EAF4),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                left: 3,
                right: 0,
                top: 0,
                bottom: 6,
              ),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                          color: Color(0xFFF0F3F8),
                          width: 0.7,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$fromTime - $toTime',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            height: 1.15,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLunch
                              ? 'Lunch Break'
                              : notScheduled
                              ? 'Not Scheduled'
                              : 'Class $className'
                                    '${section.isNotEmpty ? ' - $section' : ''}'
                                    ' - $subject',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: notScheduled
                                ? Colors.red
                                : const Color(0xFF172554),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8491A7),
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _compactStat({
  required IconData icon,
  required Color color,
  required String label,
  required String value,
  required String detail,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFF0F3F8), width: 0.7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact icon
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),

            const SizedBox(height: 8),

            // Label
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

            // Value
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF142B50),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 4),

            // Detail
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8A95A7), fontSize: 8),
            ),
          ],
        ),
      ),
    ),
  );
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget page;

  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 42,
              width: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayAttendanceWidget extends StatelessWidget {
  final List<Map<String, dynamic>> attendance;
  final VoidCallback? onMarkAll;

  const TodayAttendanceWidget({
    super.key,
    required this.attendance,
    this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      const Color(0xFF16B981),
      const Color(0xFF2693F7),
      const Color(0xFFFBB323),
      const Color(0xFF9747FF),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 300),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFF0F3F8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Today's Attendance",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172554),
                    ),
                  ),
                ),
                if (onMarkAll != null)
                  InkWell(
                    onTap: onMarkAll,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                      child: Text(
                        'Mark All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1677F2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 13),

            if (attendance.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No attendance data available',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              ...List.generate(attendance.length, (index) {
                final item = attendance[index];

                final String className =
                    (item['Class'] ?? item['class_name'] ?? 'Class').toString();

                final int present =
                    int.tryParse(
                      (item['Present'] ?? item['present'] ?? 0).toString(),
                    ) ??
                    0;

                final int total =
                    int.tryParse(
                      (item['Total'] ?? item['total'] ?? 0).toString(),
                    ) ??
                    0;

                final double percentage = total > 0
                    ? (present / total).clamp(0.0, 1.0)
                    : 0.0;

                final Color color = colors[index % colors.length];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == attendance.length - 1 ? 0 : 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              className.startsWith('Class ')
                                  ? className
                                  : 'Class $className',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF172554),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$present/$total',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF172554),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 9,
                          backgroundColor: const Color(0xFFE9EDF4),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(percentage * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
