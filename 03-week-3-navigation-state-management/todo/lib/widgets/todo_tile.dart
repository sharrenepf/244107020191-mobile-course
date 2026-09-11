import 'package:flutter/material.dart';

import '../models/todo.dart';

// TodoTile adalah widget terpisah untuk menampilkan satu Todo.
//
// Pemisahan ini membuat halaman utama menjadi lebih pendek
// dan widget TodoTile dapat diuji secara terpisah.
class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Checkbox digunakan untuk mengubah status Todo.
      leading: Checkbox(
        value: todo.isCompleted,
        onChanged: (_) => onToggle(),
      ),

      // Judul Todo.
      title: Text(
        todo.title,
        style: TextStyle(
          // Jika selesai, teks diberi garis tengah.
          decoration:
              todo.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),

      // Tombol untuk menghapus Todo.
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}