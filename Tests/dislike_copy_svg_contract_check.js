const fs = require('fs');

function read(path) {
  return fs.readFileSync(path, 'utf8');
}
function assert(condition, message) {
  if (!condition) {
    console.error(message);
    process.exit(1);
  }
}
function assertIncludes(text, snippet, message) {
  assert(text.includes(snippet), message + `\nMissing: ${snippet}`);
}
function assertMatches(text, pattern, message) {
  assert(pattern.test(text), message + `\nMissing pattern: ${pattern}`);
}
function assertNotIncludes(text, snippet, message) {
  assert(!text.includes(snippet), message + `\nUnexpected: ${snippet}`);
}

const keys = read('lib/utils/storage_key.dart');
const pref = read('lib/utils/storage_pref.dart');
const extra = read('lib/pages/setting/models/extra_settings.dart');
const assets = read('lib/common/assets.dart');
const pubspec = read('pubspec.yaml');
const popup = read('lib/common/widgets/video_popup_menu.dart');
const ugcView = read('lib/pages/video/introduction/ugc/view.dart');
const header = read('lib/pages/video/widgets/header_control.dart');
const ugcController = read('lib/pages/video/introduction/ugc/controller.dart');
const pgcController = read('lib/pages/video/introduction/pgc/controller.dart');

assertIncludes(pubspec, '- path: assets/images/wiliwili/', 'wiliwili svg assets directory must be registered');
assert(fs.existsSync('assets/images/wiliwili/bpx-svg-sprite-coin.svg'), 'coin svg must be copied into app assets');
assert(fs.existsSync('assets/images/wiliwili/bpx-svg-sprite-share.svg'), 'copy/share svg must be copied into app assets');
assertIncludes(assets, "static const wiliwiliCoin = 'assets/images/wiliwili/bpx-svg-sprite-coin.svg';", 'coin asset constant must exist');
assertIncludes(assets, 'static const wiliwiliCopyLink', 'copy link asset constant must exist');
assertIncludes(assets, "'assets/images/wiliwili/bpx-svg-sprite-share.svg'", 'copy link asset must point to wiliwili svg');

assertIncludes(keys, "disableDislikeFeature = 'disableDislikeFeature'", 'storage key for disabling dislike must exist');
assertIncludes(pref, 'static bool get disableDislikeFeature =>', 'Pref getter for disabling dislike must exist');
assertMatches(pref, /SettingBoxKey\.disableDislikeFeature,[\s\S]{0,80}defaultValue: true/, 'disable dislike must default on');
assertIncludes(extra, "title: '禁用点踩功能'", 'extra settings must expose disable dislike switch');
assertIncludes(extra, 'setKey: SettingBoxKey.disableDislikeFeature', 'disable dislike switch must use the setting key');
assertIncludes(extra, 'defaultVal: true', 'disable dislike switch must default enabled');

assertIncludes(popup, 'if (!Pref.disableDislikeFeature)', 'video card popup dislike action must be hidden by preference');
assertIncludes(ugcView, 'if (!Pref.disableDislikeFeature)', 'video intro dislike action must be hidden by preference');
assertMatches(
  header,
  /if \(introController case final UgcIntroController ugc[\s\S]{0,80}when !Pref\.disableDislikeFeature/,
  'header dislike action must be hidden by preference',
);

assertMatches(popup, /SvgPicture\.asset\(\s*Assets\.wiliwiliCopyLink/, 'popup copy icon must use wiliwili svg');
assertMatches(ugcController, /SvgPicture\.asset\(\s*Assets\.wiliwiliCopyLink/, 'UGC copy link icon must use wiliwili svg');
assertMatches(pgcController, /SvgPicture\.asset\(\s*Assets\.wiliwiliCopyLink/, 'PGC copy link icon must use wiliwili svg');
assertMatches(ugcView, /SvgPicture\.asset\(\s*Assets\.wiliwiliCoin/, 'UGC coin action must use wiliwili svg');
assertMatches(header, /SvgPicture\.asset\(\s*Assets\.wiliwiliCoin/, 'header coin action must use wiliwili svg');

assertIncludes(ugcController, 'final copyText = videoDetail.title?.isNotEmpty == true', 'UGC copy text must include title when available');
assertIncludes(ugcController, "Utils.copyText(copyText);", 'UGC copy link must copy composed text');
assertIncludes(ugcController, "Utils.copyText('$copyText$playedTimePos');", 'UGC precise copy must include composed text');
assertIncludes(pgcController, 'final copyText =', 'PGC copy text must be composed');
assertIncludes(pgcController, "Utils.copyText(copyText);", 'PGC copy link must copy composed text');

assertNotIncludes(ugcView, 'icon: const Icon(FontAwesomeIcons.b)', 'UGC coin action should not keep old FontAwesome B icon');
assertNotIncludes(header, 'FontAwesomeIcons.b,\n                        color: Colors.white', 'header coin action should not keep old FontAwesome B icon');

console.log('dislike/copy/svg contract ok');
