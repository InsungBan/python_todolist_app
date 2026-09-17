import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddTodolist extends StatefulWidget {
  const AddTodolist({super.key});

  @override
  State<AddTodolist> createState() => _AddTodolistState();
}

class _AddTodolistState extends State<AddTodolist> {
  static const String baseUrl = 'http://192.168.10.39:8000';

  final TextEditingController todoController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  XFile? imageFile;
  String filename = '';
  bool isUploading = false;

  @override
  void dispose() {
    todoController.dispose();
    super.dispose();
  }

  // 갤러리에서 이미지 선택
  Future<void> selectImage() async {
    try {
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (!mounted || pickedImage == null) {
        return;
      }

      setState(() {
        imageFile = pickedImage;
        filename = pickedImage.name;
      });
    } catch (e) {
      Get.snackbar(
        '이미지 선택 오류',
        '이미지를 가져오지 못했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  // FastAPI에 Todo와 이미지 전송
  Future<void> insertTodo() async {
    final String content = todoController.text.trim();

    if (content.isEmpty) {
      Get.snackbar(
        '입력 확인',
        'Todo 내용을 입력하세요.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
      );
      return;
    }

    if (imageFile == null) {
      Get.snackbar(
        '이미지 확인',
        '이미지를 선택하세요.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      // FastAPI의 content: str = Form(...)
      request.fields['content'] = content;

      // FastAPI의 file: UploadFile = File(...)
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile!.path,
          filename: filename,
        ),
      );

      final http.StreamedResponse streamedResponse =
          await request.send().timeout(
                const Duration(seconds: 20),
              );

      final http.Response response =
          await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['result'] == 'OK') {
          // 이전 화면으로 true를 반환
          Get.back(result: true);

          Get.snackbar(
            '등록 완료',
            'Todo가 등록되었습니다.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
          );
          return;
        }
      }

      Get.snackbar(
        '등록 실패',
        '서버 응답: ${response.body}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } catch (e) {
      Get.snackbar(
        '통신 오류',
        '서버에 연결할 수 없습니다.\n$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FF),
      appBar: AppBar(
        title: const Text('Add View'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF9FF),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이미지 선택 영역
              Center(
                child: GestureDetector(
                  onTap: isUploading ? null : selectImage,
                  child: Container(
                    width: 230,
                    height: 180,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8ECFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFACD4F8),
                        width: 1.5,
                      ),
                    ),
                    child: imageFile == null
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '이미지 선택',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '눌러서 갤러리 열기',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(imageFile!.path),
                                fit: BoxFit.cover,
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  color: Colors.black54,
                                  child: const Text(
                                    '눌러서 이미지 변경',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              if (filename.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  filename,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Todo 입력
              TextField(
                controller: todoController,
                enabled: !isUploading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => insertTodo(),
                decoration: const InputDecoration(
                  hintText: '목록을 입력하세요',
                  border: UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              // 등록 버튼
              Center(
                child: SizedBox(
                  width: 100,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: isUploading ? null : insertTodo,
                    child: isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('OK'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}