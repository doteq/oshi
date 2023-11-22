// ignore_for_file: prefer_final_fields
import 'dart:convert';
import 'dart:typed_data';

import 'package:background_fetch/background_fetch.dart';
import 'package:darq/darq.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:oshi/share/resources.dart';

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:oshi/share/share.dart';

part 'config.g.dart';

@HiveType(typeId: 4)
@JsonSerializable(includeIfNull: false)
class Config with ChangeNotifier {
  Config({
    Map<String, double>? customGradeValues,
    Map<String, double>? customGradeMarginValues,
    Map<String, double>? customGradeModifierValues,
    int? cupertinoAccentColor,
    bool? useCupertino,
    String? languageCode,
    bool? weightedAverage,
    bool? autoArithmeticAverage,
    YearlyAverageMethods? yearlyAverageMethod,
    int? lessonCallTime,
    LessonCallTypes? lessonCallType,
    Duration? bellOffset,
    bool? devMode,
    bool? notificationsAskedOnce,
    bool? enableTimetableNotifications,
    bool? enableGradesNotifications,
    bool? enableEventsNotifications,
    bool? enableAttendanceNotifications,
    bool? enableAnnouncementsNotifications,
    bool? enableMessagesNotifications,
    String? userAvatarImage,
    bool? enableBackgroundSync,
    bool? backgroundSyncWiFiOnly,
    int? backgroundSyncInterval,
  })  : _customGradeValues = customGradeValues ?? {},
        _customGradeMarginValues = customGradeMarginValues ?? {},
        _customGradeModifierValues = customGradeModifierValues ?? {'+': 0.5, '-': -0.25},
        _cupertinoAccentColor = cupertinoAccentColor ?? Resources.cupertinoAccentColors.keys.first,
        _useCupertino = useCupertino ?? true,
        _languageCode = languageCode ?? 'en',
        _weightedAverage = weightedAverage ?? true,
        _autoArithmeticAverage = autoArithmeticAverage ?? false,
        _yearlyAverageMethod = yearlyAverageMethod ?? YearlyAverageMethods.allGradesAverage,
        _lessonCallTime = lessonCallTime ?? 15,
        _lessonCallType = lessonCallType ?? LessonCallTypes.countFromEnd,
        _bellOffset = bellOffset ?? Duration.zero,
        _devMode = devMode ?? false,
        _notificationsAskedOnce = notificationsAskedOnce ?? false,
        _enableTimetableNotifications = enableTimetableNotifications ?? true,
        _enableGradesNotifications = enableGradesNotifications ?? true,
        _enableEventsNotifications = enableEventsNotifications ?? true,
        _enableAttendanceNotifications = enableAttendanceNotifications ?? true,
        _enableAnnouncementsNotifications = enableAnnouncementsNotifications ?? true,
        _enableMessagesNotifications = enableMessagesNotifications ?? true,
        _userAvatarImage = userAvatarImage ?? '',
        _enableBackgroundSync = enableBackgroundSync ?? true,
        _backgroundSyncWiFiOnly = backgroundSyncWiFiOnly ?? false,
        _backgroundSyncInterval = backgroundSyncInterval ?? 15;

  // TODO All HiveFields should be private and trigger a settings save

  @HiveField(1, defaultValue: {})
  Map<String, double> _customGradeValues;

  @HiveField(2, defaultValue: {})
  Map<String, double> _customGradeMarginValues;

  @HiveField(3, defaultValue: {'+': 0.5, '-': -0.25})
  Map<String, double> _customGradeModifierValues;

  @HiveField(4, defaultValue: 0)
  int _cupertinoAccentColor;

  @HiveField(5, defaultValue: true)
  bool _useCupertino;

  @HiveField(6, defaultValue: 'en')
  String _languageCode;

  @HiveField(7, defaultValue: true)
  bool _weightedAverage;

  @HiveField(8, defaultValue: false)
  bool _autoArithmeticAverage;

