import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.inter(
      fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, color: Colors.white);
      
  static TextStyle get headingLarge => GoogleFonts.inter(
      fontSize: 20, fontWeight: FontWeight.w700, height: 1.3, color: Colors.white);
      
  static TextStyle get headingMedium => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: Colors.white);
      
  static TextStyle get bodyLarge => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: Colors.white.withValues(alpha: 0.85));
      
  static TextStyle get bodyMedium => GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, height: 1.5, color: Colors.white.withValues(alpha: 0.65));
      
  static TextStyle get caption => GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, height: 1.4, color: Colors.white.withValues(alpha: 0.45));
      
  static TextStyle get code => GoogleFonts.jetBrainsMono(
      fontSize: 13, height: 1.6, color: Colors.white.withValues(alpha: 0.9));
}
