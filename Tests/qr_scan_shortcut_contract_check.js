const fs = require('fs');
const path = require('path');
const root = process.cwd();
function read(file) { return fs.readFileSync(path.join(root, file), 'utf8'); }
function assert(cond, msg) { if (!cond) { console.error(msg); process.exit(1); } }

const pubspec = read('pubspec.yaml');
assert(/mobile_scanner:\s*\^/.test(pubspec), 'pubspec.yaml must include mobile_scanner');
assert(/qr_code_scanner_plus:\s*\^/.test(pubspec), 'pubspec.yaml must include qr_code_scanner_plus for camera scan');
assert(/image_picker:\s*\^/.test(pubspec), 'pubspec.yaml must keep image_picker for album scan');

const route = read('lib/router/app_pages.dart');
assert(route.includes("pages/qr_scan/view.dart"), 'router must import QR scan page');
assert(route.includes("GetPage(name: '/qrScan'"), 'router must expose /qrScan route');

const pagePath = path.join(root, 'lib/pages/qr_scan/view.dart');
assert(fs.existsSync(pagePath), 'QR scan page file is missing');
const page = fs.readFileSync(pagePath, 'utf8');
assert(page.includes('QRView('), 'QR scan page must use QRView camera scanner');
assert(page.includes('scannedDataStream.listen'), 'QR scan page must listen to QRView scan stream');
assert(!page.includes('MobileScanner('), 'QR scan camera must not use MobileScanner');
assert(page.includes('MobileScannerController'), 'QR scan page must keep image scanner controller');
assert(page.includes('ImagePicker()'), 'QR scan page must use ImagePicker for album images');
assert(page.includes('analyzeImage'), 'QR scan page must decode QR from selected image path');
assert(page.includes('_extractLoginAuthCode'), 'QR scan page must detect login QR auth code');
assert(page.includes('auth_code=([^&]+)'), 'QR scan page must parse auth_code from raw QR text');
assert(page.includes('LoginHttp.confirmQRCodeLogin'), 'QR scan page must confirm login QR codes');
assert(page.includes('showConfirmDialog'), 'QR scan login must ask before confirming login');
assert(page.includes('_isWebLoginQRCode'), 'QR scan page must detect web login QR codes');
assert(page.includes('_extractWebLoginQRCodeKey'), 'QR scan page must extract web login qrcode_key');
assert(page.includes('_openOfficialBiliQRCodeScanner'), 'Web login QR scan must guide users to official Bilibili scanner');
assert(page.includes("PageUtils.launchURL('bilibili://qrcode')"), 'Web login QR scan must try to open official Bilibili QR scanner');
assert(!page.includes('LoginHttp.checkWebQRCodeLogin'), 'Web login QR scan must not call unsupported direct check API');
assert(!page.includes('LoginHttp.confirmWebQRCodeLogin'), 'Web login QR scan must not call unsupported direct confirm API');
assert(page.includes('PiliScheme.routePushFromUrl'), 'QR scan result must reuse existing URL/app scheme router');
assert(page.includes('IdUtils.matchAvorBv'), 'QR scan result must handle plain BV/av content');
assert(page.includes('PiliScheme.videoPush'), 'Plain BV/av QR scan result must open video directly');
assert(!page.includes('PageUtils.videoPush'), 'QR scan page must not call missing PageUtils.videoPush');
assert(page.includes("Icons.photo_library_outlined"), 'QR scan page must expose album scan action');

const manifest = read('android/app/src/main/AndroidManifest.xml');
assert(manifest.includes('android.permission.CAMERA'), 'Android manifest must request camera permission');
assert(manifest.includes('android:host="scan"'), 'Android app scheme must include bilibili://scan host');

const shortcuts = read('android/app/src/main/res/xml-v25/shortcuts.xml');
assert(shortcuts.includes('shortcutId="scan"'), 'Android shortcuts must include scan shortcut id');
assert(shortcuts.includes('@string/scan_qr'), 'Android scan shortcut must use scan_qr string');
assert(shortcuts.includes('bilibili://scan'), 'Android scan shortcut must open bilibili://scan');

const strings = read('android/app/src/main/res/values/string.xml');
assert(strings.includes('<string name="scan_qr">扫一扫</string>'), 'Android strings must define 扫一扫');

const iosPlist = read('ios/Runner/Info.plist');
assert(iosPlist.includes('UIApplicationShortcutItems'), 'iOS must define app icon shortcut items');
assert(iosPlist.includes('<string>扫一扫</string>'), 'iOS app icon shortcut must show 扫一扫');

const iosDelegate = read('ios/Runner/AppDelegate.swift');
assert(iosDelegate.includes('performActionFor shortcutItem'), 'iOS AppDelegate must handle shortcut actions');
assert(iosDelegate.includes('bilibili://scan'), 'iOS scan shortcut must open bilibili://scan');

const scheme = read('lib/utils/app_scheme.dart');
assert(/case 'scan':\s*PageUtils\.toDupNamed\('\/qrScan'/.test(scheme), 'App scheme must route bilibili://scan to /qrScan');
assert(scheme.includes('getInitialLink()'), 'App scheme must handle cold-start shortcut link');

const login = read('lib/http/login.dart');
assert(login.includes('confirmQRCodeLogin'), 'LoginHttp must expose QR login confirmation');
assert(login.includes('Api.qrcodeConfirm'), 'QR login confirmation must use qrcodeConfirm API');
assert(login.includes("'auth_code': authCode"), 'QR login confirmation must submit auth_code');
assert(login.includes("'scanning_type': 1"), 'QR login confirmation must submit scanning_type=1');
assert(!login.includes('checkWebQRCodeLogin'), 'LoginHttp must not keep unsupported web QR check API');
assert(!login.includes('confirmWebQRCodeLogin'), 'LoginHttp must not keep unsupported web QR confirm API');
assert(!login.includes('Api.webQRCodeCheck'), 'Unsupported webQRCodeCheck API constant must not be used');
assert(!login.includes('Api.webQRCodeConfirm'), 'Unsupported webQRCodeConfirm API constant must not be used');

console.log('QR scan shortcut contract OK');
