import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/api_client.dart';
import '../services/course_service.dart';

class UploadContentScreen extends StatefulWidget {
  final String courseId;

  const UploadContentScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<UploadContentScreen> createState() => _UploadContentScreenState();
}

class _UploadContentScreenState extends State<UploadContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedFileType;
  String? _selectedFileName;
  String? _selectedFilePath;
  List<int>? _selectedFileBytes;
  bool _isUploading = false;
  late final CourseService _courseService;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(ApiClient());
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'mov', 'avi', 'mkv', 'webm'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final fileName = file.name;
    final extension = file.extension?.toLowerCase() ?? '';
    final fileType = extension == 'pdf' ? 'pdf' : 'video';

    setState(() {
      _selectedFileType = fileType;
      _selectedFileName = fileName;
      _selectedFilePath = file.path;
      _selectedFileBytes = file.bytes;
    });
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFileType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final courseId = int.tryParse(widget.courseId);
      if (courseId == null) {
        throw Exception('Invalid course id');
      }
      if (_selectedFileName == null) {
        throw Exception('File name not found');
      }

      await _courseService.uploadCourseContent(
        courseId: courseId,
        title: _titleController.text.trim(),
        fileName: _selectedFileName!,
        filePath: _selectedFilePath,
        bytes: _selectedFileBytes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        radius: 30,
                        child: Icon(
                          Icons.upload_file,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Content',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add PDF or video to your course',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Content Title *',
                  hintText: 'e.g., Chapter 1: Introduction',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // File Selection
              Text(
                'Select File',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFileType != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedFileType != null
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                        : Colors.grey[50],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFileType == 'pdf'
                            ? Icons.picture_as_pdf
                            : _selectedFileType == 'video'
                                ? Icons.video_library
                                : Icons.cloud_upload,
                        size: 48,
                        color: _selectedFileType != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedFileName != null) ...[
                        Text(
                          _selectedFileName!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedFileType == 'pdf' ? 'PDF Document' : 'Video File',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Tap to select file',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF or Video',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Upload Button
              ElevatedButton(
                onPressed: _isUploading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Upload Content',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              // Info Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'PDF files will be automatically processed for AI question answering.',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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






