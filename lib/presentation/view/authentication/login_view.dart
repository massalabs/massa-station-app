// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:after_layout/after_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

// Project imports:
import 'package:mug/presentation/provider/local_session_timeout_provider.dart';
import 'package:mug/presentation/provider/wallet_list_provider.dart';
import 'package:mug/routes/routes.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';
import 'package:mug/presentation/widget/widget.dart';

class LoginView extends ConsumerStatefulWidget {
  final bool? isKeyboardFocused;

  const LoginView({
    this.isKeyboardFocused,
    super.key,
  });

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> with AfterLayoutMixin<LoginView> {
  // BiometricAuth:
  final LocalAuthentication auth = LocalAuthentication();
  _BiometricState _supportState = _BiometricState.unknown;
  late bool forcePassphraseInput;
  List<BiometricType> _availableBiometrics = [];

  //ClassicLogin:
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final passPhraseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool? _isKeyboardFocused;
  bool _isHidden = true;
  bool _isLocked = false;
  late StreamController<SessionState> _session;
  bool isPasswordValid = false;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageServiceProvider);
    _noOfAllowedAttempts = storage.noOfLogginAttemptAllowed;
    _isKeyboardFocused = widget.isKeyboardFocused ?? true;

    // No longer needed - Passphrase mode has no biometric option
    forcePassphraseInput = false;

    // Load available biometric types
    _loadAvailableBiometrics();

    _lockoutTime = storage.bruteforceLockOutTime;

