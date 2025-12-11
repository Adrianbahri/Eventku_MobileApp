import 'package:flutter/material.dart';
import '../Utils/app_colors.dart';

class CustomFormField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText = '',
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isPassword;
  }

  // Helper untuk konfigurasi border yang konsisten
  OutlineInputBorder _getInputBorder(BorderSide borderSide) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: borderSide,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 櫨 WARNA STROKE DENGAN OPASITAS 10% (Pasif)
    final passiveBorderColor = AppColors.secondary.withOpacity(0.1);
    // WARNA STROKE DENGAN OPASITAS 100% (Aktif/Fokus)
    final activeBorderColor = AppColors.secondary.withOpacity(1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (Untuk Login/Register)
        if (widget.label.isNotEmpty) 
          Text(
            widget.label, 
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w500, 
              color: AppColors.textDark
            )
          ),
        if (widget.label.isNotEmpty) const SizedBox(height: 8),

        // TextFormField Utama
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _isObscure,
          maxLines: widget.isPassword ? 1 : widget.maxLines, // Pastikan password hanya 1 baris
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: const TextStyle(color: AppColors.textDark), // Teks yang diketik berwarna gelap
          
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: AppColors.textDark.withOpacity(0.5)),
            
            // Icon Prefix
            prefixIcon: widget.prefixIcon != null 
              ? Icon(widget.prefixIcon, color: AppColors.primary) // Icon selalu Primary
              : null, 
            
            // Icon Suffix (Khusus Password)
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  )
                : null,
                
            filled: true,
            fillColor: AppColors.inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            
            // Border Pasif (10%)
            border: _getInputBorder(BorderSide(color: passiveBorderColor, width: 1.5)),
            enabledBorder: _getInputBorder(BorderSide(color: passiveBorderColor, width: 1.5)),
            
            // Border Aktif/Fokus (100%)
            focusedBorder: _getInputBorder(BorderSide(color: activeBorderColor, width: 1.5)),
          ),
        ),
      ],
    );
  }
}