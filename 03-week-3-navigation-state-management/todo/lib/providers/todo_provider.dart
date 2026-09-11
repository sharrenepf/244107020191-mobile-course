import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo.dart';

// Notifier digunakan untuk mengelola daftar Todo.
// State yang dikelola berupa List<Todo>.
class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    // State awal berupa daftar Todo kosong.
    return [];
  }

  // Menambahkan Todo baru ke dalam state.
  void addTodo(String title) {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );

    // Membuat List baru, bukan mengubah state lama secara langsung.
    state = [...state, newTodo];
  }

  // Mengubah status selesai/belum selesai sebuah Todo.
  void toggleTodo(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          todo.copyWith(isCompleted: !todo.isCompleted)
        else
          todo,
    ];
  }

  // Menghapus Todo berdasarkan id.
  void removeTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }
}

// Provider utama untuk daftar Todo.
final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(
  TodoListNotifier.new,
);

// Provider turunan untuk menampilkan hanya Todo yang belum selesai.
//
// Provider ini membaca todoListProvider menggunakan ref.watch().
// Jika daftar Todo berubah, provider ini akan menghitung ulang hasil filter.
final incompleteTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);

  return todos
      .where((todo) => !todo.isCompleted)
      .toList();
});