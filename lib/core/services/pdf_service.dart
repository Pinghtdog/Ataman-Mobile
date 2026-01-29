import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/auth/data/models/user_model.dart';

class PdfService {
  
  static Future<Uint8List> generateMedicalIdForm(UserModel user, {Map<String, dynamic>? triageResult}) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('REPUBLIC OF THE PHILIPPINES', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('CITY HEALTH OFFICE - NAGA CITY', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('DIGITAL HEALTH ENROLLMENT RECORD', style: pw.TextStyle(fontSize: 12, color: PdfColors.blue700)),
                    ],
                  ),
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: user.id,
                      drawText: false,
                    ),
                  ),
                ],
              ),
              
              pw.Divider(thickness: 2, color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // PATIENT BASIC INFO
              pw.Text('I. PATIENT PERSONAL INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  _infoField('LAST NAME', user.lastName.toUpperCase(), flex: 2),
                  _infoField('FIRST NAME', user.firstName.toUpperCase(), flex: 2),
                  _infoField('MIDDLE NAME', (user.middleName ?? '').toUpperCase(), flex: 2),
                ],
              ),
              pw.Row(
                children: [
                  _infoField('BIRTHDATE', user.birthDate ?? 'N/A'),
                  _infoField('GENDER', user.gender ?? 'N/A'),
                  _infoField('BLOOD TYPE', user.bloodType ?? 'N/A'),
                  _infoField('BARANGAY', user.barangay ?? 'N/A'),
                ],
              ),
              pw.SizedBox(height: 20),

              // MEDICAL STATUS
              pw.Text('II. MEDICAL PROFILE & ALERTS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 10),
              _infoField('KNOWN ALLERGIES', user.allergies ?? 'NONE REPORTED'),
              _infoField('CHRONIC CONDITIONS', user.medicalConditions ?? 'NONE REPORTED'),
              pw.SizedBox(height: 20),

              // RECENT TRIAGE SUMMARY (The Dynamic Sync)
              if (triageResult != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RECENT AI TRIAGE SUMMARY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                      pw.SizedBox(height: 5),
                      pw.Text('Priority Level: ${triageResult['priority'] ?? 'Standard'}'),
                      pw.Text('Main Complaint: ${triageResult['complaint'] ?? 'Routine Checkup'}'),
                      pw.Text('Recommendation: ${triageResult['recommendation'] ?? 'Follow-up as scheduled'}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // EMERGENCY CONTACT
              pw.Text('III. EMERGENCY CONTACT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  _infoField('CONTACT NAME', user.emergencyContactName ?? 'N/A', flex: 2),
                  _infoField('CONTACT PHONE', user.emergencyContactPhone ?? 'N/A', flex: 1),
                ],
              ),

              pw.Spacer(),

              // FOOTER / VALIDATION
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('System Generated Document', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                      pw.Text('Generated on: ${DateTime.now().toString().split('.')[0]}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                    ],
                  ),
                  pw.Container(
                    width: 150,
                    child: pw.Column(
                      children: [
                        pw.Divider(thickness: 1),
                        pw.Text('Patient Signature', style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoField(String label, String value, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(right: 8, bottom: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static Future<void> previewMedicalIdForm(UserModel user, {Map<String, dynamic>? triageResult}) async {
    final pdfBytes = await generateMedicalIdForm(user, triageResult: triageResult);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'medical_id_${user.lastName}.pdf',
    );
  }
}
