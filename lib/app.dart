// Flutter imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/presentation/provider/setting_provider.dart';
import 'package:mug/presentation/view/authentication/auth_view.dart';
import 'package:mug/routes/routes.dart';

class App extends ConsumerWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const App({super.key, required this.navigatorKey});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkTheme = ref.watch(settingProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: AuthRoutes.root, //was .mug -> .root
      onGenerateRoute: RouteGenerator.generateRoute,
      title: "MicroGateway",
      themeMode: isDarkTheme.darkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: const AuthView(),
    );
  }
}
