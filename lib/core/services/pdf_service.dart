import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/auth/data/models/user_model.dart';

class PdfService {
  static Uint8List? _cachedTemplate;

  static Future<Uint8List> generateEnrollmentPdf(UserModel user) async {
    final pdf = pw.Document();
    
    // Load the background template once and cache it
    if (_cachedTemplate == null) {
      final ByteData bytes = await rootBundle.load('assets/documents/enrollment_form.pdf');
      _cachedTemplate = bytes.buffer.asUint8List();
    }

    // Since 'pdf' package doesn't easily 'overlay' on an existing PDF file directly in the same way it creates new ones,
    // the standard approach for "Option A" in Flutter is to use the template as a background image 
    // OR recreate the layout if high precision is needed.
    
    // Note: If you want to use the template as an image background, you would convert the PDF page to an image.
    // For now, I'll keep the structure. You will need to adjust the positions (top/left) 
    // to match your specific PDF's layout.
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                pw.Positioned(
                  top: 100, // Adjust these based on your form
                  left: 50,
                  child: pw.Text(
                    '${user.firstName} ${user.lastName}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.Positioned(
                  top: 120,
                  left: 50,
                  child: pw.Text(
                    user.philhealthId ?? 'N/A',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),
                // Add more fields here...
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> previewPdf(UserModel user) async {
    final pdfBytes = await generateEnrollmentPdf(user);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'enrollment_${user.lastName}.pdf',
    );
  }
}