  @HiveField(9, defaultValue: YearlyAverageMethods.allGradesAverage)
  YearlyAverageMethods _yearlyAverageMethod;

  @HiveField(10, defaultValue: 15)
  int _lessonCallTime;

  @HiveField(11, defaultValue: LessonCallTypes.countFromEnd)
  LessonCallTypes _lessonCallType;

  @HiveField(12, defaultValue: Duration.zero)
  Duration _bellOffset;

  @HiveField(13, defaultValue: false)
  bool _devMode;

  @HiveField(14, defaultValue: false)
  bool _notificationsAskedOnce;

  @HiveField(15, defaultValue: true)
  bool _enableTimetableNotifications;

  @HiveField(16, defaultValue: true)
  bool _enableGradesNotifications;

  @HiveField(17, defaultValue: true)
  bool _enableEventsNotifications;

  @HiveField(18, defaultValue: true)
  bool _enableAttendanceNotifications;

  @HiveField(19, defaultValue: true)
  bool _enableAnnouncementsNotifications;

  @HiveField(20, defaultValue: true)
  bool _enableMessagesNotifications;

  @HiveField(21, defaultValue: '')
  String _userAvatarImage;

  @HiveField(22, defaultValue: true)
  bool _enableBackgroundSync;

  @HiveField(23, defaultValue: false)
  bool _backgroundSyncWiFiOnly;

  @HiveField(24, defaultValue: 15)
  int _backgroundSyncInterval;

  @JsonKey(includeToJson: false, includeFromJson: false)
  Map<String, double> get customGradeValues => _customGradeValues;

  @JsonKey(includeToJson: false, includeFromJson: false)
  Map<String, double> get customGradeMarginValues => _customGradeMarginValues;

  @JsonKey(includeToJson: false, includeFromJson: false)
  Map<String, double> get customGradeModifierValues => _customGradeModifierValues;

  @JsonKey(includeToJson: false, includeFromJson: false)
  ({CupertinoDynamicColor color, String name}) get cupertinoAccentColor =>
      Resources.cupertinoAccentColors[_cupertinoAccentColor] ?? Resources.cupertinoAccentColors.values.first;

  @JsonKey(includeToJson: false, includeFromJson: false)
  String get languageCode => Share.translator.supportedLanguages.any((x) => x.code == _languageCode)
      ? _languageCode
      : (Share.translator.supportedLanguages.firstOrDefault()?.code ?? 'en');

  @JsonKey(includeToJson: false, includeFromJson: false)
  String get localeCode => availableLocalesForDateFormatting.contains(_languageCode) ? _languageCode : 'en';

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get useCupertino => _useCupertino;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get weightedAverage => _weightedAverage;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get autoArithmeticAverage => _autoArithmeticAverage;

  @JsonKey(includeToJson: false, includeFromJson: false)
  YearlyAverageMethods get yearlyAverageMethod => _yearlyAverageMethod;

  @JsonKey(includeToJson: false, includeFromJson: false)
  int get lessonCallTime => _lessonCallTime;

  @JsonKey(includeToJson: false, includeFromJson: false)
  LessonCallTypes get lessonCallType => _lessonCallType;

  @JsonKey(includeToJson: false, includeFromJson: false)
  Duration get bellOffset => _bellOffset;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get devMode => _devMode;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get notificationsAskedOnce => _notificationsAskedOnce;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get enableTimetableNotifications => _enableTimetableNotifications;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get enableGradesNotifications => _enableGradesNotifications;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get enableEventsNotifications => _enableEventsNotifications;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get enableAttendanceNotifications => _enableAttendanceNotifications;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get enableAnnouncementsNotifications => _enableAnnouncementsNotifications;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get enableMessagesNotifications => _enableMessagesNotifications;

  @JsonKey(includeToJson: false, includeFromJson: false)
  Uint8List? get userAvatar {
    try {
      return base64Decode(_userAvatarImage);
    } catch (ex) {
      return null;
    }
  }

