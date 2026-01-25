import 'package:crud/model.dart';
import 'package:crud/service.dart';
import 'package:state_beacon/state_beacon.dart';

class TodoController with BeaconController {
  final TodoService service;

  TodoController(this.service);

  late final todosRaw = B.future(service.getTodos);
  List<Todo> get currentTodos => todosRaw.value.lastData ?? <Todo>[];

  late final isLoading = B.derived(() => todosRaw.value.isLoading);
  late final currentFilter = B.writable<TodoFilter>(TodoFilter.all);
  late final todos = B.derived(
    () => switch (currentFilter.value) {
      TodoFilter.all => currentTodos,
      TodoFilter.active => currentTodos.where((t) => !t.completed).toList(),
      TodoFilter.completed => currentTodos.where((t) => t.completed).toList(),
    },
  );

  Future<void> addTodo(String title) async {
    await todosRaw.updateWith(() async {
      final todo = await service.createTodo(title);
      return [...currentTodos, todo];
    });
  }

  Future<void> updateTodo(int id, {String? title, bool? completed}) async {
    await todosRaw.updateWith(() async {
      await service.updateTodo(id, title: title, completed: completed);
      return currentTodos
          .map((todo) => todo.id == id
              ? todo.copyWith(title: title, completed: completed)
              : todo)
          .toList();
    });
  }

  Future<void> deleteTodo(int id) async {
    await todosRaw.updateWith(() async {
      await service.deleteTodo(id);
      return currentTodos.where((todo) => todo.id != id).toList();
    });
  }

  Future<void> toggleTodo(int id) async {
    await todosRaw.updateWith(() async {
      await service.toggleTodo(id);
      return currentTodos
          .map((todo) =>
              todo.id == id ? todo.copyWith(completed: !todo.completed) : todo)
          .toList();
    });
  }
}
