// Dart imports:
import 'dart:async';
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/service/provider.dart';

StreamController<String> _controller = StreamController<String>.broadcast();
int _timeoutSeconds = 0; // LocalStorage.preInactivityLogoutCounter;
int _counter = 0;
Timer? _timer;

class PreInactivityLogOff extends ConsumerWidget {
  const PreInactivityLogOff({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _timeoutSeconds = ref.read(localStorageServiceProvider).preInactivityLogoutCounter;
    const double paddingAllAround = 20.0;
    const double dialogRadius = 10.0;

    return BackdropFilter(
      filter: ImageFilter.blur(),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(paddingAllAround),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _title(),
              _body(paddingAllAround),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title() {
    const String title = 'Logging Oout';
    const double topSpacing = 10.0;

    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(top: topSpacing), //, right: 100),
        child: Text(
          title,
          //style: dialogHeadTextStyle,
        ),
      ),
    );
  }

  Widget _body(double padding) {
    final initialCounterValue = _timeoutSeconds.toString().padLeft(2, '0');
    const double topSpacing = 15.0;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(top: topSpacing, bottom: padding),
        child: StreamBuilder(
          stream: _controller.stream,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            var countDownTime = snapshot.hasData ? '00:${snapshot.data}' : ' 00:${initialCounterValue}';

            return Text(
              'There was no user activity for quite a while. You will be logged out unless you cancel within $countDownTime seconds.',
              //style: dialogBodyTextStyle,
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    const double buttonTextFontSize = 15.0;
    const String yesButtonText = 'Logout';
    const String noButtonText = 'Cancel';

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: ElevatedButton(
            style: const ButtonStyle(
              backgroundColor:
                  MaterialStatePropertyAll(Colors.red), // MaterialStateProperty.all(NordColors.aurora.red),
            ),
            child: _buttonText(yesButtonText, buttonTextFontSize),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.06),
        Expanded(
          child: ElevatedButton(
            child: _buttonText(noButtonText, buttonTextFontSize),
            onPressed: () => Navigator.of(context).pop(true), // return false to dialog caller
          ),
        )
      ],
    );
  }

  Widget _buttonText(String text, double fontSize) {
    return AutoSizeText(
      text,
      textAlign: TextAlign.center,
      minFontSize: 8,
      maxLines: 1,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    );
  }
}

void _startTimer(BuildContext context) {
  _counter = _timeoutSeconds;

  if (_timer != null) {
    _timer?.cancel();
  }

  _timer = Timer.periodic(
    const Duration(seconds: 1),
    (timer) {
      (_counter > 0) ? _counter-- : _timer?.cancel();
      _controller.add(_counter.toString().padLeft(2, '0'));
      if (_counter == 0) {
        Navigator.of(context).pop();
      }
    },
  );
}

Future<bool?> preInactivityLogOffAlert(BuildContext context) async {
  bool? isUserActive = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      _startTimer(context); // start filling the stream with coutndown data
      return PreInactivityLogOff();
    },
  );

  if (_timer!.isActive) {
    // if timer is active i.e user user choose
    // some option which already pop out the dialoge
    // so disable timer to prevent re-trigger of pop
    _timer!.cancel();
  }
  return isUserActive;
}
