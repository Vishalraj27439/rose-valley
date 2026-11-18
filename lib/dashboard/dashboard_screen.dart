import 'dart:convert';
import 'dart:io';
import 'package:rose_valley/complaint/view_complaints_page.dart';
import 'package:rose_valley/connect_teacher/connect_with_us.dart';
import 'package:rose_valley/dashboard/student_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rose_valley/dashboard/timetable_page.dart';
import 'package:rose_valley/homework/homework_detail_page.dart';
import 'package:rose_valley/homework/homework_page.dart';
import 'package:rose_valley/leave/leave_apply.dart';
import 'package:rose_valley/login_page.dart';
import 'package:rose_valley/teacher/ResultcardPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rose_valley/Attendance_UI/stu_attendance_page.dart';
import 'package:rose_valley/Attendance_UI/attendance_pie_chart.dart';
import 'package:rose_valley/Notification/notification_list.dart';
import 'package:rose_valley/dashboard/calendar.dart';
import 'package:rose_valley/dashboard/payment_screen.dart';
import 'package:rose_valley/homework/homework_model.dart';
import 'package:rose_valley/main.dart';
import 'package:rose_valley/payment/fee_details_page.dart';
import 'package:rose_valley/payment/payment_page.dart';
import 'package:rose_valley/subjects_page.dart';
import 'package:rose_valley/Attendance_UI/attendnce_box.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rose_valley/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  bool isLoading = true;
  bool isRefreshing = false;
  String studentName = '';
  String studentPhoto = '';
  String schoolName = '';
  String studentClass = '';
  String studentsection = '';
  int fine = 0;
  int dues = 0;
  int payments = 0;
  String lastPaymentDate = '';
  int subjects = 0;
  String status = '';
  Map<String, dynamic> attendance = {};
  List<Map<String, dynamic>> homeworks = [];
  List<dynamic> notices = [];
  List<dynamic> events = [];
  List<dynamic> siblings = [];
  int _selectedBottomIndex = 0;
  List<dynamic> todayTimetable = [];
  bool timetableLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void didPopNext() {
    _refreshDashboard();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  Future<void> fetchTodayTimetable() async {
    if (!mounted) return;

    setState(() => timetableLoading = true);

    try {
      final dayCode = DateTime.now().weekday;

      if (dayCode > 6) {
        setState(() {
          todayTimetable = [];
          timetableLoading = false;
        });
        return;
      }

      final response = await ApiService.post(
        context,
        '/student/timetable',
        body: {'Day': dayCode},
      );

      if (!mounted) return;

      if (response != null && response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          todayTimetable = decoded is List ? decoded : [];
        });

        debugPrint('TODAY TIMETABLE: $todayTimetable');
      }
    } catch (e) {
      debugPrint('TIMETABLE ERROR: $e');
    } finally {
      if (mounted) {
        setState(() => timetableLoading = false);
      }
    }
  }

  Future<void> _startFeePayment({required double amount}) async {
    if (!mounted) return;

    // Existing API currently accepts integer amounts.
    final int paymentAmount = amount.round();

    if (paymentAmount <= 0 || paymentAmount > dues + fine) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    try {
      final paymentData = await initiatePayment(
        beforePay: dues,
        fine: fine,
        amount: paymentAmount,
      );

      if (!mounted) return;

      if (paymentData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not initialize payment. Please try again.'),
          ),
        );
        return;
      }

      final paymentUrl = paymentData['payment_url']!;
      final refNo = paymentData['ref_no']!;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(
            paymentUrl: paymentUrl,
            successRedirectUrl: 'flutter://payment-success',
            failureRedirectUrl: 'flutter://payment-failure',
          ),
        ),
      );

      if (!mounted) return;

      if (result == 'PAYMENT_COMPLETE') {
        final finalStatus = await checkPaymentStatus(refNo: refNo);

        if (!mounted) return;

        if (finalStatus == 'success') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
          await _refreshDashboard();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment status: ${finalStatus ?? 'unknown'}. Please verify.',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled or failed.')),
        );
      }
    } catch (e) {
      debugPrint('_startFeePayment error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong during payment.')),
      );
    }
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;

    if (!isLoading) {
      setState(() => isRefreshing = true);
    }

    await loadProfileData();
    await fetchDashboardData(context);
    await fetchTodayTimetable();

    if (!mounted) return;

    setState(() {
      isLoading = false;
      isRefreshing = false;
    });
  }

  Widget _feePaymentCard() {
    final double outstanding = (dues + fine).toDouble();
    final bool hasDue = outstanding > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE4A8), width: 0.8),
      ),
      child: Row(
        children: [
          // Compact icon
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB52E).withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFFDA9200),
              size: 18,
            ),
          ),

          const SizedBox(width: 8),

          // Fee details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fee Due',
                  style: TextStyle(
                    color: Color(0xFF68758B),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDue
                      ? '₹${outstanding.toStringAsFixed(0)}'
                      : 'All Fees Paid',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF142B50),
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDue ? 'Outstanding amount' : 'No pending payment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF8A95A7), fontSize: 8),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Compact Pay Now button
          SizedBox(
            height: 29,
            child: FilledButton(
              onPressed: hasDue
                  ? () async {
                      final amount = await _showFeePaymentDialog(
                        outstandingAmount: outstanding,
                      );

                      if (!mounted || amount == null) return;

                      await _startFeePayment(amount: amount);
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF142B50),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
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

  Future<double?> _showFeePaymentDialog({
    required double outstandingAmount,
  }) async {
    final amountController = TextEditingController(
      text: outstandingAmount.toStringAsFixed(2),
    );

    double enteredAmount = outstandingAmount;
    String? errorText;

    final result = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Pay School Fees',
                style: TextStyle(
                  color: Color(0xFF142B50),
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Outstanding',
                          style: TextStyle(
                            color: Color(0xFF68758B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${outstandingAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF142B50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Enter amount to pay',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: 'Enter amount',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        enteredAmount = double.tryParse(value) ?? 0;
                        errorText = null;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payable Total',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '₹${enteredAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF142B50),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Partial payment is allowed up to the outstanding amount.',
                    style: TextStyle(color: Color(0xFF68758B), fontSize: 10),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF142B50),
                  ),
                  onPressed: () {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    if (amount == null ||
                        amount <= 0 ||
                        amount > outstandingAmount) {
                      setDialogState(() {
                        errorText =
                            'Enter an amount between ₹0.01 and ₹${outstandingAmount.toStringAsFixed(2)}';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, amount);
                  },
                  child: const Text('Proceed to Pay'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    return result;
  }

  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    studentName = prefs.getString('student_name') ?? '';
    studentPhoto = prefs.getString('student_photo') ?? '';
    schoolName = prefs.getString('school_name') ?? '';
    studentClass = prefs.getString('class_name') ?? '';
    studentsection = prefs.getString('section') ?? '';
  }

  Widget buildStudentImage(String? photo) {
    if (photo == null || photo.isEmpty) {
      return CircleAvatar(radius: 40, child: Icon(Icons.person));
    }

    return Image.network(photo, width: 80, height: 80, fit: BoxFit.cover);
  }

  Future<void> fetchDashboardData(BuildContext context) async {
    final response = await ApiService.post(context, "/student/dashboard");

    if (response == null) return;

    debugPrint("🔵 DASHBOARD STATUS: ${response.statusCode}");
    debugPrint("🔵 DASHBOARD BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint("📢 RAW NOTICES: ${data['notices']}");
      fine = data['fine'] ?? 0;
      dues = data['dues'] ?? 0;
      payments = int.tryParse(data['payments'].toString()) ?? 0;

      final rawDate = data['payment_date'] ?? '';
      if (rawDate.isNotEmpty) {
        try {
          final dateObject = DateTime.parse(rawDate);
          lastPaymentDate =
              '${dateObject.day}/${dateObject.month}/${dateObject.year}';
        } catch (_) {
          lastPaymentDate = rawDate;
        }
      }

      status = data['today_status'] ?? '';
      subjects = data['subjects'] ?? 0;

      attendance = {
        'present': data['attendances']?['present'] ?? 0,
        'absent': data['attendances']?['absent'] ?? 0,
        'leave': data['attendances']?['leave'] ?? 0,
        'half_day': data['attendances']?['half_day'] ?? 0,
        'working_days': data['attendances']?['working_days'] ?? 0,
      };

      homeworks = List<Map<String, dynamic>>.from(data['homeworks'] ?? []);
      notices = data['notices'] ?? [];
      events = data['events'] ?? [];
      siblings = data['siblings'] ?? [];

      return;
    }
  }

  void _showSiblingPopup(BuildContext context) {
    if (siblings.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Siblings'),
          content: const Text('No siblings available for this student.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.people, color: AppColors.info),
            SizedBox(width: 8),
            Text(
              'Switch Sibling',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: siblings.length,
            itemBuilder: (context, index) {
              final sibling = siblings[index];
              final photoUrl =
                  sibling['Photo'] != null &&
                      sibling['Photo'].toString().isNotEmpty
                  ? sibling['Photo'].toString()
                  : ApiService.siblingUrl;

              final name = sibling['Name'] ?? 'Unknown';
              final className = sibling['Class'].toString();

              final studentId = sibling['id'].toString();

              print('🧠 Sibling Data: $sibling');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    child: ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 26,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Class: $className'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {
                    // 🔹 Show confirmation dialog before switching
                    showDialog(
                      context: context,
                      builder: (BuildContext confirmContext) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: const Text(
                            'Confirm Switch',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            'Are you sure you want to switch to $name?',
                            style: const TextStyle(fontSize: 15),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(confirmContext),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(confirmContext);
                                Navigator.pop(context);
                                if (!mounted) return;
                                await _shiftLogin(studentId);
                              },
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Yes, Switch'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.info,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required String title,
    required VoidCallback onViewAll,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142B50).withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF142B50),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976E8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Future<void> _shiftLogin(String studentId) async {
    if (!mounted) return;
    try {
      final response = await ApiService.post(
        context,
        "/student/shift_login",
        body: {'id': studentId},
      );

      if (response == null) return;

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        await ApiService.saveSession(data);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        print('❌ Shift login failed: ${data['message']}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      print('🚨 Exception in _shiftLogin: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    }
  }

  Future<Map<String, String>?> initiatePayment({
    required int beforePay,
    required int fine,
    required int amount,
  }) async {
    try {
      final response = await ApiService.post(
        context,
        "/student/payment/initiate",
        body: {
          'beforepay': beforePay.toString(),
          'fine': fine.toString(),
          'amount': amount.toString(),
        },
      );

      if (response == null) {
        debugPrint("❌ initiatePayment: response null");
        return null;
      }
      debugPrint("📤 SENDING DATA:");
      debugPrint("beforepay: $beforePay");
      debugPrint("fine: $fine");
      debugPrint("amount: $amount");
      debugPrint("DEBUG: StatusCode → ${response.statusCode}");
      debugPrint("DEBUG: Body → ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('payment_url') && data.containsKey('ref_no')) {
          return {
            'payment_url': data['payment_url'].toString(),
            'ref_no': data['ref_no'].toString(),
          };
        } else {
          debugPrint('❌ initiatePayment: payment_url / ref_no missing');
          return null;
        }
      } else {
        debugPrint('❌ initiatePayment failed → ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint("❌ initiatePayment exception: $e");
      return null;
    }
  }

  Future<String?> checkPaymentStatus({required String refNo}) async {
    try {
      final response = await ApiService.get(
        context,
        "/student/payment/status/$refNo",
      );

      if (response == null) {
        debugPrint("❌ checkPaymentStatus: response null");
        return 'error';
      }

      debugPrint("DEBUG: StatusCode → ${response.statusCode}");
      debugPrint("DEBUG: Body → ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('status')) {
          return data['status'].toString();
        } else {
          debugPrint('❌ status key missing');
          return 'unknown';
        }
      } else {
        debugPrint('❌ checkPaymentStatus failed → ${response.statusCode}');
        return 'error';
      }
    } catch (e) {
      debugPrint("❌ checkPaymentStatus exception: $e");
      return 'error';
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildBottomNavigationBar() {
    const Color activeColor = Color(0xFF1976E8);
    const Color inactiveColor = Color(0xFF7B879D);

    final items = [
      {'label': 'Home', 'icon': Icons.home_rounded},
      {'label': 'Homework', 'icon': Icons.menu_book_outlined},
      {'label': 'Timetable', 'icon': Icons.calendar_month_rounded},
      {'label': 'Results', 'icon': Icons.bar_chart_rounded},
      {'label': 'More', 'icon': Icons.grid_view_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142B50).withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(
          top: BorderSide(color: const Color(0xFFE8EDF5), width: 0.7),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 5, 4, 2),
          child: Row(
            children: List.generate(items.length, (index) {
              final bool isSelected = _selectedBottomIndex == index;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () {
                    if (index == 4) {
                      // More - Open Drawer
                      if (!isLoading) {
                        _scaffoldKey.currentState?.openDrawer();
                      }
                      return;
                    }

                    setState(() {
                      _selectedBottomIndex = index;
                    });

                    switch (index) {
                      case 0:
                        // Home
                        break;

                      case 1:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HomeworkPage()),
                        );
                        break;

                      case 2:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TimeTablePage()),
                        );
                        break;

                      case 3:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ResultCardPage()),
                        );
                        break;
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 1,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEAF3FF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            items[index]['icon'] as IconData,
                            size: 25,
                            color: isSelected ? activeColor : inactiveColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[index]['label'] as String,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.15,
                            letterSpacing: 0.05,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? activeColor : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final present = _asInt(attendance['present']);
    final workingDays = _asInt(attendance['working_days']);
    final attendancePercent = workingDays > 0
        ? ((present / workingDays) * 100).round()
        : 0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isLoading
          ? null
          : LeftSidebarMenu(
              studentName: studentName,
              studentPhoto: studentPhoto,
              studentClass: studentClass,
              studentsection: studentsection,
            ),
      appBar: AppBar(
        toolbarHeight: 50,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8FAFF),
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE3EAF4), width: 1),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF1976E8),
                      size: 25,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolName.isEmpty ? 'Student Portal' : schoolName,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: Color(0xFF142B50),
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Student Portal',
                      style: TextStyle(color: Color(0xFF7C879B), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Notifications',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationListPage()),
                ),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF142B50),
                  size: 25,
                ),
              ),
              const SizedBox(width: 3),
              GestureDetector(
                onTap: () => _showSiblingPopup(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: const Color(0xFFE7ECF4),
                      child: ClipOval(
                        child: studentPhoto.isNotEmpty
                            ? Image.network(
                                studentPhoto,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  AppAssets.defaultAvatar,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                AppAssets.defaultAvatar,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(width: 3),

                    // Logout icon beside notifications
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Logout',
                      onPressed: _showLogoutDialog,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.danger,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                if (isRefreshing)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF1976E8),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF1976E8),
                    onRefresh: _refreshDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 7, 12, 16),
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
                                            studentName.isEmpty
                                                ? 'Student'
                                                : studentName,
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
                                                  if (studentClass.isNotEmpty)
                                                    'Class $studentClass',
                                                  if (studentsection.isNotEmpty)
                                                    'Section $studentsection',
                                                ].join('  |  ').isEmpty
                                                ? 'Welcome to your student portal'
                                                : [
                                                    if (studentClass.isNotEmpty)
                                                      'Class $studentClass',
                                                    if (studentsection
                                                        .isNotEmpty)
                                                      'Section $studentsection',
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

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Fee payment card — separate design
                              _feePaymentCard(),

                              const SizedBox(height: 10),

                              // 2. Attendance, 3. Exam, 4. Homework
                              GridView.count(
                                crossAxisCount: 4,
                                crossAxisSpacing: 7,
                                mainAxisSpacing: 7,
                                childAspectRatio: 0.73,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,

                                children: [
                                  // Attendance
                                  _compactStat(
                                    icon: Icons.calendar_month_rounded,
                                    color: const Color(0xFF2783E8),
                                    label: 'Attendance',
                                    value: '$attendancePercent%',
                                    detail:
                                        '$present/${workingDays == 0 ? '—' : workingDays} days',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TimeTablePage(),
                                        ),
                                      );
                                    },
                                  ),

                                  // Notices
                                  _compactStat(
                                    icon: Icons.campaign_rounded,
                                    color: const Color(0xFF10A987),
                                    label: 'Notices',
                                    value: '${notices.length}',
                                    detail: 'Announcements',
                                    onTap: () {
                                      // Yahan apna NoticesPage navigation add karna.
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Notices page coming soon',
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Fee Status
                                  _compactStat(
                                    icon: Icons.payments_rounded,
                                    color: const Color(0xFFFFB52E),
                                    label: 'Fee Status',
                                    value: (dues + fine) <= 0
                                        ? 'Paid'
                                        : '₹${(dues + fine).toStringAsFixed(0)}',
                                    detail: (dues + fine) <= 0
                                        ? 'All clear'
                                        : 'Tap to pay',
                                    onTap: () async {
                                      final outstanding = (dues + fine)
                                          .toDouble();

                                      if (outstanding <= 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No outstanding fees.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final amount =
                                          await _showFeePaymentDialog(
                                            outstandingAmount: outstanding,
                                          );

                                      if (!mounted || amount == null) return;

                                      await _startFeePayment(amount: amount);
                                    },
                                  ),

                                  // Homework
                                  _compactStat(
                                    icon: Icons.menu_book_rounded,
                                    color: const Color(0xFF9B5DE5),
                                    label: 'Homework',
                                    value: '${homeworks.length}',
                                    detail: 'Assignments',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HomeworkPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _compactSectionHeader(
                              'Quick Links',
                              trailing: 'View All',
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: GridView.count(
                              crossAxisCount: 5,
                              crossAxisSpacing: 6,
                              childAspectRatio: 0.78,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              children: [
                                // 1. My Class
                                _quickLink(
                                  icon: Icons.home_rounded,
                                  label: 'My Class',
                                  color: const Color(0xFFF43F5E),
                                  tint: const Color(0xFFFFEDF1),
                                  onTap: () {
                                    // Apne existing My Class page ka navigation lagayein.
                                  },
                                ),

                                // 2. Homework
                                _quickLink(
                                  icon: Icons.menu_book_rounded,
                                  label: 'Homework',
                                  color: const Color(0xFF1685E8),
                                  tint: const Color(0xFFEAF4FF),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HomeworkPage(),
                                      ),
                                    );
                                  },
                                ),

                                // 3. Exam Results
                                _quickLink(
                                  icon: Icons.fact_check_rounded,
                                  label: 'Results',
                                  color: const Color(0xFF10A987),
                                  tint: const Color(0xFFE5F8F2),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ResultCardPage(),
                                      ),
                                    );
                                  },
                                ),

                                // 4. Timetable
                                _quickLink(
                                  icon: Icons.calendar_month_rounded,
                                  label: 'Timetable',
                                  color: const Color(0xFFFF9F1C),
                                  tint: const Color(0xFFFFF4E1),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TimeTablePage(),
                                      ),
                                    );
                                  },
                                ),

                                // 5. Fee Details
                                _quickLink(
                                  icon: Icons.currency_rupee_rounded,
                                  label: 'Fee Details',
                                  color: const Color(0xFF8B5CF6),
                                  tint: const Color(0xFFF2EAFF),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const FeeDetailsPage(),
                                      ),
                                    );
                                  },
                                ),

                                // 6. Transport
                                _quickLink(
                                  icon: Icons.directions_bus_rounded,
                                  label: 'Transport',
                                  color: const Color(0xFFFF9F1C),
                                  tint: const Color(0xFFFFF4E1),
                                  onTap: () {
                                    // Apne existing Transport page ka navigation lagayein.
                                  },
                                ),

                                // 7. Leave Request
                                _quickLink(
                                  icon: Icons.description_rounded,
                                  label: 'Leave ',
                                  color: const Color(0xFF1685E8),
                                  tint: const Color(0xFFEAF4FF),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ApplyLeavePage(),
                                      ),
                                    );
                                  },
                                ),

                                // 8. Library
                                _quickLink(
                                  icon: Icons.warning,
                                  label: 'Complaints',
                                  color: const Color(0xFFF43F5E),
                                  tint: const Color(0xFFFFEDF1),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ViewComplaintPage(),
                                      ),
                                    );
                                  },
                                ),

                                // 9. Certificates
                                _quickLink(
                                  icon: Icons.workspace_premium_rounded,
                                  label: 'Certificates',
                                  color: const Color(0xFF14B8B4),
                                  tint: const Color(0xFFE5FAF9),
                                  onTap: () {
                                    // Apne existing Certificates page ka navigation lagayein.
                                  },
                                ),

                                // 10. Messages
                                _quickLink(
                                  icon: Icons.forum_rounded,
                                  label: 'Messages',
                                  color: const Color(0xFF9B5DE5),
                                  tint: const Color(0xFFF2EAFF),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ConnectWithUsPage(
                                          teacherId: 0,
                                          teacherName: '',
                                          teacherPhoto: '',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LEFT: Today's Timetable
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 72,
                                    maxHeight: 240,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              "Today's Timetable",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF142B50),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      TimeTablePage(),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View All',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF2783E8),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      timetableLoading
                                          ? const Expanded(
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: AppColors.primary,
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : Expanded(
                                              child: _buildCompactTimetableList(
                                                todayTimetable,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // RIGHT: Today's Homework
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 72,
                                    maxHeight: 240,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              "Homeworks",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF142B50),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      HomeworkPage(),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View All',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF2783E8),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      homeworks.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 20,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'No homework available',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : _buildCompactHomeworkList(
                                              homeworks,
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            height: 180,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildAnnouncementCard(
                                    title: 'Announcement',
                                    onViewAll: () {
                                      // Open your complete notices page
                                    },
                                    child: NoticesEventsToggle(
                                      initialNotices: notices,
                                      initialEvents: const [],
                                      showNoticesOnly: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildAnnouncementCard(
                                    title: 'Events',
                                    onViewAll: () {
                                      // Open your complete events page
                                    },
                                    child: NoticesEventsToggle(
                                      initialNotices: const [],
                                      initialEvents: events,
                                      showEventsOnly: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

Widget _buildCompactTimetableList(List<dynamic> timetable) {
  final periods = timetable.take(4).toList();

  if (periods.isEmpty) {
    return const Center(
      child: Text(
        'No classes scheduled today',
        style: TextStyle(fontSize: 11, color: Color(0xFF7B879B)),
      ),
    );
  }
  return Column(
    children: List.generate(periods.length, (index) {
      final item = Map<String, dynamic>.from(periods[index] as Map);

      final String fromTime = item['FromTime']?.toString() ?? '--';
      final String toTime = item['ToTime']?.toString() ?? '--';

      final String periodName = item['Period']?.toString() ?? '';
      final String subject = item['Subject']?.toString().trim() ?? '';
      final String className = item['Class']?.toString() ?? '';
      final String section = item['Section']?.toString() ?? '';
      final String slot = item['Slot']?.toString() ?? '';

      final bool isLunch = slot == '2' || periodName.toUpperCase() == 'LUNCH';

      final bool notScheduled = !isLunch && subject.isEmpty;

      // If the API provides an explicit status, use it.
      final String apiStatus = (item['Status'] ?? item['status'] ?? '')
          .toString()
          .toLowerCase();

      final bool isOngoing =
          apiStatus == 'ongoing' || apiStatus == 'in progress';

      final String displaySubject = isLunch
          ? 'Lunch Break'
          : notScheduled
          ? 'Not Scheduled'
          : 'Class $className'
                '${section.isNotEmpty ? ' - $section' : ''}'
                ' - $subject';

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      height: 26,
                      width: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isOngoing || index == 0
                            ? const Color(0xFF2783E8)
                            : const Color(0xFFE8EDF5),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isOngoing || index == 0
                              ? Colors.white
                              : const Color(0xFF142B50),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$fromTime - $toTime',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF7B879B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displaySubject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: notScheduled
                            ? Colors.red
                            : const Color(0xFF142B50),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isOngoing) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F7EE),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Ongoing',
                          style: TextStyle(
                            fontSize: 8,
                            color: Color(0xFF10A987),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

Widget _buildCompactHomeworkList(List<dynamic> homeworks) {
  if (homeworks.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No homework available',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    itemCount: homeworks.length > 4 ? 4 : homeworks.length,
    separatorBuilder: (_, __) =>
        const Divider(height: 1, color: Color(0xFFF0F3F8), indent: 44),
    itemBuilder: (context, index) {
      final homework = Map<String, dynamic>.from(homeworks[index] as Map);

      final title = homework['HomeworkTitle']?.toString() ?? '';

      final workDate = homework['WorkDate']?.toString() ?? '';

      final submissionDate = homework['SubmissionDate']?.toString() ?? '';

      final remark = homework['Remark']?.toString() ?? '';

      final attachment = homework['Attachment'];

      final Color itemColor = [
        const Color(0xFF9B5DE5),
        const Color(0xFFF43F5E),
        const Color(0xFF10A987),
        const Color(0xFFFF9F1C),
      ][index % 4];

      String formatDate(String value) {
        if (value.isEmpty || value == '--') return '--';
        try {
          return DateFormat('dd MMM yyyy').format(DateTime.parse(value));
        } catch (_) {
          return value;
        }
      }

      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomeworkDetailPage(
                homework: Map<String, dynamic>.from(homework as Map),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: itemColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full Homework Title
                    Text(
                      title.isEmpty ? 'Untitled Homework' : title,
                      softWrap: true,
                      style: const TextStyle(
                        color: Color(0xFF142B50),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Work Date
                    Text(
                      'Work: ${formatDate(workDate)}',
                      softWrap: true,
                      style: const TextStyle(
                        color: Color(0xFF7B879B),
                        fontSize: 9,
                      ),
                    ),

                    // Full Remark
                    if (remark.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        remark,
                        softWrap: true,
                        style: const TextStyle(
                          color: Color(0xFF7B879B),
                          fontSize: 9,
                        ),
                      ),
                    ],

                    // Submission Date
                    if (submissionDate.isNotEmpty)
                      Text(
                        'Submit: ${formatDate(submissionDate)}',
                        softWrap: true,
                        style: const TextStyle(
                          color: Color(0xFF2783E8),
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: Color(0xFF8792A5),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _compactSectionHeader(String title, {String? trailing}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF142B50),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing,
          style: const TextStyle(
            color: Color(0xFF2783E8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
    ],
  );
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

Widget _quickLink({
  required IconData icon,
  required String label,
  required Color color,
  required Color tint,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 43,
            width: 48,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF35445E),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class DashboardSummaryCard extends StatelessWidget {
  final int feeDue;
  final int siblingDue;
  final int payments;
  final int subjects;
  final String lastPaymentDate;

  final VoidCallback onPayNowTap;

  const DashboardSummaryCard({
    super.key,
    required this.feeDue,
    required this.siblingDue,
    required this.payments,
    required this.subjects,
    required this.lastPaymentDate,
    required this.onPayNowTap,
  });
  String get greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  Widget _item({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    String? subtitle,
    required Widget page,

    bool showPayButton = false,
    VoidCallback? onPayNow,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(height: 6),

              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),

              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              if (showPayButton) ...[
                const SizedBox(height: 6),

                SizedBox(
                  height: 24,
                  width: 70,
                  child: ElevatedButton(
                    onPressed: onPayNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      "PAY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat("EEE, dd MMM yyyy").format(DateTime.now());
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142B50).withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF142B50), Color(0xFF254873)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$greeting 👋",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(.16),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      today,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Outstanding fee',
                            style: TextStyle(
                              color: Colors.white.withOpacity(.78),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹$feeDue',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (siblingDue > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                'Fine: ₹$siblingDue',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (feeDue + siblingDue > 0)
                      ElevatedButton.icon(
                        onPressed: onPayNowTap,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Pay now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF142B50),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
            child: Row(
              children: [
                _item(
                  context: context,
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFFD64B4B),
                  title: 'Fee details',
                  value: '₹$feeDue',
                  subtitle: 'Due amount',
                  page: const FeeDetailsPage(),
                ),
                Container(height: 64, width: 1, color: const Color(0xFFE8ECF2)),
                _item(
                  context: context,
                  icon: Icons.payments_outlined,
                  color: const Color(0xFF168568),
                  title: 'Payments',
                  value: payments.toString(),
                  subtitle: lastPaymentDate.isEmpty
                      ? 'Total payments'
                      : lastPaymentDate,
                  page: PaymentPage(),
                ),
                Container(height: 64, width: 1, color: const Color(0xFFE8ECF2)),
                _item(
                  context: context,
                  icon: Icons.menu_book_outlined,
                  color: const Color(0xFF3867B7),
                  title: 'Subjects',
                  value: subjects.toString(),
                  subtitle: 'Available',
                  page: SubjectsPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isEvent;

  const InfoCard({super.key, required this.item, required this.isEvent});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open attachment link.')),
      );
    }
  }

  Future<void> _downloadFile(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Attachment not available")));
      return;
    }

    try {
      final fileName = url.split('/').last;
      late File file;

      // 🔽 DIRECT HTTP (S3 public file)
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        file = File('${downloadsDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // ✅ PREVIEW
        await OpenFile.open(file.path);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📥 Downloaded & Preview opened")),
        );
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // ✅ PREVIEW
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleKey = isEvent ? "EventTitle" : "NoticeTitle";
    String formatDate(String? inputDate) {
      if (inputDate == null || inputDate.isEmpty) return '';
      try {
        final date = DateTime.parse(inputDate);
        return DateFormat('dd-MM-yyyy').format(date);
      } catch (e) {
        return inputDate;
      }
    }

    final Color primaryColor = isEvent
        ? Colors.orange.shade700
        : Colors.indigo.shade700;
    final Color lightColor = isEvent
        ? Colors.orange.shade50
        : Colors.indigo.shade50;

    final String? attachment = item["Attachment"];
    final String schoolId = item["SchoolId"]?.toString() ?? '';
    final bool hasAttachment =
        attachment != null && attachment.isNotEmpty && schoolId.isNotEmpty;
    final String fullAttachmentUrl = hasAttachment ? attachment.toString() : '';

    debugPrint("📎 NOTICE ATTACHMENT URL: $fullAttachmentUrl");

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryColor, width: 1.5),
      ),
      color: lightColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item[titleKey] ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatDate(item["Date"] ?? 'N/A'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const Divider(height: 16),

            Text(
              item["Description"] ?? 'No description provided.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            if (hasAttachment) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text("View Attachment"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    onPressed: () => _launchUrl(context, fullAttachmentUrl),
                  ),

                  const SizedBox(width: 25),

                  IconButton(
                    onPressed: () => _downloadFile(context, fullAttachmentUrl),
                    icon: Icon(Icons.download, color: primaryColor, size: 24),
                    tooltip: 'Download Attachment',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoticesEventsToggle extends StatelessWidget {
  final List<dynamic> initialNotices;
  final List<dynamic> initialEvents;
  final bool showNoticesOnly;
  final bool showEventsOnly;

  const NoticesEventsToggle({
    super.key,
    required this.initialNotices,
    required this.initialEvents,
    this.showNoticesOnly = false,
    this.showEventsOnly = false,
  });
  Widget _buildList(List<dynamic> data, {required bool isEvent}) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          isEvent ? 'No upcoming events.' : 'No new notices posted.',
          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index] as Map<String, dynamic>;
        return InfoCard(item: item, isEvent: isEvent);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showNoticesOnly) {
      return _buildList(initialNotices, isEvent: false);
    }

    if (showEventsOnly) {
      return _buildList(initialEvents, isEvent: true);
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.primary,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Notices'),
                  Tab(text: 'Events'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(initialNotices, isEvent: false),
                _buildList(initialEvents, isEvent: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
