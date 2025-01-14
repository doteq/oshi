// ignore_for_file: prefer_const_constructors
import 'package:darq/darq.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:format/format.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:oshi/interface/components/cupertino/application.dart';
import 'package:oshi/interface/components/material/data_page.dart';
import 'package:oshi/interface/shared/containers.dart';
import 'package:oshi/interface/shared/input.dart';
import 'package:oshi/interface/shared/pages/home.dart';
import 'package:oshi/interface/shared/views/events_timeline.dart';
import 'package:oshi/interface/shared/views/message_compose.dart';
import 'package:oshi/interface/shared/views/new_event.dart';
import 'package:oshi/models/data/attendances.dart';
import 'package:oshi/models/data/event.dart';
import 'package:oshi/models/data/timetables.dart';
import 'package:oshi/share/extensions.dart';
import 'package:oshi/share/resources.dart';
import 'package:oshi/share/share.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:oshi/share/translator.dart';
import 'package:share_plus/share_plus.dart' as sharing;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';

extension TimelineWidgetsExtension on Iterable<AgendaEvent> {
  List<Widget> asEventWidgets(
          TimetableDay? day, String searchQuery, String placeholder, void Function(VoidCallback fn) setState) =>
      isEmpty && searchQuery.isNotEmpty
          ? [
              AdaptiveCard(
                  centered: true,
                  secondary: true,
                  child: Opacity(
                      opacity: 0.5,
                      child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            placeholder,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                          ))))
            ]
          : select((x, index) => Visibility(
              visible: isNotEmpty,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Builder(
                    builder: (context) =>
                        x.event?.asEventWidget(context, isNotEmpty, day, setState) ??
                        x.lesson?.asLessonWidget(context, null, day, setState) ??
                        Text('')),
              ))).toList();
}

extension EventColors on Event {
  Color asColor() => switch (category) {
        EventCategory.gathering => CupertinoColors.systemPurple, // Zebranie
        EventCategory.lecture => CupertinoColors.systemBlue, // Lektura
        EventCategory.test => CupertinoColors.systemOrange, // Test
        EventCategory.classWork => CupertinoColors.systemRed, // Praca Klasowa
        EventCategory.semCorrection => CupertinoColors.systemIndigo, // Poprawka
        EventCategory.other => CupertinoColors.inactiveGray, // Inne
        EventCategory.lessonWork => CupertinoColors.systemBrown, // Praca na Lekcji
        EventCategory.shortTest => CupertinoColors.systemCyan, // Kartkowka
        EventCategory.correction => CupertinoColors.systemIndigo, // Poprawa
        EventCategory.onlineLesson => CupertinoColors.systemGreen, // Online
        EventCategory.homework => CupertinoColors.systemYellow, // Praca domowa (horror)
        EventCategory.teacher => CupertinoColors.inactiveGray, // Nieobecnosc nauczyciela
        EventCategory.freeDay => CupertinoColors.inactiveGray, // Dzien wolny (opis)
        EventCategory.conference => CupertinoColors.systemTeal, // Wywiadowka
        EventCategory.admin => CupertinoColors.systemMint // Admin
      };

  double get cardHeight {
    var height = 180.0;

    if (subtitleString.isNotEmpty) height += 45;
    if (sender?.name.isNotEmpty ?? false) height += 45;
    if (date != null) height += 45;
    if (classroom?.name.isNotEmpty ?? false) height += 45;
    if (timeTo != null && timeTo?.hour != 0) height += 45;
    if (timeFrom.hour != 0) height += 45;

    return height;
  }
}

extension EventWidgetsExtension on Iterable<Event> {
  List<Widget> asEventWidgets(
          TimetableDay? day, String searchQuery, String placeholder, void Function(VoidCallback fn) setState) =>
      isEmpty && searchQuery.isNotEmpty
          ? [
              AdaptiveCard(
                  centered: true,
                  secondary: true,
                  child: Opacity(
                      opacity: 0.5,
                      child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            placeholder,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                          ))))
            ]
          : select((x, index) => Visibility(
              visible: isNotEmpty,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Builder(builder: (context) => x.asEventWidget(context, isNotEmpty, day, setState)),
              ))).toList();
}

