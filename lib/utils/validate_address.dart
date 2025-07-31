import 'package:massa/massa.dart' as massa;

bool isAddressValid(String address) {
  try {
    massa.serialiseAddress(address);
    return true;
  } catch (e) {
    return false;
  }
}
