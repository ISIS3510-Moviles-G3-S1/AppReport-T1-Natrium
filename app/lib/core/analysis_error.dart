sealed class AnalysisError implements Exception {
  const AnalysisError();

  String get userMessage;
  String get recoverySuggestion;

  const factory AnalysisError.modelLoadFailed() = _ModelLoadFailedError;
  const factory AnalysisError.invalidImage() = _InvalidImageError;
  const factory AnalysisError.noResults() = _NoResultsError;
  const factory AnalysisError.processingFailed(String message) = _ProcessingFailedError;
  const factory AnalysisError.colorExtractionFailed() = _ColorExtractionFailedError;
}

class _ModelLoadFailedError extends AnalysisError {
  const _ModelLoadFailedError();

  @override
  String get userMessage => 'We could not load the clothing analysis model.';

  @override
  String get recoverySuggestion => 'Try again in a moment. If the issue persists, use a clearer photo.';
}

class _InvalidImageError extends AnalysisError {
  const _InvalidImageError();

  @override
  String get userMessage => 'The selected image is not valid.';

  @override
  String get recoverySuggestion => 'Pick a different photo with the clothing item clearly visible.';
}

class _NoResultsError extends AnalysisError {
  const _NoResultsError();

  @override
  String get userMessage => 'No clothing details could be detected.';

  @override
  String get recoverySuggestion => 'Use a photo with better lighting and a single item in frame.';
}

class _ProcessingFailedError extends AnalysisError {
  final String message;

  const _ProcessingFailedError(this.message);

  @override
  String get userMessage => 'The image could not be analyzed right now.';

  @override
  String get recoverySuggestion => 'Check your connection or try another photo.';

  @override
  String toString() => 'AnalysisError.processingFailed($message)';
}

class _ColorExtractionFailedError extends AnalysisError {
  const _ColorExtractionFailedError();

  @override
  String get userMessage => 'We could not extract dominant colors from the image.';

  @override
  String get recoverySuggestion => 'Try a photo with stronger lighting or a more centered subject.';
}