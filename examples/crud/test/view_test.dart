import 'dart:collection';

import 'package:crud/controller.dart';
import 'package:crud/deps.dart';
import 'package:crud/model.dart';
import 'package:crud/service.dart';
import 'package:crud/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon/state_beacon.dart';

class MockTodoService implements TodoService {
  final _todos = LinkedHashMap<int, Todo>();
  int _nextId = 1;

  @override
  get todos => _todos;

  @override
  Future<List<Todo>> getTodos() async {
    return _todos.values.toList();
  }

  @override
  Future<Todo> createTodo(String title, {bool completed = false}) async {
    final id = _nextId++;
    final todo = Todo(id: id, title: title, completed: completed);
    _todos[id] = todo;
    return todo;
  }

  @override
  Future<void> deleteTodo(int id) async {
    _todos.remove(id);
  }

  @override
  Future<void> toggleTodo(int id) async {
    if (_todos.containsKey(id)) {
      final todo = _todos[id]!;
      _todos[id] = todo.copyWith(completed: !todo.completed);
    }
  }

  @override
  Future<void> updateTodo(int id, {String? title, bool? completed}) async {
    if (_todos.containsKey(id)) {
      final todo = _todos[id]!;
      _todos[id] = todo.copyWith(
        title: title ?? todo.title,
        completed: completed ?? todo.completed,
      );
    }
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TodoListPage Widget Tests', () {
    late TodoController controller;
    late MockTodoService service;

    setUp(() {
      service = MockTodoService();
      controller = TodoController(service);
    });

    Widget createWidgetUnderTest() {
      return LiteRefScope(
        overrides: {
          controllerRef.overrideWith((_) => controller),
        },
        child: MaterialApp(
          home: const TodoListPage(),
        ),
      );
    }

    testWidgets('shows empty state initially', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Wait for future beacon

      expect(find.text('No todos found'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_turned_in_outlined), findsOneWidget);
    });

    testWidgets('can add a todo', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Check dialog
      expect(find.text('Add Todo'), findsNWidgets(2)); // FAB + Dialog title
      
      // Enter text
      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify added
      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('No todos found'), findsNothing);
    });

    testWidgets('can toggle a todo', (tester) async {
      await service.createTodo('Buy milk');
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Buy milk'), findsOneWidget);
      
      // Find checkbox
      final checkboxFinder = find.byType(Checkbox);
      final checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.value, false);

      // Tap checkbox
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify checked
      final checkboxChecked = tester.widget<Checkbox>(checkboxFinder);
      expect(checkboxChecked.value, true);
      
      // Verify strikethrough style
      final textWidget = tester.widget<Text>(find.text('Buy milk'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('can delete a todo', (tester) async {
      await service.createTodo('Buy milk');
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Buy milk'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Buy milk'), findsNothing);
      expect(find.text('No todos found'), findsOneWidget);
    });

    testWidgets('can edit a todo', (tester) async {
      await service.createTodo('Buy milk');
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap list tile
      await tester.tap(find.text('Buy milk'));
      await tester.pumpAndSettle();

      // Check dialog
      expect(find.text('Edit Todo'), findsOneWidget);
      expect(find.text('Buy milk'), findsNWidgets(2)); // List item + Dialog text field

      // Edit text
      await tester.enterText(find.byType(TextField), 'Buy almond milk');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Buy almond milk'), findsOneWidget);
    });

    testWidgets('can filter todos', (tester) async {
      await service.createTodo('Task 1'); // Active
      await service.createTodo('Task 2', completed: true); // Completed
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);

      // Open filter menu
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select Active
      await tester.tap(find.text('ACTIVE'));
      await tester.pumpAndSettle();

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsNothing);

      // Open filter menu
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select Completed
      await tester.tap(find.text('COMPLETED'));
      await tester.pumpAndSettle();

      expect(find.text('Task 1'), findsNothing);
      expect(find.text('Task 2'), findsOneWidget);

      // Open filter menu
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select All
      await tester.tap(find.text('ALL'));
      await tester.pumpAndSettle();

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
    });
  });
}
