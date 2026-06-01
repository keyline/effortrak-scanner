import 'package:flutter/material.dart';

InputDecoration appInputDecoration({
  required String label,
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: const Color(0xFF128C7E)),
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF6FFFA),
    labelStyle: const TextStyle(color: Color(0xFF075E54)),
    hintStyle: TextStyle(color: Colors.grey.shade500),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.green.shade100),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF25D366), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
  );
}
