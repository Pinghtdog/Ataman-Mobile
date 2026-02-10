import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/medical_records/data/models/referral_model.dart';
import '../../features/medical_records/data/models/medical_history_model.dart';
import '../../features/medical_records/data/models/prescription_model.dart';
import '../../features/auth/data/models/user_model.dart';
import 'yakap_form_pdf.dart';
import 'itr_form_pdf.dart';

class PdfService {
  /// Generates a PDF for a specific Hospital Referral
  static Future<void> generateReferralSlip(Referral referral) async {
    final pdf = pw.Document();
    final image = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(image, "MEDICAL REFERRAL SLIP"),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text("Ref No: ${referral.referenceNumber}", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ),
                pw.SizedBox(height: 30),

                _buildSectionTitle("PATIENT INFORMATION"),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildInfoRow("Referral Date", referral.createdAt != null ? referral.createdAt!.toIso8601String().split('T')[0] : "N/A")),
                    pw.Expanded(child: _buildInfoRow("Urgency", referral.status.name)),
                  ],
                ),
                pw.SizedBox(height: 20),

                _buildSectionTitle("FACILITY ROUTING"),
                pw.SizedBox(height: 10),
                _buildInfoRow("Origin Facility", referral.originFacilityName),
                _buildInfoRow("Destination", referral.destinationFacilityName),
                pw.SizedBox(height: 20),

                _buildSectionTitle("CLINICAL SUMMARY"),
                pw.SizedBox(height: 10),
                pw.Text("Chief Complaint:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(referral.chiefComplaint),
                pw.SizedBox(height: 10),
                pw.Text("Clinical Impression / Diagnosis:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(referral.diagnosisImpression ?? "N/A"),
                pw.SizedBox(height: 40),

                _buildSignatureArea(),
                pw.Spacer(),
                _buildFooter("This is an electronically generated referral slip from the Ataman Healthcare Module."),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Referral_${referral.referenceNumber}.pdf',
    );
  }

  /// Generates a PDF for a general Medical Record/History item
  static Future<void> generateMedicalRecordPdf(MedicalHistoryItem item) async {
    final pdf = pw.Document();
    final image = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(image, "MEDICAL RECORD SUMMARY"),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text("Record ID: ${item.id}", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ),
                pw.SizedBox(height: 30),

                _buildSectionTitle("GENERAL INFORMATION"),
                pw.SizedBox(height: 10),
                _buildInfoRow("Type", item.type.name.toUpperCase()),
                _buildInfoRow("Date", item.date.toIso8601String().split('T')[0]),
                _buildInfoRow("Service", item.title),
                _buildInfoRow("Provider/Facility", item.subtitle),
                pw.SizedBox(height: 20),

                _buildSectionTitle("RECORD DETAILS"),
                pw.SizedBox(height: 10),
                if (item.tag != null) _buildInfoRow("Summary/Tag", item.tag!),
                if (item.extraInfo != null) ...[
                  pw.SizedBox(height: 10),
                  pw.Text("Notes / Extra Info:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(item.extraInfo!),
                ],
                
                pw.SizedBox(height: 40),
                _buildSignatureArea(),
                pw.Spacer(),
                _buildFooter("This is an official digital record summary from the Ataman Healthcare system."),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Record_${item.id}.pdf',
    );
  }

  /// Generates a PDF for a Digital Prescription
  static Future<void> generatePrescriptionPdf(Prescription prescription) async {
    final pdf = pw.Document();
    final image = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(image, "DIGITAL PRESCRIPTION"),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text("Prescription ID: ${prescription.id}", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ),
                pw.SizedBox(height: 30),

                _buildSectionTitle("MEDICATION DETAILS"),
                pw.SizedBox(height: 10),
                _buildInfoRow("Medication", prescription.medicationName),
                _buildInfoRow("Dosage", prescription.dosage),
                pw.SizedBox(height: 20),

                _buildSectionTitle("DOCTOR INFORMATION"),
                pw.SizedBox(height: 10),
                _buildInfoRow("Physician", prescription.doctorName),
                _buildInfoRow("Date Prescribed", prescription.createdAt.toIso8601String().split('T')[0]),
                _buildInfoRow("Valid Until", prescription.validUntil.toIso8601String().split('T')[0]),
                pw.SizedBox(height: 20),

                if (prescription.instructions != null && prescription.instructions!.isNotEmpty) ...[
                  _buildSectionTitle("INSTRUCTIONS"),
                  pw.SizedBox(height: 10),
                  pw.Text(prescription.instructions!, style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 20),
                ],

                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 100,
                      height: 100,
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: prescription.id,
                      ),
                    ),
                    _buildSignatureArea(),
                  ],
                ),
                pw.SizedBox(height: 20),
                _buildFooter("This is a verified digital prescription from the Ataman Healthcare system."),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Prescription_${prescription.id}.pdf',
    );
  }

  /// Generates a PDF for the Digital Medical ID Form
  static Future<void> previewMedicalIdForm(UserModel user, {Map<String, dynamic>? triageResult}) async {
    final pdf = pw.Document();
    final image = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(image, "DIGITAL MEDICAL ID & CASE SUMMARY"),
                pw.SizedBox(height: 20),

                _buildSectionTitle("PATIENT PROFILE"),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow("Full Name", user.fullName),
                        _buildInfoRow("Blood Type", user.bloodType ?? "Unspecified"),
                        _buildInfoRow("Gender", user.gender ?? "Unspecified"),
                        _buildInfoRow("Barangay", user.barangay ?? "Naga City"),
                      ],
                    ),
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: user.id,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                if (triageResult != null) ...[
                  _buildSectionTitle("LATEST CASE SUMMARY"),
                  pw.SizedBox(height: 10),
                  _buildInfoRow("Priority", triageResult['priority'] ?? 'N/A'),
                  _buildInfoRow("Complaint", triageResult['complaint'] ?? 'N/A'),
                  pw.SizedBox(height: 10),
                  pw.Text("Recommendations:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(triageResult['recommendation'] ?? 'N/A', style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 20),
                ],

                _buildSectionTitle("EMERGENCY CONTACT"),
                pw.SizedBox(height: 10),
                _buildInfoRow("Contact Person", user.emergencyContactName ?? "Not Provided"),
                _buildInfoRow("Contact Number", user.emergencyContactPhone ?? "Not Provided"),
                
                pw.SizedBox(height: 40),
                _buildSignatureArea(),
                pw.Spacer(),
                _buildFooter("This document is a certified digital health ID from the City of Naga Ataman Healthcare module."),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'MedicalID_${user.fullName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Generates the official PhilHealth Konsulta Registration Form (Yakap)
  static Future<void> generateYakapForm(UserModel user) async {
    final pdf = await YakapFormPdf.generate(user);
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Yakap_Form_${user.lastName}.pdf',
    );
  }

  /// Generates the Individual Treatment Record (ITR) for Naga CHO
  static Future<void> generateITR(UserModel user) async {
    final pdf = await ItrFormPdf.generate(user);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ITR_${user.lastName}.pdf',
    );
  }

  // Helper Methods to avoid repetition
  static Future<pw.MemoryImage> _loadLogo() async {
    return pw.MemoryImage(
      (await rootBundle.load('assets/icon/icon1.png')).buffer.asUint8List(),
    );
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo, String title) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("ATAMAN HEALTH", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
            pw.Text("City Government of Naga", style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 10),
            pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          ],
        ),
        pw.Image(logo, width: 50),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(color: PdfColors.teal50),
      child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal900, fontSize: 10)),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: "$label: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.TextSpan(text: value, style: pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSignatureArea() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          children: [
            pw.Container(width: 150, height: 1, color: PdfColors.black),
            pw.Text("Authorized Medical Personnel", style: pw.TextStyle(fontSize: 10)),
            pw.Text("ATAMAN DIGITAL SIGNATURE", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(String text) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(text, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ],
    );
  }
}
