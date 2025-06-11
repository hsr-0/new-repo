import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';

String getCountryCodeInit(String phoneNumber) {
  Map<String, String> countryCodeMap = {
    '+238': 'CV', // Cabo Verde
    '+236': 'CF', // République centrafricaine
    '+235': 'TD', // Tchad
    '+56': 'CL', // Chile
    '+86': 'CN', // 中国
    '+61': 'CX', // Christmas Island
    '+61': 'CC', // Cocos (Keeling) Islands
    '+57': 'CO', // Colombia
    '+269': 'KM', // Komori
    '+242': 'CG', // République du Congo
    '+243': 'CD', // République démocratique du Congo
    '+682': 'CK', // Cook Islands
    '+506': 'CR', // Costa Rica
    '+225': 'CI', // Côte d'Ivoire
    '+385': 'HR', // Hrvatska
    '+53': 'CU', // Cuba
    '+599': 'CW', // Curaçao
    '+357': 'CY', // Κύπρος
    '+420': 'CZ', // Česká republika
    '+45': 'DK', // Danmark
    '+253': 'DJ', // Djibouti
    '+1767': 'DM', // Dominica
    '+1': 'DO', // República Dominicana
    '+593': 'EC', // Ecuador
    '+20': 'EG', // مصر
    '+503': 'SV', // El Salvador
    '+240': 'GQ', // Guinea Ecuatorial
    '+291': 'ER', // إرتريا
    '+372': 'EE', // Eesti
    '+251': 'ET', // ኢትዮጵያ
    '+500': 'FK', // Falkland Islands
    '+298': 'FO', // Føroyar
    '+679': 'FJ', // Fiji
    '+358': 'FI', // Suomi
    '+33': 'FR', // France
    '+594': 'GF', // Guyane française
    '+689': 'PF', // Polynésie française
    '+262': 'TF', // Terres australes françaises
    '+241': 'GA', // Gabon
    '+220': 'GM', // Gambia
    '+995': 'GE', // საქართველო
    '+49': 'DE', // Deutschland
    '+233': 'GH', // Ghana
    '+350': 'GI', // Gibraltar
    '+30': 'GR', // Ελλάδα
    '+299': 'GL', // Grønland
    '+1473': 'GD', // Grenada
    '+590': 'GP', // Guadeloupe
    '+1671': 'GU', // Guam
    '+502': 'GT', // Guatemala
    '+44': 'GG', // Guernsey
    '+224': 'GN', // Guinée
    '+245': 'GW', // Guiné-Bissau
    '+592': 'GY', // Guyana
    '+509': 'HT', // Haïti
    '+672': 'HM', // Heard Island and McDonald Islands
    '+504': 'HN', // Honduras
    '+852': 'HK', // 香港
    '+379': 'VA', // Vaticano
    '+36': 'HU', // Magyarország
    '+354': 'IS', // Ísland
    '+91': 'IN', // भारत
    '+62': 'ID', // Indonesia
    '+98': 'IR', // ایران
    '+964': 'IQ', // العراق
    '+353': 'IE', // Éire
    '+44': 'IM', // Isle of
    '+972': 'IL', // ישראל
    '+39': 'IT', // Italia
    '+1876': 'JM', // Jamaica
    '+81': 'JP', // 日本
    '+44': 'JE', // Jersey
    '+962': 'JO', // الأردن
    '+7': 'KZ', // Қазақстан
    '+254': 'KE', // Kenya
    '+686': 'KI', // Kiribati
    '+850': 'KP', // 북한
    '+82': 'KR', // 대한민국
    '+383': 'XK', // Republika e Kosovës
    '+965': 'KW', // الكويت
    '+996': 'KG', // Кыргызстан
    '+856': 'LA', // ລາວ
    '+371': 'LV', // Latvija
    '+961': 'LB', // لبنان
    '+266': 'LS', // Lesotho
    '+231': 'LR', // Liberia
    '+218': 'LY', // ليبيا
    '+423': 'LI', // Liechtenstein
    '+370': 'LT', // Lietuva
    '+352': 'LU', // Luxembourg
    '+853': 'MO', // 澳門
    '+389': 'MK', // Македонија
    '+261': 'MG', // Madagascar
    '+265': 'MW', // Malawi
    '+60': 'MY', // Malaysia
    '+960': 'MV', // Maldives
    '+223': 'ML', // Mali
    '+356': 'MT', // Malta
    '+692': 'MH', // Marshall Islands
    '+596': 'MQ', // Martinique
    '+222': 'MR', // موريتانيا
    '+230': 'MU', // Maurice
    '+262': 'YT', // Mayotte
    '+52': 'MX', // México
    '+691': 'FM', // Micronesia
    '+373': 'MD', // Moldova
    '+377': 'MC', // Monaco
    '+976': 'MN', // Монгол улс
    '+382': 'ME', // Crna Gora
    '+1664': 'MS', // Montserrat
    '+212': 'MA', // المغرب
    '+258': 'MZ', // Moçambique
    '+95': 'MM', // Myanma
    '+264': 'NA', // Namibia
    '+674': 'NR', // Nauru
    '+977': 'NP', // नेपाल
    '+31': 'NL', // Nederland
    '+599': 'AN', // Netherlands Antilles
    '+687': 'NC', // Nouvelle-Calédonie
    '+64': 'NZ', // New Zealand
    '+505': 'NI', // Nicaragua
    '+227': 'NE', // Niger
    '+234': 'NG', // Nigeria
    '+683': 'NU', // Niue
    '+672': 'NF', // Norfolk Island
    '+1670': 'MP', // Northern Mariana Islands
    '+47': 'NO', // Norge
    '+968': 'OM', // عمان
    '+92': 'PK', // پاکستان
    '+680': 'PW', // Palau
    '+970': 'PS', // فلسطين
    '+507': 'PA', // Panamá
    '+675': 'PG', // Papua New Guinea
    '+595': 'PY', // Paraguay
    '+51': 'PE', // Perú
    '+63': 'PH', // Pilipinas
    '+64': 'PN', // Pitcairn Islands
    '+48': 'PL', // Polska
    '+351': 'PT', // Portugal
    '+1939': 'PR', // Puerto Rico
    '+1787': 'PR', // Puerto Rico
    '+974': 'QA', // قطر
    '+262': 'RE', // La Réunion
    '+40': 'RO', // România
    '+7': 'RU', // Россия
    '+250': 'RW', // Rwanda
    '+262': 'RE', // La Réunion
    '+590': 'BL', // Saint-Barthélemy
    '+290': 'SH', // Saint Helena
    '+1869': 'KN', // Saint Kitts and Nevis
    '+1758': 'LC', // Saint Lucia
    '+590': 'MF', // Saint-Martin
    '+508': 'PM', // Saint-Pierre-et-Miquelon
    '+1784': 'VC', // Saint Vincent and the Grenadines
    '+685': 'WS', // Samoa
    '+378': 'SM', // San Marino
    '+239': 'ST', // São Tomé e Príncipe
    '+966': 'SA', // العربية السعودية
    '+221': 'SN', // Sénégal
    '+381': 'RS', // Србија
    '+248': 'SC', // Seychelles
    '+232': 'SL', // Sierra Leone
    '+65': 'SG', // Singapore
    '+1721': 'SX', // Sint Maarten
    '+421': 'SK', // Slovensko
    '+386': 'SI', // Slovenija
    '+677': 'SB', // Solomon Islands
    '+252': 'SO', // Soomaaliya
    '+27': 'ZA', // South Africa
    '+500': 'GS', // South Georgia
    '+211': 'SS', // South Sudan
    '+34': 'ES', // España
    '+94': 'LK', // ශ්‍රී ලංකාව
    '+249': 'SD', // السودان
    '+597': 'SR', // Suriname
    '+47': 'SJ', // Svalbard og Jan Mayen
    '+268': 'SZ', // Swaziland
    '+46': 'SE', // Sverige
    '+41': 'CH', // Schweiz
    '+963': 'SY', // سوريا
    '+886': 'TW', // 台灣
    '+992': 'TJ', // Тоҷикистон
    '+255': 'TZ', // Tanzania
    '+66': 'TH', // ไทย
    '+670': 'TL', // Timor-Leste
    '+228': 'TG', // Togo
    '+690': 'TK', // Tokelau
    '+676': 'TO', // Tonga
    '+1868': 'TT', // Trinidad and Tobago
    '+216': 'TN', // تونس
    '+90': 'TR', // Türkiye
    '+993': 'TM', // Türkmenistan
    '+1649': 'TC', // Turks and Caicos Islands
    '+688': 'TV', // Tuvalu
    '+256': 'UG', // Uganda
    '+380': 'UA', // Україна
    '+971': 'AE', // الإمارات العربية المتحدة
    '+44': 'GB', // United Kingdom
    '+1': 'US', // United States
    '+598': 'UY', // Uruguay
    '+998': 'UZ', // Oʻzbekiston
    '+678': 'VU', // Vanuatu
    '+58': 'VE', // Venezuela
    '+84': 'VN', // Việt Nam
    '+1284': 'VG', // British Virgin Islands
    '+1340': 'VI', // United States Virgin Islands
    '+681': 'WF', // Wallis et Futuna
    '+212': 'EH', // الصحراء الغربية
    '+967': 'YE', // اليمن
    '+260': 'ZM', // Zambia
    '+263': 'ZW', // Zimbabwe
  };

  // Extract the prefix from the phone number
  String prefix = phoneNumber.startsWith('+') ? phoneNumber.split(' ')[0] : '';

  // Look up the country code
  return countryCodeMap[prefix] ?? 'Unknown';
}

String formatOrderDateTime(String inputDate) {
// Parse the input date string into a DateTime object
  DateTime dateTime = DateTime.parse(inputDate);

  // Format the time in 12-hour format with AM/PM
  String formattedTime =
      "${dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";

  List monthNames = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  // Format the date as "day-month-year"
  String formattedDate =
      "${dateTime.day}-${monthNames[(dateTime.month) - 1]}-${dateTime.year}";

  // Combine the formatted time and date
  return "$formattedTime | $formattedDate";
}

String formatBlogDateTime(String date) {
  // Parse the date string into a DateTime object
  DateTime parsedDate = DateTime.parse(date);

  // Extract the day, month, and year
  int day = parsedDate.day;
  int month = parsedDate.month;
  int year = parsedDate.year;

  // List of abbreviated month names
  List<String> monthNames = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];

  // Get the abbreviated month name
  String monthName = monthNames[month - 1];

  // Format the date string
  String formattedDate = "$day $monthName, $year";

  // Print the formatted date
  print(formattedDate); // Output: 21 Apr, 2023

  return formattedDate;
}