extension EventWidgetExtension on Event {
  Widget asEventWidget(BuildContext context, bool isNotEmpty, TimetableDay? day, void Function(VoidCallback fn) setState,
          {bool markRemoved = false, bool markModified = false, Function()? onTap}) =>
      AdaptiveMenuButton(
          itemBuilder: (context) => [
                AdaptiveMenuItem(
                  onTap: () {
                    sharing.Share.share('A70900F1-79A1-432D-AC6D-137794074CCE'.localized.format(
                        titleString,
                        DateFormat("EEEE, MMM d, y").format(timeFrom),
                        (classroom?.name.isNotEmpty ?? false)
                            ? ('C33F8288-5BAD-4574-9C53-B54FED6757AC'.localized.format(classroom?.name ?? ""))
                            : '55FCBDA9-6905-49C9-A3E8-426058041A8B'.localized));
                    Navigator.of(context).pop();
                  },
                  icon: CupertinoIcons.share,
                  title: '/Share'.localized,
                ),
                category == EventCategory.homework
                    // Homework - mark as done
                    ? AdaptiveMenuItem(
                        onTap: () {
                          if (Share.session.data.student.mainClass.events.contains(this)) {
                            Share.session.provider.markEventAsDone(parent: this).then((s) {
                              try {
                                if (s.success) {
                                  setState(() => Share.session.data.student.mainClass
                                          .events[Share.session.data.student.mainClass.events.indexOf(this)] =
                                      Event.from(other: this, done: true));
                                }
                              } catch (ex) {
                                // ignored
                              }
                            });
                          } else {
                            // Must be a custom event
                            try {
                              setState(() => Share.session.customEvents[Share.session.customEvents.indexOf(this)] =
                                  Event.from(other: this, done: true));
                            } catch (ex) {
                              // ignored
                            }
                          }
                          Navigator.of(context).pop();
                        },
                        icon: CupertinoIcons.check_mark,
                        title: '50FD3CEB-CAA5-4AD2-AEC5-61C16308FE41'.localized,
                      )
                    // Event - add to calendar
                    : AdaptiveMenuItem(
                        onTap: () {
                          try {
                            calendar.Add2Calendar.addEvent2Cal(calendar.Event(
                                title: titleString,
                                description: subtitleString,
                                location: classroom?.name,
                                startDate: timeFrom,
                                endDate: timeTo ?? timeFrom));
                          } catch (ex) {
                            // ignored
                          }
                          Navigator.of(context).pop();
                        },
                        icon: CupertinoIcons.calendar,
                        title: '374BEB81-88EB-4C1C-A3B3-0E24DB13E0E4'.localized,
                      ),
              ]
                  .appendIf(
                      AdaptiveMenuItem(
                        icon: CupertinoIcons.pencil,
                        title: 'F0FFE57B-4458-4D41-9577-C72533B62C61'.localized,
                        onTap: () {
                          try {
                            showMaterialModalBottomSheet(
                                context: context,
                                builder: (context) => EventComposePage(
                                      previous: this,
                                    )).then((value) => setState(() {}));
                          } catch (ex) {
                            // ignored
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      isOwnEvent || isSharedEvent)
                  .appendIf(
                      AdaptiveMenuItem(
                        icon: CupertinoIcons.chat_bubble_2,
                        title: '/Inquiry'.localized,
                        onTap: () {
                          showMaterialModalBottomSheet(
                              context: context,
                              builder: (context) => MessageComposePage(
                                  receivers: sender != null ? [sender!] : [],
                                  subject: 'C834975A-FECF-4FA1-A099-242BC18FB55C'
                                      .localized
                                      .format(DateFormat("y.M.d").format(date ?? timeFrom)),
                                  signature:
                                      '${Share.session.data.student.account.name}, ${Share.session.data.student.mainClass.name}'));
                          Navigator.of(context).pop();
                        },
                      ),
                      !isOwnEvent)
                  .appendIf(
                      AdaptiveMenuItem(
                        icon: CupertinoIcons.delete,
                        title: '/Delete'.localized,
                        onTap: () {
                          setState(() => Share.session.customEvents.remove(this));
                          Share.settings.save();
                          Navigator.of(context).pop();
                        },
                      ),
                      isOwnEvent)
                  .appendIf(
                      AdaptiveMenuItem(
                        icon: CupertinoIcons.delete,
                        title: '/Delete'.localized,
                        onTap: () {
                          setState(() => Share.session.sharedEvents.remove(this));
                          Share.settings.save();
                          unshare(); // Unshare the event using the API
                          Navigator.of(context).pop();
                        },
                      ),
                      isSharedEvent),
          longPressOnly: true,
          child: eventBody(isNotEmpty, day, context,
              animation: null, markRemoved: markRemoved, markModified: markModified, onTap: onTap));

  Widget eventBody(bool isNotEmpty, TimetableDay? day, BuildContext context,
      {Animation<double>? animation,
      bool markRemoved = false,
      bool markModified = false,
      bool useOnTap = false,
      bool disableTap = false,
      Function()? onTap}) {
    var tag = Uuid().v4();
    var body = AdaptiveCard(
        regular: true,
        click: disableTap
            ? null
            : ((useOnTap && onTap != null)
                ? onTap
                : () => showMaterialModalBottomSheet(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    expand: false,
                    context: context,
                    builder: (context) => Table(
                            children: [
                          TableRow(children: [
                            Container(
                                margin: EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 5),
                                child: Hero(
                                    tag: tag,
                                    child: eventBody(isNotEmpty, day, context,
                                        useOnTap: onTap != null,
                                        markRemoved: markRemoved,
                                        markModified: markModified,
                                        disableTap: true,
                                        onTap: onTap)))
                          ]),
                        ]
                                .appendAllIf(
                                    attachments
                                            ?.select((x, index) => TableRow(children: [
                                                  GestureDetector(
                                                      onTap: () async {
                                                        try {
                                                          await launchUrlString(x.location);
                                                        } catch (ex) {
                                                          // ignored
                                                        }
                                                      },
                                                      child: Container(
                                                          padding: EdgeInsets.only(left: 12, top: 10, right: 10, bottom: 10),
                                                          margin: EdgeInsets.only(left: 15, top: 20, right: 15),
                                                          decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                                              color: CupertinoDynamicColor.resolve(
                                                                  CupertinoColors.tertiarySystemBackground, context)),
                                                          child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Icon(CupertinoIcons.paperclip,
                                                                    color: CupertinoColors.inactiveGray),
                                                                Expanded(
                                                                    child: Container(
                                                                        margin: EdgeInsets.only(left: 15),
                                                                        child: Text(
                                                                          x.name,
                                                                          overflow: TextOverflow.ellipsis,
                                                                          maxLines: 10,
                                                                          style: TextStyle(
                                                                              fontSize: 16, fontWeight: FontWeight.w600),
                                                                        ))),
                                                              ])))
                                                ]))
                                            .toList() ??
                                        [],
                                    attachments?.isNotEmpty ?? false)
                                .append(TableRow(children: [
                                  CardContainer(
                                      filled: false,
                                      additionalDividerMargin: 5,
                                      regularOverride: true,
                                      children: <Widget>[
                                        Divider(),
                                        AdaptiveCard(
                                          child: 'ED8D10FC-50FE-48C5-AD57-8E7418669AC3'.localized,
                                          regular: true,
                                          after: titleString,
                                        ),
                                      ]
                                          .appendIf(
                                              AdaptiveCard(
                                                child: '6FEE9962-29D9-4566-A44B-D9913F1CB412'.localized,
                                                regular: true,
                                                after: subtitleString,
                                              ),
                                              subtitleString.isNotEmpty)
                                          .appendIf(
                                              AdaptiveCard(
                                                child: category == EventCategory.teacher
                                                    ? '2F324FD4-CC19-4F9C-89CD-F372258AEF3C'.localized
                                                    : '/AddedBy'.localized,
                                                regular: true,
                                                after: sender?.name ?? '',
                                              ),
                                              sender?.name.isNotEmpty ?? false)
                                          .appendIf(
                                              AdaptiveCard(
                                                child: '/Date'.localized,
                                                regular: true,
                                                after: DateFormat.yMMMMEEEEd(Share.settings.appSettings.localeCode)
                                                    .format(date ?? timeFrom),
                                              ),
                                              date != null)
                                          .appendIf(
                                              AdaptiveCard(
                                                  child: 'AA2B9B71-49B6-45BD-A0FE-707D42A09EC5'.localized,
                                                  regular: true,
                                                  after: classroom?.name ?? ''),
                                              classroom?.name.isNotEmpty ?? false)
                                          .appendIf(
                                              AdaptiveCard(
                                                child: '58710A36-F758-4E5F-916E-9F7846ED58BA'.localized,
                                                regular: true,
                                                after: DateFormat.Hm(Share.settings.appSettings.localeCode).format(timeFrom),
                                              ),
                                              timeFrom.hour != 0)
                                          .appendIf(
                                              AdaptiveCard(
                                                child: '87657B56-BFB1-44FB-9B51-9155ED6396E4'.localized,
                                                regular: true,
                                                after: DateFormat.Hm(Share.settings.appSettings.localeCode)
                                                    .format(timeTo ?? timeFrom),
                                              ),
                                              timeTo != null && timeTo?.hour != 0))
                                ]))
                                .toList()))),
        margin: !Share.settings.appSettings.useCupertino && isHorizontalPhoneMode(context)
            ? EdgeInsets.only(left: 5, right: 5)
            : EdgeInsets.only(left: 15, top: 5, bottom: 5, right: 20),
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: (animation?.value ?? 0) < CupertinoContextMenu.animationOpensAt ? double.infinity : 100,
                maxWidth: (animation?.value ?? 0) < CupertinoContextMenu.animationOpensAt ? double.infinity : 260),
            child: Opacity(
                opacity: (category == EventCategory.homework && done) ? 0.5 : 1.0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 2,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      // Unread badge
                                      UnreadDot(
                                          unseen: () => unseen,
                                          markAsSeen: markAsSeen,
                                          margin: EdgeInsets.only(top: 5, right: 6)),
                                      // Event tag
                                      Visibility(
                                          visible: (day?.lessons
                                                  .any((y) => y?.any((z) => z.lessonNo == (lessonNo ?? -1)) ?? false) ??
                                              false),
                                          child: Container(
                                              margin: EdgeInsets.only(top: 5, right: 6),
                                              child: Container(
                                                height: 10,
                                                width: 10,
                                                decoration: BoxDecoration(shape: BoxShape.circle, color: asColor()),
                                              ))),
                                      // Event title
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                            titleString,
                                            maxLines:
                                                !Share.settings.appSettings.useCupertino && isHorizontalPhoneMode(context)
                                                    ? 3
                                                    : 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                fontStyle: markModified ? FontStyle.italic : null,
                                                decoration: markRemoved ? TextDecoration.lineThrough : null),
                                          )),
                                      // Symbol/homework/days
                                      Visibility(
                                          visible: category == EventCategory.homework && done,
                                          child: Container(
                                              margin: EdgeInsets.only(left: 4), child: Icon(CupertinoIcons.check_mark))),
                                      Visibility(
                                          visible: classroom?.name != null && category != EventCategory.teacher,
                                          child: Container(
                                              margin: EdgeInsets.only(top: 1, left: 3),
                                              child: Text(
                                                maxLines: 1,
                                                classroom?.name ?? '^^',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontStyle: markModified ? FontStyle.italic : null,
                                                    decoration: markRemoved ? TextDecoration.lineThrough : null),
                                              ))),
                                      Visibility(
                                          visible: category == EventCategory.teacher,
                                          child: Container(
                                              margin: EdgeInsets.only(top: 1, left: 3),
                                              child: (timeFrom.hour != 0 && timeTo?.hour != 0) &&
                                                      (timeFrom.asDate() == timeTo?.asDate())
                                                  ? Text(
                                                      maxLines: 1,
                                                      "${DateFormat.Hm(Share.settings.appSettings.localeCode).format(timeFrom)} - ${DateFormat.Hm(Share.settings.appSettings.localeCode).format(timeTo ?? DateTime.now())}",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          fontStyle: markModified ? FontStyle.italic : null,
                                                          decoration: markRemoved ? TextDecoration.lineThrough : null),
                                                    )
                                                  : Text(
                                                      maxLines: 1,
                                                      (timeFrom.month == timeTo?.month && timeFrom.day == timeTo?.day)
                                                          ? DateFormat.MMMd(Share.settings.appSettings.localeCode)
                                                              .format(timeTo ?? DateTime.now())
                                                          : (timeFrom.month == timeTo?.month)
                                                              ? "${DateFormat.d(Share.settings.appSettings.localeCode).format(timeFrom)} - ${DateFormat.MMMd(Share.settings.appSettings.localeCode).format(timeTo ?? DateTime.now())}"
                                                              : "${DateFormat.MMMd(Share.settings.appSettings.localeCode).format(timeFrom)} - ${DateFormat.MMMd(Share.settings.appSettings.localeCode).format(timeTo ?? DateTime.now())}",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          fontStyle: markModified ? FontStyle.italic : null,
                                                          decoration: markRemoved ? TextDecoration.lineThrough : null),
                                                    )))
                                    ]),
                                Visibility(
                                    visible: locationString.isNotEmpty,
                                    child: Opacity(
                                        opacity: 0.5,
                                        child: Container(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(
                                              maxLines: 1,
                                              locationString,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontStyle: markModified ? FontStyle.italic : null,
                                                  decoration: markRemoved ? TextDecoration.lineThrough : null),
                                            )))),
                                Visibility(
                                    visible: subtitleString.isNotEmpty,
                                    child: Opacity(
                                        opacity: 0.5,
                                        child: Container(
                                            margin: EdgeInsets.only(top: 4),
                                            child: Text(
                                              subtitleString.trim(),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontStyle: markModified ? FontStyle.italic : null,
                                                  decoration: markRemoved ? TextDecoration.lineThrough : null),
                                            )))),
                              ]))
                    ]))));

    return animation == null ? body : Hero(tag: tag, child: body);
  }
}

