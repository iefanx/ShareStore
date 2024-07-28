import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharstore/preview_screen.dart';

void main() => runApp(const PocketApp());

class PocketApp extends StatefulWidget {
  const PocketApp({Key? key}) : super(key: key);

  @override
  _PocketAppState createState() => _PocketAppState();
}

class SharedData {
  final String content;
  DateTime timestamp;

  SharedData({required this.content, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static SharedData fromMap(Map<String, dynamic> map) {
    return SharedData(
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  bool containsUrl() {
    return content.contains(RegExp(r'https:\/\/[^\s]+'));
  }

  String extractUrl() {
    final urlMatch = RegExp(r'https:\/\/[^\s]+').firstMatch(content);
    return urlMatch?.group(0) ?? '';
  }
}

class _PocketAppState extends State<PocketApp> {
  late StreamSubscription _intentSub;
  List<SharedData> _sharedData = [];
  List<SharedData> _filteredData = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSharedData();
    _setupReceiveSharingIntent();
    _searchController.addListener(_filterData);
  }

  void _setupReceiveSharingIntent() {
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _handleSharedData(value);
    }, onError: (err) {
      if (kDebugMode) {
        print("getIntentDataStream error: $err");
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _handleSharedData(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedData(List<SharedMediaFile> value) {
    setState(() {
      _sharedData.addAll(value.map((f) => SharedData(
        content: f.path,
        timestamp: DateTime.now(),
      )));
      _sortData();
      _saveSharedData();
    });
  }

  Future<void> _loadSharedData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedData = prefs.getStringList('sharedData');
    if (storedData != null) {
      setState(() {
        _sharedData = storedData.map((item) => SharedData.fromMap(Map<String, dynamic>.from(json.decode(item)))).toList();
        _sortData();
      });
    }
  }

  Future<void> _saveSharedData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data = _sharedData.map((item) => json.encode(item.toMap())).toList();
    await prefs.setStringList('sharedData', data);
  }

  void _deleteSharedData(int index) {
    setState(() {
      _sharedData.removeAt(index);
      _sortData();
      _saveSharedData();
    });
  }

  void _filterData() {
    setState(() {
      _filteredData = _sharedData.where((data) => data.content.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    });
  }

  void _sortData() {
    _sharedData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _filteredData = List.from(_sharedData);
  }

  @override
  void dispose() {
    _intentSub.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ShareStore'),
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Color(0xFFE2E0E0),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: _filteredData.length,
                  itemBuilder: (context, index) {
                    final data = _filteredData[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PreviewScreen(
                              data: data,
                              onSave: (updatedData) {
                                setState(() {
                                  final idx = _sharedData.indexOf(data);
                                  _sharedData[idx] = updatedData;
                                  _sortData();
                                  _saveSharedData();
                                });
                              },
                              onDelete: () {
                                _deleteSharedData(index);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.content,
                              style: TextStyle(
                                color: data.containsUrl() ? Colors.blue : Colors.white,
                                fontSize: 14.0,
                                decoration: data.containsUrl() ? TextDecoration.underline : TextDecoration.none,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              '${data.timestamp.toLocal()}'.split(' ')[0],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
