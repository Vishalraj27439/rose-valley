import 'dart:convert';
import 'package:rose_valley/admin/admissions/stu_model.dart';
import 'package:flutter/material.dart';
import 'package:rose_valley/admin/admissions/quick_admission.dart';
import 'package:rose_valley/admin/admissions/student_details.dart';
import 'package:rose_valley/api_service.dart';

class AdmissionListPage extends StatefulWidget {
  const AdmissionListPage({super.key});

  @override
  State<AdmissionListPage> createState() => _AdmissionListPageState();
}

class _AdmissionListPageState extends State<AdmissionListPage> {
  bool isLoading = true;

  List<StudentModel> students = [];
  List<StudentModel> filteredStudents = [];

  final TextEditingController searchCtrl = TextEditingController();
  String selectedClass = 'All';

  List<String> get availableClasses {
    final classes = students
        .map((s) => s.className.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    const order = [
      'nursery',
      'lkg',
      'ukg',
      'first',
      'second',
      'third',
      'fourth',
      'fifth',
      'sixth',
      'seventh',
      'eighth',
      'ninth',
      'tenth',
      'eleventh',
      'twelfth',
    ];

    classes.sort((a, b) {
      final ai = order.indexOf(a.toLowerCase());
      final bi = order.indexOf(b.toLowerCase());

      if (ai == -1 && bi == -1) {
        return a.compareTo(b);
      }
      if (ai == -1) return 1;
      if (bi == -1) return -1;

      return ai.compareTo(bi);
    });

    return ['All', ...classes];
  }

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      FocusScope.of(context).unfocus();
    }

