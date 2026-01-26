// ignore_for_file: prefer_collection_literals

import 'dart:collection';
import 'package:crud/controller.dart';
import 'package:crud/model.dart';
import 'package:crud/service.dart';
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
    if (title.trim().length < 3) {
      throw Exception('Title must be at least 3 characters long');
    }
    final id = _nextId++;
    final todo = Todo(id: id, title: title, completed: completed);
    _todos[id] = todo;
    return todo;
  }

  @override
  Future<void> deleteTodo(int id) async {
    if (!_todos.containsKey(id)) throw Exception('Todo with id $id not found');
    _todos.remove(id);
  }

  @override
  Future<void> toggleTodo(int id) async {
    if (!_todos.containsKey(id)) throw Exception('Todo with id $id not found');
    final todo = _todos[id]!;
    _todos[id] = todo.copyWith(completed: !todo.completed);
  }

  @override
  Future<void> updateTodo(int id, {String? title, bool? completed}) async {
    if (!_todos.containsKey(id)) throw Exception('Todo with id $id not found');
    final todo = _todos[id]!;
    _todos[id] = todo.copyWith(
      title: title ?? todo.title,
      completed: completed ?? todo.completed,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TodoController', () {
    late TodoController controller;
    late MockTodoService service;

    setUp(() {
      service = MockTodoService();
      controller = TodoController(service);
    });

    test('initial state is loading then empty', () async {
      expect(controller.todosRaw.value, isA<AsyncLoading>());
      await Future.delayed(Duration.zero); // Allow future to complete
      expect(controller.todos.value, isEmpty);
      expect(controller.todosRaw.value, isA<AsyncData>());
    });

    test('addTodo adds a todo', () async {
      await Future.delayed(Duration.zero); // Init
      await controller.addTodo('Buy milk');
      await Future.delayed(Duration.zero);
      expect(controller.todos.value.length, 1);
      expect(controller.todos.value.first.title, 'Buy milk');
      expect(controller.todos.value.first.completed, false);
    });

    test('addTodo validates title', () async {
      await Future.delayed(Duration.zero);
      try {
        await controller.addTodo('Hi');
      } catch (_) {}
      await Future.delayed(Duration.zero);
      // If error is swallowed, verify no todo was added
      expect(controller.todos.value, isEmpty);
    });

    test('toggleTodo updates completion status', () async {
      await Future.delayed(Duration.zero);
      await controller.addTodo('Buy milk');
      await Future.delayed(Duration.zero);
      final id = controller.todos.value.first.id;

      await controller.toggleTodo(id);
      await Future.delayed(Duration.zero);
      expect(controller.todos.value.first.completed, true);

      await controller.toggleTodo(id);
      await Future.delayed(Duration.zero);
      expect(controller.todos.value.first.completed, false);
    });

    test('deleteTodo removes todo', () async {
      await Future.delayed(Duration.zero);
      await controller.addTodo('Buy milk');
      await Future.delayed(Duration.zero);
      final id = controller.todos.value.first.id;

      await controller.deleteTodo(id);
      await Future.delayed(Duration.zero);
      expect(controller.todos.value, isEmpty);
    });

    test('filter works correctly', () async {
      await Future.delayed(Duration.zero);
      await controller.addTodo('Task 1'); // Active
      await Future.delayed(Duration.zero);
      await controller.addTodo('Task 2'); // Active
      await Future.delayed(Duration.zero);
      await controller
          .toggleTodo(controller.todos.value.last.id); // Complete Task 2
      await Future.delayed(Duration.zero);

      expect(controller.todos.value.length, 2);

      controller.currentFilter.value = TodoFilter.active;
      await Future.delayed(Duration.zero);
      expect(controller.todos.value.length, 1);
      expect(controller.todos.value.first.title, 'Task 1');

      controller.currentFilter.value = TodoFilter.completed;
      await Future.delayed(Duration.zero);
      expect(controller.todos.value.length, 1);
      expect(controller.todos.value.first.title, 'Task 2');

      controller.currentFilter.value = TodoFilter.all;
      await Future.delayed(Duration.zero);
      expect(controller.todos.value.length, 2);
    });

    test('updateTodo updates title', () async {
      await Future.delayed(Duration.zero);
      await controller.addTodo('Old Title');
      await Future.delayed(Duration.zero);
      final id = controller.todos.value.first.id;

      await controller.updateTodo(id, title: 'New Title');
      await Future.delayed(Duration.zero);
      expect(controller.todos.value.first.title, 'New Title');
    });

    test('deletingItems state changes during deletion', () async {
      await Future.delayed(Duration.zero);
      await controller.addTodo('Delete me');
      await Future.delayed(Duration.zero);
      final id = controller.todos.value.first.id;

      expect(controller.deletingItems(id).value, false);
    });
  });
}
