import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oshi/interface/cupertino/pages/home.dart';
import 'package:oshi/models/data/lesson.dart';
import 'package:oshi/models/provider.dart';

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:oshi/models/data/teacher.dart' show Teacher;
import 'package:oshi/models/progress.dart' show IProgress;

import 'package:oshi/providers/librus/librus_data.dart' show LibrusDataReader;
import 'package:oshi/providers/sample/sample_data.dart' show FakeDataReader;
import 'package:oshi/share/config.dart';
import 'package:oshi/share/translator.dart';

part 'share.g.dart';

class Share {
  // The application string resources handler
  static Translator translator = Translator();
  static String currentIdleSplash = '???';
  static ({String title, String subtitle}) currentEndingSplash = (title: '???', subtitle: '???');

  // The provider and register data for the current session
  // MUST be initialized before switching to the base app
  static late Session session;

  // Shared settings data for managing sessions
  static Settings settings = Settings();
  static String buildNumber = '9.9.9.9';
  static bool hasCheckedForUpdates = false;

  // Raised by the app to notify that the uses's just logged in
  // To subscribe: event.subscribe((args) => {})
  static Event<Value<StatefulWidget Function()>> changeBase = Event<Value<StatefulWidget Function()>>();
  static Event refreshBase = Event(); // Trigger a setState on the base app and everything subscribed
  static Event<Value<({String title, String message, Map<String, Future<void> Function()> actions})>> showErrorModal =
      Event<Value<({String title, String message, Map<String, Future<void> Function()> actions})>>();

  // Navigate the grades page to the specified subject
  static Event<Value<Lesson>> gradesNavigate = Event<Value<Lesson>>();

  // Navigate the timetable page to the specified day
  static Event<Value<DateTime>> timetableNavigateDay = Event<Value<DateTime>>();

  // Navigate the bottom tab bar to the specified page
  static Event<Value<int>> tabsNavigatePage = Event<Value<int>>();

  // Currently supported provider types, maps sample instances to factories
  static Map<String, ({IProvider instance, IProvider Function() factory})> providers = {
    // Sample data provider, only for debugging purposes
    'PROVGUID-SHIM-SMPL-FAKE-DATAPROVIDER': (instance: FakeDataReader(), factory: () => FakeDataReader()),
    // Librus synergia: log in with a synergia account
    'PROVGUID-RGLR-PROV-LIBR-LIBRSYNERGIA': (instance: LibrusDataReader(), factory: () => LibrusDataReader()),
  };
}

class Settings {
  // All sessions maintained by the app, including the current one
  SessionsData sessions = SessionsData();

  // The application configuration
  Config config = Config();

  // Load all the data from storage, called manually
  Future<({bool success, Exception? message})> load() async {
    try {
      // Remove all change listeners
      config.removeListener(save);

      // Load saved settings
      sessions = (await Hive.openBox('sessions')).get('sessions', defaultValue: SessionsData());
      config = (await Hive.openBox('config')).get('config', defaultValue: Config());

      // Re-setup change listeners
      config.addListener(save);
    } on Exception catch (ex) {
      return (success: false, message: ex);
    } catch (ex) {
      return (success: false, message: Exception(ex));
    }
    return (success: true, message: null);
  }

  // Save all received data to storage, called automatically
  Future<({bool success, Exception? message})> save() async {
    try {
      (await Hive.openBox('sessions')).put('sessions', sessions);
      (await Hive.openBox('config')).put('config', config);
    } on Exception catch (ex) {
      return (success: false, message: ex);
    } catch (ex) {
      return (success: false, message: Exception(ex));
    }
    return (success: true, message: null);
  }

  // Clear provider settings - login data, other custom settings
  Future<({bool success, Exception? message})> clear() async {
    try {
      // Remove all change listeners
      config.removeListener(save);

      // Clear internal settings
      (await Hive.openBox('sessions')).clear();
      (await Hive.openBox('config')).clear();

      // Re-generate settings
      sessions = SessionsData();
      config = Config();
    } on Exception catch (ex) {
      return (success: false, message: ex);
    } catch (ex) {
      return (success: false, message: Exception(ex));
    }
    return (success: true, message: null);
  }
}

@HiveType(typeId: 2)
@JsonSerializable(includeIfNull: false)
class SessionsData extends HiveObject {
  SessionsData({Map<String, Session>? sessions, this.lastSessionId = 'SESSIONS-SHIM-SMPL-FAKE-DATAPROVIDER'})
      : sessions = sessions ?? {};

  // The last session's identifier
  @HiveField(1)
  String? lastSessionId;

  // Last session's getter
  @JsonKey(includeToJson: false, includeFromJson: false)
  Session? get lastSession =>
      ((lastSessionId?.isNotEmpty ?? false) && sessions.containsKey(lastSessionId)) ? sessions[lastSessionId!] : null;

  // All sessions maintained by the app, including the current one
  // The 'fake' one is kept here for debugging, overwritten on startup anyway
  @HiveField(2)
  Map<String, Session> sessions = {
    'SESSIONS-SHIM-SMPL-FAKE-DATAPROVIDER': Session(providerGuid: 'PROVGUID-SHIM-SMPL-FAKE-DATAPROVIDER')
  };

  factory SessionsData.fromJson(Map<String, dynamic> json) => _$SessionsDataFromJson(json);

  Map<String, dynamic> toJson() => _$SessionsDataToJson(this);
}

