import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/auth/data/models/user_model.dart';

class Cf1FormPdf {
  static Future<pw.Document> generate(UserModel user) async {
    final pdf = pw.Document();

    // Helper to create the classic PhilHealth checkbox style field
    pw.Widget buildBoxField(String label, String value, {int boxes = 12}) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
          pw.Row(
            children: List.generate(boxes, (index) {
              return pw.Container(
                width: 12,
                height: 12,
                margin: const pw.EdgeInsets.only(right: 2),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
                child: pw.Center(
                  child: pw.Text(
                    index < value.length ? value[index] : '',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(marginLeft: 20, marginRight: 20, marginTop: 40, marginBottom: 40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Republic of the Philippines", style: const pw.TextStyle(fontSize: 8)),
                pw.Text("This form may be reproduced and is NOT FOR SALE", style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ),
          pw.Row(
             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
             crossAxisAlignment: pw.CrossAxisAlignment.start,
             children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("PHILIPPINE HEALTH INSURANCE CORPORATION", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text("Citystate Centre, 709 Shaw Boulevard, Pasig City", style: const pw.TextStyle(fontSize: 8)),
                    pw.Text("Call Center: (02) 441-7442 | Trunkline: (02) 441-7444", style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Column(
                    children: [
                      pw.Text("CF-1", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                      pw.Text("(Claim Form 1)", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Revised September 2018", style: const pw.TextStyle(fontSize: 6)),
                    ]
                  )
                )
             ]
          ),
          pw.Divider(height: 20, thickness: 2, color: PdfColors.black),
          
          // --- PART I: MEMBER INFORMATION ---
          pw.Text("PART I - MEMBER INFORMATION", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 8),
          buildBoxField("1. PhilHealth Identification Number (PIN) of Member:", user.philhealthId?.replaceAll('-', '') ?? ''),
          pw.SizedBox(height: 8),
          pw.Text("2. Name of Member:", style: const pw.TextStyle(fontSize: 7)),
          pw.Row(children: [
            pw.Expanded(child: _buildLabeledText("Last Name", user.lastName)),
            pw.SizedBox(width: 5),
            pw.Expanded(child: _buildLabeledText("First Name", user.firstName)),
            pw.SizedBox(width: 5),
            pw.Expanded(child: _buildLabeledText("Name Extension", user.suffix ?? "")),
            pw.SizedBox(width: 5),
            pw.Expanded(child: _buildLabeledText("Middle Name", user.middleName ?? "")),
          ]),
          pw.SizedBox(height: 8),
          // Simplified fields for demo purposes
          _buildLabeledText("4. Mailing Address:", "${user.residentialAddress ?? ''}, ${user.barangay ?? ''}, Naga City"),
          pw.SizedBox(height: 8),
          _buildLabeledText("6. Contact Information:", user.phoneNumber ?? ""),

          pw.SizedBox(height: 20),
          pw.Divider(thickness: 1, color: PdfColors.black),

          // Other sections would be built here...
          pw.Text("PART II - PATIENT INFORMATION", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
           pw.SizedBox(height: 10),
          pw.Text("(To be filled out only if the patient is a dependent)", style: const pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
           pw.SizedBox(height: 20),

           pw.Divider(thickness: 1, color: PdfColors.black),
          pw.Text("PART III - MEMBER CERTIFICATION", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 10),
          pw.Text("Under the penalty of law, I attest that the information I provided in this Form is true and accurate to the best of my knowledge.", style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 200, height: 1, color: PdfColors.grey700),
                  pw.Text("Signature Over Printed Name of Member", style: const pw.TextStyle(fontSize: 7))
                ]
              )
            ]
          ),

          pw.Spacer(),
          pw.Center(child: pw.Text("Generated by ATAMAN Digital Health Platform for Naga City", style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)))
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _buildLabeledText(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500)),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }
}
