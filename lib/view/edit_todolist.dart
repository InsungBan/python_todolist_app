import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditTodolist extends StatefulWidget {
  const EditTodolist({
    super.key,
    required this.seq,
    required this.content,
  });

  // selected.seq이면서 image.seq과 연결되는 값
  final int seq;

  // 기존 Todo 내용
  final String content;

  @override
  State<EditTodolist> createState() =>
      _EditTodolistState();
}

class _EditTodolistState
    extends State<EditTodolist> {
  static const String baseUrl =
      'http://192.168.10.39:8000';

  late final TextEditingController
      todoController;

  late final FixedExtentScrollController
      imagePickerController;

  final ImagePicker picker = ImagePicker();

  // 편집 화면에서 새로 추가한 이미지
  final List<XFile> imageFiles = [];

  /*
    null이면 기존 서버 이미지를 사용한다.
    값이 있으면 새로 선택한 이미지를 사용한다.
  */
  XFile? selectedImageFile;

  String filename = '기존이미지';
  bool isUpdating = false;

  String get currentImageUrl =>
      '$baseUrl/view/${widget.seq}';

  @override
  void initState() {
    super.initState();

    // 기존 Todo 내용 입력
    todoController = TextEditingController(
      text: widget.content,
    );

    /*
      CupertinoPicker index

      0: 이미지 추가
      1: 기존 이미지
      2 이상: 새로 추가한 이미지
    */
    imagePickerController =
        FixedExtentScrollController(
      initialItem: 1,
    );
  }

  @override
  void dispose() {
    todoController.dispose();
    imagePickerController.dispose();
    super.dispose();
  }

  // 갤러리에서 새로운 이미지 추가
  Future<void> selectImage() async {
    try {
      final XFile? pickedImage =
          await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (!mounted || pickedImage == null) {
        return;
      }

      setState(() {
        imageFiles.add(pickedImage);

        // 새 이미지를 현재 수정 대상으로 선택
        selectedImageFile = pickedImage;
        filename = pickedImage.name;
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!mounted ||
            !imagePickerController.hasClients) {
          return;
        }

        /*
          0번: 이미지 추가
          1번: 기존 이미지

          따라서 새 이미지의 Picker index는
          이미지 개수 + 1이다.
        */
        final int pickerIndex =
            imageFiles.length + 1;

        imagePickerController.animateToItem(
          pickerIndex,
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
    // 이미지 추가 항목에서는 선택 유지
    if (index == 0) {
      return;
    }

    // 기존 이미지 선택
    if (index == 1) {
      setState(() {
        selectedImageFile = null;
        filename = '기존 이미지';
      });

      return;
    }

    /*
      Picker의 실제 이미지 시작 index가 2이므로
      imageFiles에서는 index - 2를 사용한다.
    */
    final XFile selectedImage =
        imageFiles[index - 2];

    setState(() {
      selectedImageFile = selectedImage;
      filename = selectedImage.name;
    });
  }

  // FastAPI를 이용해 Todo 수정
  Future<void> updateTodo() async {
    final String content =
        todoController.text.trim();

    if (content.isEmpty) {
      Get.snackbar(
        '입력 확인',
        'Todo 내용을 입력하세요.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor:
            Colors.orange.shade100,
      );

      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      final http.MultipartRequest request =
          http.MultipartRequest(
        'PUT',
        Uri.parse(
          '$baseUrl/update/${widget.seq}',
        ),
      );

      /*
        FastAPI:

        content: str = Form(...)
      */
      request.fields['content'] = content;

      /*
        새 이미지를 선택했을 때만
        FastAPI에 file을 전송한다.

        selectedImageFile이 null이면
        기존 이미지를 그대로 유지한다.
      */
      if (selectedImageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            selectedImageFile!.path,
            filename:
                selectedImageFile!.name,
          ),
        );
      }

      final http.StreamedResponse
          streamedResponse =
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
          // 이전 화면으로 수정 결과 반환
          Get.back(result: true);

          Get.snackbar(
            '수정 완료',
            'Todo가 수정되었습니다.',
            snackPosition:
                SnackPosition.BOTTOM,
            backgroundColor:
                Colors.green.shade100,
          );

          return;
        }
      }

      Get.snackbar(
        '수정 실패',
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
          isUpdating = false;
        });
      }
    }
  }

  // 왼쪽 선택 이미지
  Widget buildSelectedImage() {
    // 새 이미지가 선택된 경우
    if (selectedImageFile != null) {
      return Image.file(
        File(selectedImageFile!.path),
        fit: BoxFit.cover,
      );
    }

    // 새 이미지가 없으면 기존 서버 이미지
    return Image.network(
      currentImageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return const Center(
          child: Text(
            '기존 이미지를\n불러올 수 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        );
      },
    );
  }

  // 오른쪽 CupertinoPicker 항목
  Widget buildPickerItem(int index) {
    // 첫 번째 항목: 이미지 추가
    if (index == 0) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isUpdating
            ? null
            : selectImage,
        child: const Center(
          child: Text(
            '이미지 추가',
            style: TextStyle(
              color: Color(0xFF2667A8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // 두 번째 항목: 기존 이미지
    if (index == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                currentImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const ColoredBox(
                    color: Color(0xFFE5E5E5),
                    child: Center(
                      child: Text(
                        '기존 이미지',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Align(
                alignment:
                    Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 2,
                  ),
                  color: Colors.black54,
                  child: const Text(
                    '기존 이미지',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 세 번째 항목부터 새로 추가한 이미지
    final XFile pickerImage =
        imageFiles[index - 2];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(pickerImage.path),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9FF),
      appBar: AppBar(
        title: const Text('Edit View'),
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
                        child:
                            buildSelectedImage(),
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
                            1번: 기존 이미지
                            2번 이후: 새 이미지
                          */
                          childCount:
                              imageFiles.length + 2,

                          onSelectedItemChanged:
                              selectPickerImage,

                          itemBuilder:
                              (context, index) {
                            return buildPickerItem(
                              index,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 현재 선택된 이미지 이름
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

              const SizedBox(height: 36),

              // Todo 수정 입력
              TextField(
                controller: todoController,
                enabled: !isUpdating,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  updateTodo();
                },
                decoration:
                    const InputDecoration(
                  hintText: '목록을 입력하세요',
                  border:
                      UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              // 수정 버튼
              Center(
                child: SizedBox(
                  width: 100,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : updateTodo,
                    child: isUpdating
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