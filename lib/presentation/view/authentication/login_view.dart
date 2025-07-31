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
import 'package:mug/routes/routes.dart';
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

  //ClassicLogin:
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final passPhraseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool? _isKeyboardFocused;
  bool _isHidden = true;
  bool _isLocked = false;
  late StreamController<SessionState> _session;
  bool isPasswordValid = false;

  @override
  void initState() {
    super.initState();
    _noOfAllowedAttempts = ref.read(localStorageServiceProvider).noOfLogginAttemptAllowed;
    _isKeyboardFocused = widget.isKeyboardFocused ?? true;
    forcePassphraseInput = ref.read(localStorageServiceProvider).biometricAttemptAllTimeCount % 5 == 0;
    _lockoutTime = ref.read(localStorageServiceProvider).bruteforceLockOutTime;

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
    super.dispose();
  }

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    if (ref.read(localStorageServiceProvider).isBiometricAuthEnabled && (widget.isKeyboardFocused ?? true)) {
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
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottom),
                    child: Column(
                      children: [
                        const Spacer(),
                        _buildLoginWorkflow(context: context),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void scrollToBottomIfOnScreenKeyboard() {
    try {
      if (MediaQuery.of(context).viewInsets.bottom > 0) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500), curve: Curves.ease);
      }
    } catch (e) {}
  }

  Widget _buildLoginWorkflow({required BuildContext context}) {
    const double padding = 16.0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(padding),
        child: Column(
          children: [
            _buildTimeOut(),
            _inputField(),
            _buildLoginButton(),
            const SizedBox(height: 60), // Add significant spacing
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
      });
      return numberOfAttemptExceded;
    }

    if (!isPasswordValid) {
      _noOfAllowedAttempts--;
      final wrongPhraseMsg = 'Wrong passphrase ${_noOfAllowedAttempts.toString()} attempts left!';
      return _noOfAllowedAttempts == 0 ? numberOfAttemptExceded : wrongPhraseMsg;
    }
    return null;
  }

  Future<void> validatePassword(String passphrase) async {
    final pass = await ref.read(localStorageServiceProvider).verifyPassphrase(passphrase);
    if (pass) {
      setState(() {
        isPasswordValid = pass;
      });
    }
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
    const String loginText = 'Login';

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
              child: const Wrap(
                children: <Widget>[
                  Icon(
                    Icons.fingerprint,
                    size: 30.0,
                  ),
                  SizedBox(width: 10),
                  Text(
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
      informationSnackBarMessage(context, snackMsgWrongEncryptionPhrase);
    }
  }

  Future<void> _login(String passphrase) async {
    const verifyPassphrase = 'Verifying your passphrase!';
    const snackMsgWrongEncryptionPhrase = 'Wrong passphrase!';
    if (await ref.read(localStorageServiceProvider).verifyPassphrase(passphrase)) {
      informationSnackBarMessage(context, verifyPassphrase);

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
        Container(
          alignment: Alignment.centerRight,
          child: TextButton(
            child: const Text(
              "Forgot Passphrase? Clear All Data",
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
            onPressed: () {
              _showClearDataDialog();
            },
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog() {
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
      Navigator.pushReplacementNamed(context, AuthRoutes.authWall, arguments: false);
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
        authenticated = await auth.authenticate(
          localizedReason: 'Login using your biometric credential',
          options: const AuthenticationOptions(stickyAuth: true),
        );
      } catch (e) {
        //print(e);
      }
      if (authenticated) await _login(await ref.read(localStorageServiceProvider).passphrase);
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
