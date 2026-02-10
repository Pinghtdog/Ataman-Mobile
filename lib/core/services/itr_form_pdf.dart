import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../features/auth/data/models/user_model.dart';

class ItrFormPdf {
  static Future<pw.Document> generate(UserModel user) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Column(
                    children: [
                      pw.Text("Republic of the Philippines", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Department of Health", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("NAGA CITY HEALTH OFFICE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.SizedBox(height: 5),
                      pw.Text("PATIENT ENROLMENT RECORD (ITR)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),

              pw.Container(
                color: PdfColors.grey200,
                width: double.infinity,
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text("I. PATIENT INFORMATION", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              pw.SizedBox(height: 10),

              _buildBoxedField("Last Name", user.lastName),
              _buildBoxedField("First Name", user.firstName),
              _buildBoxedField("Middle Name", user.middleName ?? "N/A"),

              pw.SizedBox(height: 5),

              pw.Row(children: [
                pw.Expanded(child: _buildBoxedField("Birth Date", user.birthDate?.toString().split(' ')[0] ?? "")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildBoxedField("Sex", user.gender ?? "")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildBoxedField("Blood Type", user.bloodType ?? "")),
              ]),

              pw.SizedBox(height: 5),
              _buildBoxedField("Residential Address", "${user.barangay ?? ""}, Naga City"),

              pw.SizedBox(height: 5),
              _buildBoxedField("PhilHealth ID No.", user.philhealthId ?? ""),

              pw.SizedBox(height: 20),

              pw.Container(
                color: PdfColors.grey200,
                width: double.infinity,
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text("II. FOR CHU / RHU PERSONNEL ONLY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              pw.SizedBox(height: 10),

              pw.Row(children: [
                pw.Text("Mode of Transaction: ", style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(width: 10),
                _buildCheckBox("Walk-in"),
                pw.SizedBox(width: 10),
                _buildCheckBox("Visited"),
                pw.SizedBox(width: 10),
                _buildCheckBox("Referral"),
              ]),

              pw.SizedBox(height: 10),

              pw.Row(children: [
                pw.Expanded(child: _buildUnderlineField("Date of Consultation")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildUnderlineField("Time")),
              ]),

              pw.SizedBox(height: 10),

              pw.Row(children: [
                pw.Expanded(child: _buildUnderlineField("BP")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildUnderlineField("Temp")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildUnderlineField("Weight (kg)")),
              ]),

              pw.SizedBox(height: 10),
              _buildUnderlineField("Chief Complaints / Nature of Visit"),

              pw.SizedBox(height: 20),
              _buildUnderlineField("Name of Attending Provider"),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildBoxedField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text("$label:", style: const pw.TextStyle(fontSize: 10))),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
              child: pw.Text(value.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCheckBox(String label) {
    return pw.Row(children: [
      pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(border: pw.Border.all())),
      pw.SizedBox(width: 4),
      pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
    ]);
  }

  static pw.Widget _buildUnderlineField(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Container(height: 1, color: PdfColors.black, width: double.infinity, margin: const pw.EdgeInsets.only(top: 15)),
      ],
    );
  }
}
