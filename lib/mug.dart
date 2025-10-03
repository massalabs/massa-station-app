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
import 'package:mug/service/session_manager.dart';
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
  late final SessionConfig sessionConfig;

  @override
  void initState() {
    super.initState();
    _storage = ref.read(localStorageServiceProvider);
    focusTimeout = _storage.focusTimeout;
    inactivityTimeout = _storage.inactivityTimeout;
    sessionConfig = SessionConfig(
      invalidateSessionForAppLostFocus: Duration(seconds: focusTimeout),
      invalidateSessionForUserInactivity: Duration(seconds: inactivityTimeout),
    );

    sessionConfig.stream.listen(sessionHandler);
    sessionStateStream = ref.read(localSessionTimeoutProvider);
  }

  @override
  Widget build(BuildContext context) {
    return SessionTimeoutManager(
      sessionConfig: sessionConfig,
      child: App(
        navigatorKey: navigatorKey,
      ),
    );
  }

  Future<void> sessionHandler(SessionTimeoutState timeoutEvent) async {
    print('Session timeout event: $timeoutEvent');
    print('Is user active: ${_storage.isUserActive}');
    print('Is inactivity timeout on: ${_storage.isInactivityTimeoutOn}');

    sessionStateStream.add(SessionState.stopListening);
    BuildContext context = navigatorKey.currentContext!;
    if (timeoutEvent == SessionTimeoutState.userInactivityTimeout && _storage.isInactivityTimeoutOn) {
      print('Handling user inactivity timeout');
      await onTimeOutDo(
        context: context,
        showPreLogoffAlert: true,
      );
    } else if (timeoutEvent == SessionTimeoutState.appFocusTimeout) {
      print('Handling app focus timeout');
      await onTimeOutDo(
        context: context,
        showPreLogoffAlert: false,
      );
    }
  }

  Future<void> onTimeOutDo({required BuildContext context, required bool showPreLogoffAlert}) async {
    print('onTimeOutDo called, showPreLogoffAlert: $showPreLogoffAlert');
    if (_storage.isUserActive) {
      print('User is active, proceeding with logout flow');
      bool? isUserActive;
      if (showPreLogoffAlert) {
        print('Showing pre-logout alert');
        isUserActive = await preInactivityLogOffAlert(context);
        print('User response to alert: $isUserActive');
      }
      if (isUserActive == null || showPreLogoffAlert == false) {
        print('Logging out without message (directly to login)');
        logout(showLogoutMsg: false);
      }
      if (isUserActive == false) {
        print('Logging out without message');
        logout(showLogoutMsg: false);
      }
    } else {
      print('User is NOT active, skipping logout');
    }
  }

  Future<void> logout({
    required bool showLogoutMsg,
  }) async {
    // Clear master key from RAM
    SessionManager().endSession();

    // Clear login status
    _storage.setLoginStatus(false);

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