String removeHtmlEntities(String input) {
  Map<String, String> htmlEntities = {
    "&CounterClockwiseContourIntegral;": "∳",
    "&DoubleLongLeftRightArrow;": "⟺",
    "&ClockwiseContourIntegral;": "∲",
    "&NotNestedGreaterGreater;": "⪢",
    "&DiacriticalDoubleAcute;": "˝",
    "&NotSquareSupersetEqual;": "⋣",
    "&NegativeVeryThinSpace;": "​",
    "&CloseCurlyDoubleQuote;": "”",
    "&NotSucceedsSlantEqual;": "⋡",
    "&NotPrecedesSlantEqual;": "⋠",
    "&NotRightTriangleEqual;": "⋭",
    "&FilledVerySmallSquare;": "▪",
    "&DoubleContourIntegral;": "∯",
    "&NestedGreaterGreater;": "≫",
    "&OpenCurlyDoubleQuote;": "“",
    "&NotGreaterSlantEqual;": "⩾",
    "&NotSquareSubsetEqual;": "⋢",
    "&CapitalDifferentialD;": "ⅅ",
    "&ReverseUpEquilibrium;": "⥯",
    "&DoubleLeftRightArrow;": "⇔",
    "&EmptyVerySmallSquare;": "▫",
    "&DoubleLongRightArrow;": "⟹",
    "&NotDoubleVerticalBar;": "∦",
    "&NotLeftTriangleEqual;": "⋬",
    "&NegativeMediumSpace;": "​",
    "&NotRightTriangleBar;": "⧐",
    "&leftrightsquigarrow;": "↭",
    "&SquareSupersetEqual;": "⊒",
    "&RightArrowLeftArrow;": "⇄",
    "&LeftArrowRightArrow;": "⇆",
    "&DownLeftRightVector;": "⥐",
    "&DoubleLongLeftArrow;": "⟸",
    "&NotGreaterFullEqual;": "≧",
    "&RightDownVectorBar;": "⥕",
    "&PrecedesSlantEqual;": "≼",
    "&Longleftrightarrow;": "⟺",
    "&DownRightTeeVector;": "⥟",
    "&NegativeThickSpace;": "​",
    "&LongLeftRightArrow;": "⟷",
    "&RightTriangleEqual;": "⊵",
    "&RightDoubleBracket;": "⟧",
    "&RightDownTeeVector;": "⥝",
    "&SucceedsSlantEqual;": "≽",
    "&SquareIntersection;": "⊓",
    "&longleftrightarrow;": "⟷",
    "&NotLeftTriangleBar;": "⧏",
    "&blacktriangleright;": "▸",
    "&ReverseEquilibrium;": "⇋",
    "&DownRightVectorBar;": "⥗",
    "&NotTildeFullEqual;": "≇",
    "&twoheadrightarrow;": "↠",
    "&LeftDownTeeVector;": "⥡",
    "&LeftDoubleBracket;": "⟦",
    "&VerticalSeparator;": "❘",
    "&RightAngleBracket;": "⟩",
    "&NotNestedLessLess;": "⪡",
    "&NotLessSlantEqual;": "⩽",
    "&FilledSmallSquare;": "◼",
    "&DoubleVerticalBar;": "∥",
    "&GreaterSlantEqual;": "⩾",
    "&DownLeftTeeVector;": "⥞",
    "&NotReverseElement;": "∌",
    "&LeftDownVectorBar;": "⥙",
    "&RightUpDownVector;": "⥏",
    "&DoubleUpDownArrow;": "⇕",
    "&NegativeThinSpace;": "​",
    "&NotSquareSuperset;": "⊐",
    "&DownLeftVectorBar;": "⥖",
    "&NotGreaterGreater;": "≫",
    "&rightleftharpoons;": "⇌",
    "&blacktriangleleft;": "◂",
    "&leftrightharpoons;": "⇋",
    "&SquareSubsetEqual;": "⊑",
    "&blacktriangledown;": "▾",
    "&LeftTriangleEqual;": "⊴",
    "&UnderParenthesis;": "⏝",
    "&LessEqualGreater;": "⋚",
    "&EmptySmallSquare;": "◻",
    "&GreaterFullEqual;": "≧",
    "&LeftAngleBracket;": "⟨",
    "&rightrightarrows;": "⇉",
    "&twoheadleftarrow;": "↞",
    "&RightUpTeeVector;": "⥜",
    "&NotSucceedsEqual;": "⪰",
    "&downharpoonright;": "⇂",
    "&GreaterEqualLess;": "⋛",
    "&vartriangleright;": "⊳",
    "&NotPrecedesEqual;": "⪯",
    "&rightharpoondown;": "⇁",
    "&DoubleRightArrow;": "⇒",
    "&DiacriticalGrave;": "`",
    "&DiacriticalAcute;": "´",
    "&RightUpVectorBar;": "⥔",
    "&NotSucceedsTilde;": "≿",
    "&DiacriticalTilde;": "˜",
    "&UpArrowDownArrow;": "⇅",
    "&NotSupersetEqual;": "⊉",
    "&DownArrowUpArrow;": "⇵",
    "&LeftUpDownVector;": "⥑",
    "&NonBreakingSpace;": " ",
    "&NotRightTriangle;": "⋫",
    "&ntrianglerighteq;": "⋭",
    "&circlearrowright;": "↻",
    "&RightTriangleBar;": "⧐",
    "&LeftRightVector;": "⥎",
    "&leftharpoondown;": "↽",
    "&bigtriangledown;": "▽",
    "&curvearrowright;": "↷",
    "&ntrianglelefteq;": "⋬",
    "&OverParenthesis;": "⏜",
    "&nleftrightarrow;": "↮",
    "&DoubleDownArrow;": "⇓",
    "&ContourIntegral;": "∮",
    "&straightepsilon;": "ϵ",
    "&vartriangleleft;": "⊲",
    "&NotLeftTriangle;": "⋪",
    "&DoubleLeftArrow;": "⇐",
    "&nLeftrightarrow;": "⇎",
    "&RightDownVector;": "⇂",
    "&DownRightVector;": "⇁",
    "&downharpoonleft;": "⇃",
    "&NotGreaterTilde;": "≵",
    "&NotSquareSubset;": "⊏",
    "&NotHumpDownHump;": "≎",
    "&rightsquigarrow;": "↝",
    "&trianglerighteq;": "⊵",
    "&LowerRightArrow;": "↘",
    "&UpperRightArrow;": "↗",
    "&LeftUpVectorBar;": "⥘",
    "&rightleftarrows;": "⇄",
    "&LeftTriangleBar;": "⧏",
    "&CloseCurlyQuote;": "’",
    "&rightthreetimes;": "⋌",
    "&leftrightarrows;": "⇆",
    "&LeftUpTeeVector;": "⥠",
    "&ShortRightArrow;": "→",
    "&NotGreaterEqual;": "≱",
    "&circlearrowleft;": "↺",
    "&leftleftarrows;": "⇇",
    "&NotLessGreater;": "≸",
    "&NotGreaterLess;": "≹",
    "&LongRightArrow;": "⟶",
    "&nshortparallel;": "∦",
    "&NotVerticalBar;": "∤",
    "&Longrightarrow;": "⟹",
    "&NotSubsetEqual;": "⊈",
    "&ReverseElement;": "∋",
    "&RightVectorBar;": "⥓",
    "&Leftrightarrow;": "⇔",
    "&downdownarrows;": "⇊",
    "&SquareSuperset;": "⊐",
    "&longrightarrow;": "⟶",
    "&TildeFullEqual;": "≅",
    "&LeftDownVector;": "⇃",
    "&rightharpoonup;": "⇀",
    "&upharpoonright;": "↾",
    "&HorizontalLine;": "─",
    "&DownLeftVector;": "↽",
    "&curvearrowleft;": "↶",
    "&DoubleRightTee;": "⊨",
    "&looparrowright;": "↬",
    "&hookrightarrow;": "↪",
    "&RightTeeVector;": "⥛",
    "&trianglelefteq;": "⊴",
    "&rightarrowtail;": "↣",
    "&LowerLeftArrow;": "↙",
    "&NestedLessLess;": "≪",
    "&leftthreetimes;": "⋋",
    "&LeftRightArrow;": "↔",
    "&doublebarwedge;": "⌆",
    "&leftrightarrow;": "↔",
    "&ShortDownArrow;": "↓",
    "&ShortLeftArrow;": "←",
    "&LessSlantEqual;": "⩽",
    "&InvisibleComma;": "⁣",
    "&InvisibleTimes;": "⁢",
    "&OpenCurlyQuote;": "‘",
    "&ZeroWidthSpace;": "​",
    "&ntriangleright;": "⋫",
    "&GreaterGreater;": "⪢",
    "&DiacriticalDot;": "˙",
    "&UpperLeftArrow;": "↖",
    "&RightTriangle;": "⊳",
    "&PrecedesTilde;": "≾",
    "&NotTildeTilde;": "≉",
    "&hookleftarrow;": "↩",
    "&fallingdotseq;": "≒",
    "&looparrowleft;": "↫",
    "&LessFullEqual;": "≦",
    "&ApplyFunction;": "⁡",
    "&DoubleUpArrow;": "⇑",
    "&UpEquilibrium;": "⥮",
    "&PrecedesEqual;": "⪯",
    "&leftharpoonup;": "↼",
    "&longleftarrow;": "⟵",
    "&RightArrowBar;": "⇥",
    "&Poincareplane;": "ℌ",
    "&LeftTeeVector;": "⥚",
    "&SucceedsTilde;": "≿",
    "&LeftVectorBar;": "⥒",
    "&SupersetEqual;": "⊇",
    "&triangleright;": "▹",
    "&varsubsetneqq;": "⫋",
    "&RightUpVector;": "↾",
    "&blacktriangle;": "▴",
    "&bigtriangleup;": "△",
    "&upharpoonleft;": "↿",
    "&smallsetminus;": "∖",
    "&measuredangle;": "∡",
    "&NotTildeEqual;": "≄",
    "&shortparallel;": "∥",
    "&DoubleLeftTee;": "⫤",
    "&Longleftarrow;": "⟸",
    "&divideontimes;": "⋇",
    "&varsupsetneqq;": "⫌",
    "&DifferentialD;": "ⅆ",
    "&leftarrowtail;": "↢",
    "&SucceedsEqual;": "⪰",
    "&VerticalTilde;": "≀",
    "&RightTeeArrow;": "↦",
    "&ntriangleleft;": "⋪",
    "&NotEqualTilde;": "≂",
    "&LongLeftArrow;": "⟵",
    "&VeryThinSpace;": " ",
    "&varsubsetneq;": "⊊",
    "&NotLessTilde;": "≴",
    "&ShortUpArrow;": "↑",
    "&triangleleft;": "◃",
    "&RoundImplies;": "⥰",
    "&UnderBracket;": "⎵",
    "&varsupsetneq;": "⊋",
    "&VerticalLine;": "|",
    "&SquareSubset;": "⊏",
    "&LeftUpVector;": "↿",
    "&DownArrowBar;": "⤓",
    "&risingdotseq;": "≓",
    "&blacklozenge;": "⧫",
    "&RightCeiling;": "⌉",
    "&HilbertSpace;": "ℋ",
    "&LeftTeeArrow;": "↤",
    "&ExponentialE;": "ⅇ",
    "&NotHumpEqual;": "≏",
    "&exponentiale;": "ⅇ",
    "&DownTeeArrow;": "↧",
    "&GreaterEqual;": "≥",
    "&Intersection;": "⋂",
    "&GreaterTilde;": "≳",
    "&NotCongruent;": "≢",
    "&HumpDownHump;": "≎",
    "&NotLessEqual;": "≰",
    "&LeftTriangle;": "⊲",
    "&LeftArrowBar;": "⇤",
    "&triangledown;": "▿",
    "&Proportional;": "∝",
    "&CircleTimes;": "⊗",
    "&thickapprox;": "≈",
    "&CircleMinus;": "⊖",
    "&circleddash;": "⊝",
    "&blacksquare;": "▪",
    "&VerticalBar;": "∣",
    "&expectation;": "ℰ",
    "&SquareUnion;": "⊔",
    "&SmallCircle;": "∘",
    "&UpDownArrow;": "↕",
    "&Updownarrow;": "⇕",
    "&backepsilon;": "϶",
    "&eqslantless;": "⪕",
    "&nrightarrow;": "↛",
    "&RightVector;": "⇀",
    "&RuleDelayed;": "⧴",
    "&nRightarrow;": "⇏",
    "&MediumSpace;": " ",
    "&OverBracket;": "⎴",
    "&preccurlyeq;": "≼",
    "&LeftCeiling;": "⌈",
    "&succnapprox;": "⪺",
    "&LessGreater;": "≶",
    "&GreaterLess;": "≷",
    "&precnapprox;": "⪹",
    "&straightphi;": "ϕ",
    "&curlyeqprec;": "⋞",
    "&curlyeqsucc;": "⋟",
    "&SubsetEqual;": "⊆",
    "&Rrightarrow;": "⇛",
    "&NotSuperset;": "⊃",
    "&quaternions;": "ℍ",
    "&diamondsuit;": "♦",
    "&succcurlyeq;": "≽",
    "&NotSucceeds;": "⊁",
    "&NotPrecedes;": "⊀",
    "&Equilibrium;": "⇌",
    "&NotLessLess;": "≪",
    "&circledcirc;": "⊚",
    "&updownarrow;": "↕",
    "&nleftarrow;": "↚",
    "&curlywedge;": "⋏",
    "&RightFloor;": "⌋",
    "&lmoustache;": "⎰",
    "&rmoustache;": "⎱",
    "&circledast;": "⊛",
    "&UnderBrace;": "⏟",
    "&CirclePlus;": "⊕",
    "&sqsupseteq;": "⊒",
    "&sqsubseteq;": "⊑",
    "&UpArrowBar;": "⤒",
    "&NotGreater;": "≯",
    "&nsubseteqq;": "⫅",
    "&Rightarrow;": "⇒",
    "&TildeTilde;": "≈",
    "&TildeEqual;": "≃",
    "&EqualTilde;": "≂",
    "&nsupseteqq;": "⫆",
    "&Proportion;": "∷",
    "&Bernoullis;": "ℬ",
    "&Fouriertrf;": "ℱ",
    "&supsetneqq;": "⫌",
    "&ImaginaryI;": "ⅈ",
    "&lessapprox;": "⪅",
    "&rightarrow;": "→",
    "&RightArrow;": "→",
    "&mapstoleft;": "↤",
    "&UpTeeArrow;": "↥",
    "&mapstodown;": "↧",
    "&LeftVector;": "↼",
    "&varepsilon;": "ϵ",
    "&upuparrows;": "⇈",
    "&nLeftarrow;": "⇍",
    "&precapprox;": "⪷",
    "&Lleftarrow;": "⇚",
    "&eqslantgtr;": "⪖",
    "&complement;": "∁",
    "&gtreqqless;": "⪌",
    "&succapprox;": "⪸",
    "&ThickSpace;": " ",
    "&lesseqqgtr;": "⪋",
    "&Laplacetrf;": "ℒ",
    "&varnothing;": "∅",
    "&NotElement;": "∉",
    "&subsetneqq;": "⫋",
    "&longmapsto;": "⟼",
    "&varpropto;": "∝",
    "&Backslash;": "∖",
    "&MinusPlus;": "∓",
    "&nshortmid;": "∤",
    "&supseteqq;": "⫆",
    "&Coproduct;": "∐",
    "&nparallel;": "∦",
    "&therefore;": "∴",
    "&Therefore;": "∴",
    "&NotExists;": "∄",
    "&HumpEqual;": "≏",
    "&triangleq;": "≜",
    "&Downarrow;": "⇓",
    "&lesseqgtr;": "⋚",
    "&Leftarrow;": "⇐",
    "&Congruent;": "≡",
    "&checkmark;": "✓",
    "&heartsuit;": "♥",
    "&spadesuit;": "♠",
    "&subseteqq;": "⫅",
    "&lvertneqq;": "≨",
    "&gtreqless;": "⋛",
    "&DownArrow;": "↓",
    "&downarrow;": "↓",
    "&gvertneqq;": "≩",
    "&NotCupCap;": "≭",
    "&LeftArrow;": "←",
    "&leftarrow;": "←",
    "&LessTilde;": "≲",
    "&NotSubset;": "⊂",
    "&Mellintrf;": "ℳ",
    "&nsubseteq;": "⊈",
    "&nsupseteq;": "⊉",
    "&rationals;": "ℚ",
    "&bigotimes;": "⨂",
    "&subsetneq;": "⊊",
    "&nleqslant;": "⩽",
    "&complexes;": "ℂ",
    "&TripleDot;": "⃛",
    "&ngeqslant;": "⩾",
    "&UnionPlus;": "⊎",
    "&OverBrace;": "⏞",
    "&gtrapprox;": "⪆",
    "&CircleDot;": "⊙",
    "&dotsquare;": "⊡",
    "&backprime;": "‵",
    "&backsimeq;": "⋍",
    "&ThinSpace;": " ",
    "&LeftFloor;": "⌊",
    "&pitchfork;": "⋔",
    "&DownBreve;": "̑",
    "&CenterDot;": "·",
    "&centerdot;": "·",
    "&PlusMinus;": "±",
    "&DoubleDot;": "¨",
    "&supsetneq;": "⊋",
    "&integers;": "ℤ",
    "&subseteq;": "⊆",
    "&succneqq;": "⪶",
    "&precneqq;": "⪵",
    "&LessLess;": "⪡",
    "&varsigma;": "ς",
    "&thetasym;": "ϑ",
    "&vartheta;": "ϑ",
    "&varkappa;": "ϰ",
    "&gnapprox;": "⪊",
    "&lnapprox;": "⪉",
    "&gesdotol;": "⪄",
    "&lesdotor;": "⪃",
    "&geqslant;": "⩾",
    "&leqslant;": "⩽",
    "&ncongdot;": "⩭",
    "&andslope;": "⩘",
    "&capbrcup;": "⩉",
    "&cupbrcap;": "⩈",
    "&triminus;": "⨺",
    "&otimesas;": "⨶",
    "&timesbar;": "⨱",
    "&plusacir;": "⨣",
    "&intlarhk;": "⨗",
    "&pointint;": "⨕",
    "&scpolint;": "⨓",
    "&rppolint;": "⨒",
    "&cirfnint;": "⨐",
    "&fpartint;": "⨍",
    "&bigsqcup;": "⨆",
    "&biguplus;": "⨄",
    "&bigoplus;": "⨁",
    "&eqvparsl;": "⧥",
    "&smeparsl;": "⧤",
    "&infintie;": "⧝",
    "&imagline;": "ℐ",
    "&imagpart;": "ℑ",
    "&rtriltri;": "⧎",
    "&naturals;": "ℕ",
    "&realpart;": "ℜ",
    "&bbrktbrk;": "⎶",
    "&laemptyv;": "⦴",
    "&raemptyv;": "⦳",
    "&angmsdah;": "⦯",
    "&angmsdag;": "⦮",
    "&angmsdaf;": "⦭",
    "&angmsdae;": "⦬",
    "&angmsdad;": "⦫",
    "&UnderBar;": "_",
    "&angmsdac;": "⦪",
    "&angmsdab;": "⦩",
    "&angmsdaa;": "⦨",
    "&angrtvbd;": "⦝",
    "&cwconint;": "∲",
    "&profalar;": "⌮",
    "&doteqdot;": "≑",
    "&barwedge;": "⌅",
    "&DotEqual;": "≐",
    "&succnsim;": "⋩",
    "&precnsim;": "⋨",
    "&trpezium;": "⏢",
    "&elinters;": "⏧",
    "&curlyvee;": "⋎",
    "&bigwedge;": "⋀",
    "&backcong;": "≌",
    "&intercal;": "⊺",
    "&approxeq;": "≊",
    "&NotTilde;": "≁",
    "&dotminus;": "∸",
    "&awconint;": "∳",
    "&multimap;": "⊸",
    "&lrcorner;": "⌟",
    "&bsolhsub;": "⟈",
    "&RightTee;": "⊢",
    "&Integral;": "∫",
    "&notindot;": "⋵",
    "&dzigrarr;": "⟿",
    "&boxtimes;": "⊠",
    "&boxminus;": "⊟",
    "&llcorner;": "⌞",
    "&parallel;": "∥",
    "&drbkarow;": "⤐",
    "&urcorner;": "⌝",
    "&sqsupset;": "⊐",
    "&sqsubset;": "⊏",
    "&circledS;": "Ⓢ",
    "&shortmid;": "∣",
    "&DDotrahd;": "⤑",
    "&setminus;": "∖",
    "&SuchThat;": "∋",
    "&mapstoup;": "↥",
    "&ulcorner;": "⌜",
    "&Superset;": "⊃",
    "&Succeeds;": "≻",
    "&profsurf;": "⌓",
    "&triangle;": "▵",
    "&Precedes;": "≺",
    "&hksearow;": "⤥",
    "&clubsuit;": "♣",
    "&emptyset;": "∅",
    "&NotEqual;": "≠",
    "&PartialD;": "∂",
    "&hkswarow;": "⤦",
    "&Uarrocir;": "⥉",
    "&profline;": "⌒",
    "&lurdshar;": "⥊",
    "&ldrushar;": "⥋",
    "&circledR;": "®",
    "&thicksim;": "∼",
    "&supseteq;": "⊇",
    "&rbrksld;": "⦎",
    "&lbrkslu;": "⦍",
    "&nwarrow;": "↖",
    "&nearrow;": "↗",
    "&searrow;": "↘",
    "&swarrow;": "↙",
    "&suplarr;": "⥻",
    "&subrarr;": "⥹",
    "&rarrsim;": "⥴",
    "&lbrksld;": "⦏",
    "&larrsim;": "⥳",
    "&simrarr;": "⥲",
    "&rdldhar;": "⥩",
    "&ruluhar;": "⥨",
    "&rbrkslu;": "⦐",
    "&UpArrow;": "↑",
    "&uparrow;": "↑",
    "&vzigzag;": "⦚",
    "&dwangle;": "⦦",
    "&Cedilla;": "¸",
    "&harrcir;": "⥈",
    "&cularrp;": "⤽",
    "&curarrm;": "⤼",
    "&cudarrl;": "⤸",
    "&cudarrr;": "⤵",
    "&Uparrow;": "⇑",
    "&Implies;": "⇒",
    "&zigrarr;": "⇝",
    "&uwangle;": "⦧",
    "&NewLine;": "\n",
    "&nexists;": "∄",
    "&alefsym;": "ℵ",
    "&orderof;": "ℴ",
    "&Element;": "∈",
    "&notinva;": "∉",
    "&rarrbfs;": "⤠",
    "&larrbfs;": "⤟",
    "&Cayleys;": "ℭ",
    "&notniva;": "∌",
    "&Product;": "∏",
    "&dotplus;": "∔",
    "&bemptyv;": "⦰",
    "&demptyv;": "⦱",
    "&cemptyv;": "⦲",
    "&realine;": "ℛ",
    "&dbkarow;": "⤏",
    "&cirscir;": "⧂",
    "&ldrdhar;": "⥧",
    "&planckh;": "ℎ",
    "&Cconint;": "∰",
    "&nvinfin;": "⧞",
    "&bigodot;": "⨀",
    "&because;": "∵",
    "&Because;": "∵",
    "&NoBreak;": "⁠",
    "&angzarr;": "⍼",
    "&backsim;": "∽",
    "&OverBar;": "‾",
    "&napprox;": "≉",
    "&pertenk;": "‱",
    "&ddagger;": "‡",
    "&asympeq;": "≍",
    "&npolint;": "⨔",
    "&quatint;": "⨖",
    "&suphsol;": "⟉",
    "&coloneq;": "≔",
    "&eqcolon;": "≕",
    "&pluscir;": "⨢",
    "&questeq;": "≟",
    "&simplus;": "⨤",
    "&bnequiv;": "≡",
    "&maltese;": "✠",
    "&natural;": "♮",
    "&plussim;": "⨦",
    "&supedot;": "⫄",
    "&bigstar;": "★",
    "&subedot;": "⫃",
    "&supmult;": "⫂",
    "&between;": "≬",
    "&NotLess;": "≮",
    "&bigcirc;": "◯",
    "&lozenge;": "◊",
    "&lesssim;": "≲",
    "&lessgtr;": "≶",
    "&submult;": "⫁",
    "&supplus;": "⫀",
    "&gtrless;": "≷",
    "&subplus;": "⪿",
    "&plustwo;": "⨧",
    "&minusdu;": "⨪",
    "&lotimes;": "⨴",
    "&precsim;": "≾",
    "&succsim;": "≿",
    "&nsubset;": "⊂",
    "&rotimes;": "⨵",
    "&nsupset;": "⊃",
    "&olcross;": "⦻",
    "&triplus;": "⨹",
    "&tritime;": "⨻",
    "&intprod;": "⨼",
    "&boxplus;": "⊞",
    "&ccupssm;": "⩐",
    "&orslope;": "⩗",
    "&congdot;": "⩭",
    "&LeftTee;": "⊣",
    "&DownTee;": "⊤",
    "&nvltrie;": "⊴",
    "&nvrtrie;": "⊵",
    "&ddotseq;": "⩷",
    "&equivDD;": "⩸",
    "&angrtvb;": "⊾",
    "&ltquest;": "⩻",
    "&diamond;": "⋄",
    "&Diamond;": "⋄",
    "&gtquest;": "⩼",
    "&lessdot;": "⋖",
    "&nsqsube;": "⋢",
    "&nsqsupe;": "⋣",
    "&lesdoto;": "⪁",
    "&gesdoto;": "⪂",
    "&digamma;": "ϝ",
    "&isindot;": "⋵",
    "&upsilon;": "υ",
    "&notinvc;": "⋶",
    "&notinvb;": "⋷",
    "&omicron;": "ο",
    "&suphsub;": "⫗",
    "&notnivc;": "⋽",
    "&notnivb;": "⋾",
    "&supdsub;": "⫘",
    "&epsilon;": "ε",
    "&Upsilon;": "Υ",
    "&Omicron;": "Ο",
    "&topfork;": "⫚",
    "&npreceq;": "⪯",
    "&Epsilon;": "Ε",
    "&nsucceq;": "⪰",
    "&luruhar;": "⥦",
    "&urcrop;": "⌎",
    "&nexist;": "∄",
    "&midcir;": "⫰",
    "&DotDot;": "⃜",
    "&incare;": "℅",
    "&hamilt;": "ℋ",
    "&commat;": "@",
    "&eparsl;": "⧣",
    "&varphi;": "ϕ",
    "&lbrack;": "[",
    "&zacute;": "ź",
    "&iinfin;": "⧜",
    "&ubreve;": "ŭ",
    "&hslash;": "ℏ",
    "&planck;": "ℏ",
    "&plankv;": "ℏ",
    "&Gammad;": "Ϝ",
    "&gammad;": "ϝ",
    "&Ubreve;": "Ŭ",
    "&lagran;": "ℒ",
    "&kappav;": "ϰ",
    "&numero;": "№",
    "&copysr;": "℗",
    "&weierp;": "℘",
    "&boxbox;": "⧉",
    "&primes;": "ℙ",
    "&rbrack;": "]",
    "&Zacute;": "Ź",
    "&varrho;": "ϱ",
    "&odsold;": "⦼",
    "&Lambda;": "Λ",
    "&vsupnE;": "⫌",
    "&midast;": "*",
    "&zeetrf;": "ℨ",
    "&bernou;": "ℬ",
    "&preceq;": "⪯",
    "&lowbar;": "_",
    "&Jsercy;": "Ј",
    "&phmmat;": "ℳ",
    "&gesdot;": "⪀",
    "&lesdot;": "⩿",
    "&daleth;": "ℸ",
    "&lbrace;": "{",
    "&verbar;": "|",
    "&vsubnE;": "⫋",
    "&frac13;": "⅓",
    "&frac23;": "⅔",
    "&frac15;": "⅕",
    "&frac25;": "⅖",
    "&frac35;": "⅗",
    "&frac45;": "⅘",
    "&frac16;": "⅙",
    "&frac56;": "⅚",
    "&frac18;": "⅛",
    "&frac38;": "⅜",
    "&frac58;": "⅝",
    "&frac78;": "⅞",
    "&rbrace;": "}",
    "&vangrt;": "⦜",
    "&udblac;": "ű",
    "&ltrPar;": "⦖",
    "&gtlPar;": "⦕",
    "&rpargt;": "⦔",
    "&lparlt;": "⦓",
    "&curren;": "¤",
    "&cirmid;": "⫯",
    "&brvbar;": "¦",
    "&Colone;": "⩴",
    "&dfisht;": "⥿",
    "&nrarrw;": "↝",
    "&ufisht;": "⥾",
    "&rfisht;": "⥽",
    "&lfisht;": "⥼",
    "&larrtl;": "↢",
    "&gtrarr;": "⥸",
    "&rarrtl;": "↣",
    "&ltlarr;": "⥶",
    "&rarrap;": "⥵",
    "&apacir;": "⩯",
    "&easter;": "⩮",
    "&mapsto;": "↦",
    "&utilde;": "ũ",
    "&Utilde;": "Ũ",
    "&larrhk;": "↩",
    "&rarrhk;": "↪",
    "&larrlp;": "↫",
    "&tstrok;": "ŧ",
    "&rarrlp;": "↬",
    "&lrhard;": "⥭",
    "&rharul;": "⥬",
    "&llhard;": "⥫",
    "&lharul;": "⥪",
    "&simdot;": "⩪",
    "&wedbar;": "⩟",
    "&Tstrok;": "Ŧ",
    "&cularr;": "↶",
    "&tcaron;": "ť",
    "&curarr;": "↷",
    "&gacute;": "ǵ",
    "&Tcaron;": "Ť",
    "&tcedil;": "ţ",
    "&Tcedil;": "Ţ",
    "&scaron;": "š",
    "&Scaron;": "Š",
    "&scedil;": "ş",
    "&plusmn;": "±",
    "&Scedil;": "Ş",
    "&sacute;": "ś",
    "&Sacute;": "Ś",
    "&rcaron;": "ř",
    "&Rcaron;": "Ř",
    "&Rcedil;": "Ŗ",
    "&racute;": "ŕ",
    "&Racute;": "Ŕ",
    "&SHCHcy;": "Щ",
    "&middot;": "·",
    "&HARDcy;": "Ъ",
    "&dollar;": "\$",
    "&SOFTcy;": "Ь",
    "&andand;": "⩕",
    "&rarrpl;": "⥅",
    "&larrpl;": "⤹",
    "&frac14;": "¼",
    "&capcap;": "⩋",
    "&nrarrc;": "⤳",
    "&cupcup;": "⩊",
    "&frac12;": "½",
    "&swnwar;": "⤪",
    "&seswar;": "⤩",
    "&nesear;": "⤨",
    "&frac34;": "¾",
    "&nwnear;": "⤧",
    "&iquest;": "¿",
    "&Agrave;": "À",
    "&Aacute;": "Á",
    "&forall;": "∀",
    "&ForAll;": "∀",
    "&swarhk;": "⤦",
    "&searhk;": "⤥",
    "&capcup;": "⩇",
    "&Exists;": "∃",
    "&topcir;": "⫱",
    "&cupcap;": "⩆",
    "&Atilde;": "Ã",
    "&emptyv;": "∅",
    "&capand;": "⩄",
    "&nearhk;": "⤤",
    "&nwarhk;": "⤣",
    "&capdot;": "⩀",
    "&rarrfs;": "⤞",
    "&larrfs;": "⤝",
    "&coprod;": "∐",
    "&rAtail;": "⤜",
    "&lAtail;": "⤛",
    "&mnplus;": "∓",
    "&ratail;": "⤚",
    "&Otimes;": "⨷",
    "&plusdo;": "∔",
    "&Ccedil;": "Ç",
    "&ssetmn;": "∖",
    "&lowast;": "∗",
    "&compfn;": "∘",
    "&Egrave;": "È",
    "&latail;": "⤙",
    "&Rarrtl;": "⤖",
    "&propto;": "∝",
    "&Eacute;": "É",
    "&angmsd;": "∡",
    "&angsph;": "∢",
    "&zcaron;": "ž",
    "&smashp;": "⨳",
    "&lambda;": "λ",
    "&timesd;": "⨰",
    "&bkarow;": "⤍",
    "&Igrave;": "Ì",
    "&Iacute;": "Í",
    "&nvHarr;": "⤄",
    "&supsim;": "⫈",
    "&nvrArr;": "⤃",
    "&nvlArr;": "⤂",
    "&odblac;": "ő",
    "&Odblac;": "Ő",
    "&shchcy;": "щ",
    "&conint;": "∮",
    "&Conint;": "∯",
    "&hardcy;": "ъ",
    "&roplus;": "⨮",
    "&softcy;": "ь",
    "&ncaron;": "ň",
    "&there4;": "∴",
    "&Vdashl;": "⫦",
    "&becaus;": "∵",
    "&loplus;": "⨭",
    "&Ntilde;": "Ñ",
    "&mcomma;": "⨩",
    "&minusd;": "∸",
    "&homtht;": "∻",
    "&rcedil;": "ŗ",
    "&thksim;": "∼",
    "&supsup;": "⫖",
    "&Ncaron;": "Ň",
    "&xuplus;": "⨄",
    "&permil;": "‰",
    "&bottom;": "⊥",
    "&rdquor;": "”",
    "&parsim;": "⫳",
    "&timesb;": "⊠",
    "&minusb;": "⊟",
    "&lsquor;": "‚",
    "&rmoust;": "⎱",
    "&uacute;": "ú",
    "&rfloor;": "⌋",
    "&Dstrok;": "Đ",
    "&ugrave;": "ù",
    "&otimes;": "⊗",
    "&gbreve;": "ğ",
    "&dcaron;": "ď",
    "&oslash;": "ø",
    "&ominus;": "⊖",
    "&sqcups;": "⊔",
    "&dlcorn;": "⌞",
    "&lfloor;": "⌊",
    "&sqcaps;": "⊓",
    "&nsccue;": "⋡",
    "&urcorn;": "⌝",
    "&divide;": "÷",
    "&Dcaron;": "Ď",
    "&sqsupe;": "⊒",
    "&otilde;": "õ",
    "&sqsube;": "⊑",
    "&nparsl;": "⫽",
    "&nprcue;": "⋠",
    "&oacute;": "ó",
    "&rsquor;": "’",
    "&cupdot;": "⊍",
    "&ccaron;": "č",
    "&vsupne;": "⊋",
    "&Ccaron;": "Č",
    "&cacute;": "ć",
    "&ograve;": "ò",
    "&vsubne;": "⊊",
    "&ntilde;": "ñ",
    "&percnt;": "%",
    "&square;": "□",
    "&subdot;": "⪽",
    "&Square;": "□",
    "&squarf;": "▪",
    "&iacute;": "í",
    "&gtrdot;": "⋗",
    "&hellip;": "…",
    "&Gbreve;": "Ğ",
    "&supset;": "⊃",
    "&Cacute;": "Ć",
    "&Supset;": "⋑",
    "&Verbar;": "‖",
    "&subset;": "⊂",
    "&Subset;": "⋐",
    "&ffllig;": "ﬄ",
    "&xoplus;": "⨁",
    "&rthree;": "⋌",
    "&igrave;": "ì",
    "&abreve;": "ă",
    "&Barwed;": "⌆",
    "&marker;": "▮",
    "&horbar;": "―",
    "&eacute;": "é",
    "&egrave;": "è",
    "&hyphen;": "‐",
    "&supdot;": "⪾",
    "&lthree;": "⋋",
    "&models;": "⊧",
    "&inodot;": "ı",
    "&lesges;": "⪓",
    "&ccedil;": "ç",
    "&Abreve;": "Ă",
    "&xsqcup;": "⨆",
    "&iiiint;": "⨌",
    "&gesles;": "⪔",
    "&gtrsim;": "≳",
    "&Kcedil;": "Ķ",
    "&elsdot;": "⪗",
    "&kcedil;": "ķ",
    "&hybull;": "⁃",
    "&rtimes;": "⋊",
    "&barwed;": "⌅",
    "&atilde;": "ã",
    "&ltimes;": "⋉",
    "&bowtie;": "⋈",
    "&tridot;": "◬",
    "&period;": ".",
    "&divonx;": "⋇",
    "&sstarf;": "⋆",
    "&bullet;": "•",
    "&Udblac;": "Ű",
    "&kgreen;": "ĸ",
    "&aacute;": "á",
    "&rsaquo;": "›",
    "&hairsp;": " ",
    "&succeq;": "⪰",
    "&Hstrok;": "Ħ",
    "&subsup;": "⫓",
    "&lmoust;": "⎰",
    "&Lacute;": "Ĺ",
    "&solbar;": "⌿",
    "&thinsp;": " ",
    "&agrave;": "à",
    "&puncsp;": " ",
    "&female;": "♀",
    "&spades;": "♠",
    "&lacute;": "ĺ",
    "&hearts;": "♥",
    "&Lcedil;": "Ļ",
    "&Yacute;": "Ý",
    "&bigcup;": "⋃",
    "&bigcap;": "⋂",
    "&lcedil;": "ļ",
    "&bigvee;": "⋁",
    "&emsp14;": " ",
    "&cylcty;": "⌭",
    "&notinE;": "⋹",
    "&Lcaron;": "Ľ",
    "&lsaquo;": "‹",
    "&emsp13;": " ",
    "&bprime;": "‵",
    "&equals;": "=",
    "&tprime;": "‴",
    "&lcaron;": "ľ",
    "&nequiv;": "≢",
    "&isinsv;": "⋳",
    "&xwedge;": "⋀",
    "&egsdot;": "⪘",
    "&Dagger;": "‡",
    "&vellip;": "⋮",
    "&barvee;": "⊽",
    "&ffilig;": "ﬃ",
    "&qprime;": "⁗",
    "&ecaron;": "ě",
    "&veebar;": "⊻",
    "&equest;": "≟",
    "&Uacute;": "Ú",
    "&dstrok;": "đ",
    "&wedgeq;": "≙",
    "&circeq;": "≗",
    "&eqcirc;": "≖",
    "&sigmav;": "ς",
    "&ecolon;": "≕",
    "&dagger;": "†",
    "&Assign;": "≔",
    "&nrtrie;": "⋭",
    "&ssmile;": "⌣",
    "&colone;": "≔",
    "&Ugrave;": "Ù",
    "&sigmaf;": "ς",
    "&nltrie;": "⋬",
    "&Zcaron;": "Ž",
    "&jsercy;": "ј",
    "&intcal;": "⊺",
    "&nbumpe;": "≏",
    "&scnsim;": "⋩",
    "&Oslash;": "Ø",
    "&hercon;": "⊹",
    "&Gcedil;": "Ģ",
    "&bumpeq;": "≏",
    "&Bumpeq;": "≎",
    "&ldquor;": "„",
    "&Lmidot;": "Ŀ",
    "&CupCap;": "≍",
    "&topbot;": "⌶",
    "&subsub;": "⫕",
    "&prnsim;": "⋨",
    "&ulcorn;": "⌜",
    "&target;": "⌖",
    "&lmidot;": "ŀ",
    "&origof;": "⊶",
    "&telrec;": "⌕",
    "&langle;": "⟨",
    "&sfrown;": "⌢",
    "&Lstrok;": "Ł",
    "&rangle;": "⟩",
    "&lstrok;": "ł",
    "&xotime;": "⨂",
    "&approx;": "≈",
    "&Otilde;": "Õ",
    "&supsub;": "⫔",
    "&nsimeq;": "≄",
    "&hstrok;": "ħ",
    "&Nacute;": "Ń",
    "&ulcrop;": "⌏",
    "&Oacute;": "Ó",
    "&drcorn;": "⌟",
    "&Itilde;": "Ĩ",
    "&yacute;": "ý",
    "&plusdu;": "⨥",
    "&prurel;": "⊰",
    "&nVDash;": "⊯",
    "&dlcrop;": "⌍",
    "&nacute;": "ń",
    "&Ograve;": "Ò",
    "&wreath;": "≀",
    "&nVdash;": "⊮",
    "&drcrop;": "⌌",
    "&itilde;": "ĩ",
    "&Ncedil;": "Ņ",
    "&nvDash;": "⊭",
    "&nvdash;": "⊬",
    "&mstpos;": "∾",
    "&Vvdash;": "⊪",
    "&subsim;": "⫇",
    "&ncedil;": "ņ",
    "&thetav;": "ϑ",
    "&Ecaron;": "Ě",
    "&nvsim;": "∼",
    "&Tilde;": "∼",
    "&Gamma;": "Γ",
    "&xrarr;": "⟶",
    "&mDDot;": "∺",
    "&Ntilde": "Ñ",
    "&Colon;": "∷",
    "&ratio;": "∶",
    "&caron;": "ˇ",
    "&xharr;": "⟷",
    "&eqsim;": "≂",
    "&xlarr;": "⟵",
    "&Ograve": "Ò",
    "&nesim;": "≂",
    "&xlArr;": "⟸",
    "&cwint;": "∱",
    "&simeq;": "≃",
    "&Oacute": "Ó",
    "&nsime;": "≄",
    "&napos;": "ŉ",
    "&Ocirc;": "Ô",
    "&roang;": "⟭",
    "&loang;": "⟬",
    "&simne;": "≆",
    "&ncong;": "≇",
    "&Icirc;": "Î",
    "&asymp;": "≈",
    "&nsupE;": "⫆",
    "&xrArr;": "⟹",
    "&Otilde": "Õ",
    "&thkap;": "≈",
    "&Omacr;": "Ō",
    "&iiint;": "∭",
    "&jukcy;": "є",
    "&xhArr;": "⟺",
    "&omacr;": "ō",
    "&Delta;": "Δ",
    "&Cross;": "⨯",
    "&napid;": "≋",
    "&iukcy;": "і",
    "&bcong;": "≌",
    "&wedge;": "∧",
    "&Iacute": "Í",
    "&robrk;": "⟧",
    "&nspar;": "∦",
    "&Igrave": "Ì",
    "&times;": "×",
    "&nbump;": "≎",
    "&lobrk;": "⟦",
    "&bumpe;": "≏",
    "&lbarr;": "⤌",
    "&rbarr;": "⤍",
    "&lBarr;": "⤎",
    "&Oslash": "Ø",
    "&doteq;": "≐",
    "&esdot;": "≐",
    "&nsmid;": "∤",
    "&nedot;": "≐",
    "&rBarr;": "⤏",
    "&Ecirc;": "Ê",
    "&efDot;": "≒",
    "&RBarr;": "⤐",
    "&erDot;": "≓",
    "&Ugrave": "Ù",
    "&kappa;": "κ",
    "&tshcy;": "ћ",
    "&Eacute": "É",
    "&OElig;": "Œ",
    "&angle;": "∠",
    "&ubrcy;": "ў",
    "&oelig;": "œ",
    "&angrt;": "∟",
    "&rbbrk;": "❳",
    "&infin;": "∞",
    "&veeeq;": "≚",
    "&vprop;": "∝",
    "&lbbrk;": "❲",
    "&Egrave": "È",
    "&radic;": "√",
    "&Uacute": "Ú",
    "&sigma;": "σ",
    "&equiv;": "≡",
    "&Ucirc;": "Û",
    "&Ccedil": "Ç",
    "&setmn;": "∖",
    "&theta;": "θ",
    "&subnE;": "⫋",
    "&cross;": "✗",
    "&minus;": "−",
    "&check;": "✓",
    "&sharp;": "♯",
    "&AElig;": "Æ",
    "&natur;": "♮",
    "&nsubE;": "⫅",
    "&simlE;": "⪟",
    "&simgE;": "⪠",
    "&diams;": "♦",
    "&nleqq;": "≦",
    "&Yacute": "Ý",
    "&notni;": "∌",
    "&THORN;": "Þ",
    "&Alpha;": "Α",
    "&ngeqq;": "≧",
    "&numsp;": " ",
    "&clubs;": "♣",
    "&lneqq;": "≨",
    "&szlig;": "ß",
    "&angst;": "Å",
    "&breve;": "˘",
    "&gneqq;": "≩",
    "&Aring;": "Å",
    "&phone;": "☎",
    "&starf;": "★",
    "&iprod;": "⨼",
    "&amalg;": "⨿",
    "&notin;": "∉",
    "&agrave": "à",
    "&isinv;": "∈",
    "&nabla;": "∇",
    "&Breve;": "˘",
    "&cupor;": "⩅",
    "&empty;": "∅",
    "&aacute": "á",
    "&lltri;": "◺",
    "&comma;": ",",
    "&twixt;": "≬",
    "&acirc;": "â",
    "&nless;": "≮",
    "&urtri;": "◹",
    "&exist;": "∃",
    "&ultri;": "◸",
    "&xcirc;": "◯",
    "&awint;": "⨑",
    "&npart;": "∂",
    "&colon;": ":",
    "&delta;": "δ",
    "&hoarr;": "⇿",
    "&ltrif;": "◂",
    "&atilde": "ã",
    "&roarr;": "⇾",
    "&loarr;": "⇽",
    "&jcirc;": "ĵ",
    "&dtrif;": "▾",
    "&Acirc;": "Â",
    "&Jcirc;": "Ĵ",
    "&nlsim;": "≴",
    "&aring;": "å",
    "&ngsim;": "≵",
    "&xdtri;": "▽",
    "&filig;": "ﬁ",
    "&duarr;": "⇵",
    "&aelig;": "æ",
    "&Aacute": "Á",
    "&rarrb;": "⇥",
    "&ijlig;": "ĳ",
    "&IJlig;": "Ĳ",
    "&larrb;": "⇤",
    "&rtrif;": "▸",
    "&Atilde": "Ã",
    "&gamma;": "γ",
    "&Agrave": "À",
    "&rAarr;": "⇛",
    "&lAarr;": "⇚",
    "&swArr;": "⇙",
    "&ndash;": "–",
    "&prcue;": "≼",
    "&seArr;": "⇘",
    "&egrave": "è",
    "&sccue;": "≽",
    "&neArr;": "⇗",
    "&hcirc;": "ĥ",
    "&mdash;": "—",
    "&prsim;": "≾",
    "&ecirc;": "ê",
    "&scsim;": "≿",
    "&nwArr;": "⇖",
    "&utrif;": "▴",
    "&imath;": "ı",
    "&xutri;": "△",
    "&nprec;": "⊀",
    "&fltns;": "▱",
    "&iquest": "¿",
    "&nsucc;": "⊁",
    "&frac34": "¾",
    "&iogon;": "į",
    "&frac12": "½",
    "&rarrc;": "⤳",
    "&vnsub;": "⊂",
    "&igrave": "ì",
    "&Iogon;": "Į",
    "&frac14": "¼",
    "&gsiml;": "⪐",
    "&lsquo;": "‘",
    "&vnsup;": "⊃",
    "&ccups;": "⩌",
    "&ccaps;": "⩍",
    "&imacr;": "ī",
    "&raquo;": "»",
    "&fflig;": "ﬀ",
    "&iacute": "í",
    "&nrArr;": "⇏",
    "&rsquo;": "’",
    "&icirc;": "î",
    "&nsube;": "⊈",
    "&blk34;": "▓",
    "&blk12;": "▒",
    "&nsupe;": "⊉",
    "&blk14;": "░",
    "&block;": "█",
    "&subne;": "⊊",
    "&imped;": "Ƶ",
    "&nhArr;": "⇎",
    "&prnap;": "⪹",
    "&supne;": "⊋",
    "&ntilde": "ñ",
    "&nlArr;": "⇍",
    "&rlhar;": "⇌",
    "&alpha;": "α",
    "&uplus;": "⊎",
    "&ograve": "ò",
    "&sqsub;": "⊏",
    "&lrhar;": "⇋",
    "&cedil;": "¸",
    "&oacute": "ó",
    "&sqsup;": "⊐",
    "&ddarr;": "⇊",
    "&ocirc;": "ô",
    "&lhblk;": "▄",
    "&rrarr;": "⇉",
    "&middot": "·",
    "&otilde": "õ",
    "&uuarr;": "⇈",
    "&uhblk;": "▀",
    "&boxVH;": "╬",
    "&sqcap;": "⊓",
    "&llarr;": "⇇",
    "&lrarr;": "⇆",
    "&sqcup;": "⊔",
    "&boxVh;": "╫",
    "&udarr;": "⇅",
    "&oplus;": "⊕",
    "&divide": "÷",
    "&micro;": "µ",
    "&rlarr;": "⇄",
    "&acute;": "´",
    "&oslash": "ø",
    "&boxvH;": "╪",
    "&boxHU;": "╩",
    "&dharl;": "⇃",
    "&ugrave": "ù",
    "&boxhU;": "╨",
    "&dharr;": "⇂",
    "&boxHu;": "╧",
    "&uacute": "ú",
    "&odash;": "⊝",
    "&sbquo;": "‚",
    "&plusb;": "⊞",
    "&Scirc;": "Ŝ",
    "&rhard;": "⇁",
    "&ldquo;": "“",
    "&scirc;": "ŝ",
    "&ucirc;": "û",
    "&sdotb;": "⊡",
    "&vdash;": "⊢",
    "&parsl;": "⫽",
    "&dashv;": "⊣",
    "&rdquo;": "”",
    "&boxHD;": "╦",
    "&rharu;": "⇀",
    "&boxhD;": "╥",
    "&boxHd;": "╤",
    "&plusmn": "±",
    "&UpTee;": "⊥",
    "&uharl;": "↿",
    "&vDash;": "⊨",
    "&boxVL;": "╣",
    "&Vdash;": "⊩",
    "&uharr;": "↾",
    "&VDash;": "⊫",
    "&strns;": "¯",
    "&lhard;": "↽",
    "&lharu;": "↼",
    "&orarr;": "↻",
    "&vBarv;": "⫩",
    "&boxVl;": "╢",
    "&vltri;": "⊲",
    "&boxvL;": "╡",
    "&olarr;": "↺",
    "&vrtri;": "⊳",
    "&yacute": "ý",
    "&ltrie;": "⊴",
    "&thorn;": "þ",
    "&boxVR;": "╠",
    "&crarr;": "↵",
    "&rtrie;": "⊵",
    "&boxVr;": "╟",
    "&boxvR;": "╞",
    "&bdquo;": "„",
    "&sdote;": "⩦",
    "&boxUL;": "╝",
    "&nharr;": "↮",
    "&mumap;": "⊸",
    "&harrw;": "↭",
    "&udhar;": "⥮",
    "&duhar;": "⥯",
    "&laquo;": "«",
    "&erarr;": "⥱",
    "&Omega;": "Ω",
    "&lrtri;": "⊿",
    "&omega;": "ω",
    "&lescc;": "⪨",
    "&Wedge;": "⋀",
    "&eplus;": "⩱",
    "&boxUl;": "╜",
    "&boxuL;": "╛",
    "&pluse;": "⩲",
    "&boxUR;": "╚",
    "&Amacr;": "Ā",
    "&rnmid;": "⫮",
    "&boxUr;": "╙",
    "&Union;": "⋃",
    "&boxuR;": "╘",
    "&rarrw;": "↝",
    "&lopar;": "⦅",
    "&boxDL;": "╗",
    "&nrarr;": "↛",
    "&boxDl;": "╖",
    "&amacr;": "ā",
    "&ropar;": "⦆",
    "&nlarr;": "↚",
    "&brvbar": "¦",
    "&swarr;": "↙",
    "&Equal;": "⩵",
    "&searr;": "↘",
    "&gescc;": "⪩",
    "&nearr;": "↗",
    "&Aogon;": "Ą",
    "&bsime;": "⋍",
    "&lbrke;": "⦋",
    "&cuvee;": "⋎",
    "&aogon;": "ą",
    "&cuwed;": "⋏",
    "&eDDot;": "⩷",
    "&nwarr;": "↖",
    "&boxdL;": "╕",
    "&curren": "¤",
    "&boxDR;": "╔",
    "&boxDr;": "╓",
    "&boxdR;": "╒",
    "&rbrke;": "⦌",
    "&boxvh;": "┼",
    "&smtes;": "⪬",
    "&ltdot;": "⋖",
    "&gtdot;": "⋗",
    "&pound;": "£",
    "&ltcir;": "⩹",
    "&boxhu;": "┴",
    "&boxhd;": "┬",
    "&gtcir;": "⩺",
    "&boxvl;": "┤",
    "&boxvr;": "├",
    "&Ccirc;": "Ĉ",
    "&ccirc;": "ĉ",
    "&boxul;": "┘",
    "&boxur;": "└",
    "&boxdl;": "┐",
    "&boxdr;": "┌",
    "&Imacr;": "Ī",
    "&cuepr;": "⋞",
    "&Hacek;": "ˇ",
    "&cuesc;": "⋟",
    "&langd;": "⦑",
    "&rangd;": "⦒",
    "&iexcl;": "¡",
    "&srarr;": "→",
    "&lates;": "⪭",
    "&tilde;": "˜",
    "&Sigma;": "Σ",
    "&slarr;": "←",
    "&Uogon;": "Ų",
    "&lnsim;": "⋦",
    "&gnsim;": "⋧",
    "&range;": "⦥",
    "&uogon;": "ų",
    "&bumpE;": "⪮",
    "&prime;": "′",
    "&nltri;": "⋪",
    "&Emacr;": "Ē",
    "&emacr;": "ē",
    "&nrtri;": "⋫",
    "&scnap;": "⪺",
    "&Prime;": "″",
    "&supnE;": "⫌",
    "&Eogon;": "Ę",
    "&eogon;": "ę",
    "&fjlig;": "f",
    "&Wcirc;": "Ŵ",
    "&grave;": "`",
    "&gimel;": "ℷ",
    "&ctdot;": "⋯",
    "&utdot;": "⋰",
    "&dtdot;": "⋱",
    "&disin;": "⋲",
    "&wcirc;": "ŵ",
    "&isins;": "⋴",
    "&aleph;": "ℵ",
    "&Ubrcy;": "Ў",
    "&Ycirc;": "Ŷ",
    "&TSHcy;": "Ћ",
    "&isinE;": "⋹",
    "&order;": "ℴ",
    "&blank;": "␣",
    "&forkv;": "⫙",
    "&oline;": "‾",
    "&Theta;": "Θ",
    "&caret;": "⁁",
    "&Iukcy;": "І",
    "&dblac;": "˝",
    "&Gcirc;": "Ĝ",
    "&Jukcy;": "Є",
    "&lceil;": "⌈",
    "&gcirc;": "ĝ",
    "&rceil;": "⌉",
    "&fllig;": "ﬂ",
    "&ycirc;": "ŷ",
    "&iiota;": "℩",
    "&bepsi;": "϶",
    "&Dashv;": "⫤",
    "&ohbar;": "⦵",
    "&TRADE;": "™",
    "&trade;": "™",
    "&operp;": "⦹",
    "&reals;": "ℝ",
    "&frasl;": "⁄",
    "&bsemi;": "⁏",
    "&epsiv;": "ϵ",
    "&olcir;": "⦾",
    "&ofcir;": "⦿",
    "&bsolb;": "⧅",
    "&trisb;": "⧍",
    "&xodot;": "⨀",
    "&Kappa;": "Κ",
    "&Umacr;": "Ū",
    "&umacr;": "ū",
    "&upsih;": "ϒ",
    "&frown;": "⌢",
    "&csube;": "⫑",
    "&smile;": "⌣",
    "&image;": "ℑ",
    "&jmath;": "ȷ",
    "&varpi;": "ϖ",
    "&lsime;": "⪍",
    "&ovbar;": "⌽",
    "&gsime;": "⪎",
    "&nhpar;": "⫲",
    "&quest;": "?",
    "&Uring;": "Ů",
    "&uring;": "ů",
    "&lsimg;": "⪏",
    "&csupe;": "⫒",
    "&Hcirc;": "Ĥ",
    "&eacute": "é",
    "&ccedil": "ç",
    "&copy;": "©",
    "&gdot;": "ġ",
    "&bnot;": "⌐",
    "&scap;": "⪸",
    "&Gdot;": "Ġ",
    "&xnis;": "⋻",
    "&nisd;": "⋺",
    "&edot;": "ė",
    "&Edot;": "Ė",
    "&boxh;": "─",
    "&gesl;": "⋛",
    "&boxv;": "│",
    "&cdot;": "ċ",
    "&Cdot;": "Ċ",
    "&lesg;": "⋚",
    "&epar;": "⋕",
    "&boxH;": "═",
    "&boxV;": "║",
    "&fork;": "⋔",
    "&Star;": "⋆",
    "&sdot;": "⋅",
    "&diam;": "⋄",
    "&xcup;": "⋃",
    "&xcap;": "⋂",
    "&xvee;": "⋁",
    "&imof;": "⊷",
    "&yuml;": "ÿ",
    "&thorn": "þ",
    "&uuml;": "ü",
    "&ucirc": "û",
    "&perp;": "⊥",
    "&oast;": "⊛",
    "&ocir;": "⊚",
    "&odot;": "⊙",
    "&osol;": "⊘",
    "&ouml;": "ö",
    "&ocirc": "ô",
    "&iuml;": "ï",
    "&icirc": "î",
    "&supe;": "⊇",
    "&sube;": "⊆",
    "&nsup;": "⊅",
    "&nsub;": "⊄",
    "&squf;": "▪",
    "&rect;": "▭",
    "&Idot;": "İ",
    "&euml;": "ë",
    "&ecirc": "ê",
    "&succ;": "≻",
    "&utri;": "▵",
    "&prec;": "≺",
    "&ntgl;": "≹",
    "&rtri;": "▹",
    "&ntlg;": "≸",
    "&aelig": "æ",
    "&aring": "å",
    "&gsim;": "≳",
    "&dtri;": "▿",
    "&auml;": "ä",
    "&lsim;": "≲",
    "&ngeq;": "≱",
    "&ltri;": "◃",
    "&nleq;": "≰",
    "&acirc": "â",
    "&ngtr;": "≯",
    "&nGtv;": "≫",
    "&nLtv;": "≪",
    "&subE;": "⫅",
    "&star;": "☆",
    "&gvnE;": "≩",
    "&szlig": "ß",
    "&male;": "♂",
    "&lvnE;": "≨",
    "&THORN": "Þ",
    "&geqq;": "≧",
    "&leqq;": "≦",
    "&sung;": "♪",
    "&flat;": "♭",
    "&nvge;": "≥",
    "&Uuml;": "Ü",
    "&nvle;": "≤",
    "&malt;": "✠",
    "&supE;": "⫆",
    "&sext;": "✶",
    "&Ucirc": "Û",
    "&trie;": "≜",
    "&cire;": "≗",
    "&ecir;": "≖",
    "&eDot;": "≑",
    "&times": "×",
    "&bump;": "≎",
    "&nvap;": "≍",
    "&apid;": "≋",
    "&lang;": "⟨",
    "&rang;": "⟩",
    "&Ouml;": "Ö",
    "&Lang;": "⟪",
    "&Rang;": "⟫",
    "&Ocirc": "Ô",
    "&cong;": "≅",
    "&sime;": "≃",
    "&esim;": "≂",
    "&nsim;": "≁",
    "&race;": "∽",
    "&bsim;": "∽",
    "&Iuml;": "Ï",
    "&Icirc": "Î",
    "&oint;": "∮",
    "&tint;": "∭",
    "&cups;": "∪",
    "&xmap;": "⟼",
    "&caps;": "∩",
    "&npar;": "∦",
    "&spar;": "∥",
    "&tbrk;": "⎴",
    "&Euml;": "Ë",
    "&Ecirc": "Ê",
    "&nmid;": "∤",
    "&smid;": "∣",
    "&nang;": "∠",
    "&prop;": "∝",
    "&Sqrt;": "√",
    "&AElig": "Æ",
    "&prod;": "∏",
    "&Aring": "Å",
    "&Auml;": "Ä",
    "&isin;": "∈",
    "&part;": "∂",
    "&Acirc": "Â",
    "&comp;": "∁",
    "&vArr;": "⇕",
    "&toea;": "⤨",
    "&hArr;": "⇔",
    "&tosa;": "⤩",
    "&half;": "½",
    "&dArr;": "⇓",
    "&rArr;": "⇒",
    "&uArr;": "⇑",
    "&ldca;": "⤶",
    "&rdca;": "⤷",
    "&raquo": "»",
    "&lArr;": "⇐",
    "&ordm;": "º",
    "&sup1;": "¹",
    "&cedil": "¸",
    "&para;": "¶",
    "&micro": "µ",
    "&QUOT;": "\"",
    "&acute": "´",
    "&sup3;": "³",
    "&sup2;": "²",
    "&Barv;": "⫧",
    "&vBar;": "⫨",
    "&macr;": "¯",
    "&Vbar;": "⫫",
    "&rdsh;": "↳",
    "&lHar;": "⥢",
    "&uHar;": "⥣",
    "&rHar;": "⥤",
    "&dHar;": "⥥",
    "&ldsh;": "↲",
    "&Iscr;": "ℐ",
    "&bNot;": "⫭",
    "&laquo": "«",
    "&ordf;": "ª",
    "&COPY;": "©",
    "&qint;": "⨌",
    "&Darr;": "↡",
    "&Rarr;": "↠",
    "&Uarr;": "↟",
    "&Larr;": "↞",
    "&sect;": "§",
    "&varr;": "↕",
    "&pound": "£",
    "&harr;": "↔",
    "&cent;": "¢",
    "&iexcl": "¡",
    "&darr;": "↓",
    "&quot;": "\"",
    "&rarr;": "→",
    "&nbsp;": " ",
    "&uarr;": "↑",
    "&rcub;": "}",
    "&excl;": "!",
    "&ange;": "⦤",
    "&larr;": "←",
    "&vert;": "|",
    "&lcub;": "{",
    "&beth;": "ℶ",
    "&oscr;": "ℴ",
    "&Mscr;": "ℳ",
    "&Fscr;": "ℱ",
    "&Escr;": "ℰ",
    "&escr;": "ℯ",
    "&Bscr;": "ℬ",
    "&rsqb;": "]",
    "&Zopf;": "ℤ",
    "&omid;": "⦶",
    "&opar;": "⦷",
    "&Ropf;": "ℝ",
    "&csub;": "⫏",
    "&real;": "ℜ",
    "&Rscr;": "ℛ",
    "&Qopf;": "ℚ",
    "&cirE;": "⧃",
    "&solb;": "⧄",
    "&Popf;": "ℙ",
    "&csup;": "⫐",
    "&Nopf;": "ℕ",
    "&emsp;": " ",
    "&siml;": "⪝",
    "&prap;": "⪷",
    "&tscy;": "ц",
    "&chcy;": "ч",
    "&iota;": "ι",
    "&NJcy;": "Њ",
    "&KJcy;": "Ќ",
    "&shcy;": "ш",
    "&scnE;": "⪶",
    "&yucy;": "ю",
    "&circ;": "ˆ",
    "&yacy;": "я",
    "&nges;": "⩾",
    "&iocy;": "ё",
    "&DZcy;": "Џ",
    "&lnap;": "⪉",
    "&djcy;": "ђ",
    "&gjcy;": "ѓ",
    "&prnE;": "⪵",
    "&dscy;": "ѕ",
    "&yicy;": "ї",
    "&nles;": "⩽",
    "&ljcy;": "љ",
    "&gneq;": "⪈",
    "&IEcy;": "Е",
    "&smte;": "⪬",
    "&ZHcy;": "Ж",
    "&Esim;": "⩳",
    "&lneq;": "⪇",
    "&napE;": "⩰",
    "&njcy;": "њ",
    "&kjcy;": "ќ",
    "&dzcy;": "џ",
    "&ensp;": " ",
    "&khcy;": "х",
    "&plus;": "+",
    "&gtcc;": "⪧",
    "&semi;": ";",
    "&Yuml;": "Ÿ",
    "&zwnj;": "‌",
    "&KHcy;": "Х",
    "&TScy;": "Ц",
    "&bbrk;": "⎵",
    "&dash;": "‐",
    "&Vert;": "‖",
    "&CHcy;": "Ч",
    "&nvlt;": "<",
    "&bull;": "•",
    "&andd;": "⩜",
    "&nsce;": "⪰",
    "&npre;": "⪯",
    "&ltcc;": "⪦",
    "&nldr;": "‥",
    "&mldr;": "…",
    "&euro;": "€",
    "&andv;": "⩚",
    "&dsol;": "⧶",
    "&beta;": "β",
    "&IOcy;": "Ё",
    "&DJcy;": "Ђ",
    "&tdot;": "⃛",
    "&Beta;": "Β",
    "&SHcy;": "Ш",
    "&upsi;": "υ",
    "&oror;": "⩖",
    "&lozf;": "⧫",
    "&GJcy;": "Ѓ",
    "&Zeta;": "Ζ",
    "&Lscr;": "ℒ",
    "&YUcy;": "Ю",
    "&YAcy;": "Я",
    "&Iota;": "Ι",
    "&ogon;": "˛",
    "&iecy;": "е",
    "&zhcy;": "ж",
    "&apos;": "'",
    "&mlcp;": "⫛",
    "&ncap;": "⩃",
    "&zdot;": "ż",
    "&Zdot;": "Ż",
    "&nvgt;": ">",
    "&ring;": "˚",
    "&Copf;": "ℂ",
    "&Upsi;": "ϒ",
    "&ncup;": "⩂",
    "&gscr;": "ℊ",
    "&Hscr;": "ℋ",
    "&phiv;": "ϕ",
    "&lsqb;": "[",
    "&epsi;": "ε",
    "&zeta;": "ζ",
    "&DScy;": "Ѕ",
    "&Hopf;": "ℍ",
    "&YIcy;": "Ї",
    "&lpar;": "(",
    "&LJcy;": "Љ",
    "&hbar;": "ℏ",
    "&bsol;": "\\",
    "&rhov;": "ϱ",
    "&rpar;": ")",
    "&late;": "⪭",
    "&gnap;": "⪊",
    "&odiv;": "⨸",
    "&simg;": "⪞",
    "&fnof;": "ƒ",
    "&ell;": "ℓ",
    "&ogt;": "⧁",
    "&Ifr;": "ℑ",
    "&olt;": "⧀",
    "&Rfr;": "ℜ",
    "&Tab;": "\t",
    "&Hfr;": "ℌ",
    "&mho;": "℧",
    "&Zfr;": "ℨ",
    "&Cfr;": "ℭ",
    "&Hat;": "^",
    "&nbsp": " ",
    "&cent": "¢",
    "&yen;": "¥",
    "&sect": "§",
    "&bne;": "=",
    "&uml;": "¨",
    "&die;": "¨",
    "&Dot;": "¨",
    "&quot": "\"",
    "&copy": "©",
    "&COPY": "©",
    "&rlm;": "‏",
    "&lrm;": "‎",
    "&zwj;": "‍",
    "&map;": "↦",
    "&ordf": "ª",
    "&not;": "¬",
    "&sol;": "/",
    "&shy;": "­",
    "&Not;": "⫬",
    "&lsh;": "↰",
    "&Lsh;": "↰",
    "&rsh;": "↱",
    "&Rsh;": "↱",
    "&reg;": "®",
    "&Sub;": "⋐",
    "&REG;": "®",
    "&macr": "¯",
    "&deg;": "°",
    "&QUOT": "\"",
    "&sup2": "²",
    "&sup3": "³",
    "&ecy;": "э",
    "&ycy;": "ы",
    "&amp;": "&",
    "&para": "¶",
    "&num;": "#",
    "&sup1": "¹",
    "&fcy;": "ф",
    "&ucy;": "у",
    "&tcy;": "т",
    "&scy;": "с",
    "&ordm": "º",
    "&rcy;": "р",
    "&pcy;": "п",
    "&ocy;": "о",
    "&ncy;": "н",
    "&mcy;": "м",
    "&lcy;": "л",
    "&kcy;": "к",
    "&iff;": "⇔",
    "&Del;": "∇",
    "&jcy;": "й",
    "&icy;": "и",
    "&zcy;": "з",
    "&Auml": "Ä",
    "&niv;": "∋",
    "&dcy;": "д",
    "&gcy;": "г",
    "&vcy;": "в",
    "&bcy;": "б",
    "&acy;": "а",
    "&sum;": "∑",
    "&And;": "⩓",
    "&Sum;": "∑",
    "&Ecy;": "Э",
    "&ang;": "∠",
    "&Ycy;": "Ы",
    "&mid;": "∣",
    "&par;": "∥",
    "&orv;": "⩛",
    "&Map;": "⤅",
    "&ord;": "⩝",
    "&and;": "∧",
    "&vee;": "∨",
    "&cap;": "∩",
    "&Fcy;": "Ф",
    "&Ucy;": "У",
    "&Tcy;": "Т",
    "&Scy;": "С",
    "&apE;": "⩰",
    "&cup;": "∪",
    "&Rcy;": "Р",
    "&Pcy;": "П",
    "&int;": "∫",
    "&Ocy;": "О",
    "&Ncy;": "Н",
    "&Mcy;": "М",
    "&Lcy;": "Л",
    "&Kcy;": "К",
    "&Jcy;": "Й",
    "&Icy;": "И",
    "&Zcy;": "З",
    "&Int;": "∬",
    "&eng;": "ŋ",
    "&les;": "⩽",
    "&Dcy;": "Д",
    "&Gcy;": "Г",
    "&ENG;": "Ŋ",
    "&Vcy;": "В",
    "&Bcy;": "Б",
    "&ges;": "⩾",
    "&Acy;": "А",
    "&Iuml": "Ï",
    "&ETH;": "Ð",
    "&acE;": "∾",
    "&acd;": "∿",
    "&nap;": "≉",
    "&Ouml": "Ö",
    "&ape;": "≊",
    "&leq;": "≤",
    "&geq;": "≥",
    "&lap;": "⪅",
    "&Uuml": "Ü",
    "&gap;": "⪆",
    "&nlE;": "≦",
    "&lne;": "⪇",
    "&ngE;": "≧",
    "&gne;": "⪈",
    "&lnE;": "≨",
    "&gnE;": "≩",
    "&ast;": "*",
    "&nLt;": "≪",
    "&nGt;": "≫",
    "&lEg;": "⪋",
    "&nlt;": "≮",
    "&gEl;": "⪌",
    "&piv;": "ϖ",
    "&ngt;": "≯",
    "&nle;": "≰",
    "&cir;": "○",
    "&psi;": "ψ",
    "&lgE;": "⪑",
    "&glE;": "⪒",
    "&chi;": "χ",
    "&phi;": "φ",
    "&els;": "⪕",
    "&loz;": "◊",
    "&egs;": "⪖",
    "&nge;": "≱",
    "&auml": "ä",
    "&tau;": "τ",
    "&rho;": "ρ",
    "&npr;": "⊀",
    "&euml": "ë",
    "&nsc;": "⊁",
    "&eta;": "η",
    "&sub;": "⊂",
    "&sup;": "⊃",
    "&squ;": "□",
    "&iuml": "ï",
    "&ohm;": "Ω",
    "&glj;": "⪤",
    "&gla;": "⪥",
    "&eth;": "ð",
    "&ouml": "ö",
    "&Psi;": "Ψ",
    "&Chi;": "Χ",
    "&smt;": "⪪",
    "&lat;": "⪫",
    "&div;": "÷",
    "&Phi;": "Φ",
    "&top;": "⊤",
    "&Tau;": "Τ",
    "&Rho;": "Ρ",
    "&pre;": "⪯",
    "&bot;": "⊥",
    "&uuml": "ü",
    "&yuml": "ÿ",
    "&Eta;": "Η",
    "&Vee;": "⋁",
    "&sce;": "⪰",
    "&Sup;": "⋑",
    "&Cap;": "⋒",
    "&Cup;": "⋓",
    "&nLl;": "⋘",
    "&AMP;": "&",
    "&prE;": "⪳",
    "&scE;": "⪴",
    "&ggg;": "⋙",
    "&nGg;": "⋙",
    "&leg;": "⋚",
    "&gel;": "⋛",
    "&nis;": "⋼",
    "&dot;": "˙",
    "&Euml": "Ë",
    "&sim;": "∼",
    "&ac;": "∾",
    "&Or;": "⩔",
    "&oS;": "Ⓢ",
    "&Gg;": "⋙",
    "&Pr;": "⪻",
    "&Sc;": "⪼",
    "&Ll;": "⋘",
    "&sc;": "≻",
    "&pr;": "≺",
    "&gl;": "≷",
    "&lg;": "≶",
    "&Gt;": "≫",
    "&gg;": "≫",
    "&Lt;": "≪",
    "&ll;": "≪",
    "&gE;": "≧",
    "&lE;": "≦",
    "&ge;": "≥",
    "&le;": "≤",
    "&ne;": "≠",
    "&ap;": "≈",
    "&wr;": "≀",
    "&el;": "⪙",
    "&or;": "∨",
    "&mp;": "∓",
    "&ni;": "∋",
    "&in;": "∈",
    "&ii;": "ⅈ",
    "&ee;": "ⅇ",
    "&dd;": "ⅆ",
    "&DD;": "ⅅ",
    "&rx;": "℞",
    "&Re;": "ℜ",
    "&wp;": "℘",
    "&Im;": "ℑ",
    "&ic;": "⁣",
    "&it;": "⁢",
    "&af;": "⁡",
    "&pi;": "π",
    "&xi;": "ξ",
    "&nu;": "ν",
    "&mu;": "μ",
    "&Pi;": "Π",
    "&Xi;": "Ξ",
    "&eg;": "⪚",
    "&Mu;": "Μ",
    "&eth": "ð",
    "&ETH": "Ð",
    "&pm;": "±",
    "&deg": "°",
    "&REG": "®",
    "&reg": "®",
    "&shy": "­",
    "&not": "¬",
    "&uml": "¨",
    "&yen": "¥",
    "&GT;": ">",
    "&amp": "&",
    "&AMP": "&",
    "&gt;": ">",
    "&LT;": "<",
    "&Nu;": "Ν",
    "&lt;": "<",
    "&LT": "<",
    "&gt": ">",
    "&GT": ">",
    "&lt": "<",
    "&#8211;": "-"
  };

  htmlEntities.forEach((entity, character) {
    input = input.replaceAll(entity, character);
    //.replaceAll(RegExp(r'&[a-zA-Z]+;'), '')
    //  .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
  });
  return input;
}

