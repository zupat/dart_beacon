// ignore_for_file: prefer_collection_literals

import 'dart:collection';

import 'package:crud/model.dart';

class TodoService {
  final todos = LinkedHashMap<int, Todo>();
  var _nextID = 1;

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 1500));

  Future<List<Todo>> getTodos() async {
    return todos.values.toList();
  }

  Future<Todo> createTodo(String title, {bool completed = false}) async {
    if (title.trim().length < 3) {
      throw Exception('Title must be at least 3 characters long');
    }
    await _delay();
    final id = _nextID++;
    final todo = Todo(id: id, title: title, completed: completed);
    todos[id] = todo;
    return todo;
  }

  Future<void> updateTodo(int id, {String? title, bool? completed}) async {
    await _delay();
    final todo = todos[id];

    if (todo == null) throw Exception('Todo with id $id not found');

    final updatedTodo = Todo(
      id: id,
      title: title ?? todo.title,
      completed: completed ?? todo.completed,
    );

    todos[id] = updatedTodo;
  }

  Future<void> deleteTodo(int id) async {
    await _delay();
    if (todos.remove(id) == null) {
      throw Exception('Todo with id $id not found');
    }
  }

  Future<void> toggleTodo(int id) async {
    await _delay();
    final todo = todos[id];
    if (todo == null) throw Exception('Todo with id $id not found');
    await updateTodo(id, completed: !todo.completed);
  }
}
