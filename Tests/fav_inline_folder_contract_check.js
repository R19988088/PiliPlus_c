const fs = require('fs');
const path = require('path');
const root = process.cwd();
function read(file) { return fs.readFileSync(path.join(root, file), 'utf8'); }
function assert(cond, msg) { if (!cond) { console.error(msg); process.exit(1); } }

const view = read('lib/pages/fav/video/view.dart');
assert(view.includes('SliverPersistentHeader'), 'Fav video page must keep the folder cover strip pinned');
assert(view.includes('_FolderStripHeaderDelegate'), 'Fav video page must render a top folder cover strip');
assert(view.includes('pinned: true'), 'Folder cover strip must not scroll away with the list');
assert(view.includes('SingleChildScrollView') && view.includes('scrollDirection: Axis.horizontal'), 'Folder strip must support horizontal drag/scroll');
assert(view.includes('_buildInlineDetailBody'), 'Fav video page must render selected folder content inline');
assert(view.includes('FavVideoCardH'), 'Inline folder content must reuse video cards');
assert(view.includes('Icons.visibility_outlined'), 'Public folders must show open-eye icon');
assert(view.includes('Icons.visibility_off_outlined'), 'Private folders must show closed-eye icon');
assert(view.includes('BiliUtils.isPublicFav'), 'Folder eye icon must follow public/private attr');
assert(!view.includes("Get.toNamed(\n                        '/favDetail'"), 'Folder cover tap must not navigate to favDetail');

const controller = read('lib/pages/fav/video/controller.dart');
assert(controller.includes('selectedFolderIndex'), 'Fav controller must track selected folder index');
assert(controller.includes('inlineDetailController'), 'Fav controller must own inline detail controller');
assert(controller.includes('selectFolder'), 'Fav controller must switch folder inline');
assert(controller.includes('InlineFavDetailController'), 'Fav video page must use inline detail controller');
assert(controller.includes('mediaId = folder.id'), 'Inline detail controller must bind selected folder media id');
assert(controller.includes('folderInfo.value = folder'), 'Inline detail controller must show selected folder info immediately');

console.log('Fav inline folder contract OK');
