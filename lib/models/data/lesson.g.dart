// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
      id: json['id'] as int,
      url: json['url'] as String,
      name: json['name'] as String,
      no: json['no'] as int,
      short: json['short'] as String,
      isExtracurricular: json['isExtracurricular'] as bool,
      isBlockLesson: json['isBlockLesson'] as bool,
      hostClass: json['hostClass'] == null
          ? null
          : Class.fromJson(json['hostClass'] as Map<String, dynamic>),
      teacher: json['teacher'] == null
          ? null
          : Teacher.fromJson(json['teacher'] as Map<String, dynamic>),
      grades: (json['grades'] as List<dynamic>?)
          ?.map((e) => Grade.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'name': instance.name,
      'no': instance.no,
      'short': instance.short,
      'isExtracurricular': instance.isExtracurricular,
      'isBlockLesson': instance.isBlockLesson,
      'hostClass': instance.hostClass,
      'teacher': instance.teacher,
      'grades': instance.grades,
    };