extension LessonWidgetExtension on TimetableLesson {
  Widget asLessonWidget(
      BuildContext context, DateTime? selectedDate, TimetableDay? selectedDay, void Function(VoidCallback fn) setState,
      {bool markRemoved = false, bool markModified = false, Function()? onTap}) {
    var lessonCallButtonString = switch (Share.session.settings.lessonCallType) {
      LessonCallTypes.countFromEnd =>
        'BF38C0A9-D585-46AE-A37B-F42F1655B0AF'.localized.format(Share.session.settings.lessonCallTime),
      LessonCallTypes.countFromStart =>
        'D761036A-4380-47BA-B8B3-E85CBBAC5DED'.localized.format(Share.session.settings.lessonCallTime),
      LessonCallTypes.halfLesson => '4A1B9B79-8787-4A49-BAAF-6C98F86795DD'.localized,
      LessonCallTypes.wholeLesson => '4192A962-C0A5-4276-89BC-7A68CA727370'.localized
    };

    var lessonCallMessageString = switch (Share.session.settings.lessonCallType) {
      LessonCallTypes.countFromEnd =>
        '4C63899A-2106-49F7-8E70-7DEFE2348C9B'.localized.format(Share.session.settings.lessonCallTime),
      LessonCallTypes.countFromStart =>
        '744D287F-E683-4E60-A01C-03F3379ED8C8'.localized.format(Share.session.settings.lessonCallTime),
      LessonCallTypes.halfLesson => '9DA6EABD-96E7-4561-8164-706DE026FD19'.localized,
      LessonCallTypes.wholeLesson => '28C22BA4-22F1-4685-B999-A35BD36767FA'.localized
    };

    return AdaptiveMenuButton(
        itemBuilder: (context) => [
              AdaptiveMenuItem(
                onTap: () {
                  sharing.Share.share('5E6CA4CB-4757-46BC-80F3-2B208CE822DD'.localized.format(
                      subject?.name ?? '25EFC95E-A925-4F98-BE8B-AB646D266E25'.localized,
                      DateFormat("EEEE, MMM d, y").format(date),
                      teacher?.name ?? '0ED15CBE-83CA-4E47-818F-61FCD06CBADA'.localized));
                  Navigator.of(context).pop();
                },
                icon: CupertinoIcons.share,
                title: '/Share'.localized,
              ),
              AdaptiveMenuItem(
                onTap: () {
                  try {
                    calendar.Add2Calendar.addEvent2Cal(calendar.Event(
                        title: subject?.name ??
                            '6BB62617-7000-4A27-A499-534F1E04764E'
                                .localized
                                .format(DateFormat("EEEE, MMM d, y").format(date)),
                        location: classroom?.name,
                        startDate: timeFrom ?? date,
                        endDate: timeTo ?? date));
                  } catch (ex) {
                    // ignored
                  }
                  Navigator.of(context).pop();
                },
                icon: CupertinoIcons.calendar,
                title: '374BEB81-88EB-4C1C-A3B3-0E24DB13E0E4'.localized,
              ),
              AdaptiveMenuItem(
                onTap: () {
                  try {
                    showMaterialModalBottomSheet(
                        context: context,
                        builder: (context) => EventComposePage(
                              date: date,
                              startTime: timeFrom,
                              endTime: timeTo,
                              classroom: classroom?.name,
                              lessonNumber: lessonNo,
                            )).then((value) => setState(() {}));
                  } catch (ex) {
                    // ignored
                  }
                  Navigator.of(context).pop();
                },
                icon: CupertinoIcons.add,
                title: '567C490D-B7D0-403A-99A1-9E21F7F77EB8'.localized,
              ),
              AdaptiveMenuItem(
                icon: CupertinoIcons.timer,
                title: '3B6E8151-45FD-48B3-97CB-99E556E02F3E'.localized.format(lessonCallButtonString),
                onTap: () {
                  showMaterialModalBottomSheet(
                      context: context,
                      builder: (context) => MessageComposePage(
                          receivers: teacher != null ? [teacher!] : [],
                          subject: '4DF5CFE9-2B5F-4AE1-AEFC-B4B8888A09ED'
                              .localized
                              .format(lessonCallMessageString, DateFormat("y.M.d").format(date), lessonNo),
                          message: '7955E73E-D260-43BA-8E2F-88CD43348BBD'
                              .localized
                              .format(lessonCallMessageString, subject?.name, DateFormat("y.M.d").format(date), lessonNo),
                          signature:
                              '${Share.session.data.student.account.name}, ${Share.session.data.student.mainClass.name}'));
                  Navigator.of(context).pop();
                },
              ),
              AdaptiveMenuItem(
                icon: CupertinoIcons.chat_bubble_2,
                title: '/Inquiry'.localized,
                onTap: () {
                  showMaterialModalBottomSheet(
                      context: context,
                      builder: (context) => MessageComposePage(
                          receivers: teacher != null ? [teacher!] : [],
                          subject: '50CFA04B-E8EB-4BC9-80F1-C5EF39FE8F3A'
                              .localized
                              .format(DateFormat("y.M.d").format(date), lessonNo),
                          signature:
                              '${Share.session.data.student.account.name}, ${Share.session.data.student.mainClass.name}'));
                  Navigator.of(context).pop();
                },
              ),
            ],
        longPressOnly: true,
        child: lessonBody(context, selectedDate, selectedDay,
            animation: null, markRemoved: markRemoved, markModified: markModified, onTap: onTap));
  }

