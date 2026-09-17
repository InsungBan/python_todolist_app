import 'package:get/get.dart';
import 'package:http/http.dart' as http;


Future<void> deleteTodo(int seq) async {
  try {
    final response = await http.delete(
      Uri.parse('http://192.168.10.39:8000/todos/$seq'),
    );

    if (response.statusCode == 200) {
      Get.back();

      // 기존 Todo 목록 조회 함수
      await getTodoList();
    } else {
      Get.snackbar(
        '삭제 실패',
        '삭제할 수 없습니다.',
      );
    }
  } catch (e) {
    print('Delete Error: $e');

    Get.snackbar(
      '오류',
      '서버 연결에 실패했습니다.',
    );
  }
}



void confirmDelete(int seq) {
  Get.dialog(
    AlertDialog(
      title: const Text('삭제'),
      content: const Text('이 일정을 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            deleteTodo(seq);
          },
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}