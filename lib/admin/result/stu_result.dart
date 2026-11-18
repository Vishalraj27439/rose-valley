import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rose_valley/admin/helper.dart';
import 'package:rose_valley/api_service.dart';

class ClassModel {
  final String id;
  final String name;

  ClassModel({required this.id, required this.name});

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'].toString(),
      name: json['Class'].toString(),
    );
  }
}

class SectionModel {
  final String id;
  final String name;

  SectionModel({required this.id, required this.name});

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'].toString(),
      name: json['SectionName'].toString(),
    );
  }
}

class ExamModel {
  final String id;
  final String name;

  ExamModel({required this.id, required this.name});

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['ExamId'].toString(),
      name: json['Exam'].toString(),
    );
  }
}

class AdminResultPage extends StatefulWidget {
  const AdminResultPage({super.key});

  @override
  State<AdminResultPage> createState() => _AdminResultPageState();
}

class _AdminResultPageState extends State<AdminResultPage> {
  // Search
  final TextEditingController searchCtrl = TextEditingController();

  String? selectedSectionId;
  String? selectedExamId;

  List<SectionModel> sectionList = [];
  List<ExamModel> examList = [];
  List<ClassModel> classList = [];
  String? selectedClassId;
  List<Map<String, dynamic>> resultList = [];
  bool isLoading = false;
  bool isSearched = false;
  final TextEditingController classCtrl = TextEditingController();
  final TextEditingController sectionCtrl = TextEditingController();
  final TextEditingController examCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(context, "/get_class");

      if (response != null && response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        classList = data.map((e) => ClassModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Class error: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> searchResult() async {
    if (selectedClassId == null ||
        selectedSectionId == null ||
        selectedExamId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select all filters")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        context,
        "/admin/result",
        body: {
          "ClassId": selectedClassId,
          "SectionId": selectedSectionId,
          "ExamId": selectedExamId,
        },
      );

      if (response != null && response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        resultList = List<Map<String, dynamic>>.from(data);
        isSearched = true;
      }
    } catch (e) {
      debugPrint("Result error: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> loadSectionAndExam(String classId) async {
    if (selectedClassId != null &&
        selectedSectionId != null &&
        selectedExamId != null) {
      searchResult();
    }
    setState(() {
      isLoading = true;

      selectedSectionId = null;
      selectedExamId = null;

      sectionCtrl.clear();
      examCtrl.clear();

      sectionList.clear();
      examList.clear();

      resultList.clear();
      isSearched = false;
    });

    try {
      /// ---------- SECTION ----------
      final sectionResponse = await ApiService.post(
        context,
        "/get_section",
        body: {"ClassId": classId},
      );

      if (sectionResponse != null && sectionResponse.statusCode == 200) {
        final List data = jsonDecode(sectionResponse.body);
        sectionList = data.map((e) => SectionModel.fromJson(e)).toList();
      }

      /// ---------- EXAM ----------
      final examResponse = await ApiService.post(
        context,
        "/get_exam",
        body: {"ClassId": classId},
      );

      if (examResponse != null && examResponse.statusCode == 200) {
        final List data = jsonDecode(examResponse.body);
        examList = data.map((e) => ExamModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Load error: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F1FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Student Result",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 SEARCH FORM CARD
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // CLASS + SECTION
                    Row(
                      children: [
                        Expanded(
                          child: ReusableOverlayDropdown(
                            label: 'Class',
                            hint: 'Select Class',
                            list: classList
                                .map((e) => {'id': e.id, 'name': e.name})
                                .toList(),
                            labelKey: 'name',
                            valueKey: 'id',
                            controller: classCtrl,
                            onSelected: (value, label) async {
                              setState(() {
                                selectedClassId = value;

                                selectedSectionId = null;
                                selectedExamId = null;

                                sectionCtrl.clear();
                                examCtrl.clear();

                                sectionList.clear();
                                examList.clear();

                                resultList.clear();
                                isSearched = false;
                              });

                              await loadSectionAndExam(value);
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: ReusableOverlayDropdown(
                            label: 'Section',
                            hint: 'Select Section',
                            list: sectionList
                                .map((e) => {'id': e.id, 'name': e.name})
                                .toList(),
                            labelKey: 'name',
                            valueKey: 'id',
                            controller: sectionCtrl,
                            onSelected: (value, label) {
                              setState(() {
                                selectedSectionId = value;
                                resultList.clear();
                                isSearched = false;
                              });

                              if (selectedClassId != null &&
                                  selectedExamId != null) {
                                searchResult();
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // EXAM BELOW
                    ReusableOverlayDropdown(
                      label: 'Exam',
                      hint: 'Select Exam',
                      list: examList
                          .map((e) => {'id': e.id, 'name': e.name})
                          .toList(),
                      labelKey: 'name',
                      valueKey: 'id',
                      controller: examCtrl,
                      onSelected: (value, label) {
                        setState(() {
                          selectedExamId = value;
                          resultList.clear();
                          isSearched = false;
                        });

                        if (selectedClassId != null &&
                            selectedSectionId != null) {
                          searchResult();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 📊 RESULT SECTION
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isSearched)
              resultList.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("No result found"),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: resultList.length,
                      itemBuilder: (context, index) {
                        final s = resultList[index];
                        return _resultCard(s);
                      },
                    ),
          ],
        ),
      ),
    );
  }

  // ---------------- DROPDOWN FIELD ----------------
  Widget _dropdownField({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    List<String>? displayItems,
    required ValueChanged<String?>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text("Select $label", style: TextStyle(fontSize: 12)),
                isExpanded: true,
                items: List.generate(
                  items.length,
                  (index) => DropdownMenuItem(
                    value: items[index],
                    child: Text(
                      displayItems?[index] ?? items[index],
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(Map<String, dynamic> s) {
    final List subjects = s['Marks'] ?? [];

    int total = 0;
    int obtained = 0;

    for (var sub in subjects) {
      total += int.tryParse(sub['TotalMark'] ?? "0") ?? 0;
      obtained += int.tryParse(sub['GetMark'] ?? "0") ?? 0;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ⭐ Student Info
            RichText(
              text: TextSpan(
                children: [
                  /// ⭐ Roll no first
                  TextSpan(
                    text: "Roll-${s['RollNo'] ?? ""}  ",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),

                  /// ⭐ Student name
                  TextSpan(
                    text: s['StudentName'] ?? "",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  /// ⭐ Father name in braces
                  TextSpan(
                    text: " (${s['FatherName'] ?? ""})",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            /// ⭐ Subject marks
            ...subjects.map<Widget>((sub) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sub['Subject'] ?? "",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "${sub['GetMark']} / ${sub['TotalMark']}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const Divider(height: 20),

            /// ⭐ Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Marks",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  "$obtained / $total",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