List<dynamic> jsonToListConverter(List<dynamic> dataList) {
  return dataList;
}

List<String> getCountryAndStateName(List<dynamic> dataList) {
  List<String> finalList = [];
  for (int i = 0; i < dataList.length; i++) {
    finalList.add(dataList[i]['name']);
  }
  return finalList;
}

String formatPrice(
  String price,
  String thousandSeparator,
  String decimalSeparator,
  String decimalPlaces,
  String currencyPosition,
  String currency,
) {
  String priceStr = price.toString();

  // Split number into integer and decimal parts
  List<String> parts = priceStr.split(decimalSeparator);
  String integerPart = parts[0];
  String decimalPart =
      parts.length > 1 ? parts[1] : '0' * int.parse(decimalPlaces);

  // Format the integer part with Indian number system
  String formattedInteger = '';
  int len = integerPart.length;

  if (len > 3) {
    // First three digits remain unchanged
    formattedInteger = integerPart.substring(len - 3);
    int start = len - 3;

    while (start > 0) {
      int end = start - 2;
      if (end < 0) end = 0;
      formattedInteger = integerPart.substring(end, start) +
          thousandSeparator +
          formattedInteger;
      start = end;
    }
  } else {
    formattedInteger = integerPart;
  }

  return currencyPosition == 'left'
      ? '$currency$formattedInteger$decimalSeparator$decimalPart'
      : '$formattedInteger$decimalSeparator$decimalPart$currency';
}

