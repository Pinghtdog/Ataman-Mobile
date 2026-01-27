import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/auth/data/models/user_model.dart';

class PdfService {
  static Uint8List? _cachedPage1;
  static Uint8List? _cachedPage2;

  static Future<Uint8List> generateEnrollmentPdf(UserModel user) async {
    final pdf = pw.Document();

    // Parse birthDate string to DateTime
    DateTime? birthDateTime;
    if (user.birthDate != null) {
      try {
        birthDateTime = DateTime.parse(user.birthDate!);
      } catch (e) {
        // Fallback or handle different formats if necessary
      }
    }

    // Load background images if not cached
    if (_cachedPage1 == null) {
      _cachedPage1 = (await rootBundle.load('assets/documents/form1_bg.png')).buffer.asUint8List();
    }
    if (_cachedPage2 == null) {
      _cachedPage2 = (await rootBundle.load('assets/documents/form2_bg.png')).buffer.asUint8List();
    }

    final page1Image = pw.MemoryImage(_cachedPage1!);
    final page2Image = pw.MemoryImage(_cachedPage2!);

    // PAGE 1: PATIENT ENROLMENT RECORD
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Background Template
              pw.FullPage(ignoreMargins: true, child: pw.Image(page1Image)),

              // I. PATIENT INFORMATION
              _plot(45, 188, user.lastName.toUpperCase()),
              _plot(552, 188, user.suffix ?? ''),
              _plot(45, 212, user.firstName.toUpperCase()),
              _plot(552, 212, user.maidenName ?? ''),
              _plot(45, 237, (user.middleName ?? '').toUpperCase()),
              _plot(715, 266, user.motherName ?? ''), 

              // Sex Checkboxes
              if (user.gender?.toLowerCase() == 'female') _plot(216, 266, "X", isBold: true),
              if (user.gender?.toLowerCase() == 'male') _plot(394, 266, "X", isBold: true),

              // Birthdate
              _plot(195, 291, birthDateTime?.month.toString().padLeft(2, '0') ?? ''),
              _plot(245, 291, birthDateTime?.day.toString().padLeft(2, '0') ?? ''),
              _plot(295, 291, birthDateTime?.year.toString() ?? ''),

              _plot(45, 316, user.birthplace ?? ''),
              _plot(552, 340, user.residentialAddress ?? '', width: 250),
              _plot(45, 341, user.bloodType ?? ''),

              // Civil Status
              if (user.civilStatus == 'Single') _plot(216, 355, "X"),
              if (user.civilStatus == 'Married') _plot(216, 375, "X"),

              // PhilHealth
              if (user.philhealthId != null && user.philhealthId!.isNotEmpty) _plot(815, 498, "X"),
              _plot(715, 545, user.philhealthId ?? ''),

              // Educational Attainment
              if (user.education == 'College') _plot(216, 518, "X"),
            ],
          );
        },
      ),
    );

    // PAGE 2: INDIVIDUAL TREATMENT RECORD
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.FullPage(ignoreMargins: true, child: pw.Image(page2Image)),

              // Header ID
              _plot(540, 44, user.philhealthId ?? '', size: 14),

              // Patient Info Section
              _plot(45, 180, user.lastName.toUpperCase()),
              _plot(540, 180, user.suffix ?? ''),
              _plot(710, 180, _calculateAge(birthDateTime)), 
              _plot(860, 180, user.gender?.toLowerCase() == 'male' ? 'M' : 'F'),

              _plot(45, 215, user.firstName.toUpperCase()),
              _plot(540, 215, user.residentialAddress ?? '', width: 300),
              _plot(45, 240, (user.middleName ?? '').toUpperCase()),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _plot(double x, double y, String text, {double size = 10, bool isBold = false, double? width}) {
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.SizedBox(
        width: width,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: size,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return '';
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }

  static Future<void> previewPdf(UserModel user) async {
    final pdfBytes = await generateEnrollmentPdf(user);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'enrollment_${user.lastName}.pdf',
    );
  }
}
