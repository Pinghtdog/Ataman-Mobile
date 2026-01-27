import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AtamanTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool autoFocus;
  final int? maxLines;
  final int? minLines;

  const AtamanTextField({
    super.key,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.readOnly = false,
    this.autoFocus = false,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  State<AtamanTextField> createState() => _AtamanTextFieldState();
}

class _AtamanTextFieldState extends State<AtamanTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      readOnly: widget.readOnly,
      autofocus: widget.autoFocus,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        alignLabelWithHint: true,
        filled: widget.readOnly,
        fillColor: widget.readOnly ? Colors.grey.shade100 : null,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.primary.withOpacity(0.7))
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