String capitalizeFirst(String input) {
  if (input.isEmpty) return input; // Return input if it's empty

  // Capitalize first character and convert rest to lowercase
  return input.substring(0, 1).toUpperCase() + input.substring(1).toLowerCase();
}

String calculateTotal(List<dynamic> lineItems) {
  double total = 0.0;
  for (var item in lineItems) {
    total += double.parse(item['subtotal']);
  }
  return total.toStringAsFixed(2);
}

String calculateTotalQuantity(List<dynamic> items) {
  int totalQuantity = 0;

  for (var item in items) {
    totalQuantity += int.parse(item['quantity'].toString());
  }
  return items.isEmpty
      ? '0'
      : totalQuantity > 100
          ? '99+'
          : totalQuantity.toString();
}

List<dynamic> addToCartListConverter(
  List<dynamic> optionList,
  List<String> dataList,
) {
  List<dynamic> list = [];
  if (optionList.isNotEmpty && dataList.isNotEmpty) {
    for (int i = 0; i < optionList.length; i++) {
      list.add(
          {"attribute": "${optionList[i]['name']}", "value": "${dataList[i]}"});
    }
  } else {
    list = [];
  }

  return list;
}

dynamic findVariations(
  List<dynamic> variationsList,
  List<String> optionsList,
) {
  dynamic productDetail;

  for (int i = 0; i < variationsList.length; i++) {
    List list = variationsList[i]['attributes'];
    if (list.isEmpty) {
      productDetail = variationsList[i];
    }
    for (int j = 0; j < list.length; j++) {
      if (optionsList.isNotEmpty && optionsList.length >= list.length) {
        bool allMatch = true;
        for (int k = 0; k < list.length; k++) {
          if (optionsList[k] != list[k]['option']) {
            allMatch = false;

            print("Not Matched data: ${list[k]['option']} at index $i$j");

            break;
          }
        }
        if (allMatch) {
          productDetail = variationsList[i];
          print("Matched data: ${list} at index $i$j");
          break;
        }
      }
    }
  }
  return productDetail;
}

