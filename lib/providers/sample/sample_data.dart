import 'package:event/src/event.dart';
import 'package:event/src/eventargs.dart';
import 'package:ogaku/models/data/messages.dart';
import 'package:ogaku/models/data/student.dart';
import 'package:ogaku/models/data/teacher.dart';
import 'package:ogaku/models/progress.dart';
import 'package:ogaku/models/provider.dart';
import 'package:ogaku/models/data/event.dart' as models;

class FakeDataReader implements IProvider {
  @override
  Event<Value<String>> propertyChanged = Event<Value<String>>();

  @override
  Future<({Exception? message, bool success})> login({Map<String, String>? credentials}) async {
    return (success: true, message: null);
  }

  @override
  Future<({Exception? message, bool success})> refresh(
      {DateTime? weekStart, IProgress<({String? message, double? progress})>? progress}) async {
    return (success: true, message: null);
  }

  @override
  Future<({Exception? message, bool success})> refreshMessages(
      {IProgress<({String? message, double? progress})>? progress}) async {
    return (success: true, message: null);
  }

  @override
  Future<({Exception? message, bool success})> sendMessage(
      {required List<Teacher> receivers, required String topic, required String content}) async {
    return (success: true, message: null);
  }

  @override
  Uri? get providerBannerUri => Uri.parse('https://media.tenor.com/QPvKS6-yrzUAAAAC/cirno-touhou.gif');

  @override
  String get providerDescription =>
      "This is a sample provider, it's here for debugging purposes only. You could say hello, I guess? Be prepared for no actual response, though.";

  @override
  String get providerName => 'Sample Provider';

  @override
  ProviderData? get registerData => ProviderData(student: Student(account: Account(firstName: 'John', lastName: 'Doe')));

  @override
  Map<String, ({String name, bool obscure})> get credentialsConfig => {};

  @override
  Future<({Exception? message, Message? result, bool success})> fetchMessageContent(
      {required Message parent, required bool byMe}) async {
    return (success: true, message: null, result: null);
  }

  @override
  Future<({Exception? message, bool success})> moveMessageToTrash({required Message parent, required bool byMe}) async {
    return (success: true, message: null);
  }

  @override
  Future<({Exception? message, bool success})> markEventAsDone({required models.Event parent}) async {
    return (success: true, message: null);
  }

  @override
  Future<({Exception? message, bool success})> markEventAsViewed({required models.Event parent}) async {
    return (success: true, message: null);
  }
}