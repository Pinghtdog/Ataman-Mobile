import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdfx/pdfx.dart' as render;
import '../../features/auth/data/models/user_model.dart';

class PdfService {
  static Uint8List? _cachedPage1;
  static Uint8List? _cachedPage2;

  static Future<Uint8List> generateEnrollmentPdf(UserModel user) async {
    final pdf = pw.Document();

    // Parse birthDate string to DateTime
    DateTime? birthDateTime;
    if (user.birthDate != null && user.birthDate!.isNotEmpty) {
      try {
        birthDateTime = DateTime.parse(user.birthDate!);
      } catch (e) {
        // Fallback for other formats
      }
    }

    // Load and render PDF background if not cached
    if (_cachedPage1 == null || _cachedPage2 == null) {
      final doc = await render.PdfDocument.openAsset('assets/documents/enrollment_form.pdf');
      
      final page1 = await doc.getPage(1);
      final page1Render = await page1.render(
        width: page1.width * 2, // High resolution
        height: page1.height * 2,
        format: render.PdfPageImageFormat.png,
      );
      _cachedPage1 = page1Render!.bytes;
      await page1.close();

      final page2 = await doc.getPage(2);
      final page2Render = await page2.render(
        width: page2.width * 2,
        height: page2.height * 2,
        format: render.PdfPageImageFormat.png,
      );
      _cachedPage2 = page2Render!.bytes;
      await page2.close();
      
      await doc.close();
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
              pw.FullPage(ignoreMargins: true, child: pw.Image(page1Image)),

              // I. PATIENT INFORMATION
              _plot(45, 160, user.lastName.toUpperCase()),
              _plot(330, 160, user.suffix ?? ''),
              _plot(45, 190, user.firstName.toUpperCase()),
              _plot(330, 190, user.maidenName ?? ''),
              _plot(45, 220, (user.middleName ?? '').toUpperCase()),
              _plot(330, 220, user.motherName ?? ''), 

              // Sex Checkboxes
              if (user.gender?.toLowerCase() == 'female') _plot(100, 245, "X", isBold: true),
              if (user.gender?.toLowerCase() == 'male') _plot(230, 245, "X", isBold: true),

              // Birthdate
              _plot(365, 245, birthDateTime?.month.toString().padLeft(2, '0') ?? ''),
              _plot(415, 245, birthDateTime?.day.toString().padLeft(2, '0') ?? ''),
              _plot(465, 245, birthDateTime?.year.toString() ?? ''),

              _plot(45, 275, user.birthplace ?? ''),
              _plot(330, 275, user.residentialAddress ?? '', width: 250),
              _plot(45, 305, user.bloodType ?? ''),

              // Civil Status
              if (user.civilStatus == 'Single') _plot(115, 325, "X"),
              if (user.civilStatus == 'Married') _plot(115, 345, "X"),
              if (user.civilStatus == 'Widow/er') _plot(220, 325, "X"),
              if (user.civilStatus == 'Separated') _plot(220, 345, "X"),
              if (user.civilStatus == 'Annulled') _plot(115, 365, "X"),
              if (user.civilStatus == 'Co-Habitation') _plot(220, 365, "X"),

              // 4Ps Member
              if (user.is4psMember) _plot(450, 455, "X") else _plot(515, 455, "X"),

              // PhilHealth
              if (user.philhealthId != null && user.philhealthId!.isNotEmpty) ...[
                _plot(450, 500, "X"), // Yes
                if (user.philhealthStatus == 'Member') _plot(450, 525, "X")
                else if (user.philhealthStatus == 'Dependent') _plot(515, 525, "X"),
                _plot(330, 550, user.philhealthId ?? ''),
              ] else ...[
                _plot(515, 500, "X"), // No
              ],

              // Educational Attainment
              if (user.education == 'No Formal Education') _plot(115, 455, "X"),
              if (user.education == 'Elementary') _plot(220, 455, "X"),
              if (user.education == 'High School') _plot(115, 475, "X"),
              if (user.education == 'Vocational') _plot(220, 475, "X"),
              if (user.education == 'College') _plot(115, 495, "X"),
              if (user.education == 'Post Graduate') _plot(220, 495, "X"),

              // Primary Care Benefit (PCB) Member
              if (user.isPcbMember) _plot(450, 675, "X") else _plot(515, 675, "X"),
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
              _plot(450, 40, user.philhealthId ?? '', size: 14),

              // Patient Info Section
              _plot(45, 175, user.lastName.toUpperCase()),
              _plot(330, 175, user.suffix ?? ''),
              _plot(420, 175, _calculateAge(birthDateTime)), 
              _plot(510, 175, user.gender?.toLowerCase() == 'male' ? 'M' : 'F'),

              _plot(45, 205, user.firstName.toUpperCase()),
              _plot(330, 205, user.residentialAddress ?? '', width: 250),
              _plot(45, 235, (user.middleName ?? '').toUpperCase()),
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