String divideBy100(String price) {
  int intValue = int.tryParse(price) ?? 0;
  double result = intValue / 100;
  return result.toStringAsFixed(2);
}

bool checkExpire(String date) {
  DateTime currentDate = DateTime.now();
  DateTime expireDate = DateTime.parse(date);
  if (currentDate.isAfter(expireDate)) {
    return true;
  } else {
    return false;
  }
}

List<dynamic> filterPaymentList(List<dynamic> paymentList) {
  List fixList = ["cod", "razorpay", "stripe", "ppcp-gateway"];
  List finalList = [];
  if (paymentList.isEmpty) {
    return [];
  } else {
    for (int i = 0; i < fixList.length; i++) {
      for (int j = 0; j < paymentList.length; j++) {
        if (fixList[i] == paymentList[j]['id']) {
          finalList.add(paymentList[j]);
        }
      }
    }
    if (finalList.length != paymentList.length) {
      finalList.add({"id": "webview", "method_title": "Webview checkout"});
    }
    return finalList;
  }
}

String paymentImages(String value) {
  switch (value) {
    case "cod":
      return "money_1.png";
      break;
    case "razorpay":
      return "razorPay.png";
      break;
    case "stripe":
      return "stripe.png";
      break;
    case "ppcp-gateway":
      return "paypal.png";
      break;
    default:
      return "webview_logo.png";
  }
}

