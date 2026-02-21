import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injector.dart';
import '../../../../core/services/philhealth_service.dart';
import '../../data/models/user_model.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class PhilHealthVerificationScreen extends StatefulWidget {
  final UserModel user;
  const PhilHealthVerificationScreen({super.key, required this.user});

  @override
  State<PhilHealthVerificationScreen> createState() => _PhilHealthVerificationScreenState();
}

class _PhilHealthVerificationScreenState extends State<PhilHealthVerificationScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isAutoFilling = false;
  bool _isInitialized = false;
  bool _showCaptureButton = false;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeWebView() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.sensors,
    ].request();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _showCaptureButton = false;
            });
            _detectionTimer?.cancel();
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            if (url.contains('pcu.philhealth.gov.ph')) {
              _autoFillForm();
              _startResultDetection();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://pcu.philhealth.gov.ph/main'));

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(false);
      await androidController.setOnPlatformPermissionRequest(
            (PlatformWebViewPermissionRequest request) => request.grant(),
      );
    }

    _controller = controller;
    if (mounted) setState(() => _isInitialized = true);
  }

  void _startResultDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      final bool hasResults = await _checkIfDataIsLoaded();
      if (hasResults && !_showCaptureButton) {
        setState(() => _showCaptureButton = true);
        timer.cancel();
      }
    });
  }

  Future<bool> _checkIfDataIsLoaded() async {
    const String checkJs = """
      (function() {
        const text = document.body.innerText.toUpperCase();
        return text.includes('PIN') || 
               text.includes('PHILHEALTH ID') || 
               text.includes('IDENTIFICATION NUMBER') ||
               text.includes('MEMBER DETAILS');
      })();
    """;
    try {
      final dynamic res = await _controller.runJavaScriptReturningResult(checkJs);
      return res == true || res.toString() == "true";
    } catch (e) {
      return false;
    }
  }

  Future<void> _autoFillForm() async {
    if (_isAutoFilling) return;
    _isAutoFilling = true;

    String rawBirthDate = widget.user.birthDate ?? "";
    if (rawBirthDate.contains('/')) {
      final parts = rawBirthDate.split('/');
      if (parts.length == 3) {
        rawBirthDate = parts[0].length == 4
            ? "${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}"
            : "${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}";
      }
    }

    final String js = """
      (function() {
        function fill(id, val) {
          if (!val) return;
          const el = document.getElementById(id) || document.getElementsByName(id)[0];
          if (el) {
            el.focus();
            if (id.toLowerCase().includes('dob')) el.type = 'date';
            el.value = val;
            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
            el.blur();
          }
        }
        setTimeout(function() {
          fill('inputLastName', '${widget.user.lastName}');
          fill('inputFirstName', '${widget.user.firstName}');
          fill('inputDoB', '$rawBirthDate');
          const middleName = '${widget.user.middleName ?? ""}';
          const checkbox = document.getElementById('nomiddlenamecb');
          if (checkbox) {
              if (middleName && middleName.trim() !== '') {
                  if(checkbox.checked) checkbox.click();
                  fill('inputMiddleName', middleName);
              } else {
                  if(!checkbox.checked) checkbox.click();
              }
          }
        }, 2000);
      })();
    """;
    try {
      await _controller.runJavaScript(js);
    } catch (_) {} finally {
      _isAutoFilling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PhilHealth Verification"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (_isInitialized) WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
      bottomNavigationBar: _showCaptureButton
          ? Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: AtamanButton(
                text: "Capture Result & Verify",
                onPressed: () => _confirmVerification(),
              ),
            )
          : null,
    );
  }

  void _confirmVerification() async {
    setState(() => _isLoading = true);
    final String scraperJs = """
      (function() {
        try {
          function getVal(label) {
            var tds = document.getElementsByTagName('td');
            var search = label.toLowerCase().replace(':', '').trim();
            for (var i = 0; i < tds.length; i++) {
              var text = tds[i].innerText.toLowerCase().replace(':', '').trim();
              if (text.includes(search)) {
                var val = tds[i].nextElementSibling ? tds[i].nextElementSibling.innerText.trim() : '';
                if (val) return val;
              }
            }
            var spans = document.getElementsByTagName('span');
            for (var i = 0; i < spans.length; i++) {
              if (spans[i].innerText.toLowerCase().includes(search)) {
                return spans[i].nextElementSibling ? spans[i].nextElementSibling.innerText.trim() : '';
              }
            }
            return '';
          }
          var results = {
            pin: getVal('PIN') || getVal('Identification Number') || getVal('PhilHealth ID'),
            lastName: getVal('Last Name'),
            firstName: getVal('First Name'),
            middleName: getVal('Middle Name'),
            dob: getVal('Date of birth') || getVal('DOB'),
            sex: getVal('Sex') || getVal('Gender'),
            found: true
          };
          if(!results.pin && !results.lastName) results.found = false;
          return JSON.stringify(results);
        } catch(e) { return JSON.stringify({found: false}); }
      })();
    """;

    try {
      final dynamic rawResult = await _controller.runJavaScriptReturningResult(scraperJs);
      
      String resString = rawResult.toString();
      if (resString.startsWith('"') && resString.endsWith('"')) {
        resString = jsonDecode(resString);
      }
      final Map<String, dynamic> data = jsonDecode(resString);

      setState(() => _isLoading = false);
      if (data['found'] == true && data['pin'] != null && data['pin'].toString().isNotEmpty) {
        _showValidationDialog(data);
      } else {
        _showManualConfirmation();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showManualConfirmation();
    }
  }

  void _showValidationDialog(Map<String, dynamic> portalData) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 8),
            Text("Verification Success"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Official portal data found:", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildDataRow("PIN", portalData['pin'] ?? 'N/A'),
            _buildDataRow("Name", "${portalData['firstName']} ${portalData['lastName']}"),
            _buildDataRow("DOB", portalData['dob'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel")
          ),
          AtamanButton(
            text: "Sync Profile",
            width: 140,
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        if (!mounted) return;
        setState(() => _isLoading = true);

        try {
          await getIt<PhilHealthService>().syncVerifiedData(widget.user.id, portalData);
          if (mounted) {
            Navigator.pop(context, portalData);
          }
        } catch (e) {
          final String errorMsg = e.toString();
          // If the identity is already verified, the DB blocks the change.
          // We treat this as a success for the UI since the user IS verified.
          if (errorMsg.contains("Identity is verified") || errorMsg.contains("P0001")) {
            if (mounted) {
              Navigator.pop(context, portalData);
            }
            return;
          }

          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Database Error: $e"),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    });
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(color: Colors.grey)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showManualConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Capture Failed"),
        content: const Text("Could not read results automatically. Please ensure your details are visible on the screen and try again."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Retry")),
        ],
      ),
    );
  }
}
