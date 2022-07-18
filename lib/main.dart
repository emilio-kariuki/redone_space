import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'Screens/Home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const GetMaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}
