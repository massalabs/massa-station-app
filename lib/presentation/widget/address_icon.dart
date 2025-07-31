import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mug/constants/colors.dart';

Widget AddressIcon(String address) {
  var seed = getSeed(address);

  // Expanded color palette (removed dark colors including black)
  final colors = <String>[
    "red", "lightblue", "green", "yellow", "orange", "purple", "pink", "cyan", 
    "lime", "teal", "amber", "lightgreen", "deeporange", 
    "lightcoral", "forestgreen", "gold", "crimson", "mediumorchid",
    "hotpink", "springgreen", "deepskyblue", "orangered", "mediumspringgreen",
    "tomato", "royalblue", "limegreen", "magenta", "coral"
  ];

  final part1Index = randBetwen(0, colors.length - 1, seed.ySeed);
  final part2Index = randBetwen(0, colors.length - 1, seed.iSeed);
  final part3Index = randBetwen(0, colors.length - 1, (seed.xSeed + seed.ySeed) % 1000000);

  final svg = '''<svg xmlns="http://www.w3.org/2000/svg" width="132" height="132">
    <!-- Top right part -->
    <path fill="${colors[part1Index]}" opacity="1.00000"
        d="m90.495 64.545 8.34-14.436-3.948-6.84-16.701-.012 9.669-16.734a42.623 42.623 0 0 0-8.376-3.738L66.318 45.531l3.966 6.84h16.701l-8.346 14.454 3.942 6.852h25.521c.702-2.934 1.104-6 1.167-9.132H90.495z" />
    <!-- Bottom part -->
    <path fill="${colors[part2Index]}" opacity="1.00000"
        d="m62.355 99.525h7.899l8.364-14.442 9.114 15.774a43.221 43.221 0 0 0 7.422-5.391L82.581 73.677h-7.908l-8.364 14.457-8.343-14.457h-7.914l-12.57 21.789a43.272 43.272 0 0 0 7.422 5.394l9.111-15.771 8.34 14.436z" />
    <!-- Top left part -->
    <path fill="${colors[part3Index]}" opacity="1.00000"
        d="M54 66.828l-8.34-14.457h16.686l3.972-6.84-13.161-22.746a42.72 42.72 0 0 0-8.376 3.738l9.663 16.728h-16.68l-3.954 6.837 8.34 14.457H23.364a42.93 42.93 0 0 0 1.167 9.132h25.518L54 66.828z" />
</svg>''';

  return SvgPicture.string(svg);
}

// supporting functions

// Function to generate a random number in a range
double generateRandomInRange(double min, double max, int seed) {
  Random random = Random(seed);
  return min + random.nextDouble() * (max - min);
}

class Seed {
  int iSeed; //image seed
  int xSeed; //x coordinate seed
  int ySeed; //y coordinate seed
  Seed({required this.iSeed, required this.xSeed, required this.ySeed});
}

Point getPoint(
    {required int height,
    required int width,
    required int radius,
    required int factor,
    required int xSeed,
    required int ySeed}) {
  int x = randDim(width, radius * factor, xSeed);
  int y = randDim(height, radius * factor, ySeed);
  Point p = Point(x, y);
  return p;
}

/// dim = is the dimension [height or width], rad = is the radius
int randDim(int dim, int rad, int seed) {
  int min = rad;
  int max = dim - rad;

  //print("dim = $dim, rad = $rad, min = $min, max = $max");
  var rnd = Random(seed);
  return min + rnd.nextInt(max - min);
}

/// dim = is the dimension [height or width], rad = is the radius
int randBetwen(int min, int max, int seed) {
  var rnd = Random(seed);
  return min + rnd.nextInt(max - min);
}

Seed getSeed(String address) {
  var hashBytes = utf8.encode(address);
  var hash = sha256.convert(hashBytes);
  var buff = ByteData.view(Uint8List.fromList(hash.bytes).buffer);
  int iSeed = buff.getInt64(0);
  int xSeed = buff.getInt64(8);
  int ySeed = buff.getInt64(16);
  return Seed(iSeed: iSeed, xSeed: xSeed, ySeed: ySeed);
}
