import 'package:crud/view.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

void main() {
  runApp(
    LiteRefScope(
      child: MaterialApp(
        title: 'State Beacon Animation Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: TodoListPage(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
