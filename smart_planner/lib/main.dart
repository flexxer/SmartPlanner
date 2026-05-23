import 'package:flutter/material.dart';
import 'package:smart_planner/app.dart';
import 'package:smart_planner/core/app_initializer.dart';

Future<void> main() async {
  await AppInitializer.init();
  runApp(const SmartPlannerApp());
}