@HiveType(typeId: 3)
@JsonSerializable(includeIfNull: false)
class Session extends HiveObject {
  Session(
      {this.sessionName = 'John Doe',
      this.providerGuid = 'PROVGUID-SHIM-SMPL-FAKE-DATAPROVIDER',
      Map<String, String>? credentials,
      IProvider? provider})
      : provider = provider ?? Share.providers[providerGuid]!.factory(),
        sessionCredentials = credentials ?? {},
        data = ProviderData();

  // Internal 'pretty' name
  @HiveField(1)
  String sessionName;

  @HiveField(5)
  String providerGuid;

  // Persistent login, pass, etc
  @HiveField(2)
  Map<String, String> sessionCredentials;

  // Downlaoded data
  @HiveField(4)
  ProviderData data;

  @JsonKey(includeToJson: false, includeFromJson: false)
  IProvider provider;

  // Login and reset methods for early setup - implement as async
  Future<({bool success, Exception? message})> login(
      {Map<String, String>? credentials, IProgress<({double? progress, String? message})>? progress}) async {
    if (credentials?.isNotEmpty ?? false) sessionCredentials = credentials ?? {};
    return await provider.login(credentials: credentials ?? sessionCredentials, progress: progress);
  }

  // Login and reset methods for early setup - implement as async
  Future<({bool success, Exception? message})> tryLogin(
      {Map<String, String>? credentials,
      IProgress<({double? progress, String? message})>? progress,
      bool showErrors = false}) async {
    try {
      if (credentials?.isNotEmpty ?? false) sessionCredentials = credentials ?? {};
      return await provider.login(credentials: credentials ?? sessionCredentials, progress: progress);
    } catch (ex, stack) {
      if (showErrors) {
        Share.showErrorModal.broadcast(Value((
          title: 'Error logging in!',
          message:
              'An exception "$ex" occurred and the provider couldn\'t log you in to the e-register.\n\nPlease check your credentials and try again later.',
          actions: {
            'Copy Exception': () async => await Clipboard.setData(ClipboardData(text: ex.toString())),
            'Copy Stack Trace': () async => await Clipboard.setData(ClipboardData(text: stack.toString())),
          }
        )));
      }
      return (success: false, message: Exception(ex));
    }
  }

  // Login and refresh methods for runtime - implement as async
  // For null 'weekStart' - get (only) the current week's data
  // For reporting 'progress' - mark 'Progress' as null for indeterminate status
  Future<({bool success, Exception? message})> refreshAll(
      {DateTime? weekStart, IProgress<({double? progress, String? message})>? progress}) async {
    try {
      var result1 = await provider.refresh(weekStart: weekStart, progress: progress);
      var result2 = await provider.refreshMessages(progress: progress);
      await updateData(info: result1.success, messages: result2.success);

      Share.currentIdleSplash = Share.translator.getRandomSplash();
      Share.currentEndingSplash = Share.translator.getRandomEndingSplash(
          Share.session.data.timetables[DateTime.now().asDate(utc: true).asDate()]?.lessonsNumber.asLessonNumber() ?? '???');
          
      return (success: result1.success && result2.success, message: result1.message ?? result2.message);
    } catch (ex, stack) {
      Share.showErrorModal.broadcast(Value((
        title: 'Error refreshing data!',
        message:
            'A fatal exception "$ex" occurred and the provider couldn\'t update the e-register data.\n\nPlease try again later.\nConsider reporting this error.',
        actions: {
          'Copy Exception': () async => await Clipboard.setData(ClipboardData(text: ex.toString())),
          'Copy Stack Trace': () async => await Clipboard.setData(ClipboardData(text: stack.toString())),
        }
      )));
      return (success: false, message: Exception(ex));
    }
  }

  // Login and refresh methods for runtime - implement as async
  // For null 'weekStart' - get (only) the current week's data
  // For reporting 'progress' - mark 'Progress' as null for indeterminate status
  Future<({bool success, Exception? message})> refresh(
      {DateTime? weekStart, IProgress<({double? progress, String? message})>? progress}) async {
    var result = await provider.refresh(weekStart: weekStart, progress: progress);
    if (result.success) await updateData(info: true);
    return result;
  }

  // Login and refresh methods for runtime - implement as async
  // For null 'weekStart' - get (only) the current week's data
  // For reporting 'progress' - mark 'Progress' as null for indeterminate status
  Future<({bool success, Exception? message})> refreshMessages(
      {IProgress<({double? progress, String? message})>? progress}) async {
    var result = await provider.refreshMessages(progress: progress);
    if (result.success) await updateData(messages: true);
    return result;
  }

  // Send a message to selected user/s, fetched from `Messages.Receivers`
  // Don't encode the strings, the provider will need to take care of that
  Future<({bool success, Exception? message})> sendMessage(List<Teacher> receivers, String topic, String content) async {
    var result = await provider.sendMessage(receivers: receivers, topic: topic, content: content);
    if (result.success) await updateData(messages: true);
    return result;
  }

  // Update session's data based on the provider, save to storage
  Future<void> updateData({bool info = false, bool messages = false}) async {
    if (provider.registerData == null) throw Exception('Provider cannot be null, cannot proceed!');
    if (messages) data.messages = provider.registerData!.messages; // TODO Only update
    if (info) {
      data.student = provider.registerData!.student;
      sessionName = data.student.account.name;
      provider.registerData!.timetables.timetable.forEach((key, value) => data.timetables.timetable.update(
            key,
            (x) => x = value,
            ifAbsent: () => value,
          ));
    }
    await Share.settings.save();
  }

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

  Map<String, dynamic> toJson() => _$SessionToJson(this);
}
