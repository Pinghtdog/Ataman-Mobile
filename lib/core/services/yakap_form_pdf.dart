import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/auth/data/models/user_model.dart';

class YakapFormPdf {
  static Future<pw.Document> generate(UserModel user) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("PhilHealth Konsulta Registration Form (PKRF)", 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
              pw.SizedBox(height: 20),

              _buildSectionHeader("PERSONAL INFORMATION"),
              pw.SizedBox(height: 10),
              
              _buildField("PhilHealth No.", user.philhealthId ?? "N/A"),
              pw.SizedBox(height: 8),
              
              pw.Row(children: [
                pw.Expanded(child: _buildField("Last Name", user.lastName)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildField("First Name", user.firstName)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildField("Middle Name", user.middleName ?? "")),
              ]),
              
              pw.SizedBox(height: 8),
              
              pw.Row(children: [
                pw.Expanded(child: _buildField("Birthdate", user.birthDate?.toString().split(' ')[0] ?? "")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildField("Sex", user.gender ?? "")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildField("Contact No.", user.phoneNumber ?? "")),
              ]),
              
              pw.SizedBox(height: 8),
              _buildField("Address", "${user.barangay ?? ""}, Naga City, Camarines Sur"),

              pw.SizedBox(height: 20),

              _buildSectionHeader("KONSULTA PACKAGE PROVIDER (KPP) CHOICE"),
              pw.SizedBox(height: 10),
              _buildField("1st Choice KPP", "Naga City Health Center / Designated BHC"),
              pw.SizedBox(height: 5),
              _buildField("Address", "Naga City"),

              pw.SizedBox(height: 20),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                child: pw.Text(
                  "I hereby certify that I did not avail of FPE in other KPP. Moreover, I grant my free and voluntary consent to the collection and processing of my personal data for PhilHealth purposes.",
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.justify
                ),
              ),

              pw.SizedBox(height: 40),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 200, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text("${user.firstName} ${user.lastName}".toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text("Signature over Printed Name", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  )
                ],
              )
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      color: PdfColors.black,
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
    );
  }

  static pw.Widget _buildField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Text(value.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
      ],
    );
  }
}
