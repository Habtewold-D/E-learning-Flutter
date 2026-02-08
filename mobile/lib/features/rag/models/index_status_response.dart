class IndexStatusResponse {
  final int contentId;
  final String status;
  final int chunksCreated;
  final String? lastUpdated;
  final String? errorMessage;

  IndexStatusResponse({
    required this.contentId,
    required this.status,
    required this.chunksCreated,
    this.lastUpdated,
    this.errorMessage,
  });

  factory IndexStatusResponse.fromJson(Map<String, dynamic> json) {
    return IndexStatusResponse(
      contentId: json['content_id'] ?? 0,
      status: json['status'] ?? 'unknown',
      chunksCreated: json['chunks_created'] ?? 0,
      lastUpdated: json['last_updated'],
      errorMessage: json['error_message'],
    );
  }

  String get statusText {
    switch (status) {
      case 'completed':
        return 'Indexed';
      case 'indexing':
        return 'Processing...';
      case 'not_indexed':
        return 'Not Indexed';
      default:
        return 'Unknown';
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isIndexing => status == 'indexing';
  bool get hasError => errorMessage != null;
}
