import 'package:flutter/material.dart';
import '../../../../core/widgets/ataman_button.dart';
import '../../../../core/services/pdf_service.dart';
import '../../data/models/user_model.dart';

class PatientEnrollmentForm extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onSave;
  final VoidCallback onCancel;

  const PatientEnrollmentForm({
    super.key,
    required this.user,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<PatientEnrollmentForm> createState() => _PatientEnrollmentFormState();
}

class _PatientEnrollmentFormState extends State<PatientEnrollmentForm> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  late UserModel _updatedUser;

  // Controllers for text fields
  final _motherNameController = TextEditingController();
  final _birthplaceController = TextEditingController();
  final _residentialAddressController = TextEditingController();
  final _maidenNameController = TextEditingController();
  final _philhealthIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updatedUser = widget.user;
    _motherNameController.text = widget.user.motherName ?? '';
    _birthplaceController.text = widget.user.birthplace ?? '';
    _residentialAddressController.text = widget.user.residentialAddress ?? '';
    _maidenNameController.text = widget.user.maidenName ?? '';
    _philhealthIdController.text = widget.user.philhealthId ?? '';
  }

  @override
  void dispose() {
    _motherNameController.dispose();
    _birthplaceController.dispose();
    _residentialAddressController.dispose();
    _maidenNameController.dispose();
    _philhealthIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Column(
              children: [
                if (_currentStep == 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AtamanButton(
                      text: "Preview Enrollment Form",
                      isOutlined: true,
                      icon: Icons.picture_as_pdf,
                      onPressed: () => PdfService.previewPdf(_updatedUser),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: AtamanButton(
                        text: _currentStep == 2 ? "Submit & Consent" : "Continue",
                        onPressed: details.onStepContinue,
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text("Back"),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text("Personal"),
            isActive: _currentStep >= 0,
            content: _buildPersonalInfo(),
          ),
          Step(
            title: const Text("Social"),
            isActive: _currentStep >= 1,
            content: _buildSocialInfo(),
          ),
          Step(
            title: const Text("Consent"),
            isActive: _currentStep >= 2,
            content: _buildConsentInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      children: [
        if (_updatedUser.gender == 'Female')
          _buildTextField("Maiden Name (for married women)", _maidenNameController,
              (val) => _updatedUser = _updatedUser.copyWith(maidenName: val)),
        _buildTextField("Mother's Name", _motherNameController,
            (val) => _updatedUser = _updatedUser.copyWith(motherName: val),
            required: true),
        _buildTextField("Birthplace", _birthplaceController,
            (val) => _updatedUser = _updatedUser.copyWith(birthplace: val),
            required: true),
        _buildTextField("Residential Address", _residentialAddressController,
            (val) => _updatedUser = _updatedUser.copyWith(residentialAddress: val),
            required: true),
        const SizedBox(height: 16),
        _buildDropdown("Civil Status",
            ["Single", "Married", "Widow/er", "Separated", "Annulled", "Co-Habitation"],
            _updatedUser.civilStatus, (val) {
          setState(() => _updatedUser = _updatedUser.copyWith(civilStatus: val));
        }),
      ],
    );
  }

  Widget _buildSocialInfo() {
    return Column(
      children: [
        _buildDropdown(
            "Educational Attainment",
            ["No Formal Education", "Elementary", "High School", "Vocational", "College", "Post Graduate"],
            _updatedUser.education, (val) {
          setState(() => _updatedUser = _updatedUser.copyWith(education: val));
        }),
        const SizedBox(height: 16),
        _buildDropdown(
            "Employment Status",
            ["Student", "Employed", "Unemployed", "Retired", "Unknown"],
            _updatedUser.employmentStatus, (val) {
          setState(() => _updatedUser = _updatedUser.copyWith(employmentStatus: val));
        }),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text("4Ps Member?"),
          value: _updatedUser.is4psMember,
          onChanged: (val) =>
              setState(() => _updatedUser = _updatedUser.copyWith(is4psMember: val)),
        ),
        _buildTextField("PhilHealth ID Number", _philhealthIdController,
            (val) => _updatedUser = _updatedUser.copyWith(philhealthId: val)),
        _buildDropdown("PhilHealth Status", ["Member", "Dependent", "None"],
            _updatedUser.philhealthStatus, (val) {
          setState(() => _updatedUser = _updatedUser.copyWith(philhealthStatus: val));
        }),
      ],
    );
  }

  Widget _buildConsentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PATIENT'S CONSENT (PAHINTULOT)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const SingleChildScrollView(
            child: Text(
              "I permit the CHU/RHU to encode the information concerning my person and the collected data regarding disease symptoms and consultations for the Integrated Clinic Information System (iClinicSys). I have been informed about the importance of this system.\n\n"
              "Pinapayagan ko ang CHU/RHU upang i-encode ang mga impormasyon patungkol sa akin at ang mga nakolektang impormasyon tungkol sa mga sintomas ng aking sakit at konsultasyong kaugnay dito para sa iClinicSys.",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text("I have read and understood the consent form."),
          value: _updatedUser.isProfileComplete,
          onChanged: (val) =>
              setState(() => _updatedUser = _updatedUser.copyWith(isProfileComplete: val ?? false)),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      Function(String) onChanged,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onChanged: onChanged,
        validator: required
            ? (val) => val == null || val.isEmpty ? "Required" : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(
      String label, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      value: items.contains(value) ? value : null,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Required" : null,
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else {
      if (_updatedUser.isProfileComplete) {
        widget.onSave(_updatedUser);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please check the consent box to proceed")),
        );
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      widget.onCancel();
    }
  }
}
