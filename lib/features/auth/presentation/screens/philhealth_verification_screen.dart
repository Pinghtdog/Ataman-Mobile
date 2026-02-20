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
  bool _showCaptureButton = false;
  bool _isInitialized = false;
  Timer? _pageCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _pageCheckTimer?.cancel();
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
        (PlatformWebViewPermissionRequest request) {
          request.grant();
        },
      );
    }

    _controller = controller;
    if (mounted) setState(() => _isInitialized = true);
  }

  void _startResultDetection() {
    _pageCheckTimer?.cancel();
    _pageCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      final String checkJs = "(function() { return document.body.innerText.includes('PIN:'); })();";
      try {
        final dynamic hasResults = await _controller.runJavaScriptReturningResult(checkJs);
        if (hasResults == true || hasResults.toString() == "true") {
          setState(() => _showCaptureButton = true);
          timer.cancel();
        }
      } catch (e) {}
    });
  }

  Future<void> _autoFillForm() async {
    if (_isAutoFilling) return;
    _isAutoFilling = true;

    String formattedBirthDate = widget.user.birthDate ?? "";
    if (formattedBirthDate.contains('-')) {
      try {
        final parts = formattedBirthDate.split('-');
        if (parts.length == 3 && parts[0].length == 4) {
          formattedBirthDate = "${parts[2]}/${parts[1]}/${parts[0]}";
        }
      } catch (_) {}
    }

    final String js = """
      (function() {
        function fillField(id, val) {
          if (!val) return;
          const el = document.getElementById(id);
          if (el) {
            el.value = val;
            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
          }
        }

        setTimeout(function() {
          fillField('inputLastName', '${widget.user.lastName}');
          fillField('inputFirstName', '${widget.user.firstName}');
          fillField('inputDOB', '$formattedBirthDate');
          
          const middleName = '${widget.user.middleName ?? ""}';
          const checkbox = document.getElementById('nomiddlenamecb');

          if (checkbox) {
              if (middleName && middleName.trim() !== '') {
                  if(checkbox.checked) checkbox.click();
                  fillField('inputMiddleName', middleName);
              } else {
                  if(!checkbox.checked) checkbox.click();
              }
          }
        }, 3000);
      })();
    """;

    try {
      await _controller.runJavaScript(js);
    } catch (e) {
      debugPrint("JS Autofill Error: $e");
    } finally {
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
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          if (_showCaptureButton)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                  ],
                ),
                child: AtamanButton(
                  text: "Capture Result & Verify",
                  onPressed: () => _confirmVerification(),
                ),
              ),
            ),
        ],
      ),
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
                return tds[i].nextElementSibling.innerText.trim();
              }
            }
            return '';
          }
          var results = {
            pin: getVal('PIN'),
            lastName: getVal('Last Name'),
            firstName: getVal('First Name'),
            middleName: getVal('Middle Name'),
            dob: getVal('Date of birth'),
            found: true
          };
          if(!results.pin && !results.lastName) results.found = false;
          return JSON.stringify(results);
        } catch(e) {
          return JSON.stringify({found: false});
        }
      })();
    """;

    try {
      final dynamic rawResult = await _controller.runJavaScriptReturningResult(scraperJs);
      final String decodedOnce = jsonDecode(rawResult.toString());
      final Map<String, dynamic> data = jsonDecode(decodedOnce);

      if (mounted) {
        setState(() => _isLoading = false);
        if (data['found'] == true) {
          _showValidationDialog(data);
        } else {
          _showManualConfirmation();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showManualConfirmation();
      }
    }
  }

  void _showValidationDialog(Map<String, dynamic> portalData) {
    final String portalName = "${portalData['firstName']} ${portalData['lastName']}";
    final bool isPinMatch = portalData['pin'] == widget.user.philhealthId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isPinMatch ? Icons.verified : Icons.warning, color: isPinMatch ? Colors.green : Colors.orange),
            const SizedBox(width: 8),
            const Text("Official Data Found"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRow("Name", portalName),
            _buildDataRow("PIN", portalData['pin'] ?? 'N/A'),
            _buildDataRow("DOB", portalData['dob'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          AtamanButton(
            text: "Sync Profile",
            width: 140,
            onPressed: () async {
              await getIt<PhilHealthService>().syncVerifiedData(widget.user.id, portalData);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
      builder: (context) => AlertDialog(
        title: const Text("Capture Failed"),
        content: const Text("Could not read results automatically. Verify manually if your status is 'ACTIVE'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Retry")),
          TextButton(
            onPressed: () async {
              await getIt<PhilHealthService>().updateVerificationStatus(widget.user.id, true);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
            child: const Text("Verify Manually"),
          ),
        ],
      ),
    );
  }
}
