const fs = require('fs');
const path = require('path');
const root = process.cwd();
function read(file) { return fs.readFileSync(path.join(root, file), 'utf8'); }
function assert(cond, msg) { if (!cond) { console.error(msg); process.exit(1); } }

const pubspec = read('pubspec.yaml');
assert(/qr_code_scanner_plus:\s*\^/.test(pubspec), 'camera scan must use qr_code_scanner_plus');

const scanPage = read('lib/pages/qr_scan/view.dart');
assert(scanPage.includes('QRView('), 'QR scan camera must use QRView camera scanner');
assert(scanPage.includes('scannedDataStream.listen'), 'QR scan page must listen to QRView scan stream');
assert(!scanPage.includes('MobileScanner('), 'QR scan camera must not use MobileScanner because it crashes on device');
assert(scanPage.includes('MobileScannerController') && scanPage.includes('analyzeImage'), 'Album image scan should keep analyzeImage path');

const favController = read('lib/pages/fav/video/controller.dart');
assert(favController.includes('folderScrollOffsets'), 'Fav controller must remember per-folder list offsets');
assert(favController.includes('saveCurrentFolderOffset'), 'Fav controller must save current folder list offset before switching');
assert(favController.includes('restoreFolderOffset'), 'Fav controller must restore selected folder list offset after switching');
assert(!favController.includes('inlineDetailController.scrollController.offset'), 'Fav folder offset memory must use the visible page scroll controller');
assert(favController.includes('_pendingRestoreOffset'), 'Fav folder offset restore must wait until selected folder data loads');

const homeView = read('lib/pages/home/view.dart');
assert(homeView.includes('Assets.scanIcon'), 'Home search bar must use scan svg asset');
assert(homeView.includes("Get.toNamed('/qrScan')"), 'Home search bar scan action must open /qrScan');
assert(homeView.includes('SvgPicture.asset'), 'Home search bar scan action must render SVG icon');

const assets = read('lib/common/assets.dart');
assert(assets.includes('scanIcon'), 'Assets must expose scan icon');
assert(fs.existsSync(path.join(root, 'assets/images/scan.svg')), 'scan.svg asset must exist');

console.log('Current QR/fav/home regression contract OK');
