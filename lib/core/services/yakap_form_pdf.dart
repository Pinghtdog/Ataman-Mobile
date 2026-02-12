import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/auth/data/models/user_model.dart';

class YakapFormPdf {
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
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text("PhilHealth", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.green900)),
                   pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.end,
                     children: [
                        pw.Text("ANNEX A", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text("PKRF v.2023", style: const pw.TextStyle(fontSize: 8)),
                     ]
                   )
                ]
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("PHILHEALTH KONSULTA REGISTRATION FORM", 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text("(Member/Dependent)", style: const pw.TextStyle(fontSize: 10)),
                  ]
                ),
              ),
              pw.SizedBox(height: 20),

              _buildSectionHeader("I. PATIENT INFORMATION"),
              pw.SizedBox(height: 10),
              
              pw.Row(children: [
                pw.Expanded(child: _buildField("PhilHealth Identification Number (PIN)", user.philhealthId ?? "PENDING")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildField("Category", user.is4psMember ? "INDIGENT / 4PS" : "INFORMAL ECONOMY")),
              ]),
              
              pw.SizedBox(height: 8),
              
              pw.Row(children: [
                pw.Expanded(child: _buildField("Last Name", user.lastName)),
                pw.SizedBox(width: 5),
                pw.Expanded(child: _buildField("First Name", user.firstName)),
                pw.SizedBox(width: 5),
                pw.Expanded(child: _buildField("Middle Name", user.middleName ?? "")),
                pw.SizedBox(width: 5),
                pw.Expanded(flex: 0, child: _buildField("Suffix", user.suffix ?? "")),
              ]),
              
              pw.SizedBox(height: 8),
              
              pw.Row(children: [
                pw.Expanded(child: _buildField("Birthdate (MM-DD-YYYY)", user.birthDate?.toString().split(' ')[0] ?? "")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildField("Sex", user.gender ?? "")),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildField("Civil Status", user.civilStatus ?? "SINGLE")),
              ]),
              
              pw.SizedBox(height: 8),
              _buildField("Residential Address", "${user.residentialAddress ?? ""}, ${user.barangay ?? ""}, Naga City"),
              _buildField("Contact Number / Email", "${user.phoneNumber ?? ""} / ${user.email}"),

              pw.SizedBox(height: 20),

              _buildSectionHeader("II. KONSULTA PACKAGE PROVIDER (KPP) CHOICE"),
              pw.SizedBox(height: 10),
              pw.Text("The member/dependent hereby chooses the following KPP in Naga City:", style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 5),
              _buildField("Accredited KPP Name", "NAGA CITY HEALTH OFFICE / BICOL MEDICAL CENTER"),
              pw.SizedBox(height: 5),
              _buildField("KPP Address", "Naga City, Camarines Sur"),

              pw.SizedBox(height: 20),

              _buildSectionHeader("III. PROVISION OF CONSENT (DATA PRIVACY ACT)"),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Text(
                  "I hereby certify that the above information is true and correct. I grant my free and voluntary consent to the collection and processing of my personal health data for the purpose of the PhilHealth Konsulta Package, in accordance with the Data Privacy Act of 2012.",
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.justify
                ),
              ),

              pw.SizedBox(height: 40),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                       pw.Text("Date Signed: ${DateTime.now().month}-${DateTime.now().day}-${DateTime.now().year}", style: const pw.TextStyle(fontSize: 9)),
                    ]
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 180, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text(user.fullName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text("Signature over Printed Name", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  )
                ],
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text("Generated via ATAMAN Digital Health Platform - Naga City", 
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
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
      color: PdfColors.grey200,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 5),
      child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
    );
  }

  static pw.Widget _buildField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Text(value.isEmpty ? " " : value.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
      ],
    );
  }
}
