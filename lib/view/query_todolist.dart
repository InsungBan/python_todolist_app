import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:python_todolist_app/view/add_todolist.dart';

class QueryTodolist extends StatefulWidget {
  const QueryTodolist({super.key});

  @override
  State<QueryTodolist> createState() => _QueryTodolistState();
}

class _QueryTodolistState extends State<QueryTodolist> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List 검색'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Get.to(AddTodolist()),
            icon: Icon(Icons.add_outlined),
          ),
        ],
      ),
    );
  }
}