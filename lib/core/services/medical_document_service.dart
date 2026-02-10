import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicalDocumentService {
  final SupabaseClient _supabase;

  MedicalDocumentService(this._supabase);

  Future<String?> pickAndUploadDocument({
    required String userId,
    required String folder,
  }) async {
    try {
      // 1. Pick a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      );

      if (result == null || result.files.single.path == null) return null;

      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String path = '$userId/$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // 2. Upload to Supabase Storage
      await _supabase.storage
          .from('medical_documents')
          .upload(path, file);

      // 3. Get Public URL
      final String publicUrl = _supabase.storage
          .from('medical_documents')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}
