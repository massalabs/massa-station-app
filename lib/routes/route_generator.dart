// Flutter imports:
import 'package:flutter/material.dart';
import 'package:mug/domain/entity/address_entity.dart';
import 'package:mug/mug.dart';
import 'package:mug/presentation/view/dex/swap_view.dart';
import 'package:mug/presentation/view/explorer/block_view.dart';
import 'package:mug/presentation/view/explorer/domain_view.dart';
import 'package:mug/presentation/view/explorer/mns_view.dart';
import 'package:mug/presentation/view/explorer/operation_view.dart';
import 'package:mug/presentation/view/explorer/search_not_found_view.dart';
import 'package:mug/presentation/view/wallet/edit_wallet_view.dart';
import 'package:mug/presentation/view/wallet/import_wallet_view.dart';
import 'package:mug/presentation/view/wallet/transfer_view.dart';
import 'package:mug/presentation/view/wallet/wallet_view.dart';

// Package imports:
import 'package:page_transition/page_transition.dart';

// Project imports:
import 'package:mug/presentation/view/authentication/auth_view.dart';
import 'package:mug/presentation/view/authentication/login_view.dart';
import 'package:mug/presentation/view/authentication/set_passphrase_view.dart';
import 'package:mug/presentation/view/explorer/address_view.dart';
import 'package:mug/presentation/view/view.dart';
import 'package:mug/routes/routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    var args = settings.arguments;
    final String? routeName = settings.name;
    const transitionDuration = 400;
    const transitionType = PageTransitionType.rightToLeftWithFade;

    switch (routeName) {
      case AuthRoutes.authWall:
        if (args is bool) {
          return PageTransition(
            child: AuthView(
              isKeyboardFocused: args,
            ),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'StreamController<SessionState>');

      //auth
      case AuthRoutes.login:
        if (args is bool) {
          return PageTransition(
            child: LoginView(
              isKeyboardFocused: args,
            ),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'bool');

      case AuthRoutes.setPassphrase:
        if (args is bool) {
          return PageTransition(
            child: SetPassphraseView(
              isKeyboardFocused: args,
            ),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'StreamController<SessionState>');

      case AuthRoutes.root:
        return PageTransition(
          child: Mug(),
          duration: const Duration(milliseconds: transitionDuration),
          type: transitionType,
        );
      case AuthRoutes.home:
        //if (args is StreamController<SessionState>) {
        return PageTransition(
          child: const Home(),
          duration: const Duration(milliseconds: transitionDuration),
          type: transitionType,
        );

//Explorer routes
      case ExploreRoutes.address:
        if (args is String) {
          return PageTransition(
            child: AddressView(args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'AddressDetail');

      case ExploreRoutes.block:
        if (args is String) {
          return PageTransition(
            child: BlockView(args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'BlockDetails');

      case ExploreRoutes.operation:
        if (args is String) {
          return PageTransition(
            child: OperationView(args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'OperationDetails');

      case ExploreRoutes.domain:
        if (args is DomainArguments) {
          return PageTransition(
            child: DomainView(args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'DomainView');

      case ExploreRoutes.mns:
        if (args is MNSArguments) {
          return PageTransition(
            child: MNSView(args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'MNSView');

      case ExploreRoutes.notFound:
        if (args is String) {
          return PageTransition(
            child: NotFoundView(searchText: args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'NotFound');

//Wallet routes
      case WalletRoutes.importWallet:
        return PageTransition(
          child: const ImportWalletView(),
          duration: const Duration(milliseconds: transitionDuration),
          type: transitionType,
        );

      case WalletRoutes.wallet:
        if (args is WalletViewArg) {
          return PageTransition(
            child: WalletView(args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'Walet Details');

      case WalletRoutes.walleName:
        if (args is String) {
          return PageTransition(
            child: EditWalletNameView(address: args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'Wallet Name');

      case WalletRoutes.transfer:
        if (args is AddressEntity) {
          return PageTransition(
            child: TransferView(args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'Token Transfer');

//Dex routes

      case DexRoutes.dex:
        return PageTransition(
          child: const DexView(),
          duration: const Duration(milliseconds: transitionDuration),
          type: transitionType,
        );

      case DexRoutes.swap:
        if (args is String) {
          return PageTransition(
            child: SwapView(args),
            duration: const Duration(milliseconds: transitionDuration),
            type: transitionType,
          );
        }
        return _errorRoute(route: routeName, argsType: 'SwapView');

      default:
        return _errorRoute(route: routeName);
    }
  }

  static Route<dynamic> _errorRoute({required String? route, String? argsType}) {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Route Error')),
        body: Padding(
          padding: const EdgeInsets.only(left: 5, right: 5),
          child: Center(
            child: argsType == null ? Text('No route: $route') : Text('$argsType, Needed for route: $route'),
          ),
        ),
      );
    });
  }
}
