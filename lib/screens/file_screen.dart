import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cuttinglist/database_helper.dart';
import 'package:cuttinglist/screens/csv_ui.dart';
import 'package:cuttinglist/screens/drawingboard_screen.dart'; // Ensure this file exists

class FileScreen extends StatefulWidget {
  final int folderId;

  FileScreen({required this.folderId});

  @override
  _FileScreenState createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  final _fileController = TextEditingController();
  final _contentController = TextEditingController();
  List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  // Load the files from the database
  _loadFiles() async {
    try {
      var files = await DatabaseHelper().getFiles(widget.folderId);
      setState(() {
        _files = files;
      });
    } catch (e) {
      print("Error loading files: $e");
    }
  }

  // Create a new file and add it to the database
  _createFile() async {
    if (_fileController.text.isNotEmpty && _contentController.text.isNotEmpty) {
      try {
        await DatabaseHelper().insertFile(
            widget.folderId, _fileController.text, _contentController.text);
        _fileController.clear();
        _contentController.clear();
        _loadFiles(); // Refresh file list
      } catch (e) {
        print("Error creating file: $e");
      }
    }
  }

  // Show dialog to create a new file
  _showFileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create New File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _fileController,
                decoration: InputDecoration(labelText: 'File Name'),
              ),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'File Content'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _createFile();
                Navigator.pop(context);
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Files")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: _files.length,
          itemBuilder: (context, index) {
            final file = _files[index];
            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ListTile(
                leading:
                    Icon(Icons.insert_drive_file, color: Colors.blue, size: 40),
                title: Text(
                  file['name'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Created: ${DateFormat('dd MMM yyyy').format(
                    DateTime.parse(file['created_at'] ?? ''),
                  )}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CsvDisplayPage(fileId: file['id']),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showFileDialog,
              child: Icon(Icons.add),
              backgroundColor: Colors.blue,
              heroTag: 'addFile',
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DrawingScreen()),
                );
              },
              child: Icon(Icons.brush),
              backgroundColor: Colors.green,
              heroTag: 'openCanva',
              tooltip: 'Open Canva',
            ),
          ),
        ],
      ),
    );
  }
}
