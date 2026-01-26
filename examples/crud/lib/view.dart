import 'package:crud/deps.dart';
import 'package:crud/model.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  const TodoItem(this.todo, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge;
    final controller = controllerRef.of(context);
    final deleting = controller.deletingItems(todo.id).watch(context);

    return Card(
      color: deleting ? theme.colorScheme.surfaceContainerHighest : null,
      elevation: deleting ? 0 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        enabled: !deleting,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          value: todo.completed,
          onChanged: deleting ? null : (_) => controller.toggleTodo(todo.id),
        ),
        title: Text(
          todo.title,
          style: todo.completed
              ? textStyle?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.disabledColor,
                )
              : textStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: deleting ? theme.disabledColor : theme.colorScheme.error,
          ),
          onPressed: deleting ? null : () => controller.deleteTodo(todo.id),
        ),
        onTap: () async {
          final textController = TextEditingController(text: todo.title);
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Edit Todo'),
              content: TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter todo title',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      controller.updateTodo(
                        todo.id,
                        title: textController.text,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = controllerRef.of(context);
    final todosRaw = controller.todosRaw.watch(context);
    final todos = controller.todos.watch(context);
    final currentFilter = controller.currentFilter.watch(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('State Beacon CRUD'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        actions: [
          PopupMenuButton<TodoFilter>(
            initialValue: currentFilter,
            onSelected: (filter) => controller.currentFilter.value = filter,
            itemBuilder: (context) => TodoFilter.values
                .map((f) => PopupMenuItem(
                      value: f,
                      child: Text(f.name.toUpperCase()),
                    ))
                .toList(),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          return switch (todosRaw) {
            AsyncLoading() when todos.isEmpty =>
              const Center(child: CircularProgressIndicator()),
            AsyncError(:final error) when todos.isEmpty => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error: $error',
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            _ => Column(
                children: [
                  if (todosRaw.isLoading) const LinearProgressIndicator(),
                  Expanded(
                    child: todos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_turned_in_outlined,
                                    size: 64,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  'No todos found',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: todos.length,
                            itemBuilder: (context, index) {
                              final todo = todos[index];
                              return TodoItem(todo);
                            },
                          ),
                  ),
                ],
              ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final textController = TextEditingController();
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Todo'),
              content: TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      controller.addTodo(textController.text);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        label: const Text('Add Todo'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
