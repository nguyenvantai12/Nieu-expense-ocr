import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wrapper for Google ML Kit Text Recognition
class OcrService {
  final TextRecognizer _textRecognizer;

  OcrService()
    : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Processes the image at [imagePath] and returns the extracted raw text.
  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      return recognizedText.text;
    } catch (e) {
      throw Exception('OCR Error: $e');
    }
  }

  /// MUST be called when the service is no longer needed to free up resources.
  void dispose() {
    _textRecognizer.close();
  }
}
