// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/mug.dart';
import 'package:mug/service/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final providerContainer = ProviderContainer();
  await providerContainer.read(asyncInitProvider).init();
  //await providerContainer.read(accountProvider.future);

  final isAutoRotate = providerContainer.read(localStorageServiceProvider).isAutoRotate;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    if (isAutoRotate) ...[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]
  ]);

  // Hide status bar completely but keep app background extending to top
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersive,
    overlays: [],
  );
  
  // Make status bar area match app background
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.grey[900], // App background color
    ),
  );

  Animate.restartOnHotReload = true;
  runApp(UncontrolledProviderScope(container: providerContainer, child: Mug()));
}
