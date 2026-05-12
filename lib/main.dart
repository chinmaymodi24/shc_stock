import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';

void main() {
  runApp(const SecureHeatCareApp());
}

class SecureHeatCareApp extends StatelessWidget {
  const SecureHeatCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Secure Heat Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B1888),
          primary: const Color(0xFF2B1888),
          secondary: const Color(0xFFF47B20),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEEECFF),
      ),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
