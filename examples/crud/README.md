# State Beacon CRUD

A Todo application demonstrating robust async state management using `state_beacon`.

<div align='center'>
    <video src='https://github.com/user-attachments/assets/ef1a6525-e627-47fc-9344-fe4e48a87c33' />
</div>

## Project Structure

```
lib/
├── main.dart       # App entry point with LiteRefScope
├── deps.dart       # Dependency injection setup
├── controller.dart # Business logic with beacons
├── service.dart    # Mock backend service
├── model.dart      # Todo and Filter models
└── view.dart       # UI implementation
```

## How Beacons Are Used

This example showcases how to handle async data and filtering.

### 1. Async Data (`todosRaw`)

```dart
late final todosRaw = B.future(service.getTodos);
```
- Fetches initial data automatically.
- Acts as the source of truth for the raw list of todos.
- Updated via `updateWith`.

### 2. Derived State (`todos`)

```dart
late final todos = B.derived(
  () => switch (currentFilter.value) {
    TodoFilter.all => currentTodos,
    TodoFilter.active => currentTodos.where((t) => !t.completed).toList(),
    TodoFilter.completed => currentTodos.where((t) => t.completed).toList(),
  },
);
```
- Automatically recomputes whenever `todosRaw` or `currentFilter` changes.
- Ensures the UI always displays the correct subset of data without manual synchronization.

### 3. Ephemeral State (`deletingItems`)

```dart
late final deletingItems = B.family((int id) => B.writable(false));
```
- A `family` of beacons creates a separate state for each todo item.
- Used to grey out/disable items during deletion.
- Demonstrates how to manage granular state without rebuilding the entire list.

### 4. Async Actions

The controller methods demonstrate how to perform async operations and update the state:

```dart
Future<void> addTodo(String title) async {
  await todosRaw.updateWith(() async {
    final todo = await service.createTodo(title);
    return [...currentTodos, todo];
  });
}
```
- `updateWith` puts the beacon in a loading state (optional) and then updates it with the result of the callback.
- Errors are automatically captured by the beacon.

## Features

- **Create**: Add new todos.
- **Read**: View todos with filtering (All, Active, Completed).
- **Update**: Toggle completion status or edit the title.
- **Delete**: Remove todos with a specific loading state.
- **Async Updates**: UI reflects changes based on the beacon's state lifecycle.
