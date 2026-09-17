import 'package:flutter/material.dart';

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
            onPressed: () {
              //
            }, 
            icon: Icon(Icons.add_outlined),
          ),
        ],
      ),
    );
  }
}