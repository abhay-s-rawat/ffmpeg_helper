import 'dart:async';
import 'package:ffmpeg_helper/ffmpeg_helper.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:window_manager/window_manager.dart';
import 'homepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setSize(const Size(755, 545));
      await windowManager.setMinimumSize(const Size(350, 600));
      await windowManager.center();
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }
  await FFMpegHelper.instance.initialize();
  runApp(const MyApp());
}

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int topIndex = 0;
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        accentColor: Colors.purple,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen() ? 2.0 : 0.0,
        ),
      ),
      themeMode: ThemeMode.system,
      color: Colors.green,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen() ? 2.0 : 0.0,
        ),
      ),
      home: NavigationView(
        appBar: NavigationAppBar(
          height: 40,
          leading: const Icon(FluentIcons.a_a_d_logo),
          title: const DragToMoveArea(child: Text("FFMpeg Testing")),
          automaticallyImplyLeading: false,
          actions:
              Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
            if (!kIsWeb) WindowButtons(),
          ]),
        ),
        pane: NavigationPane(
          selected: topIndex,
          size: const NavigationPaneSize(
            compactWidth: 50,
            openMaxWidth: 200,
          ),
          onChanged: (int index) {
            if (mounted) {
              setState(() {
                topIndex = index;
              });
            }
          },
          displayMode: PaneDisplayMode.auto,
          items: [
            PaneItem(
              body: const HomePage(),
              icon: const Icon(material.Icons.home),
              title: const Text("Homepage"),
            ),
          ],
        ),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 40,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
