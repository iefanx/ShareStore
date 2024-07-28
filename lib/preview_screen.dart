import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class PreviewScreen extends StatefulWidget {
  final SharedData data;
  final Function(SharedData) onSave;
  final Function() onDelete;

  const PreviewScreen({
    Key? key,
    required this.data,
    required this.onSave,
    required this.onDelete,
  }) : super(key: key);

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late TextEditingController _contentController;
  bool _isEditing = false;
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.data.content);
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    final updatedData = SharedData(
      content: _contentController.text,
      timestamp: DateTime.now(),
    );
    widget.onSave(updatedData);
    _toggleEditMode();
    _showSnackBar('Changes saved successfully');
  }

  void _deleteItem() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                widget.onDelete(); // Perform the delete operation
                _navigateBack(); // Navigate back to the main page
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateBack() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop the PreviewScreen
        _showSnackBar('Item deleted');
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode ? _darkTheme : _lightTheme;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Preview'),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: _isEditing ? _saveChanges : _toggleEditMode,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteItem,
            ),
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last edited: ${DateFormat('MMM d, y HH:mm').format(widget.data.timestamp)}',
                style: TextStyle(color: theme.hintColor),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isEditing
                    ? _buildEditableContent(theme)
                    : _buildMarkdownContent(theme),
              ),
            ],
          ),
        ),
        floatingActionButton: _isEditing
            ? FloatingActionButton(
                onPressed: _saveChanges,
                child: const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  Widget _buildEditableContent(ThemeData theme) {
    return TextField(
      controller: _contentController,
      maxLines: null,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Edit content here...',
        hintStyle: TextStyle(color: theme.hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: theme.primaryColor, width: 2.0),
        ),
        filled: true,
        fillColor: theme.cardColor,
      ),
    );
  }

  Widget _buildMarkdownContent(ThemeData theme) {
    return Markdown(
      data: _contentController.text,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium,
        h1: theme.textTheme.headlineLarge,
        h2: theme.textTheme.headlineMedium,
        h3: theme.textTheme.headlineSmall,
        h4: theme.textTheme.titleLarge,
        h5: theme.textTheme.titleMedium,
        h6: theme.textTheme.titleSmall,
        strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        code: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.secondary,
          fontFamily: 'monospace',
        ),
        blockquote: theme.textTheme.bodyMedium?.copyWith(
          color: theme.hintColor,
          fontStyle: FontStyle.italic,
        ),
        listBullet: theme.textTheme.bodyMedium,
        a: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.secondary,
          decoration: TextDecoration.underline,
        ),
      ),
      selectable: true,
    );
  }

  final ThemeData _darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.blue,
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.orange,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
  );

  final ThemeData _lightTheme = ThemeData.light().copyWith(
    primaryColor: Colors.blue,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.orange,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.grey[100],
  );

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
