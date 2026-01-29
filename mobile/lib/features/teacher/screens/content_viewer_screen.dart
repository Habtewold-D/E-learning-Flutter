import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/utils/constants.dart';

class TeacherContentViewerScreen extends StatefulWidget {
  final String title;
  final String type; // 'pdf' or 'video'
  final String url;

  const TeacherContentViewerScreen({
    super.key,
    required this.title,
    required this.type,
    required this.url,
  });

  @override
  State<TeacherContentViewerScreen> createState() => _TeacherContentViewerScreenState();
}

class _TeacherContentViewerScreenState extends State<TeacherContentViewerScreen> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideo;

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(_resolveUrl(widget.url)));
      _initializeVideo = _videoController!.initialize();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  bool get _isVideo => widget.type.toLowerCase() == 'video';

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = AppConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base/uploads/$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isVideo ? _buildVideo() : _buildPdf(),
    );
  }

  Widget _buildVideo() {
    if (_videoController == null) {
      return const Center(child: Text('Video not available'));
    }

    return FutureBuilder<void>(
      future: _initializeVideo,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            const SizedBox(height: 12),
            IconButton(
              iconSize: 48,
              icon: Icon(
                _videoController!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
              ),
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPdf() {
    final url = _resolveUrl(widget.url);
    return SfPdfViewer.network(url);
  }
}
