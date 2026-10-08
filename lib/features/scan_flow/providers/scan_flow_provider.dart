import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/expense_repository.dart';
import '../../../data/models/expense_item.dart';
import '../../../data/ocr/camera_capture_service.dart';
import '../../../data/ocr/ocr_service.dart';
import '../../../data/ocr/receipt_parser.dart';
import '../../expense_list/providers/expense_list_provider.dart';

/// Sealed class representing the scan flow states.
sealed class ScanFlowState {
  const ScanFlowState();
}

class ScanIdle extends ScanFlowState {
  const ScanIdle();
}

class ScanCapturing extends ScanFlowState {
  const ScanCapturing();
}

class ScanRecognizing extends ScanFlowState {
  final String imagePath;
  const ScanRecognizing({required this.imagePath});
}

class ScanParsing extends ScanFlowState {
  const ScanParsing();
}

class ScanReviewing extends ScanFlowState {
  final ParsedReceipt parsedReceipt;
  final String rawOcrText;
  final String imagePath;
  const ScanReviewing({
    required this.parsedReceipt,
    required this.rawOcrText,
    required this.imagePath,
  });
}

class ScanSaving extends ScanFlowState {
  const ScanSaving();
}

class ScanSuccess extends ScanFlowState {
  const ScanSuccess();
}

class ScanError extends ScanFlowState {
  final String message;
  const ScanError({required this.message});
}

/// Notifier for the scan flow state machine.
final scanFlowProvider = NotifierProvider<ScanFlowNotifier, ScanFlowState>(
  ScanFlowNotifier.new,
);

class ScanFlowNotifier extends Notifier<ScanFlowState> {
  final CameraCaptureService _cameraService = CameraCaptureService();
  OcrService? _ocrService;
  bool _isSelectingImage = false;

  @override
  ScanFlowState build() {
    ref.onDispose(() => _ocrService?.dispose());
    return const ScanIdle();
  }

  /// Starts the scan flow by capturing from camera.
  Future<void> captureFromCamera() async {
    await _selectImage(
      _cameraService.captureFromCamera,
      errorPrefix: 'Không thể mở camera',
    );
  }

  /// Starts the scan flow by picking from gallery.
  Future<void> pickFromGallery() async {
    await _selectImage(
      _cameraService.pickFromGallery,
      errorPrefix: 'Không thể chọn ảnh',
    );
  }

  Future<void> _selectImage(
    Future<String?> Function() pickImage, {
    required String errorPrefix,
  }) async {
    if (_isSelectingImage) return;
    _isSelectingImage = true;
    state = const ScanCapturing();

    try {
      final imagePath =
          await _cameraService.retrieveLostImage() ?? await pickImage();
      if (imagePath == null) {
        state = const ScanIdle();
        return;
      }
      await _processImage(imagePath);
    } on CameraCaptureException catch (error) {
      state = ScanError(message: error.message);
    } catch (error) {
      state = ScanError(message: '$errorPrefix: $error');
    } finally {
      _isSelectingImage = false;
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      // Step 1: OCR recognition
      state = ScanRecognizing(imagePath: imagePath);
      _ocrService ??= OcrService();
      final rawText = await _ocrService!.recognizeText(imagePath);

      if (rawText.trim().isEmpty) {
        state = const ScanError(
          message:
              'Không nhận diện được chữ nào trong ảnh. '
              'Hãy thử chụp lại rõ hơn hoặc chọn ảnh khác.',
        );
        return;
      }

      // Step 2: Parse
      state = const ScanParsing();
      final parsedReceipt = ReceiptParser.parse(rawText);

      // Step 3: Review
      state = ScanReviewing(
        parsedReceipt: parsedReceipt,
        rawOcrText: rawText,
        imagePath: imagePath,
      );
    } catch (e) {
      state = ScanError(message: 'Lỗi xử lý ảnh: $e');
    }
  }

  void reset() {
    _ocrService?.dispose();
    _ocrService = null;
    state = const ScanIdle();
  }

  Future<ExpenseItem?> saveExpense(
    ExpenseItem expense, {
    bool allowDuplicate = false,
  }) async {
    final previousState = state;
    state = const ScanSaving();
    try {
      await ref
          .read(expenseRepositoryProvider)
          .insert(expense, allowDuplicate: allowDuplicate);
      ref.invalidate(expenseListProvider);
      state = const ScanSuccess();
      return null;
    } on DuplicateExpenseException catch (error) {
      state = previousState;
      return error.existingExpense;
    } catch (error) {
      state = ScanError(message: 'Không thể lưu chi tiêu: $error');
      rethrow;
    }
  }
}
