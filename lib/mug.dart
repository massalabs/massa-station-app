// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

// Project imports:
import 'package:mug/app.dart';
import 'package:mug/presentation/provider/local_session_timeout_provider.dart';
import 'package:mug/routes/routes.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';
import 'package:mug/presentation/widget/generic.dart';
import 'package:mug/presentation/widget/logout_alert.dart';

class Mug extends ConsumerStatefulWidget {
  const Mug({super.key});

  @override
  _MugState createState() => _MugState();
}

class _MugState extends ConsumerState<Mug> {
  final navigatorKey = GlobalKey<NavigatorState>();
  NavigatorState? get _navigator => navigatorKey.currentState;
  late final StreamController<SessionState> sessionStateStream;
  late final int focusTimeout;
  late final int inactivityTimeout;
  late final LocalStorageService _storage;

  @override
  void initState() {
    super.initState();
    _storage = ref.read(localStorageServiceProvider);
    focusTimeout = _storage.focusTimeout;
    inactivityTimeout = _storage.inactivityTimeout;
    final sessionConfig = SessionConfig(
      invalidateSessionForAppLostFocus: Duration(seconds: focusTimeout),
      invalidateSessionForUserInactivity: Duration(seconds: inactivityTimeout),
    );

    sessionConfig.stream.listen(sessionHandler);
    sessionStateStream = ref.read(localSessionTimeoutProvider);
  }

  @override
  Widget build(BuildContext context) {
    return SessionTimeoutManager(
      sessionConfig: SessionConfig(
        invalidateSessionForAppLostFocus: Duration(seconds: focusTimeout),
        invalidateSessionForUserInactivity: Duration(seconds: inactivityTimeout),
      ),
      child: App(
        navigatorKey: navigatorKey,
      ),
    );
  }

  Future<void> sessionHandler(SessionTimeoutState timeoutEvent) async {
    sessionStateStream.add(SessionState.stopListening);
    BuildContext context = navigatorKey.currentContext!;
    if (timeoutEvent == SessionTimeoutState.userInactivityTimeout && _storage.isInactivityTimeoutOn) {
      await onTimeOutDo(
        context: context,
        showPreLogoffAlert: true,
      );
    } else if (timeoutEvent == SessionTimeoutState.appFocusTimeout) {
      await onTimeOutDo(
        context: context,
        showPreLogoffAlert: false,
      );
    }
  }

  Future<void> onTimeOutDo({required BuildContext context, required bool showPreLogoffAlert}) async {
    if (_storage.isUserActive) {
      bool? isUserActive;
      if (showPreLogoffAlert) isUserActive = await preInactivityLogOffAlert(context);
      if (isUserActive == null || showPreLogoffAlert == false) {
        logout(showLogoutMsg: true);
      }
      if (isUserActive == false) {
        logout(showLogoutMsg: false);
      }
    }
  }

  Future<void> logout({
    required bool showLogoutMsg,
  }) async {
    _navigator?.pushNamedAndRemoveUntil(
      AuthRoutes.authWall,
      (Route<dynamic> route) => false,
      arguments: false,
    );

    if (showLogoutMsg) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showGenericDialog(
          context: navigatorKey.currentContext!,
          icon: Icons.info_outline,
          message: "You were logged out due to extended inactivity. This is to protect your privacy.",
        );
      });
    }
    _storage.setLoginStatus(false);
  }
}