    // BiometricAuth:
    auth.isDeviceSupported().then(
      (bool isSupported) {
        setState(() => _supportState = isSupported ? _BiometricState.supported : _BiometricState.unsupported);
      },
    );
  }

  @override
  void dispose() {
    passPhraseController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    final storage = ref.read(localStorageServiceProvider);
    final authMode = storage.authenticationMode;

    // Auto-trigger biometric for Biometric Only mode
    if (authMode == AuthenticationMode.biometricOnly && (widget.isKeyboardFocused ?? true)) {
      await _authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    scrollToBottomIfOnScreenKeyboard();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: MediaQuery.of(context).orientation == Orientation.portrait
              ? Image.asset(
                  'assets/icons/massa_station_full.png',
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  'assets/icons/massa_station_full.png',
                  height: 40,
                ),
          centerTitle: true,
        ),
        body: Consumer(
          builder: (context, watch, _) {
            _session = watch.read(localSessionTimeoutProvider);
            return SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        kToolbarHeight,
                padding: EdgeInsets.only(bottom: bottom),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    _buildLoginWorkflow(context: context),
                    const Spacer(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void scrollToBottomIfOnScreenKeyboard() {
    try {
      if (MediaQuery.of(context).viewInsets.bottom > 0) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (e) {}
  }

  Widget _buildLoginWorkflow({required BuildContext context}) {
    const double padding = 16.0;
    final authMode = ref.read(localStorageServiceProvider).authenticationMode;

    // Biometric Only mode - show only biometric button
    if (authMode == AuthenticationMode.biometricOnly) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            const Icon(Icons.lock_outline, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              _getBiometricLabel(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: Icon(_getBiometricIcon(), size: 36, color: Colors.blue),
              label: const Text('Unlock', style: TextStyle(fontSize: 22, color: Colors.blue)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 30, 30, 30),
                minimumSize: const Size(240, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Always back up your wallet private keys!\nThey are your only way to recover funds in case of lost phone.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            _buildClearDataButton(),
          ],
        ),
      );
    }

    // Passphrase mode - show passphrase field only (no biometric option)
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(padding),
        child: Column(
          children: [
            _buildTimeOut(),
            _inputField(),
            _buildLoginButton(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Always back up your wallet private keys!\nThey are your only way to recover funds in case of lost phone.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
            _buildForgotPassphrase(),
          ],
        ),
      ),
    );
  }

  _buildTimeOut() {
    if (_isLocked) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      passPhraseController.clear();
      _startTimer(
        () {
          setState(
            () {
              _isLocked = false;
              _isKeyboardFocused = true;
              _formKey = GlobalKey<FormState>();
            },
          );
        },
        allowedLoginAttempts: ref.read(localStorageServiceProvider).noOfLogginAttemptAllowed,
        lockoutTime: ref.read(localStorageServiceProvider).bruteforceLockOutTime,
      );

      return StreamBuilder(
        stream: _controller.stream,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          String? timeLeft = snapshot.hasData ? snapshot.data : _lockoutTime.toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Exceeded number of attempts, try after ${timeLeft.toString()} seconds',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      );
    }
    return const SizedBox(height: 20);
  }

  Widget _inputField() {
    const double inputBoxEdgeRadious = 10.0;

    return TextFormField(
      enabled: !_isLocked,
      enableIMEPersonalizedLearning: false,
      controller: passPhraseController,
      focusNode: _passwordFocusNode,
      autofocus: _isKeyboardFocused!,
      obscureText: _isHidden,
      decoration: _inputFieldDecoration(inputBoxEdgeRadious),
      autofillHints: const [AutofillHints.password],
      keyboardType: TextInputType.visiblePassword,
      onEditingComplete: _loginController,
      onChanged: (value) => validatePassword(value),
      validator: _passphraseValidator,
    );
  }

  String? _passphraseValidator(String? passphrase) {
    const numberOfAttemptExceded = 'Number of attempt exceeded';
    if (_noOfAllowedAttempts <= 1) {
      setState(() {
        _isLocked = true;
        _isKeyboardFocused = false;
      });
      return numberOfAttemptExceded;
    }

    if (!isPasswordValid) {
      _noOfAllowedAttempts--;
      // Don't refocus after validation error
      _passwordFocusNode.unfocus();
      setState(() {
        _isKeyboardFocused = false;
      });
      final wrongPhraseMsg = 'Wrong passphrase ${_noOfAllowedAttempts.toString()} attempts left!';
      return _noOfAllowedAttempts == 0 ? numberOfAttemptExceded : wrongPhraseMsg;
    }
    return null;
  }

  Future<void> validatePassword(String passphrase) async {
    // Use verifyAndCacheMasterKey but don't cache yet (just for validation)
    // Actually we can't use it here as it caches. Let's create a simpler verify method
    // For now, just verify format - actual verification happens in _login
    setState(() {
      isPasswordValid = passphrase.length >= 8;
    });
  }

  InputDecoration _inputFieldDecoration(double inputBoxEdgeRadious) {
    const String hintText = 'Enter Passphrase';

    return InputDecoration(
      hintText: hintText,
      label: const Text('Passphrase'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBoxEdgeRadious),
      ),
      prefixIcon: const Icon(Icons.lock),
      suffixIcon: IconButton(
        icon: !_isHidden ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
        onPressed: _togglePasswordVisibility,
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _isHidden = !_isHidden);
  }

  Widget _buildLoginButton() {
    const String loginText = 'Unlock';

    return ButtonWidget(
      isDarkTheme: true,
      text: loginText,
      onClicked: _isLocked ? null : () async => _loginController(),
    );
  }

  Widget _buildBiometricAuthButton(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            'OR',
            style: TextStyle(fontSize: 15),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shadowColor: Theme.of(context).primaryColor,
                minimumSize: const Size(200, 50), //Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5.0,
              ),
              onPressed:
                  (ref.read(localStorageServiceProvider).isBiometricAuthEnabled && !forcePassphraseInput && !_isLocked)
                      ? _authenticate
                      : null,
              child: Wrap(
                children: <Widget>[
                  Icon(
                    _getBiometricIcon(),
                    size: 30.0,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Biometric',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _loginController() async {
    final form = _formKey.currentState!;
    const snackMsgWrongEncryptionPhrase = 'Wrong passphrase!';

    if (form.validate()) {
      final phrase = passPhraseController.text;
      await _login(phrase);
    } else {
      // Don't refocus keyboard after validation failure
      _passwordFocusNode.unfocus();
      setState(() {
        _isKeyboardFocused = false;
      });
      informationSnackBarMessage(context, snackMsgWrongEncryptionPhrase);
    }
  }

  Future<void> _loadAvailableBiometrics() async {
    try {
      final biometrics = await ref.read(localStorageServiceProvider).getAvailableBiometrics();
      print('🔐 Available biometrics: $biometrics');
      if (mounted) {
        setState(() {
          _availableBiometrics = biometrics;
        });
      }
    } catch (e) {
      print('🔐 Error loading biometrics: $e');
      // Ignore errors, default to fingerprint icon
    }
  }

  IconData _getBiometricIcon() {
    // Check for actual biometric types (not security levels)
    final actualBiometrics = _availableBiometrics.where((type) =>
      type != BiometricType.weak && type != BiometricType.strong
    ).toList();

    // If multiple actual biometric types, show generic icon
    if (actualBiometrics.length > 1) {
      return Icons.lock_outline;
    }

    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.remove_red_eye;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }

    // Default to fingerprint (for weak/strong on Android)
    return Icons.fingerprint;
  }

  String _getBiometricLabel() {
    // Check for actual biometric types (not security levels)
    final actualBiometrics = _availableBiometrics.where((type) =>
      type != BiometricType.weak && type != BiometricType.strong
    ).toList();

    if (actualBiometrics.length > 1) {
      return 'Biometric Authentication';
    }

    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face Authentication';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris Authentication';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint Authentication';
    }

    // Default for weak/strong on Android
    return 'Biometric Authentication';
  }

  Future<void> _login(String passphrase) async {
    const snackMsgWrongEncryptionPhrase = 'Wrong passphrase!';

    // Close keyboard
    FocusScope.of(context).unfocus();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Verifying passphrase...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Verify passphrase AND cache master key in one operation
    final isValid = await ref.read(localStorageServiceProvider).verifyAndCacheMasterKey(passphrase);

    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (isValid) {
      // Clear passphrase from memory immediately
      passPhraseController.clear();

      // re-enable biometric auth
      if (forcePassphraseInput) ref.read(localStorageServiceProvider).incrementBiometricAttemptAllTimeCount();

      print("user login status before starting session: ${ref.read(localStorageServiceProvider).isUserActive}");

      // start listening for session inactivity on successful login
      _session.add(SessionState.startListening);
      ref.read(localStorageServiceProvider).setLoginStatus(true);
      await Navigator.pushReplacementNamed(
        context,
        AuthRoutes.home,
      );
    } else {
      // Don't refocus keyboard after failed login
      _passwordFocusNode.unfocus();
      setState(() {
        _isKeyboardFocused = false;
      });
      informationSnackBarMessage(context, snackMsgWrongEncryptionPhrase);
    }
  }

  Widget _buildForgotPassphrase() {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerRight,
          child: TextButton(
            child: const Text(
              "Can't decrypt without phrase!",
              style: TextStyle(fontSize: 10),
            ),
            onPressed: () {
              showGenericDialog(
                context: context,
                icon: Icons.info_outline,
                message:
                    'There is no way to access your wallet and digital assets without the passphrase. With great security comes the great responsibility of remembering the passphrase!',
              );
            },
          ),
        ),
        _buildClearDataButton(),
      ],
    );
  }

  Widget _buildClearDataButton() {
    return Container(
      alignment: Alignment.centerRight,
      child: TextButton(
        child: Text(
          ref.read(localStorageServiceProvider).authenticationMode == AuthenticationMode.biometricOnly
              ? "Clear All Data"
              : "Forgot Passphrase? Clear All Data",
          style: const TextStyle(fontSize: 12, color: Colors.red),
        ),
        onPressed: () {
          _showClearDataDialog();
        },
      ),
    );
  }

  void _showClearDataDialog() async {
    final storage = ref.read(localStorageServiceProvider);

    // Check if biometric is available on device
    final canUseBiometric = await storage.canUseBiometrics();

    // Require biometric authentication if available
    if (canUseBiometric) {
      final authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to clear all data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device PIN fallback
        ),
      );

      if (!authenticated) {
        if (mounted) {
          informationSnackBarMessage(context, 'Authentication required to clear data');
        }
        return;
      }
    }

    // Show confirmation dialog
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'This will permanently delete all wallets, settings, and data. You will lose access to all your funds unless you have backed up your wallet keys.\n\nThis action cannot be undone!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAllData();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All Data'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllData() async {
    await ref.read(localStorageServiceProvider).clearAllData();

    if (mounted) {
      // Reload wallet list to clear cached data (same as retry button does)
      await ref.read(walletListProvider.notifier).loadWallets();

      // Navigate to root
      Navigator.pushNamedAndRemoveUntil(
        context,
        AuthRoutes.root,
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<bool> _authenticate() async {
    bool authenticated = false;
    print(ref.read(localStorageServiceProvider).biometricAttemptAllTimeCount);
    if (_supportState == _BiometricState.unsupported) {
      showGenericDialog(
        context: context,
        icon: Icons.error_outline,
        message: "No biometrics found. Go to your device settings to enroll your biometric.",
      );
    } else if (forcePassphraseInput) {
      showGenericDialog(
        context: context,
        icon: Icons.info_outline,
        message: "Still remember your passphrase? Use passphrase to login this time.",
      );
    } else {
      ref.read(localStorageServiceProvider).incrementBiometricAttemptAllTimeCount();

      try {
        // Attempt biometric login (native prompt shows automatically)
        authenticated = await ref.read(localStorageServiceProvider).loginWithBiometric();

        if (authenticated) {
          // re-enable biometric auth counter
          if (forcePassphraseInput) ref.read(localStorageServiceProvider).incrementBiometricAttemptAllTimeCount();

          print("user login status before starting session: ${ref.read(localStorageServiceProvider).isUserActive}");

          // start listening for session inactivity on successful login
          _session.add(SessionState.startListening);
          ref.read(localStorageServiceProvider).setLoginStatus(true);
          await Navigator.pushReplacementNamed(
            context,
            AuthRoutes.home,
          );
        } else {
          if (mounted) {
            informationSnackBarMessage(context, 'Biometric authentication failed. Please use passphrase.');
          }
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        print('Biometric auth error: $e');
        if (mounted) {
          informationSnackBarMessage(context, 'Biometric authentication error. Please use passphrase.');
        }
      }
    }
    setState(() {
      forcePassphraseInput = ref.read(localStorageServiceProvider).biometricAttemptAllTimeCount % 5 == 0;
    });
    return authenticated;
  }
}

int _noOfAllowedAttempts = 0;
int _lockoutTime = 0;
int _counter = 0;

Timer? _timer;
StreamController<String> _controller = StreamController<String>.broadcast();

void _startTimer(VoidCallback callback, {required int lockoutTime, required int allowedLoginAttempts}) {
  _counter = lockoutTime;
  if (_timer != null) _timer?.cancel();
  _timer = Timer.periodic(
    const Duration(seconds: 1),
    (timer) {
      (_counter > 0) ? _counter-- : _timer?.cancel();
      _controller.add(_counter.toString().padLeft(2, '0'));
      if (_counter <= 0) {
        _noOfAllowedAttempts = allowedLoginAttempts;
        callback();
      }
    },
  );
}

enum _BiometricState { unknown, supported, unsupported }
