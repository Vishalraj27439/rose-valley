import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rose_valley/admin/helper.dart';
import 'package:rose_valley/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FeeDuePage extends StatefulWidget {
  const FeeDuePage({super.key});

  @override
  State<FeeDuePage> createState() => _FeeDuePageState();
}

class _FeeDuePageState extends State<FeeDuePage> {
  List<Map<String, dynamic>> classList = [];
  List<Map<String, dynamic>> sectionList = [];
  List<dynamic> studentList = [];

  bool loadingClass = false;
  bool loadingSection = false;
  bool isLoading = false;

  String selectedClass = 'All';
  String selectedSection = 'All';

  int? selectedClassId;
  int? selectedSectionId;
  int totalStudents = 0;
  double totalDueAmount = 0;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  List<dynamic> get filteredStudents {
    if (searchQuery.trim().isEmpty) return studentList;

    final query = searchQuery.toLowerCase().trim();

    return studentList.where((student) {
      final name = (student['StudentName'] ?? '').toString().toLowerCase();
      final father = (student['FatherName'] ?? '').toString().toLowerCase();
      final mobile = (student['ContactNo'] ?? '').toString().toLowerCase();
      final className = (student['Class'] ?? '').toString().toLowerCase();
      final section = (student['Section'] ?? '').toString().toLowerCase();

      return name.contains(query) ||
          father.contains(query) ||
          mobile.contains(query) ||
          className.contains(query) ||
          section.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _callStudent(String mobile) async {
    final number = mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: number);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsappStudent(String mobile, String name, String due) async {
    try {
      String number = mobile.replaceAll(RegExp(r'\D'), '');

      // Remove leading 0
      if (number.startsWith('0') && number.length == 11) {
        number = number.substring(1);
      }

      // Add India country code
      if (number.length == 10) {
        number = '91$number';
      }

      // Validate Indian mobile number
      if (number.length != 12 || !number.startsWith('91')) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid mobile number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final message =
          'Dear Parent,\n\n'
          'Fee payment of $name is pending.\n'
          'Outstanding Amount: Rs. $due\n\n'
          'Kindly clear the pending dues. Thank you.';

      final uri = Uri.https('wa.me', '/$number', {'text': message});

      // Direct launch, no canLaunchUrl check
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('WhatsApp Error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WhatsApp Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareStudentPdf(Map<String, dynamic> student) async {
    final pdf = pw.Document();

    final name = (student['StudentName'] ?? '').toString();
    final father = (student['FatherName'] ?? '').toString();
    final className = (student['Class'] ?? '').toString();
    final section = (student['Section'] ?? '').toString();
    final mobile = (student['ContactNo'] ?? '').toString();
    final due = (student['Due'] ?? '0').toString();

    final dueAmount = double.tryParse(due.replaceAll(',', '')) ?? 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'STUDENT FEE DUE REPORT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Divider(),

              pw.SizedBox(height: 20),

              pw.Text(
                'Student Details',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 15),

              _pdfDetail('Student Name', name),
              _pdfDetail('Father Name', father),
              _pdfDetail('Class / Section', '$className / $section'),
              _pdfDetail('Mobile Number', mobile),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 15),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Pending Fee Amount',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Rs. ${dueAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              pw.Divider(),

              pw.Center(
                child: pw.Text(
                  'Please clear the pending fee at the earliest.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Fee_Due_${name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf',
    );
  }

  pw.Widget _pdfDetail(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '-' : value,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateStudentPdf(Map<String, dynamic> student) async {
    final pdf = pw.Document();

    final name = (student['StudentName'] ?? '').toString();
    final father = (student['FatherName'] ?? '').toString();
    final className = (student['Class'] ?? '').toString();
    final section = (student['Section'] ?? '').toString();
    final mobile = (student['ContactNo'] ?? '').toString();
    final due = (student['Due'] ?? '0').toString();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'STUDENT FEE DUE REPORT',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text('Student Name: $name'),
              pw.SizedBox(height: 8),
              pw.Text('Father Name: $father'),
              pw.SizedBox(height: 8),
              pw.Text('Class: $className / $section'),
              pw.SizedBox(height: 8),
              pw.Text('Mobile: $mobile'),
              pw.SizedBox(height: 18),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text(
                'Outstanding Fee: Rs. $due',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  void initState() {
    super.initState();
    fetchClasses();
    fetchFeeDue();
  }

  Future<void> fetchClasses() async {
    setState(() => loadingClass = true);

    final res = await ApiService.post(context, "/get_class");

    if (!mounted) return;

    if (res != null && res.statusCode == 200) {
      classList = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }

    setState(() {
      selectedClass = 'All';
      selectedSection = 'All';
      selectedClassId = null;
      selectedSectionId = null;
      sectionList.clear();
      loadingClass = false;
    });
  }

  Future<void> fetchSections(int classId) async {
    setState(() {
      loadingSection = true;
      sectionList.clear();
      selectedSection = 'All';
      selectedSectionId = null;
    });

    final res = await ApiService.post(
      context,
      "/get_section",
      body: {"ClassId": classId},
    );

    if (!mounted) return;

    if (res != null && res.statusCode == 200) {
      sectionList = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }

    setState(() {
      selectedSection = 'All';
      selectedSectionId = null;
      loadingSection = false;
    });
  }

  Future<void> fetchFeeDue() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(
      context,
      "/admin/student/due",
      body: {
        "Class": selectedClassId?.toString() ?? "",
        "Section": selectedSectionId?.toString() ?? "",
      },
    );

    if (!mounted) return;

    if (response != null && response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);

      // Count all students
      final int studentCount = decoded.length;

      // Add all students' due amount
      final double dueTotal = decoded.fold<double>(0, (sum, student) {
        final due =
            double.tryParse(student['Due'].toString().replaceAll(',', '')) ?? 0;

        return sum + due;
      });

      // Show only students having pending dues
      final dueStudentList = decoded.where((student) {
        final due =
            double.tryParse(student['Due'].toString().replaceAll(',', '')) ?? 0;

        return due > 0;
      }).toList();

      setState(() {
        totalStudents = studentCount;
        totalDueAmount = dueTotal;
        studentList = dueStudentList;
        isLoading = false;
      });
    } else {
      setState(() {
        totalStudents = 0;
        totalDueAmount = 0;
        studentList = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Student Fees Dues',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                _summaryCard(
                  icon: Icons.groups_rounded,
                  title: 'Total Students',
                  value: totalStudents.toString(),
                  color: const Color(0xff2563EB),
                  background: const Color(0xffEFF6FF),
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Total Due',
                  value: '₹${totalDueAmount.toStringAsFixed(0)}',
                  color: const Color(0xffE11D48),
                  background: const Color(0xffFFF1F3),
                ),
              ],
            ),
          ),

          /// FILTER SECTION
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _iconDropdownField(
                    icon: Icons.class_,
                    value: selectedClass,
                    items: [
                      'All',
                      ...classList.map((e) => e['Class'].toString()),
                    ],
                    onChanged: (value) async {
                      if (value == 'All') {
                        setState(() {
                          selectedClass = 'All';
                          selectedClassId = null;

                          selectedSection = 'All';
                          selectedSectionId = null;
                          sectionList.clear();
                        });

                        fetchFeeDue();
                        return;
                      }

                      final cls = classList.firstWhere(
                        (e) => e['Class'].toString() == value,
                      );

                      final classId = int.parse(cls['id'].toString());

                      setState(() {
                        selectedClass = value;
                        selectedClassId = classId;

                        selectedSection = 'All';
                        selectedSectionId = null;
                      });

                      await fetchSections(classId);
                      await fetchFeeDue();
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _iconDropdownField(
                    icon: Icons.group,
                    value: selectedSection,
                    items: [
                      'All',
                      if (selectedClassId != null)
                        ...sectionList.map((e) => e['SectionName'].toString()),
                    ],
                    onChanged: (value) {
                      if (value == 'All') {
                        setState(() {
                          selectedSection = 'All';
                          selectedSectionId = null;
                        });

                        fetchFeeDue();
                        return;
                      }

                      final sec = sectionList.firstWhere(
                        (e) => e['SectionName'].toString() == value,
                      );

                      setState(() {
                        selectedSection = value;
                        selectedSectionId = int.parse(sec['id'].toString());
                      });

                      fetchFeeDue();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xffE5EAF2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.025),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xff64748B),
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search name, father name or mobile...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xff94A3B8),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        searchController.clear();
                        setState(() => searchQuery = '');
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: Color(0xff64748B),
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStudents.isEmpty
                ? const Center(
                    child: Text(
                      'No Data Found',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = Map<String, dynamic>.from(
                        filteredStudents[index],
                      );

                      return FeeCard(
                        index: index + 1,
                        name: (student['StudentName'] ?? '').toString(),
                        father: (student['FatherName'] ?? '').toString(),
                        classSec:
                            '${student['Class'] ?? ''} / ${student['Section'] ?? ''}',
                        mobile: (student['ContactNo'] ?? '').toString(),
                        due: (student['Due'] ?? '0').toString(),
                        photo: (student['Photo'] ?? '').toString(),
                        onCall: () => _callStudent(
                          (student['ContactNo'] ?? '').toString(),
                        ),
                        onWhatsApp: () => _whatsappStudent(
                          (student['ContactNo'] ?? '').toString(),
                          (student['StudentName'] ?? '').toString(),
                          (student['Due'] ?? '0').toString(),
                        ),
                        onPdf: () => _generateStudentPdf(student),

                        onSharePdf: () => _shareStudentPdf(student),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Expanded(
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
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

  Widget _iconDropdownField({
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),

          Expanded(
            child: AnchoredDropdown(
              value: value,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class FeeCard extends StatelessWidget {
  final int index;
  final String name;
  final String father;
  final String classSec;
  final String mobile;
  final String due;
  final String photo;

  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onPdf;
  final VoidCallback onSharePdf;

  const FeeCard({
    super.key,
    required this.index,
    required this.name,
    required this.father,
    required this.classSec,
    required this.mobile,
    required this.due,
    required this.photo,
    required this.onCall,
    required this.onWhatsApp,
    required this.onPdf,
    required this.onSharePdf,
  });

  @override
  Widget build(BuildContext context) {
    final dueAmount = double.tryParse(due.replaceAll(',', '')) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffEDF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Student Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              height: 36,
              width: 36,
              color: const Color(0xffEFF6FF),
              child: photo.isNotEmpty
                  ? Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 23,
                        color: Color(0xff64748B),
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      size: 23,
                      color: Color(0xff64748B),
                    ),
            ),
          ),

          const SizedBox(width: 7),

          // Student Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ROW 1: Student Name + Father Name
                RichText(
                  softWrap: true,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.15,
                      color: Color(0xff172033),
                    ),
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (father.isNotEmpty)
                        TextSpan(
                          text: ' ($father)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff64748B),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 1),

                // ROW 2: Mobile + Actions
                Row(
                  children: [
                    const Icon(
                      Icons.call_rounded,
                      size: 13,
                      color: Color(0xff16A34A),
                    ),
                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        mobile,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xff64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    _actionButton(
                      icon: Icons.call_rounded,
                      color: const Color(0xff0875DB),
                      background: const Color(0xffEAF4FF),
                      onTap: onCall,
                    ),

                    const SizedBox(width: 8),

                    _actionButton(
                      icon: Icons.chat,
                      color: const Color(0xff16A34A),
                      background: const Color(0xffE9F9EF),
                      onTap: onWhatsApp,
                    ),

                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                      iconSize: 18,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xff64748B),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (value) {
                        if (value == 'download') {
                          onPdf();
                        } else if (value == 'share') {
                          onSharePdf();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'download',
                          height: 38,
                          child: Row(
                            children: [
                              Icon(
                                Icons.download_rounded,
                                size: 17,
                                color: Color(0xff2563EB),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Download PDF',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          height: 38,
                          child: Row(
                            children: [
                              Icon(
                                Icons.share_rounded,
                                size: 17,
                                color: Color(0xff16A34A),
                              ),
                              SizedBox(width: 8),
                              Text('Share PDF', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 1),

                // ROW 3: Class + Due Amount
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            size: 13,
                            color: Color(0xff64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              classSec,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      'Due: ₹${dueAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xffDC2626),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: color.withOpacity(0.15),
        child: Ink(
          height: 27,
          width: 27,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.15), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}
