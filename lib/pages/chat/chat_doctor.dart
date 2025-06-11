import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة تحكم الأطباء')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          return SfDataGrid(
            source: ChatDataSource(data),
            columns: [
              GridColumn(
                columnName: 'text',
                label: Container(
                  padding: const EdgeInsets.all(8.0),
                  alignment: Alignment.centerRight,
                  child: const Text('الرسالة'),
                ),
              ),
              GridColumn(
                columnName: 'userName',
                label: Container(
                  padding: const EdgeInsets.all(8.0),
                  alignment: Alignment.centerRight,
                  child: const Text('المرسل'),
                ),
              ),
              GridColumn(
                columnName: 'createdAt',
                label: Container(
                  padding: const EdgeInsets.all(8.0),
                  alignment: Alignment.centerRight,
                  child: const Text('الوقت'),
                ),
              ),
              GridColumn(
                columnName: 'actions',
                label: Container(
                  padding: const EdgeInsets.all(8.0),
                  alignment: Alignment.centerRight,
                  child: const Text('الإجراءات'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatDataSource extends DataGridSource {
  ChatDataSource(List<Map<String, dynamic>> chats) {
    _chats = chats
        .map<DataGridRow>((chat) => DataGridRow(cells: [
      DataGridCell<String>(columnName: 'text', value: chat['text']),
      DataGridCell<String>(columnName: 'userName', value: chat['userName']),
      DataGridCell<Timestamp>(
          columnName: 'createdAt', value: chat['createdAt']),
      DataGridCell<String>(columnName: 'actions', value: 'رد'),
    ]))
        .toList();
  }

  List<DataGridRow> _chats = [];

  @override
  List<DataGridRow> get rows => _chats;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        if (dataGridCell.columnName == 'actions') {
          return Container(
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(Icons.reply),
              onPressed: () {
                // تنفيذ الرد
              },
            ),
          );
        } else if (dataGridCell.columnName == 'createdAt') {
          return Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              (dataGridCell.value as Timestamp).toDate().toString(),
            ),
          );
        } else {
          return Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.all(8.0),
            child: Text(dataGridCell.value.toString()),
          );
        }
      }).toList(),
    );
  }
}