import 'package:crud/view.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

void main() {
  runApp(
    LiteRefScope(
      child: MaterialApp(
        title: 'State Beacon CRUD',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          textTheme: TextTheme(
            displayLarge: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const TodoListPage(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
