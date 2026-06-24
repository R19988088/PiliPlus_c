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
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart' as qr;

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final GlobalKey _qrViewKey = GlobalKey(debugLabel: 'QR');
  qr.QRViewController? _cameraController;
  final ms.MobileScannerController _imageScannerController =
      ms.MobileScannerController(
    detectionSpeed: ms.DetectionSpeed.noDuplicates,
    formats: const [ms.BarcodeFormat.qrCode],
    autoStart: false,
  );
  final ImagePicker _imagePicker = ImagePicker();
  bool _handling = false;

  @override
  void reassemble() {
    super.reassemble();
    _cameraController?.pauseCamera();
    _cameraController?.resumeCamera();
  }

  String? _extractLoginAuthCode(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    final query = uri.queryParameters;
    if (query['auth_code'] case final authCode?) return authCode;
    if (query['oauthKey'] case final oauthKey?) return oauthKey;
    if (query['key'] case final key?) return key;
    final authCodeMatch = RegExp(
      r'auth_code=([^&]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (authCodeMatch != null) {
      return Uri.decodeComponent(authCodeMatch.group(1)!);
    }
    return null;
  }

  bool _isWebLoginQRCode(String value) {
    return _extractWebLoginQRCodeKey(value) != null;
  }

  String? _extractWebLoginQRCodeKey(String value) {
    final uri = Uri.tryParse(value);
    final key = uri?.queryParameters['qrcode_key'];
    if (key != null && key.isNotEmpty) return key;
    final match = RegExp(
      r'qrcode_key=([^&]+)',
      caseSensitive: false,
    ).firstMatch(value);
    return match == null ? null : Uri.decodeComponent(match.group(1)!);
  }

  Future<void> _confirmWebLoginQRCode(String value) async {
    final qrcodeKey = _extractWebLoginQRCodeKey(value);
    if (qrcodeKey == null || qrcodeKey.isEmpty) {
      SmartDialog.showToast('未识别到网页登录二维码');
      _handling = false;
      _cameraController?.resumeCamera();
      return;
    }
    final confirmed = await showConfirmDialog(
      context: context,
      title: const Text('网页登录二维码'),
      content: const Text('该二维码需要使用官方哔哩哔哩 App 确认登录。是否打开官方 App 扫一扫？'),
    );
    if (!confirmed) {
      _handling = false;
      _cameraController?.resumeCamera();
      return;
    }
    _openOfficialBiliQRCodeScanner();
    _handling = false;
    _cameraController?.resumeCamera();
  }

  void _openOfficialBiliQRCodeScanner() {
    PageUtils.launchURL('bilibili://qrcode');
  }

  Future<void> _confirmLoginQRCode(String authCode) async {
    if (!Accounts.main.isLogin) {
      SmartDialog.showToast('请先登录当前设备账号');
      _handling = false;
      _cameraController?.resumeCamera();
      return;
    }
    final confirmed = await showConfirmDialog(
      context: context,
      title: const Text('确认登录'),
      content: const Text('是否使用当前账号确认这次扫码登录？'),
    );
    if (!confirmed) {
      _handling = false;
      _cameraController?.resumeCamera();
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
      if (mounted) {
        _handling = false;
        _cameraController?.resumeCamera();
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _imageScannerController.dispose();
    super.dispose();
  }

  void _onQrViewCreated(qr.QRViewController controller) {
    _cameraController = controller;
    controller.resumeCamera();
    controller.scannedDataStream.listen((scanData) {
      _handleRawValue(scanData.code);
    });
  }

  Future<void> _handleRawValue(String? rawValue) async {
    final value = rawValue?.trim();
    if (_handling || value == null || value.isEmpty) return;
    _handling = true;
    _cameraController?.pauseCamera();

    final authCode = _extractLoginAuthCode(value);
    if (authCode != null && authCode.isNotEmpty) {
      await _confirmLoginQRCode(authCode);
      return;
    }
    if (_isWebLoginQRCode(value)) {
      await _confirmWebLoginQRCode(value);
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
        _cameraController?.resumeCamera();
      }
    }
  }

  Future<void> _pickImage() async {
    if (_handling) return;
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final capture = await _imageScannerController.analyzeImage(image.path);
    final barcodes = capture?.barcodes ?? const <ms.Barcode>[];
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
          qr.QRView(
            key: _qrViewKey,
            onQRViewCreated: _onQrViewCreated,
            formatsAllowed: const [qr.BarcodeFormat.qrcode],
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
