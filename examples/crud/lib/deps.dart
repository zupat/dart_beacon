import 'package:crud/controller.dart';
import 'package:crud/service.dart';
import 'package:state_beacon/state_beacon.dart';

final controllerRef = Ref.scoped((_) => TodoController(TodoService()));
