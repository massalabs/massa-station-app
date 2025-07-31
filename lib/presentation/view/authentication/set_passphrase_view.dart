// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

// Package imports:

// Project imports:
import 'package:mug/routes/routes_name.dart';
import 'package:mug/service/provider.dart';
import 'package:mug/utils/passphrase_util.dart';
import 'package:mug/presentation/widget/widget.dart';

class SetPassphraseView extends ConsumerStatefulWidget {
  final bool? isKeyboardFocused;
  const SetPassphraseView({
    super.key,
    this.isKeyboardFocused,
  });

  @override
  _SetPassphraseViewState createState() => _SetPassphraseViewState();
}

class _SetPassphraseViewState extends ConsumerState<SetPassphraseView> {
  final _formKey = GlobalKey<FormState>();
  final _passPhraseController = TextEditingController();
  final _passPhraseControllerConfirm = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _focusFirst = FocusNode();
  final _focusSecond = FocusNode();
  bool _isHiddenFirst = true;
  bool _isHiddenConfirm = true;

  final navigatorKey = GlobalKey<NavigatorState>();
  NavigatorState? get _navigator => navigatorKey.currentState;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _passPhraseController.dispose();
    _passPhraseControllerConfirm.dispose();
    super.dispose();
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
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottom),
                child: Column(
                  children: [
                    const Spacer(),
                    _buildPassphraseSetWorkflow(context),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: footer(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopLogo() {
    final double topPadding = MediaQuery.of(context).size.height * 0.070;
    final double dimensions = MediaQuery.of(context).orientation == Orientation.portrait
        ? MediaQuery.of(context).size.width * 0.40
        : MediaQuery.of(context).size.height * 0.40;

    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 20),
      child: Center(
        child: Image.asset(
          'assets/icons/massa_station.png',
          height: 200,
          width: 200,
        ),
      ),
    );
  }

  Widget _buildPassphraseSetWorkflow(BuildContext context) {
    const double padding = 16.0;
    const double inputBoxSeparation = 10.0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(padding),
        child: Column(
          children: [
            AutofillGroup(
              child: Column(
                children: [
                  _inputFieldFirst(),
                  const SizedBox(height: inputBoxSeparation),
                  _inputFieldConfirm(),
                ],
              ),
            ),
            _buildForgotPassphrase(),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  void scrollToBottomIfOnScreenKeyboard() {
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500), curve: Curves.ease);
    }
  }

  Widget _inputFieldFirst() {
    const double inputBoxEdgeRadius = 10.0;
    const String firstHintText = 'New Passphrase';

    return TextFormField(
      enableIMEPersonalizedLearning: false,
      controller: _passPhraseController,
      autofocus: widget.isKeyboardFocused ?? true, //true,
      obscureText: _isHiddenFirst,
      focusNode: _focusFirst,
      decoration: _inputBoxDecoration(
        inputFieldID: 'first',
        inputHintText: firstHintText,
        label: firstHintText,
        inputBoxEdgeRadius: inputBoxEdgeRadius,
      ),
      autofillHints: const [AutofillHints.password],

      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(_focusSecond);
      },
      validator: _firstInputValidator,
    );
  }

  Widget _inputFieldConfirm() {
    const double inputBoxEdgeRadius = 10.0;
    const double padding = 10.0;
    const String confirmHintText = 'Re-enter Passphrase';

    return Padding(
      padding: const EdgeInsets.only(top: padding),
      child: TextFormField(
        enableIMEPersonalizedLearning: false,
        controller: _passPhraseControllerConfirm,
        focusNode: _focusSecond,
        obscureText: _isHiddenConfirm,
        decoration: _inputBoxDecoration(
          inputFieldID: 'confirm',
          inputHintText: confirmHintText,
          label: confirmHintText,
          inputBoxEdgeRadius: inputBoxEdgeRadius,
        ),
        autofillHints: const [AutofillHints.password],
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
        validator: _confirmInputValidator,
      ),
    );
  }

  InputDecoration _inputBoxDecoration({
    required String inputFieldID,
    required String inputHintText,
    required String label,
    required double inputBoxEdgeRadius,
  }) {
    bool? visibility;

    if (inputFieldID == 'first') {
      visibility = _isHiddenFirst;
    } else {
      visibility = _isHiddenConfirm;
    }

    return InputDecoration(
      hintText: inputHintText,
      label: Text(label),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBoxEdgeRadius),
      ),
      prefixIcon: const Icon(Icons.lock),
      suffixIcon: IconButton(
        icon: !visibility ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
        onPressed: () {
          if (inputFieldID == 'first') {
            return setState(() => _isHiddenFirst = !_isHiddenFirst);
          } else {
            return setState(() => _isHiddenConfirm = !_isHiddenConfirm);
          }
        },
      ),
    );
  }

  String? _firstInputValidator(String? passphrase) {
    const int minPassphraseLength = 8;
    const double minPassphraseStrength = 0.5;

    return passphrase == null || passphrase.length < minPassphraseLength
        ? 'Must be at least 8 characters long!'
        : (estimateBruteforceStrength(passphrase) < minPassphraseStrength)
            ? 'Passphrase is too weak!'
            : null;
  }

  String? _confirmInputValidator(String? passphraseConfirm) {
    return passphraseConfirm == null || passphraseConfirm != _passPhraseController.text ? 'Passphrase mismatch!' : null;
  }

  Widget _buildLoginButton() {
    return ButtonWidget(
      isDarkTheme: true, //replace this with dynamic status
      text: 'Confirm',
      onClicked: () async {
        _loginController();
      },
    );
  }

  Widget _buildForgotPassphrase() {
    return Container(
      alignment: Alignment.centerRight,
      child: TextButton(
        child: const Text('What is passphrase?'),
        onPressed: () {
          showGenericDialog(
            context: context,
            icon: Icons.info_outline,
            message:
                'Passphrase is similar to password but generally longer, it will be used to encrypt wallet accounts. Use strong passphrase and make sure to remember it. It is impossible to decrypt wallet secret keys without the passphrase. With great security comes the great responsibility of remembering the passphrase!',
          );
        },
      ),
    );
  }

  void _loginController() async {
    final form = _formKey.currentState!;
    if (form.validate()) {
      final enteredPassphrase = _passPhraseController.text;
      final enteredPassphraseConfirm = _passPhraseControllerConfirm.text;

      if (enteredPassphrase == enteredPassphraseConfirm) {
        informationSnackBarMessage(context, 'Passphrase set!');

        await ref.read(localStorageServiceProvider).setPassphrase(enteredPassphrase);
        // Auto-login after setting passphrase instead of going to login screen
        ref.read(localStorageServiceProvider).setLoginStatus(true);
        TextInput.finishAutofillContext();
        await Navigator.pushReplacementNamed(
          context,
          AuthRoutes.home,
        );
      } else {
        informationSnackBarMessage(context, 'Passphrase mismatch!');
      }
    }
  }
}
