import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
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

  final TextEditingController todoController =
      TextEditingController();

  final ImagePicker picker = ImagePicker();

  final FixedExtentScrollController imagePickerController =
      FixedExtentScrollController();

  // CupertinoPicker에 표시할 이미지 목록
  final List<XFile> imageFiles = [];

  // 현재 선택된 이미지
  XFile? imageFile;

  String filename = '';
  bool isUploading = false;

  @override
  void dispose() {
    todoController.dispose();
    imagePickerController.dispose();
    super.dispose();
  }

  // 갤러리에서 이미지 추가
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
        imageFiles.add(pickedImage);

        // 새로 추가한 이미지를 현재 이미지로 선택
        imageFile = pickedImage;
        filename = pickedImage.name;
      });

      // 새로 추가한 이미지 위치로 Picker 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !imagePickerController.hasClients) {
          return;
        }

        /*
          Picker의 0번 항목은 '이미지 추가'이고
          실제 이미지는 1번부터 시작한다.

          imageFiles.length가 새 이미지의
          Picker index와 동일하다.
        */
        imagePickerController.animateToItem(
          imageFiles.length,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      Get.snackbar(
        '이미지 선택 오류',
        '이미지를 가져오지 못했습니다.\n$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  // CupertinoPicker에서 이미지 선택
  void selectPickerImage(int index) {
    // 0번은 이미지 추가 항목
    if (index == 0) {
      return;
    }

    final XFile selectedImage =
        imageFiles[index - 1];

    setState(() {
      imageFile = selectedImage;
      filename = selectedImage.name;
    });
  }

  // FastAPI 서버에 Todo와 이미지 전송
  Future<void> insertTodo() async {
    final String content =
        todoController.text.trim();

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
      final http.MultipartRequest request =
          http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      /*
        FastAPI:
        content: str = Form(...)
      */
      request.fields['content'] = content;

      /*
        FastAPI:
        file: UploadFile = File(...)
      */
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
          await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode == 200) {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is Map &&
            decoded['result'] == 'OK') {
          // 이전 화면으로 등록 성공 결과 반환
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
      backgroundColor:
          const Color(0xFFFFF9FF),
      appBar: AppBar(
        title: const Text('Add View'),
        centerTitle: true,
        backgroundColor:
            const Color(0xFFFFF9FF),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    // 왼쪽: 현재 선택된 이미지
                    Expanded(
                      child: Container(
                        height: 180,
                        clipBehavior:
                            Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF2F2F2,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            color: Colors.black12,
                          ),
                        ),
                        child: imageFile == null
                            ? const Center(
                                child: Text(
                                  '선택된 이미지가\n없습니다.',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        Colors.black54,
                                  ),
                                ),
                              )
                            : Image.file(
                                File(
                                  imageFile!.path,
                                ),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // 오른쪽: CupertinoPicker
                    Expanded(
                      child: Container(
                        height: 180,
                        clipBehavior:
                            Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFD8ECFF,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFACD4F8,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child:
                            CupertinoPicker.builder(
                          scrollController:
                              imagePickerController,
                          itemExtent: 70,
                          diameterRatio: 1.4,
                          squeeze: 1.0,
                          useMagnifier: true,
                          magnification: 1.08,
                          backgroundColor:
                              const Color(
                            0xFFD8ECFF,
                          ),
                          selectionOverlay:
                              const CupertinoPickerDefaultSelectionOverlay(
                            background: Color(
                              0x223D8BFD,
                            ),
                          ),

                          /*
                            0번: 이미지 추가
                            1번 이후: 추가한 이미지
                          */
                          childCount:
                              imageFiles.length + 1,

                          onSelectedItemChanged:
                              selectPickerImage,

                          itemBuilder:
                              (context, index) {
                            // 가장 첫 번째 항목
                            if (index == 0) {
                              return GestureDetector(
                                behavior:
                                    HitTestBehavior
                                        .opaque,
                                onTap: isUploading
                                    ? null
                                    : selectImage,
                                child: const Center(
                                  child: Text(
                                    '이미지 추가',
                                    style: TextStyle(
                                      color: Color(
                                        0xFF2667A8,
                                      ),
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final XFile
                                pickerImage =
                                imageFiles[
                                    index - 1];

                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  8,
                                ),
                                child: Image.file(
                                  File(
                                    pickerImage.path,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 현재 선택된 파일명
              if (filename.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  filename,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
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
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  insertTodo();
                },
                decoration:
                    const InputDecoration(
                  hintText: '목록을 입력하세요',
                  border:
                      UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              // 등록 버튼
              Center(
                child: SizedBox(
                  width: 100,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: isUploading
                        ? null
                        : insertTodo,
                    child: isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
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