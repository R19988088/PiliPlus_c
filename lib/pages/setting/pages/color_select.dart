import 'dart:io' show Platform;

import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models/common/theme/theme_color_type.dart';
import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/setting/widgets/select_dialog.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ColorSelectPage extends StatefulWidget {
  const ColorSelectPage({super.key});

  @override
  State<ColorSelectPage> createState() => _ColorSelectPageState();
}

class _ColorSelectPageState extends State<ColorSelectPage> {
  final ctr = Get.put(_ColorSelectController());

  Future<void> _updateThemeColor(Color color) async {
    ctr.currentColor.value = color.toARGB32();
    await GStorage.setting.put(SettingBoxKey.customColor, color.toARGB32());
    Get.updateMyAppTheme();
  }

  Widget _channelSlider({
    required BuildContext context,
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text(title)),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              min: 0,
              max: 255,
              divisions: 255,
              value: value.toDouble(),
              label: value.toString(),
              onChanged: (newValue) => onChanged(newValue.round()),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            child: Text(
              value.toString(),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    TextStyle titleStyle = theme.textTheme.titleMedium!;
    TextStyle subTitleStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.viewPaddingOf(
      context,
    ).copyWith(top: 0, bottom: 0);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('选择应用主题')),
      body: ListView(
        children: [
          ListTile(
            onTap: () async {
              final result = await showDialog<ThemeType>(
                context: context,
                builder: (context) => SelectDialog<ThemeType>(
                  title: '主题模式',
                  value: ctr.themeType.value,
                  values: ThemeType.values.map((e) => (e, e.desc)).toList(),
                ),
              );
              if (result != null) {
                try {
                  Get.find<MineController>().themeType.value = result;
                } catch (_) {}
                ctr.themeType.value = result;
                GStorage.setting.put(SettingBoxKey.themeMode, result.index);
                Get.changeThemeMode(ThemeUtils.themeMode = result.toThemeMode);
              }
            },
            leading: const Icon(Icons.flashlight_on_outlined),
            title: Text('主题模式', style: titleStyle),
            subtitle: Obx(
              () => Text(
                '当前模式：${ctr.themeType.value.desc}',
                style: subTitleStyle,
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: Obx(() {
              final currentColor = resolveThemeColor(ctr.currentColor.value);
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: currentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                colorThemeTypes.single.label,
                                style: titleStyle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '当前颜色：${formatThemeColorHex(currentColor)}',
                                style: subTitleStyle,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _updateThemeColor(amberThemeColor),
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _channelSlider(
                      context: context,
                      title: 'R',
                      value: currentColor.red,
                      onChanged: (value) => _updateThemeColor(
                        currentColor.withRed(value),
                      ),
                    ),
                    _channelSlider(
                      context: context,
                      title: 'G',
                      value: currentColor.green,
                      onChanged: (value) => _updateThemeColor(
                        currentColor.withGreen(value),
                      ),
                    ),
                    _channelSlider(
                      context: context,
                      title: 'B',
                      value: currentColor.blue,
                      onChanged: (value) => _updateThemeColor(
                        currentColor.withBlue(value),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          if (!Platform.isIOS)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '已移除动态取色与调色板风格，主题色基于琥珀色并支持滑条微调。',
                style: subTitleStyle,
              ),
            ),
          Padding(
            padding: padding,
            child: ExcludeFocus(
              child: IgnorePointer(
                child: Container(
                  height: size.height / 2,
                  width: size.width,
                  color: theme.colorScheme.surface,
                  child: const HomePage(),
                ),
              ),
            ),
          ),
          ExcludeFocus(
            child: IgnorePointer(
              child: NavigationBar(
                destinations: NavigationBarType.values
                    .map(
                      (item) => NavigationDestination(
                        icon: item.icon,
                        label: item.label,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSelectController extends GetxController {
  final RxInt currentColor = Pref.customColor.obs;
  final Rx<ThemeType> themeType = Pref.themeType.obs;
}
