import 'package:flutter/material.dart';

class SHCLogo extends StatelessWidget {
  const SHCLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/logo.png",
      width: 380,
      height: 280,
      fit: BoxFit.fitWidth,
    );
  }
}
