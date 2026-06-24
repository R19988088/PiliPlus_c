import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final ImagePicker _imagePicker = ImagePicker();
  bool _handling = false;

  String? _extractLoginAuthCode(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    final query = uri.queryParameters;
    if (query['auth_code'] case final authCode?) return authCode;
    if (query['oauthKey'] case final oauthKey?) return oauthKey;
    if (query['key'] case final key?) return key;
    return null;
  }

  bool _isWebLoginQRCode(String value) {
    final uri = Uri.tryParse(value);
    return uri?.queryParameters.containsKey('qrcode_key') ?? false;
  }

  void _openWebLoginQRCode(String value) {
    SmartDialog.showToast('网页登录二维码将打开确认页面');
    PageUtils.inAppWebview(value);
    Get.back();
  }

  Future<void> _confirmLoginQRCode(String authCode) async {
    if (!Accounts.main.isLogin) {
      SmartDialog.showToast('请先登录当前设备账号');
      _handling = false;
      return;
    }
    final confirmed = await showConfirmDialog(
      context: context,
      title: const Text('确认登录'),
      content: const Text('是否使用当前账号确认这次扫码登录？'),
    );
    if (!confirmed) {
      _handling = false;
      return;
    }

    SmartDialog.showLoading(msg: '确认中');
    final res = await LoginHttp.confirmQRCodeLogin(authCode);
    SmartDialog.dismiss();
    if (res['status'] == true) {
      SmartDialog.showToast('登录确认成功');
      Get.back();
    } else {
      SmartDialog.showToast(res['msg']?.toString() ?? '登录确认失败');
      if (mounted) _handling = false;
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleRawValue(String? rawValue) async {
    final value = rawValue?.trim();
    if (_handling || value == null || value.isEmpty) return;
    _handling = true;

    final authCode = _extractLoginAuthCode(value);
    if (authCode != null && authCode.isNotEmpty) {
      await _confirmLoginQRCode(authCode);
      return;
    }
    if (_isWebLoginQRCode(value)) {
      _openWebLoginQRCode(value);
      return;
    }

    final videoId = IdUtils.matchAvorBv(input: value);
    if (videoId.isNotEmpty && !value.contains('://')) {
      PiliScheme.videoPush(videoId.av, videoId.bv);
      Get.back();
      return;
    }

    final handled = await PiliScheme.routePushFromUrl(value, selfHandle: true);
    if (handled) {
      Get.back();
    } else {
      SmartDialog.showToast('未识别到支持的哔哩哔哩链接');
      if (mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        _handling = false;
      }
    }
  }

  Future<void> _pickImage() async {
    if (_handling) return;
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final capture = await _scannerController.analyzeImage(image.path);
    final barcodes = capture?.barcodes ?? const <Barcode>[];
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        await _handleRawValue(rawValue);
        return;
      }
    }
    SmartDialog.showToast('未识别到二维码');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('扫一扫'),
        actions: [
          IconButton(
            tooltip: '从相册选择',
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.trim().isNotEmpty) {
                  _handleRawValue(rawValue);
                  return;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 3),
                borderRadius: const BorderRadius.all(Radius.circular(24)),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36 + MediaQuery.viewPaddingOf(context).bottom,
            child: FilledButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('扫描相册图片'),
            ),
          ),
        ],
      ),
    );
  }
}