List<dynamic> getLineItems(List<dynamic> inputList) {
// Output data list
  List data = [];
  List variationList = [];

  // Transform input list to desired output format
  if (inputList.isNotEmpty) {
    for (var item in inputList) {
      variationList = [];
      List varList = item['variation'];
      if (item['type'] == "variation" && varList.isNotEmpty) {
        for (var variation in varList) {
          variationList.add({
            "key": variation['attribute']
                .toString()
                .toLowerCase()
                .replaceAll(" ", "-")
                .replaceAll('(', '')
                .replaceAll(')', ''),
            "value": variation['value']
          });
        }
      }
      data.add({
        "product_id": item['id'],
        "quantity": item['quantity'],
        "variation_id": item['type'] == "variation" ? item['id'] : 0,
        "meta_data": variationList
      });
    }

    // Print the output list
    print(data);

    return data;
  } else {
    return data;
  }
}

List<dynamic> getCouponLines(List<dynamic> inputList) {
  // Output data list
  List data = [];

  // Transform input list to desired output format
  if (inputList.isNotEmpty) {
    for (var item in inputList) {
      data.add({"code": item['code']});
    }

    // Print the output list
    print(data);

    return data;
  } else {
    return data;
  }
}

List<dynamic> getShippingLines(List<dynamic> inputList) {
  // Output data list
  List data = [];

  // Transform input list to desired output format
  if (inputList.isNotEmpty) {
    for (var item in inputList) {
      String price = (int.parse(item['price']) / 100).toStringAsFixed(2);
      data.add({
        "method_id": item['method_id'],
        "method_title": item['name'],
        "total": price,
      });
    }

    // Print the output list
    print(data);

    return data;
  } else {
    return data;
  }
}

List<dynamic> getTaxLines(dynamic input) {
  // Output data list
  List data = [];

  // Transform input list to desired output format
  if (input != null && input['total_tax'] != "") {
    // for (var item in inputList) {
    data.add({"rate_id": 1, "total": input['total_tax']});
    // }

    // Print the output list
    print(data);

    return data;
  } else {
    return data;
  }
}

String formateReviewDate(String date) {
// Parse the date string into a DateTime object
  DateTime parsedDate = DateTime.parse(date);

  // Extract the day, month, and year
  int day = parsedDate.day;
  int month = parsedDate.month;
  int year = parsedDate.year;

  // List of abbreviated month names
  List<String> monthNames = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];

  // Get the abbreviated month name
  String monthName = monthNames[month - 1];

  // Format the date string
  String formattedDate = "$day $monthName, $year";

  // Print the formatted date
  print(formattedDate); // Output: 21 Apr, 2023

  return formattedDate;
}