  @JsonKey(includeToJson: false, includeFromJson: false)
  Image? get userAvatarImage {
    try {
      if (userAvatar?.isEmpty ?? true) return null;
      return Image.memory(userAvatar!);
    } catch (ex) {
      return null;
    }
  }

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get enableBackgroundSync => _enableBackgroundSync;

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get backgroundSyncWiFiOnly => _backgroundSyncWiFiOnly;

  @JsonKey(includeToJson: false, includeFromJson: false)
  int get backgroundSyncInterval => _backgroundSyncInterval;

  set customGradeValues(Map<String, double> customGradeValues) {
    _customGradeValues = customGradeValues;
    notifyListeners();
  }

  set customGradeMarginValues(Map<String, double> customGradeMarginValues) {
    _customGradeMarginValues = customGradeMarginValues;
    notifyListeners();
  }

  set customGradeModifierValues(Map<String, double> customGradeModifierValues) {
    _customGradeModifierValues = customGradeModifierValues;
    notifyListeners();
  }

  set cupertinoAccentColor(({CupertinoDynamicColor color, String name}) cupertinoAccentColor) {
    _cupertinoAccentColor =
        Resources.cupertinoAccentColors.entries.firstWhereOrDefault((value) => value.value == cupertinoAccentColor)?.key ??
            0;
    notifyListeners();
  }

  set languageCode(String code) {
    _languageCode = code;
    notifyListeners();
  }

  set useCupertino(bool value) {
    _useCupertino = value;
    notifyListeners();
  }

  set weightedAverage(bool value) {
    _weightedAverage = value;
    notifyListeners();
  }

  set autoArithmeticAverage(bool value) {
    _autoArithmeticAverage = value;
    notifyListeners();
  }

  set yearlyAverageMethod(YearlyAverageMethods value) {
    _yearlyAverageMethod = value;
    notifyListeners();
  }

  set lessonCallTime(int value) {
    _lessonCallTime = value;
    notifyListeners();
  }

  set lessonCallType(LessonCallTypes value) {
    _lessonCallType = value;
    notifyListeners();
  }

  set bellOffset(Duration value) {
    _bellOffset = value;
    notifyListeners();
  }

  set devMode(bool value) {
    _devMode = value;
    notifyListeners();
  }

  set notificationsAskedOnce(bool value) {
    _notificationsAskedOnce = value;
    notifyListeners();
  }

  set enableTimetableNotifications(bool value) {
    _enableTimetableNotifications = value;
    notifyListeners();
  }

  set enableGradesNotifications(bool value) {
    _enableGradesNotifications = value;
    notifyListeners();
  }

  set enableEventsNotifications(bool value) {
    _enableEventsNotifications = value;
    notifyListeners();
  }

  set enableAttendanceNotifications(bool value) {
    _enableAttendanceNotifications = value;
    notifyListeners();
  }

  set enableAnnouncementsNotifications(bool value) {
    _enableAnnouncementsNotifications = value;
    notifyListeners();
  }

  set enableMessagesNotifications(bool value) {
    _enableMessagesNotifications = value;
    notifyListeners();
  }

  set userAvatar(Uint8List? value) {
    try {
      _userAvatarImage = value != null ? base64Encode(value) : '';
      notifyListeners();
    } catch (ex) {
      // ignored
    }
  }

  set enableBackgroundSync(bool value) {
    _enableBackgroundSync = value;
    notifyListeners();

    if (_enableBackgroundSync) {
      BackgroundFetch.start().then((int status) {
        Share.backgroundSyncActive = true;
      }).catchError((e) {
        Share.backgroundSyncActive = false;
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        Share.backgroundSyncActive = false;
      });
    }
  }

  set backgroundSyncWiFiOnly(bool value) {
    _backgroundSyncWiFiOnly = value;
    notifyListeners();
  }

  set backgroundSyncInterval(int value) {
    _backgroundSyncInterval = value;
    notifyListeners();
  }

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigToJson(this);
}