  Widget lessonBody(BuildContext context, DateTime? selectedDate, TimetableDay? selectedDay,
      {Animation<double>? animation,
      bool markRemoved = false,
      bool markModified = false,
      bool useOnTap = false,
      bool disableTap = false,
      Function()? onTap}) {
    var events = Share.session.events
        .where((y) => y.date == selectedDate)
        .where((y) => (y.lessonNo ?? -1) == lessonNo)
        .select((y, index) => TableRow(children: [
              Container(
                  margin: EdgeInsets.only(top: 20, left: 15, right: 15), child: y.eventBody(true, selectedDay, context))
            ]))
        .toList();

    var tag = Uuid().v4();
    var body = AdaptiveCard(
        regular: true,
        click: disableTap
            ? null
            : ((useOnTap && onTap != null)
                ? onTap
                : () => showMaterialModalBottomSheet(
                    expand: false,
                    context: context,
                    builder: (context) => Table(
                            children: <TableRow>[
                          TableRow(children: [
                            Container(
                                margin: EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 10),
                                child: Hero(
                                    tag: tag,
                                    child: lessonBody(context, selectedDate, selectedDay,
                                        useOnTap: onTap != null,
                                        markRemoved: markRemoved,
                                        markModified: markModified,
                                        disableTap: true,
                                        onTap: onTap)))
                          ])
                        ].appendAllIf(events, events.isNotEmpty).appendIf(
                                TableRow(children: [
                                  CardContainer(
                                      filled: true,
                                      additionalDividerMargin: 5,
                                      regularOverride: true,
                                      children: <Widget>[]
                                          .appendIf(
                                              AdaptiveCard(
                                                child: 'AC7FCED9-3CEA-4C69-9512-8B409015DF2C'.localized,
                                                regular: true,
                                                after: subject?.name ?? '',
                                              ),
                                              subject?.name.isNotEmpty ?? false)
                                          .appendIf(
                                              AdaptiveCard(
                                                child: '2F324FD4-CC19-4F9C-89CD-F372258AEF3C'.localized,
                                                regular: true,
                                                after: teacher?.name ?? '',
                                              ),
                                              teacher?.name.isNotEmpty ?? false)
                                          .appendIf(
                                              AdaptiveCard(
                                                child: 'AA2B9B71-49B6-45BD-A0FE-707D42A09EC5'.localized,
                                                regular: true,
                                                after: classroom?.name ?? '',
                                              ),
                                              classroom?.name.isNotEmpty ?? false)
                                          .appendIf(
                                              AdaptiveCard(
                                                child: '4CCE58F6-2805-4D44-B97A-556679808477'.localized,
                                                regular: true,
                                                after: lessonNo.toString(),
                                              ),
                                              lessonNo >= 0)
                                          // Substitution details - original lesson
                                          .appendIf(
                                              AdaptiveCard(
                                                  child: '3098FAAF-7223-4E86-AB19-431882A7985C'.localized,
                                                  regular: true,
                                                  after: substitutionDetails?.originalSubject?.name ?? ''),
                                              (isCanceled || modifiedSchedule) &&
                                                  !isMovedLesson &&
                                                  (substitutionDetails?.originalSubject?.name.isNotEmpty ?? false))
                                          // Substitution details - original teacher
                                          .appendIf(
                                              AdaptiveCard(
                                                child: '58787B41-324C-4E3D-97AE-5EC23D058A5B'.localized,
                                                regular: true,
                                                after: substitutionDetails?.originalTeacher?.name ?? '',
                                              ),
                                              (isCanceled || modifiedSchedule) &&
                                                  !isMovedLesson &&
                                                  (substitutionDetails?.originalTeacher?.name.isNotEmpty ?? false))
                                          // Substitution details - moved lesson
                                          .appendIf(
                                              AdaptiveCard(
                                                child: isCanceled
                                                    ? '43026DF3-97E9-4449-BD20-D1E256C42F89'.localized
                                                    : '8A2F8A9D-1428-4EAA-BA31-CE64A64789C6'.localized,
                                                regular: true,
                                                after:
                                                    '${DateFormat.yMd(Share.settings.appSettings.localeCode).format(substitutionDetails?.originalDate ?? DateTime.now().asDate())}${substitutionDetails?.originalLessonNo != null ? ', L${substitutionDetails?.originalLessonNo.toString()}' : ''}',
                                              ),
                                              isMovedLesson)
                                          // Substitution details - cancelled
                                          .appendIf(
                                              AdaptiveCard(
                                                centered: true,
                                                child: '947A950F-6638-4194-91B2-99BCB42ADA86'.localized,
                                              ),
                                              isCanceled && !isMovedLesson))
                                ]),
                                true)))),
        margin: !Share.settings.appSettings.useCupertino && isHorizontalPhoneMode(context)
            ? EdgeInsets.only(left: 5, right: 5)
            : EdgeInsets.only(left: 15, top: 3, bottom: 3, right: 20),
        child: Opacity(
            opacity: (isCanceled ||
                    (date == DateTime.now().asDate() &&
                        (selectedDay?.dayEnd?.isAfter(DateTime.now()) ?? false) &&
                        (hourTo?.asHour(DateTime.now()).isBefore(DateTime.now()) ?? false)))
                ? 0.5
                : 1.0,
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: (animation?.value ?? 0) < CupertinoContextMenu.animationOpensAt
                        ? double.infinity
                        : ((modifiedSchedule || isCanceled) ? 110 : 80),
                    maxWidth: (animation?.value ?? 0) < CupertinoContextMenu.animationOpensAt ? double.infinity : 300),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children:
                              // Event tags
                              Share.session.events
                                      .where((y) => y.date == selectedDate)
                                      .where((y) => (y.lessonNo ?? -1) == lessonNo)
                                      .select((y, index) => Container(
                                          margin: EdgeInsets.only(top: 5, right: 6),
                                          child: Container(
                                            height: 10,
                                            width: 10,
                                            decoration: BoxDecoration(shape: BoxShape.circle, color: y.asColor()),
                                          )) as Widget)
                                      .toList() +
                                  // The lesson block
                                  [
                                    UnreadDot(
                                        unseen: () => unseen,
                                        markAsSeen: markAsSeen,
                                        margin: EdgeInsets.only(top: 5, right: 6)),
                                    // Lesson name
                                    Expanded(
                                        flex: 2,
                                        child: Text(
                                          subject?.name ?? '94149CBB-5B72-4186-A155-20A9C7FB1B2C'.localized,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              fontStyle: (isCanceled || modifiedSchedule || markModified)
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                              decoration: (isCanceled || markRemoved) ? TextDecoration.lineThrough : null),
                                        )),
                                    // Classroom name/symbol
                                    Container(
                                        padding: EdgeInsets.only(left: 15),
                                        child: ((animation?.value ?? 0) < CupertinoContextMenu.animationOpensAt &&
                                                (Share.session.data.student.attendances
                                                        ?.any((y) => y.date == date && y.lessonNo == lessonNo) ??
                                                    false))
                                            ? (switch (Share.session.data.student.attendances!
                                                .firstWhere((y) => y.date == date && y.lessonNo == lessonNo)
                                                .type) {
                                                AttendanceType.absent =>
                                                  Icon(CupertinoIcons.xmark, color: CupertinoColors.destructiveRed),
                                                AttendanceType.late =>
                                                  Icon(CupertinoIcons.timer, color: CupertinoColors.systemYellow),
                                                AttendanceType.excused =>
                                                  Icon(CupertinoIcons.doc_on_clipboard, color: CupertinoColors.systemCyan),
                                                AttendanceType.duty => Icon(CupertinoIcons.rectangle_stack_person_crop,
                                                    color: CupertinoColors.systemIndigo),
                                                AttendanceType.present =>
                                                  Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeGreen),
                                                AttendanceType.other =>
                                                  Icon(CupertinoIcons.question, color: CupertinoColors.inactiveGray)
                                              })
                                            : Text(
                                                classroom?.name ?? '',
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    fontStyle: (isCanceled || modifiedSchedule || markModified)
                                                        ? FontStyle.italic
                                                        : FontStyle.normal,
                                                    decoration:
                                                        (isCanceled || markRemoved) ? TextDecoration.lineThrough : null),
                                              ))
                                  ]),
                      // Time and teacher details
                      Visibility(
                          visible: !(date == DateTime.now().asDate() &&
                              (selectedDay?.dayEnd?.isAfter(DateTime.now()) ?? false) &&
                              ((hourTo?.asHour(DateTime.now()).isBefore(DateTime.now()) ?? false) || isCanceled)),
                          child: Container(
                              margin: EdgeInsets.only(top: 4),
                              child: Opacity(
                                  opacity: 0.5,
                                  child: Text(
                                    detailsTimeTeacherString,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontStyle: (isCanceled || modifiedSchedule || markModified)
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                        decoration: (isCanceled || markRemoved) ? TextDecoration.lineThrough : null),
                                  )))),
                      // Substitution details - visible if context is opened - not supported in material
                      Visibility(
                          visible: (animation?.value ?? 0) >= CupertinoContextMenu.animationOpensAt &&
                              (modifiedSchedule || isCanceled),
                          child: Container(
                              margin: EdgeInsets.only(top: 4),
                              child: Opacity(
                                  opacity: 0.5,
                                  child: Text(
                                    substitutionDetailsString,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontStyle: (isCanceled || modifiedSchedule || markModified)
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                        decoration: (isCanceled || markRemoved) ? TextDecoration.lineThrough : null),
                                  ))))
                    ]))));

    return animation == null ? body : Hero(tag: tag, child: body);
  }
}
