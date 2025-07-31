/// shorten the string to [len] where len should not be less than 5
String shortenString(String source, int len) {
  if (len < 5 || source.length <= len) {
    return source;
  } else {
    const dotLen = 3; //change the number of dots accordingly
    var halfLen = (len - dotLen) ~/ 2;
    final leftString = source.substring(0, halfLen);
    final rightString = source.substring(source.length - halfLen);
    return "$leftString...$rightString";
  }
}
