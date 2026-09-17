import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QueryTodolist extends StatefulWidget {
  const QueryTodolist({super.key});

  @override
  State<QueryTodolist> createState() => _QueryTodolistState();
}

class _QueryTodolistState extends State<QueryTodolist> {

  List data = [];
  String dataUrl = 'http://192.168.10.39:8000';

  @override
  void initState() {
    super.initState();
    getJSONData();
  }


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
      body: data.isEmpty
      ? Center(child: Text('데이터가 없습니다.'),)
      : ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          return Card(
            child: Row(
              children: [
                Image.network(
                  '$dataUrl/view/${data[index]['seq']}',
                  width: 100,
                ),
                Text('  ${data[index]['content']}  /  '),
                Text(
                  (data[index]['insertdate']).toString().substring(0,10)
                ),
              ],
            ),
          );
        },),
    );
  }

  Future<void> getJSONData() async{
    var url = Uri.parse('$dataUrl/select');
    var response = await http.get(url);
    data.clear();
    var dataConvertedJSON = json.decode(utf8.decode((response.bodyBytes)));
    List result = dataConvertedJSON['todoResult'];
    data.addAll(result);
    setState(() {});
  }
}