    _applyFilters();
  }

  void _applyFilters() {
    List<StudentModel> result = List.from(students);

    if (selectedClass != 'All') {
      result = result
          .where(
            (s) =>
                s.className.trim().toLowerCase() == selectedClass.toLowerCase(),
          )
          .toList();
    }

    final q = searchCtrl.text.trim().toLowerCase();

    if (q.isNotEmpty) {
      result = result
          .where(
            (s) =>
                s.studentName.toLowerCase().contains(q) ||
                s.fatherName.toLowerCase().contains(q) ||
                s.contactNo.toLowerCase().contains(q) ||
                s.ledgerNo.toLowerCase().contains(q),
          )
          .toList();
    }

    setState(() {
      filteredStudents = result;
    });
  }

  void _showAdmissionFilters() {
    String tempSelectedClass = selectedClass;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 8),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          width: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(.09),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: AppColors.primary,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filters',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF17233F),
                                    ),
                                  ),
                                  Text(
                                    'Refine your student list',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF8792A5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                tempSelectedClass = 'All';
                                setSheetState(() {});
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // FILTER CONTENT
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
                      children: [
                        _compactFilterCard(
                          'Class',
                          Icons.school_outlined,
                          Wrap(
                            spacing: 7,
                            runSpacing: 3,
                            children: availableClasses.map((item) {
                              final selected = tempSelectedClass == item;

                              return ChoiceChip(
                                label: Text(item),
                                selected: selected,
                                onSelected: (_) {
                                  setSheetState(() {
                                    tempSelectedClass = item;
                                  });
                                },
                                showCheckmark: false,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 0,
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF526078),
                                ),
                                backgroundColor: Colors.white,
                                selectedColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.primary
                                        : const Color(0xFFE7EAF0),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _compactFilterCard(
                          'Admission Type',
                          Icons.how_to_reg_outlined,
                          Wrap(
                            spacing: 7,
                            runSpacing: 3,
                            children: [
                              'New Admission',
                              'Re-admission',
                              'Promoted',
                            ].map((e) => _compactOption(e)).toList(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _compactFilterCard(
                          'Admission Status',
                          Icons.fact_check_outlined,
                          Wrap(
                            spacing: 7,
                            runSpacing: 3,
                            children: [
                              'Admitted',
                              'Pending',
                              'Rejected',
                            ].map((e) => _compactOption(e)).toList(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _compactFilterCard(
                          'Section',
                          Icons.grid_view_rounded,
                          Wrap(
                            spacing: 7,
                            runSpacing: 3,
                            children: [
                              'A',
                              'B',
                              'C',
                              'D',
                            ].map((e) => _compactOption('Section $e')).toList(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _compactFilterCard(
                          'Student',
                          Icons.people_outline_rounded,
                          Wrap(
                            spacing: 7,
                            runSpacing: 3,
                            children: [
                              'Male',
                              'Female',
                              'Active',
                              'Inactive',
                            ].map((e) => _compactOption(e)).toList(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _compactFilterCard(
                          'Documents',
                          Icons.folder_outlined,
                          Wrap(
                            spacing: 7,
                            runSpacing: 3,
                            children: [
                              'Complete',
                              'Pending',
                            ].map((e) => _compactOption(e)).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // FIXED BOTTOM BUTTONS
                  Container(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFEDF0F5))),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                selectedClass = 'All';
                                searchCtrl.clear();
                                Navigator.pop(sheetContext);
                                _applyFilters();
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 42),
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Reset All',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                selectedClass = tempSelectedClass;
                                Navigator.pop(sheetContext);
                                _applyFilters();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(0, 42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Apply Filters',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // COMPACT FILTER CARD
  Widget _compactFilterCard(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEDF0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF26334D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }

  // COMPACT OPTION CHIP
  Widget _compactOption(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF526078),
        ),
      ),
    );
  }

  Future<void> fetchStudents() async {
    final response = await ApiService.post(
      context,
      "/admin/student/list",
      body: {},
    );

    if (response != null && response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      students = data.map((e) => StudentModel.fromJson(e)).toList();
      filteredStudents = students;
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        leading: const BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("Admissions"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuickAdmissionPage()),
              );

              if (result == true) {
                fetchStudents();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.school_outlined,
                            size: 42,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "No Students Found",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final s = filteredStudents[index];
                        return StudentCard(
                          id: s.id,
                          name: s.studentName,
                          ledger: s.ledgerNo,
                          father: s.fatherName,
                          classText: s.className,
                          section: s.section,
                          mobile: s.contactNo,
                          onDetails: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentDetailsPage(
                                  id: s.id,
                                  name: s.studentName,
                                  ledger: s.ledgerNo,
                                  father: s.fatherName,
                                  classText: s.className,
                                  section: s.section,
                                  mobile: s.contactNo,
                                  photo: s.photo,
                                  color: AppColors.primary,
                                ),
                              ),
                            );

                            if (result == true) {
                              await fetchStudents();
                            }
                          },
                          color: AppColors.primary,
                          photo: s.photo,
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    QuickAdmissionPage(studentId: s.id),
                              ),
                            );

                            if (result == true) {
                              fetchStudents();
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: _onSearch,
                      decoration: const InputDecoration(
                        hintText: 'Search student...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          InkWell(
            onTap: _showAdmissionFilters,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EAF2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18),
                  SizedBox(width: 5),
                  Text(
                    'Filter',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

class StudentCard extends StatelessWidget {
  final int id;
  final String name;
  final String ledger;
  final String father;
  final String classText;
  final String section;
  final String mobile;

  final Color color;
  final String photo;
  final VoidCallback onEdit;
  final VoidCallback onDetails;

  const StudentCard({
    super.key,
    required this.id,
    required this.name,
    required this.ledger,
    required this.father,
    required this.classText,
    required this.section,
    required this.mobile,
    required this.onDetails,
    required this.color,
    required this.photo,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDF1F7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF172B4D).withOpacity(0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Student photo
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photo.isNotEmpty
                      ? Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            color: color,
                            size: 25,
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SizedBox(
                                height: 17,
                                width: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: color,
                                ),
                              ),
                            );
                          },
                        )
                      : Icon(Icons.person_rounded, color: color, size: 25),
                ),
              ),

              const SizedBox(width: 11),

              // Student information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + edit
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF17233F),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Father name + Ledger in same row
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: Color(0xFF8491A5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            father,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF68758B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 12,
                                color: Color(0xFF159568),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                ledger,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF159568),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // Class + mobile in same row
                    Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 13,
                          color: Color(0xFF4285F4),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$classText - $section',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF43516A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: Color(0xFF159568),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            mobile,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF43516A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              // Right arrow: open details
              Container(
                height: 29,
                width: 25,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF2864D8),
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
