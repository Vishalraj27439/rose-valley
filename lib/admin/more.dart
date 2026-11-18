import 'package:flutter/material.dart';
import 'package:rose_valley/api_service.dart';
import 'package:rose_valley/admin/AllDue/alldue.dart';
import 'package:rose_valley/admin/complaint/list_complaint.dart';
import 'package:rose_valley/admin/day%20book/day_book.dart';
import 'package:rose_valley/admin/enquiry/list_enquiry.dart';
import 'package:rose_valley/admin/income/list_income.dart';
import 'package:rose_valley/admin/ledger/stu_ledger.dart';
import 'package:rose_valley/admin/ledger/teacher_ledger.dart';
import 'package:rose_valley/admin/gatepass/list_gatepass.dart';
import 'package:rose_valley/admin/birthday.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  static const Color navy = Color(0xFF111B3C);
  static const Color muted = Color(0xFF68738B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Explore More',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your school activities in one place',
              style: TextStyle(fontSize: 11, color: muted),
            ),

            const SizedBox(height: 20),

            _sectionTitle('School Management'),

            _grid(
              [
                _MoreItem(
                  'Enquiry',
                  Icons.contact_support_rounded,
                  const Color(0xFF1479F6),
                ),
                _MoreItem(
                  'Complaints',
                  Icons.report_problem_rounded,
                  const Color(0xFFEF476F),
                ),
                _MoreItem(
                  'Gate Pass',
                  Icons.exit_to_app_rounded,
                  const Color(0xFF10B981),
                ),
                _MoreItem(
                  'Birthdays',
                  Icons.cake_rounded,
                  const Color(0xFFEC4899),
                ),
                _MoreItem(
                  'Day Book',
                  Icons.menu_book_rounded,
                  const Color(0xFF8B5CF6),
                ),
                _MoreItem(
                  'All Dues',
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFFF59E0B),
                ),
              ],
              [
                () => AdmissionEnquiryPage(),
                () => AdminComplaintList(),
                () => GatePassListPage(),
                () => null,
                () => DayBook(),
                () => AllDuePage(),
              ],
            ),

            const SizedBox(height: 22),

            _sectionTitle('Accounts & Finance'),

            _grid(
              [
                _MoreItem(
                  'Income',
                  Icons.trending_up_rounded,
                  const Color(0xFF10B981),
                ),
                _MoreItem(
                  'Student Ledger',
                  Icons.receipt_long_rounded,
                  const Color(0xFF1479F6),
                ),
                _MoreItem(
                  'Staff Ledger',
                  Icons.badge_rounded,
                  const Color(0xFF8B5CF6),
                ),
                _MoreItem(
                  'Expenses',
                  Icons.payments_rounded,
                  const Color(0xFFF59E0B),
                ),
              ],
              [
                () => IncomeExpenseList(),
                () => StudentLedgerPage(),
                () => TeacherLedgerPage(),
                () => null,
              ],
            ),

            const SizedBox(height: 22),

            _sectionTitle('Coming Soon', comingSoon: true),

            _comingSoonSection(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {bool comingSoon = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const Spacer(),
          if (comingSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: Color(0xFFB7791F),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _grid(List<_MoreItem> items, List<Widget? Function()> pages) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return _moreCard(
          item,
          onTap: () {
            final page = pages[index]();
            if (page != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            }
          },
        );
      },
    );
  }

  Widget _moreCard(_MoreItem item, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAF0F8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 39,
                width: 39,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 21),
              ),
              const SizedBox(height: 9),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comingSoonSection() {
    final features = [
      _MoreItem(
        'Transport',
        Icons.directions_bus_rounded,
        const Color(0xFF1479F6),
      ),
      _MoreItem(
        'Library',
        Icons.local_library_rounded,
        const Color(0xFF8B5CF6),
      ),
      _MoreItem('Hostel', Icons.apartment_rounded, const Color(0xFF10B981)),
      _MoreItem(
        'Timetable',
        Icons.calendar_month_rounded,
        const Color(0xFFF59E0B),
      ),
      _MoreItem(
        'Examination',
        Icons.assignment_rounded,
        const Color(0xFFEC4899),
      ),
      _MoreItem(
        'Staff Payroll',
        Icons.currency_rupee_rounded,
        const Color(0xFF0EA5E9),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = features[index];

        return Stack(
          children: [
            Positioned.fill(child: _moreCard(item, onTap: () {})),
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SOON',
                  style: TextStyle(
                    fontSize: 7,
                    color: Color(0xFFB7791F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MoreItem {
  final String title;
  final IconData icon;
  final Color color;

  _MoreItem(this.title, this.icon, this.color);
}
