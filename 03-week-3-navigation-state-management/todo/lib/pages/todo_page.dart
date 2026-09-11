import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  // Menampilkan dialog untuk menambahkan Todo baru.
  void _showAddTodoDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Tugas'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nama tugas',
              hintText: 'Masukkan tugas',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final title = controller.text.trim();

                if (title.isNotEmpty) {
                  // Menggunakan ref.read karena pemanggilan
                  // dilakukan sebagai aksi dari tombol.
                  ref
                      .read(todoListProvider.notifier)
                      .addTodo(title);

                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mengambil daftar Todo dari provider.
    final todos = ref.watch(todoListProvider);

    // Mengambil daftar Todo yang belum selesai
    // dari provider turunan.
    final incompleteTodos = ref.watch(incompleteTodosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Minggu 3'),
      ),

      body: todos.isEmpty
          ? const Center(
              child: Text('Belum ada tugas'),
            )
          : Column(
              children: [
                // Informasi jumlah tugas yang belum selesai.
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Belum selesai: ${incompleteTodos.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),

                // Daftar semua Todo.
                Expanded(
                  child: ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];

                      // Widget Todo sudah dipisahkan menjadi TodoTile.
                      return TodoTile(
                        todo: todo,
                        onToggle: () {
                          ref
                              .read(todoListProvider.notifier)
                              .toggleTodo(todo.id);
                        },
                        onDelete: () {
                          ref
                              .read(todoListProvider.notifier)
                              .removeTodo(todo.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

      // Tombol untuk menambahkan tugas baru.
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}