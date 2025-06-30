import 'dart:core';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern for DatabaseHelper instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  // Private constructor
  DatabaseHelper._internal();

  // Lazy loading of the database (initializes only when needed)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database =
        await _initDatabase(); // Initialize the database when first accessed
    return _database!;
  }

  // Initialize the database with version and create tables
  Future<Database> _initDatabase() async {
    // Get the database path
    String path = join(await getDatabasesPath(), 'folder_file.db');

    // Open the database and create tables if not exists
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Create the 'folders' table
        await db.execute('''
          CREATE TABLE folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            created_at TEXT
          )
        ''');

        // Create the 'files' table with a foreign key constraint
        await db.execute('''
          CREATE TABLE files(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folder_id INTEGER,
            name TEXT,
            content TEXT,
            created_at TEXT,
            FOREIGN KEY(folder_id) REFERENCES folders(id)
          )
        ''');

        await db.execute('''
        CREATE TABLE drawings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          file_id INTEGER,
          drawing_data TEXT,
          created_at TEXT,
          FOREIGN KEY(file_id) REFERENCES files(id)
        )
      ''');
        await db.execute('''
        CREATE TABLE csv_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT,
          length TEXT,
          width TEXT,
          depth TEXT,
          lengthSize TEXT,
          widthSize TEXT,
          qty TEXT,
          panel TEXT,
          file_id INTEGER, 
          FOREIGN KEY(file_id) REFERENCES files(id)
)
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Handle any schema upgrades here
          // Example: Alter table, add columns, etc.
        }
      },
    );
  }

  // Insert a new folder into the 'folders' table
  Future<void> insertFolder(String folderName) async {
    final db = await database; // Ensure you have initialized the database

    await db.insert(
      'folders',
      {
        'name': folderName,
        'created_at': DateTime.now().toIso8601String(), // Store creation time
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replace existing rows if conflict
    );
  }

  // Fetch all folders from the 'folders' table, ordered by creation time
  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.query(
      'folders',
      orderBy:
          'created_at DESC', // Sort folders by creation date in descending order
    );
  }

  // Insert a new file into the 'files' table
  Future<void> insertFile(int folderId, String fileName, String content) async {
    final db = await database;

    await db.insert(
      'files',
      {
        'folder_id': folderId,
        'name': fileName,
        'content': content,
        'created_at':
            DateTime.now().toIso8601String(), // Store file creation time
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replace existing rows if conflict
    );
  }

  // Fetch all files from the 'files' table based on the folderId, ordered by creation date
  Future<List<Map<String, dynamic>>> getFiles(int folderId) async {
    final db = await database;

    return await db.query(
      'files',
      where: 'folder_id = ?', // Filter files by the folder ID
      whereArgs: [folderId], // Bind folder ID to the query
      orderBy:
          'created_at DESC', // Sort files by creation date in ascending order
    );
  }

  // Update a file's content by ID
  Future<int> updateFile(int fileId, String content) async {
    final db = await database;
    return await db.update(
      'files',
      {'content': content}, // Update the content field
      where: 'id = ?',
      whereArgs: [fileId],
    );
  }

  // Delete a file by ID
  Future<int> deleteFile(int fileId) async {
    final db = await database;
    return await db.delete(
      'files',
      where: 'id = ?',
      whereArgs: [fileId],
    );
  }

  // Delete a folder by ID (also deletes associated files)
  Future<int> deleteFolder(int folderId) async {
    final db = await database;
    await db.delete(
      'files',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    ); // Delete all files in the folder first

    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [folderId],
    ); // Then delete the folder itself
  }

  // Helper function to get all files and their associated folders
  Future<List<Map<String, dynamic>>> getFilesWithFolders() async {
    final db = await database;

    // Join 'folders' and 'files' tables to get files with folder details
    return await db.rawQuery('''
      SELECT files.*, folders.name AS folder_name
      FROM files
      JOIN folders ON files.folder_id = folders.id
      ORDER BY files.created_at DESC
    ''');
  }

  Future<int> insertCsvDataForFile(
      int fileId, Map<String, dynamic> data) async {
    final db = await database;
    data['file_id'] = fileId; // Ensure file_id is added to the data
    return await db.insert('csv_data', data);
  }

  Future<List<Map<String, dynamic>>> fetchCsvDataForFile(int fileId) async {
    final db = await database;
    return await db.query(
      'csv_data',
      where: 'file_id = ?', // Filter by file_id
      whereArgs: [fileId], // Bind the file_id
    );
  }

  Future<void> insertDrawing(int fileId, String drawingData) async {
    final db = await database;
    await db.insert(
      'drawings',
      {
        'file_id': fileId,
        'drawing_data': drawingData, // Save the drawing data as a JSON string
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get drawing data associated with a specific file
  Future<List<Map<String, dynamic>>> getDrawing(int fileId) async {
    final db = await database;
    return await db.query(
      'drawings',
      where: 'file_id = ?',
      whereArgs: [fileId],
    );
  }
}
