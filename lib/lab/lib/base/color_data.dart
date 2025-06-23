import 'dart:ui';

Color accentColor = "#8870E6".toColor();
Color lightAccentColor = "#F1EDFF".toColor();
Color skipColor = "#7B7681".toColor();
Color fillColor = "#F6F6FA".toColor();
Color redColor = "#DD3333".toColor();
Color gradientFirst = "#F1EEFF".toColor();
Color gradientSecond = "#FFFFFF".toColor();
Color checkBox = "#B5B1B9".toColor();
Color greyFontColor = "#7B7681".toColor();
Color speBackColor = "#FFD6D6".toColor();

extension ColorExtension on String {
  toColor() {
    var hexColor = replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }
}
