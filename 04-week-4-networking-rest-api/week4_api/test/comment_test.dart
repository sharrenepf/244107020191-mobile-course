import 'package:flutter_test/flutter_test.dart';

import 'package:week4_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson aman terhadap field yang hilang', () {
    final comment = Comment.fromJson({
      'id': 5,
      'postId': 1,
    });

    expect(comment.id, 5);
    expect(comment.postId, 1);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}