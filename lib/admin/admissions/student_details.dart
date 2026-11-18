import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rose_valley/admin/admissions/quick_admission.dart';
import 'package:rose_valley/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDetailsPage extends StatefulWidget {
  final int id;
  final String name;
  final String ledger;
  final String father;
  final String classText;
  final String section;
  final String mobile;
  final String photo;
  final Color color;

  // Additional details can be passed later from the API.
  final String mother;
  final String admissionNo;
  final String rollNo;
  final String dob;
  final String gender;
  final String bloodGroup;
  final String address;
  final String email;
  final String status;

  const StudentDetailsPage({
    super.key,
    required this.id,
    required this.name,
    required this.ledger,
    required this.father,
    required this.classText,
    required this.section,
    required this.mobile,
    required this.photo,
    required this.color,
    this.mother = '',
    this.admissionNo = '',
    this.rollNo = '',
    this.dob = '',
    this.gender = '',
    this.bloodGroup = '',
    this.address = '',
    this.email = '',
    this.status = 'Active',
  });

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  int selectedTab = 0;

  static const Color muted = Color(0xFF718096);
  static const Color pageBg = Color(0xFFF4F7FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Student Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Student',
            onPressed: _openEditStudent,
            icon: const Icon(Icons.edit_outlined, size: 22),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copy') {
                Clipboard.setData(ClipboardData(text: widget.mobile));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mobile number copied')),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'copy', child: Text('Copy mobile number')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          children: [
            _buildProfileCard(),
            const SizedBox(height: 14),
            _buildContactActions(),
            const SizedBox(height: 18),
            _buildTabs(),
            const SizedBox(height: 14),
            _buildSelectedTab(),
            const SizedBox(height: 14),
            _buildMoreActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact student photo
              Container(
                height: 76,
                width: 66,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.photo.isNotEmpty
                    ? Image.network(
                        widget.photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _studentPlaceholder(30),
                      )
                    : _studentPlaceholder(30),
              ),
              const SizedBox(width: 10),

              // Student details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _statusBadge(),
                      ],
                    ),

                    if (widget.father.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.father,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: muted, fontSize: 10.5),
                      ),
                    ],

                    const SizedBox(height: 7),

                    _profileInfo(
                      'Admission No.',
                      widget.admissionNo.isEmpty ? '—' : widget.admissionNo,
                    ),
                    const SizedBox(height: 4),

                    _profileInfo(
                      'Class & Section',
                      '${widget.classText} (${widget.section})',
                    ),
                    const SizedBox(height: 4),

                    _profileInfo(
                      'Roll No.',
                      widget.rollNo.isEmpty ? '—' : widget.rollNo,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          // Compact ledger row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Ledger',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                Flexible(
                  child: Text(
                    widget.ledger.isEmpty ? '—' : widget.ledger,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Color(0xFF159568),
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentPlaceholder(double size) {
    return Center(
      child: Icon(Icons.person_rounded, color: widget.color, size: size),
    );
  }

  Widget _statusBadge() {
    final active = widget.status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE5F8EC) : const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: active ? const Color(0xFF16A34A) : Colors.red,
          ),
          const SizedBox(width: 5),
          Text(
            widget.status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF15803D) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: muted),
          ),
        ),
        const Text(': ', style: TextStyle(color: muted, fontSize: 11)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildContactActions() {
    return Row(
      children: [
        _contactButton(
          icon: Icons.call_rounded,
          label: 'Call',
          color: const Color(0xFF16A765),
          background: const Color(0xFFE5F8EE),
          onTap: _launchPhone,
        ),
        const SizedBox(width: 8),
        _contactButton(
          icon: Icons.chat_rounded,
          label: 'WhatsApp',
          color: const Color(0xFF20A65A),
          background: const Color(0xFFE5F8EB),
          onTap: _launchWhatsApp,
        ),
        const SizedBox(width: 8),
        _contactButton(
          icon: Icons.sms_rounded,
          label: 'Message',
          color: const Color(0xFFE74778),
          background: const Color(0xFFFFE8F0),
          onTap: _launchSms,
        ),
        const SizedBox(width: 8),
        _contactButton(
          icon: Icons.more_horiz_rounded,
          label: 'More',
          color: const Color(0xFF8254D8),
          background: const Color(0xFFF0E9FF),
          onTap: _showMoreContactOptions,
        ),
      ],
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: background,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF26334D),
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

  Widget _buildTabs() {
    const tabs = ['Personal Info', 'Academic', 'Fee Details', 'Documents'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (selectedTab) {
      case 0:
        return _buildPersonalInfo();
      case 1:
        return _buildAcademicInfo();
      case 2:
        return _buildFeeInfo();
      case 3:
        return _buildDocuments();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: iconColor),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2876DB),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(':', style: TextStyle(color: muted)),
          ),
          Expanded(
            flex: 7,
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _sectionCard(
      title: 'Personal Information',
      icon: Icons.people_alt_rounded,
      iconColor: AppColors.primary,
      onEdit: _openEditStudent,
      children: [
        _detailRow('Student Name', widget.name),
        _detailRow("Father's Name", widget.father),
        _detailRow("Mother's Name", widget.mother),
        _detailRow('Admission No.', widget.admissionNo),
        _detailRow('Date of Birth', widget.dob),
        _detailRow('Gender', widget.gender),
        _detailRow('Blood Group', widget.bloodGroup),
        _detailRow('Mobile No.', widget.mobile),
        _detailRow('Email', widget.email),
        _detailRow('Address', widget.address),
      ],
    );
  }

  Widget _buildAcademicInfo() {
    return _sectionCard(
      title: 'Academic Information',
      icon: Icons.school_rounded,
      iconColor: const Color(0xFF2876DB),
      children: [
        _detailRow('Student ID', widget.id.toString()),
        _detailRow('Admission No.', widget.admissionNo),
        _detailRow('Class', widget.classText),
        _detailRow('Section', widget.section),
        _detailRow('Roll Number', widget.rollNo),
        _detailRow('Academic Status', widget.status),
      ],
    );
  }

  Widget _buildFeeInfo() {
    return _sectionCard(
      title: 'Fee Details',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: const Color(0xFF159568),
      children: [
        _detailRow('Ledger', widget.ledger),
        const SizedBox(height: 8),
        const Text(
          'Connect the fee summary and payment history API here '
          'to display actual fees, paid amount and outstanding balance.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDocuments() {
    return _sectionCard(
      title: 'Student Documents',
      icon: Icons.folder_copy_rounded,
      iconColor: const Color(0xFF8656D9),
      children: [
        _documentTile(Icons.badge_outlined, 'Student ID / Admission Form'),
        _documentTile(Icons.description_outlined, 'Birth Certificate'),
        _documentTile(Icons.folder_shared_outlined, 'Other Documents'),
        const SizedBox(height: 6),
        const Text(
          'Connect your documents API to load and open uploaded files.',
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _documentTile(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: AppColors.primary, size: 23),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: muted),
      onTap: () {
        // Open the corresponding document when its URL is available.
      },
    );
  }

  Widget _buildMoreActions() {
    final actions = [
      (
        Icons.receipt_long_rounded,
        'View Fees',
        const Color(0xFF21B573),
        const Color(0xFFE7F8EF),
      ),
      (
        Icons.fact_check_rounded,
        'Attendance',
        const Color(0xFF2876DB),
        const Color(0xFFE8F1FF),
      ),
      (
        Icons.assignment_rounded,
        'Results',
        const Color(0xFFED962D),
        const Color(0xFFFFF3E1),
      ),
      (
        Icons.folder_copy_rounded,
        'Documents',
        const Color(0xFF8656D9),
        const Color(0xFFF0E9FF),
      ),
      (
        Icons.description_rounded,
        'TC / Transfer',
        const Color(0xFFEC4778),
        const Color(0xFFFFEAF1),
      ),
      (
        Icons.edit_note_rounded,
        'Edit Details',
        const Color(0xFF159FA8),
        const Color(0xFFE3F8FA),
      ),
      (
        Icons.print_rounded,
        'Print Profile',
        const Color(0xFFED962D),
        const Color(0xFFFFF3E1),
      ),
      (
        Icons.delete_outline_rounded,
        'Delete',
        const Color(0xFFE5484D),
        const Color(0xFFFFEAEA),
      ),
    ];

    return _sectionCard(
      title: 'More Actions',
      icon: Icons.dashboard_customize_rounded,
      iconColor: const Color(0xFF2876DB),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final item = actions[index];

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                switch (item.$2) {
                  case 'View Fees':
                    setState(() => selectedTab = 2);
                    break;
                  case 'Documents':
                    setState(() => selectedTab = 3);
                    break;
                  case 'Edit Details':
                    _openEditStudent();
                    break;
                  case 'Delete':
                    _confirmDelete();
                    break;
                  default:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${item.$2}: connect your page or API here.',
                        ),
                      ),
                    );
                }
              },
              child: Column(
                children: [
                  Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: item.$4,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.$1, color: item.$3, size: 25),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showMoreContactOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy mobile number'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.mobile));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email student / parent'),
              onTap: () {
                Navigator.pop(context);
                _launchEmail();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone() async {
    await _openUri('tel:${widget.mobile}');
  }

  Future<void> _launchSms() async {
    await _openUri('sms:${widget.mobile}');
  }

  Future<void> _launchWhatsApp() async {
    final phone = widget.mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    await _openUri('https://wa.me/${phone.replaceAll('+', '')}');
  }

  Future<void> _launchEmail() async {
    if (widget.email.isEmpty) {
      _showMessage('Email address is not available.');
      return;
    }
    await _openUri('mailto:${widget.email}');
  }

  Future<void> _openEditStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuickAdmissionPage(studentId: widget.id),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _openUri(String value) async {
    final uri = Uri.parse(value);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showMessage('Could not open this application.');
      }
    } catch (_) {
      _showMessage('Could not open this application.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text(
          'Do you want to delete ${widget.name}? '
          'This action needs to be connected to your delete API.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFEDF1F7)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF172B4D).withOpacity(0.035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
