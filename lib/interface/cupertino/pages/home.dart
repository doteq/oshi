// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:darq/darq.dart';
import 'package:event/event.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:oshi/interface/cupertino/pages/timetable.dart';
import 'package:oshi/interface/cupertino/sessions_page.dart';
import 'package:oshi/interface/cupertino/views/grades_detailed.dart';
import 'package:oshi/interface/cupertino/views/message_compose.dart';
import 'package:oshi/interface/cupertino/widgets/searchable_bar.dart';
import 'package:oshi/models/data/event.dart';
import 'package:oshi/models/data/grade.dart';
import 'package:oshi/share/share.dart';

import 'package:oshi/interface/cupertino/widgets/text_chip.dart' show TextChip;
import 'package:pull_down_button/pull_down_button.dart';

// Boiler: returned to the app tab builder
StatefulWidget get homePage => HomePage();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();

  bool get isLucky =>
      Share.session.data.student.mainClass.unit.luckyNumber != null &&
      Share.session.data.student.account.number == Share.session.data.student.mainClass.unit.luckyNumber;

  @override
  Widget build(BuildContext context) {
    var currentDay = Share.session.data.timetables.timetable[DateTime.now().asDate()];
    var nextDay = Share.session.data.timetables.timetable[DateTime.now().asDate().add(Duration(days: 1))];

    var currentLesson = currentDay?.lessons
        .firstWhereOrDefault((x) =>
            x?.any((y) => DateTime.now().isAfterOrSame(y.hourFrom) && DateTime.now().isBeforeOrSame(y.hourTo)) ?? false)
        ?.firstOrDefault();
    var nextLesson = currentDay?.lessons
        .firstWhereOrDefault((x) => x?.any((y) => DateTime.now().isBeforeOrSame(y.hourFrom)) ?? false)
        ?.firstOrDefault();

    // Event list for the next week (7 days), exc homeworks and teacher absences
    var eventsWeek = Share.session.data.student.mainClass.events
        .where((x) => x.category != EventCategory.homework && x.category != EventCategory.teacher)
        .where((x) => x.date?.isAfter(DateTime.now().asDate()) ?? false)
        .where((x) => x.date?.isBefore(DateTime.now().add(Duration(days: 7)).asDate()) ?? false)
        .orderBy((x) => x.date ?? x.timeTo ?? x.timeFrom)
        .toList();

    // Event list for the next week (7 days), exc homeworks and teacher absences
    var gradesWeek = Share.session.data.student.subjects
        .where((x) => x.grades.isNotEmpty)
        .select((x, index) => (
              lesson: x,
              grades: x.grades.where((y) => y.addDate.isAfter(DateTime.now().subtract(Duration(days: 7)).asDate())).toList()
            ))
        .where((x) => x.grades.isNotEmpty)
        .orderByDescending((x) => x.grades.orderByDescending((y) => y.addDate).first.addDate)
        .toList();

    // Homework list for the next week (7 days)
    var homeworksWeek = Share.session.data.student.mainClass.events
        .where((x) => x.category == EventCategory.homework)
        .where((x) => x.timeTo?.isAfter(DateTime.now().asDate()) ?? false)
        .where((x) => x.timeTo?.isBefore(DateTime.now().add(Duration(days: 7)).asDate()) ?? false)
        .orderByDescending((x) => x.done ? 0 : 1)
        .thenBy((x) => x.date ?? x.timeTo ?? x.timeFrom)
        .toList();

    // Homeworks - first if any(), otherwise last
    var homeworksLast = homeworksWeek.isEmpty || homeworksWeek.all((x) => x.done);
    var homeworksWidget = CupertinoListSection.insetGrouped(
      margin: EdgeInsets.only(left: 15, right: 15, bottom: 10),
      dividerMargin: 35,
      header: Text('Homeworks'),
      children: homeworksWeek.isEmpty
          // No homeworks to display
          ? [
              CupertinoListTile(
                  title: Opacity(
                      opacity: 0.5,
                      child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            'All done, yay!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                          ))))
            ]
          // Bindable homework layout
          : homeworksWeek
              .select((x, index) => CupertinoListTile(
                  padding: EdgeInsets.all(0),
                  title: CupertinoContextMenu.builder(
                      actions: [
                        CupertinoContextMenuAction(
                          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                          trailingIcon: CupertinoIcons.share,
                          child: const Text('Share'),
                        ),
                        CupertinoContextMenuAction(
                          isDestructiveAction: true,
                          trailingIcon: CupertinoIcons.chat_bubble_2,
                          child: const Text('Inquiry'),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            showCupertinoModalBottomSheet(
                                context: context,
                                builder: (context) => MessageComposePage(
                                    receivers: x.sender != null ? [x.sender!] : [],
                                    subject:
                                        'Pytanie o pracę domową na dzień ${DateFormat("y.M.d").format(x.timeTo ?? x.timeFrom)}',
                                    signature:
                                        '${Share.session.data.student.account.name}, ${Share.session.data.student.mainClass.name}'));
                          },
                        ),
                      ],
                      builder: (BuildContext context, Animation<double> animation) => CupertinoButton(
                          onPressed: () {
                            Share.tabsNavigatePage.broadcast(Value(2));
                            Future.delayed(Duration(milliseconds: 250))
                                .then((arg) => Share.timetableNavigateDay.broadcast(Value(x.timeTo ?? x.timeFrom)));
                          },
                          padding: EdgeInsets.zero,
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  color: CupertinoDynamicColor.resolve(
                                      CupertinoDynamicColor.withBrightness(
                                          color: const Color.fromARGB(255, 255, 255, 255),
                                          darkColor: const Color.fromARGB(255, 28, 28, 30)),
                                      context)),
                              padding: EdgeInsets.only(right: 10, left: 6),
                              child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxHeight:
                                          animation.value < CupertinoContextMenu.animationOpensAt ? double.infinity : 125,
                                      maxWidth:
                                          animation.value < CupertinoContextMenu.animationOpensAt ? double.infinity : 260),
                                  child: Opacity(
                                      opacity: x.done ? 0.5 : 1.0,
                                      child: Container(
                                          margin: EdgeInsets.only(right: 10),
                                          alignment: Alignment.centerLeft,
                                          child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    TextChip(
                                                        text: DateFormat('d/M').format(x.timeTo ?? x.timeFrom),
                                                        margin: EdgeInsets.only(top: 6, bottom: 6, right: 10)),
                                                    Expanded(
                                                        child: Align(
                                                            alignment: Alignment.centerLeft,
                                                            child: Flexible(
                                                                child: Text(
                                                              x.title ?? x.content,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                  color: CupertinoDynamicColor.resolve(
                                                                      CupertinoDynamicColor.withBrightness(
                                                                          color: CupertinoColors.black,
                                                                          darkColor: CupertinoColors.white),
                                                                      context)),
                                                            )))),
                                                    Align(
                                                        alignment: Alignment.centerRight,
                                                        child: Visibility(
                                                          visible: x.done,
                                                          child: Container(
                                                              margin: EdgeInsets.only(left: 5),
                                                              child: Icon(CupertinoIcons.check_mark)),
                                                        ))
                                                  ],
                                                ),
                                                Visibility(
                                                    visible: animation.value >= CupertinoContextMenu.animationOpensAt,
                                                    child: Container(
                                                        margin: EdgeInsets.only(left: 5, right: 5, bottom: 7, top: 3),
                                                        child: Flexible(
                                                            child: Text(
                                                          'Notes: ${x.content}',
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w500,
                                                              color: CupertinoDynamicColor.resolve(
                                                                  CupertinoDynamicColor.withBrightness(
                                                                      color: CupertinoColors.black,
                                                                      darkColor: CupertinoColors.white),
                                                                  context)),
                                                        )))),
                                                Visibility(
                                                    visible: animation.value >= CupertinoContextMenu.animationOpensAt,
                                                    child: Container(
                                                        margin: EdgeInsets.only(left: 5, right: 5, bottom: 7),
                                                        child: Flexible(
                                                            child: Text(
                                                          x.addedByString,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w500,
                                                              color: CupertinoDynamicColor.resolve(
                                                                  CupertinoDynamicColor.withBrightness(
                                                                      color: CupertinoColors.black,
                                                                      darkColor: CupertinoColors.white),
                                                                  context)),
                                                        ))))
                                              ])))))))))
              .toList(),
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.withBrightness(
          color: const Color.fromARGB(255, 242, 242, 247), darkColor: const Color.fromARGB(255, 0, 0, 0)),
      child: SearchableSliverNavigationBar(
        setState: setState,
        segments: {'home': 'Home', 'timeline': 'Timeline'},
        searchController: searchController,
        largeTitle: Text('Home'),
        trailing: PullDownButton(
          itemBuilder: (context) => [
            PullDownMenuItem(
              title: 'Settings',
              icon: CupertinoIcons.gear,
              onTap: () {},
            ),
            PullDownMenuDivider.large(),
            PullDownMenuTitle(title: Text('Accounts')),
            PullDownMenuItem(
              title: 'Sessions',
              icon: CupertinoIcons.rectangle_stack_person_crop,
              onTap: () => Share.changeBase.broadcast(Value(() => sessionsPage)),
            )
          ],
          buttonBuilder: (context, showMenu) => GestureDetector(
            onTap: showMenu,
            child: const Icon(CupertinoIcons.ellipsis_circle),
          ),
        ),
        children: [
          CupertinoListSection.insetGrouped(
              margin: EdgeInsets.only(left: 15, right: 15, bottom: 10),
              additionalDividerMargin: 5,
              hasLeading: false,
              header: Text('Summary'),
              children: [
                CupertinoListTile(
                    onTap: () {
                      Share.tabsNavigatePage.broadcast(Value(2));
                      Future.delayed(Duration(milliseconds: 250)).then((arg) => Share.timetableNavigateDay.broadcast(Value(
                          DateTime.now().asDate().add(Duration(
                              days: DateTime.now().isAfterOrSame(currentDay?.dayEnd) && (nextDay?.hasLessons ?? false)
                                  ? 1
                                  : 0)))));
                    },
                    title: Container(
                        margin: EdgeInsets.only(top: 10, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Expanded(
                                  child: Text(
                                glanceTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                ),
                              )),
                              Visibility(
                                  visible: Share.session.data.student.mainClass.unit.luckyNumber != null,
                                  child: Stack(alignment: Alignment.center, children: [
                                    Text(
                                        (DateTime.now().isAfterOrSame(currentDay?.dayEnd) &&
                                                    Share.session.data.student.account.number ==
                                                        Share.session.data.student.mainClass.unit.luckyNumber &&
                                                    Share.session.data.student.mainClass.unit.luckyNumberTomorrow) ||
                                                (DateTime.now().isBeforeOrSame(currentDay?.dayStart) &&
                                                    Share.session.data.student.account.number ==
                                                        Share.session.data.student.mainClass.unit.luckyNumber &&
                                                    !Share.session.data.student.mainClass.unit.luckyNumberTomorrow)
                                            ? '🌟'
                                            : '⭐',
                                        style: TextStyle(fontSize: 28)),
                                    Container(
                                        margin: EdgeInsets.only(top: 1),
                                        child: Text(
                                            Share.session.data.student.mainClass.unit.luckyNumber?.toString() ?? '69',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: CupertinoColors.black.withAlpha(220)))),
                                  ]))
                            ]),
                            Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Row(children: [
                                  Flexible(
                                      child: Container(
                                          margin: EdgeInsets.only(right: 3),
                                          child: Text(
                                            glanceSubtitle.flexible,
                                            style: TextStyle(fontWeight: FontWeight.w400),
                                          ))),
                                  Text(
                                    glanceSubtitle.standard,
                                    style: TextStyle(fontWeight: FontWeight.w400),
                                  )
                                ])),
                          ],
                        )))
              ]
                  .appendIf(
                      CupertinoListTile(
                          onTap: () {
                            Share.tabsNavigatePage.broadcast(Value(2));
                            Future.delayed(Duration(milliseconds: 250)).then((arg) => Share.timetableNavigateDay.broadcast(
                                Value(DateTime.now().asDate().add(Duration(
                                    days: DateTime.now().isAfterOrSame(currentDay?.dayEnd) && (nextDay?.hasLessons ?? false)
                                        ? 1
                                        : 0)))));
                          },
                          title: Container(
                              margin: EdgeInsets.only(top: 10, bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Visibility(
                                      visible: currentLesson != null,
                                      child: Row(children: [
                                        Text(
                                          'Now:',
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Flexible(
                                            child: Container(
                                                margin: EdgeInsets.only(right: 3, left: 3),
                                                child: Text(
                                                  currentLesson?.subject?.name ?? 'Your mom',
                                                  style: TextStyle(fontWeight: FontWeight.w500),
                                                ))),
                                        Text(
                                          'in ${currentLesson?.classroom?.name ?? "the otherworld"}',
                                          style: TextStyle(fontWeight: FontWeight.w400),
                                        )
                                      ])),
                                  Visibility(
                                      visible: nextLesson != null,
                                      child: Opacity(
                                          opacity: 0.5,
                                          child: Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Row(children: [
                                                Text(
                                                  'Next:',
                                                  style: TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                                Flexible(
                                                    child: Container(
                                                        margin: EdgeInsets.only(right: 3, left: 3),
                                                        child: Text(
                                                          nextLesson?.subject?.name ?? 'Your mom',
                                                          style: TextStyle(fontWeight: FontWeight.w500),
                                                        ))),
                                                Text(
                                                  'in ${nextLesson?.classroom?.name ?? "the otherworld"}',
                                                  style: TextStyle(fontWeight: FontWeight.w400),
                                                )
                                              ]))))
                                ],
                              ))),
                      nextLesson != null || currentLesson != null)
                  .appendIf(
                      CupertinoListTile(
                          onTap: () {
                            Share.tabsNavigatePage.broadcast(Value(2));
                            Future.delayed(Duration(milliseconds: 250)).then((arg) => Share.timetableNavigateDay.broadcast(
                                Value(DateTime.now().asDate().add(Duration(
                                    days: DateTime.now().isAfterOrSame(currentDay?.dayEnd) && (nextDay?.hasLessons ?? false)
                                        ? 1
                                        : 0)))));
                          },
                          title: Container(
                              margin: EdgeInsets.only(top: 10, bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(
                                      'First:',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Flexible(
                                        child: Container(
                                            margin: EdgeInsets.only(right: 3, left: 3),
                                            child: Text(
                                              nextDay?.lessonsStripped
                                                      .firstWhereOrDefault((x) => x?.any((y) => !y.isCanceled) ?? false)
                                                      ?.firstWhereOrDefault((x) => !x.isCanceled)
                                                      ?.subject
                                                      ?.name ??
                                                  'Your mom',
                                              style: TextStyle(fontWeight: FontWeight.w500),
                                            ))),
                                    Text(
                                      'in ${nextDay?.lessonsStripped.firstWhereOrDefault((x) => x?.any((y) => !y.isCanceled) ?? false)?.firstWhereOrDefault((x) => !x.isCanceled)?.classroom?.name ?? "the otherworld"}',
                                      style: TextStyle(fontWeight: FontWeight.w400),
                                    )
                                  ])
                                ],
                              ))),
                      DateTime.now().isAfterOrSame(currentDay?.dayEnd) && (nextDay?.hasLessons ?? false))
                  .appendIf(
                      CupertinoListTile(
                          onTap: () {
                            Share.tabsNavigatePage.broadcast(Value(2));
                            Future.delayed(Duration(milliseconds: 250)).then((arg) => Share.timetableNavigateDay.broadcast(
                                Value(DateTime.now().asDate().add(Duration(
                                    days: DateTime.now().isAfterOrSame(currentDay?.dayEnd) && (nextDay?.hasLessons ?? false)
                                        ? 1
                                        : 0)))));
                          },
                          title: Row(children: [
                            Expanded(
                                child: Container(
                                    margin: EdgeInsets.only(right: 3),
                                    child: Text(
                                      DateTime.now().isAfterOrSame(currentDay?.dayEnd) && (nextDay?.hasLessons ?? false)
                                          ? 'Tomorrow: ${nextDay?.lessonsStripped.length} lessons'
                                          : 'Later: ${currentDay?.lessonsStripped.where((x) => x?.any((y) => DateTime.now().isBeforeOrSame(y.hourFrom)) ?? false).length} lessons',
                                      style: TextStyle(fontWeight: FontWeight.w400),
                                    ))),
                            Text(
                              DateTime.now().isAfterOrSame(currentDay?.dayEnd) && (nextDay?.hasLessons ?? false)
                                  ? 'until ${DateFormat("H:mm").format(nextDay?.dayEnd ?? DateTime.now())}'
                                  : 'until ${DateFormat("H:mm").format(currentDay?.dayEnd ?? DateTime.now())}',
                              style:
                                  TextStyle(fontWeight: FontWeight.w400, fontSize: 15, color: CupertinoColors.inactiveGray),
                            ),
                            Container(
                                margin: EdgeInsets.only(left: 2),
                                child: Transform.scale(
                                    scale: 0.7,
                                    child: Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.inactiveGray)))
                          ])),
                      (DateTime.now().isBeforeOrSame(currentDay?.dayEnd) && (currentDay?.hasLessons ?? false)) ||
                          (DateTime.now().isAfterOrSame(currentDay?.dayEnd) && (nextDay?.hasLessons ?? false)))),
          // Homeworks - first if any(), otherwise last
          Visibility(visible: !homeworksLast, child: homeworksWidget),
          // Upcoming events - in the middle, or top
          CupertinoListSection.insetGrouped(
            margin: EdgeInsets.only(left: 15, right: 15, bottom: 10),
            dividerMargin: 35,
            header: Text('Upcoming events'),
            children: eventsWeek.isEmpty
                // No events to display
                ? [
                    CupertinoListTile(
                        title: Opacity(
                            opacity: 0.5,
                            child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  'No events to display',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                                ))))
                  ]
                // Bindable event layout
                : eventsWeek
                    .select((x, index) => CupertinoListTile(
                        padding: EdgeInsets.all(0),
                        title: CupertinoContextMenu.builder(
                            actions: [
                              CupertinoContextMenuAction(
                                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                                trailingIcon: CupertinoIcons.share,
                                child: const Text('Share'),
                              ),
                              CupertinoContextMenuAction(
                                isDestructiveAction: true,
                                trailingIcon: CupertinoIcons.chat_bubble_2,
                                child: const Text('Inquiry'),
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  showCupertinoModalBottomSheet(
                                      context: context,
                                      builder: (context) => MessageComposePage(
                                          receivers: x.sender != null ? [x.sender!] : [],
                                          subject:
                                              'Pytanie o wydarzenie w dniu ${DateFormat("y.M.d").format(x.date ?? x.timeFrom)}',
                                          signature:
                                              '${Share.session.data.student.account.name}, ${Share.session.data.student.mainClass.name}'));
                                },
                              ),
                            ],
                            builder: (BuildContext context, Animation<double> animation) => CupertinoButton(
                                onPressed: () {
                                  Share.tabsNavigatePage.broadcast(Value(2));
                                  Future.delayed(Duration(milliseconds: 250))
                                      .then((arg) => Share.timetableNavigateDay.broadcast(Value(x.date ?? x.timeFrom)));
                                },
                                padding: EdgeInsets.zero,
                                child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                        color: CupertinoDynamicColor.resolve(
                                            CupertinoDynamicColor.withBrightness(
                                                color: const Color.fromARGB(255, 255, 255, 255),
                                                darkColor: const Color.fromARGB(255, 28, 28, 30)),
                                            context)),
                                    padding: EdgeInsets.only(right: 10, left: 6),
                                    child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxHeight: animation.value < CupertinoContextMenu.animationOpensAt
                                                ? double.infinity
                                                : 100,
                                            maxWidth: animation.value < CupertinoContextMenu.animationOpensAt
                                                ? double.infinity
                                                : 260),
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  TextChip(
                                                      text: DateFormat('d/M').format(x.date ?? x.timeFrom),
                                                      margin: EdgeInsets.only(top: 6, bottom: 6, right: 10)),
                                                  Flexible(
                                                      child: Text(
                                                    (x.title ?? x.content).capitalize(),
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        color: CupertinoDynamicColor.resolve(
                                                            CupertinoDynamicColor.withBrightness(
                                                                color: CupertinoColors.black,
                                                                darkColor: CupertinoColors.white),
                                                            context)),
                                                  ))
                                                ],
                                              ),
                                              Visibility(
                                                  visible: animation.value >= CupertinoContextMenu.animationOpensAt,
                                                  child: Container(
                                                      margin: EdgeInsets.only(left: 5, right: 5, bottom: 7),
                                                      child: Flexible(
                                                          child: Text(
                                                        x.locationTypeString,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w500,
                                                            color: CupertinoDynamicColor.resolve(
                                                                CupertinoDynamicColor.withBrightness(
                                                                    color: CupertinoColors.black,
                                                                    darkColor: CupertinoColors.white),
                                                                context)),
                                                      ))))
                                            ])))))))
                    .toList(),
          ),
          // Recent grades - always below events
          CupertinoListSection.insetGrouped(
            margin: EdgeInsets.only(left: 15, right: 15, bottom: 10),
            additionalDividerMargin: 5,
            header: Text('Recent grades'),
            children: gradesWeek.isEmpty
                // No grades to display
                ? [
                    CupertinoListTile(
                        title: Opacity(
                            opacity: 0.5,
                            child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  'No recent grades',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                                ))))
                  ]
                // Bindable grades layout
                : gradesWeek
                    .select((x, index) => CupertinoListTile(
                        padding: EdgeInsets.all(0),
                        title: CupertinoContextMenu.builder(
                            actions: [
                              CupertinoContextMenuAction(
                                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                                trailingIcon: CupertinoIcons.share,
                                child: const Text('Share'),
                              ),
                              CupertinoContextMenuAction(
                                isDestructiveAction: true,
                                trailingIcon: CupertinoIcons.chat_bubble_2,
                                child: const Text('Inquiry'),
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  showCupertinoModalBottomSheet(
                                      context: context,
                                      builder: (context) => MessageComposePage(
                                          receivers: [x.lesson.teacher],
                                          subject:
                                              'Pytanie o ${x.grades.length > 1 ? "oceny" : "ocenę"} ${x.grades.select((y, index) => y.value).join(', ')} z przedmiotu ${x.lesson.name}',
                                          signature:
                                              '${Share.session.data.student.account.name}, ${Share.session.data.student.mainClass.name}'));
                                },
                              ),
                            ],
                            builder: (BuildContext context, Animation<double> animation) => CupertinoButton(
                                onPressed: () {
                                  Share.tabsNavigatePage.broadcast(Value(1));
                                  Future.delayed(Duration(milliseconds: 250))
                                      .then((arg) => Share.gradesNavigate.broadcast(Value(x.lesson)));
                                },
                                padding: EdgeInsets.zero,
                                child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                        color: CupertinoDynamicColor.resolve(
                                            CupertinoDynamicColor.withBrightness(
                                                color: const Color.fromARGB(255, 255, 255, 255),
                                                darkColor: const Color.fromARGB(255, 28, 28, 30)),
                                            context)),
                                    padding: EdgeInsets.only(right: 10, left: 6),
                                    child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxHeight: animation.value < CupertinoContextMenu.animationOpensAt
                                                ? double.infinity
                                                : 100,
                                            maxWidth: animation.value < CupertinoContextMenu.animationOpensAt
                                                ? double.infinity
                                                : 260),
                                        child: Container(
                                            margin: EdgeInsets.only(right: 10, left: 7),
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                    flex: 2,
                                                    child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text(
                                                          x.lesson.name,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.w700,
                                                              color: CupertinoDynamicColor.resolve(
                                                                  CupertinoDynamicColor.withBrightness(
                                                                      color: CupertinoColors.black,
                                                                      darkColor: CupertinoColors.white),
                                                                  context)),
                                                        ))),
                                                Expanded(
                                                    child: Align(
                                                        alignment: Alignment.centerRight,
                                                        child: RichText(
                                                            overflow: TextOverflow.ellipsis,
                                                            text: TextSpan(
                                                                text: '',
                                                                children: x.grades
                                                                    .select((y, index) => TextSpan(
                                                                        text: y.value,
                                                                        style: TextStyle(
                                                                            fontSize: 25,
                                                                            fontWeight: FontWeight.w600,
                                                                            color: y.asColor())))
                                                                    .toList()
                                                                    .intersperse(TextSpan(
                                                                        text: ', ',
                                                                        style: TextStyle(
                                                                            fontSize: 25,
                                                                            fontWeight: FontWeight.w600,
                                                                            color: CupertinoDynamicColor.resolve(
                                                                                CupertinoDynamicColor.withBrightness(
                                                                                    color: CupertinoColors.black,
                                                                                    darkColor: CupertinoColors.white),
                                                                                context))))
                                                                    .toList()))))
                                              ],
                                            ))))))))
                    .toList(),
          ),
          // Homeworks - first if any(), otherwise last
          Visibility(visible: homeworksLast, child: homeworksWidget)
        ],
      ),
    );
  }

  // Glance widget's subtitle
  ({String flexible, String standard}) get glanceSubtitle {
    var currentDay = Share.session.data.timetables.timetable[DateTime.now().asDate()];
    var nextDay = Share.session.data.timetables.timetable[DateTime.now().asDate().add(Duration(days: 1))];

    var currentLesson = currentDay?.lessons
        .firstWhereOrDefault((x) =>
            x?.any((y) => DateTime.now().isAfterOrSame(y.hourFrom) && DateTime.now().isBeforeOrSame(y.hourTo)) ?? false)
        ?.firstOrDefault();
    var nextLesson = currentDay?.lessons
        .firstWhereOrDefault((x) => x?.any((y) => DateTime.now().isBeforeOrSame(y.hourFrom)) ?? false)
        ?.firstOrDefault();

    // Current lesson's end time
    if (currentLesson != null) {
      return (
        flexible: currentLesson.subject?.name ?? 'The current lesson',
        standard: 'ends in ${DateTime.now().difference(currentLesson.hourTo ?? DateTime.now()).inMinutes}'
      );
    }

    // Next lesson's start time
    if (nextLesson != null) {
      return (
        flexible: nextLesson.subject?.name ?? 'The next lesson',
        standard: DateTime.now().difference(nextLesson.hourFrom ?? DateTime.now()).inMinutes < 20
            ? 'starts in ${DateTime.now().difference(nextLesson.hourFrom ?? DateTime.now()).inMinutes}'
            : 'starts at ${DateFormat("HH:mm").format(nextLesson.hourFrom ?? DateTime.now())}'
      );
    }

    // Lessons have just ended - 7
    if ((currentDay?.hasLessons ?? false) &&
        DateTime.now().isAfterOrSame(currentDay?.dayEnd) &&
        DateTime.now().difference(currentDay?.dayEnd ?? DateTime.now()).inHours < 2) {
      return (flexible: "You've survived all ${currentDay!.lessonsStripped.length} lessons!", standard: '');
    }

    // No lessons today - T5
    if (!(currentDay?.hasLessons ?? false)) {
      return (flexible: "It's a free real estate!", standard: '');
    }

    // But lessons tomorrow - T6
    if ((nextDay?.hasLessons ?? false) && nextDay?.dayEnd != null) {
      return (
        flexible:
            '${nextDay!.lessonsStripped.length} lessons, ${DateFormat("H:mm").format(nextDay.dayStart!)} to ${DateFormat("H:mm").format(nextDay.dayEnd!)}',
        standard: ''
      );
    }

    // Other options, possibly?
    return (flexible: '', standard: '');
  }

  // Glance widget's main title
  String get glanceTitle {
    var currentDay = Share.session.data.timetables.timetable[DateTime.now().asDate()];
    var nextDay = Share.session.data.timetables.timetable[DateTime.now().asDate().add(Duration(days: 1))];

    var currentLesson = currentDay?.lessons
        .firstWhereOrDefault((x) =>
            x?.any((y) => DateTime.now().isAfterOrSame(y.hourFrom) && DateTime.now().isBeforeOrSame(y.hourTo)) ?? false)
        ?.firstOrDefault();
    var nextLesson = currentDay?.lessons
        .firstWhereOrDefault((x) => x?.any((y) => DateTime.now().isBeforeOrSame(y.hourFrom)) ?? false)
        ?.firstOrDefault();

    // Absent - current lesson - TOP
    if (currentLesson != null &&
        (Share.session.data.student.attendances
                ?.any((x) => x.date == DateTime.now().asDate() && x.lessonNo == currentLesson.lessonNo) ??
            false)) {
      return "${Share.session.data.student.account.firstName}, you're absent!";
    }

    // Lessons have just ended - 7.1
    if ((currentDay?.hasLessons ?? false) &&
        DateTime.now().isAfterOrSame(currentDay?.dayEnd) &&
        DateTime.now().difference(currentDay?.dayEnd ?? DateTime.now()).inHours < 2) {
      return 'Way to go!';
    }

    // Lessons have ended - 7.2
    if ((currentDay?.hasLessons ?? false) &&
        DateTime.now().isAfterOrSame(currentDay?.dayEnd) &&
        DateTime.now().difference(currentDay?.dayEnd ?? DateTime.now()).inHours >= 2) {
      return 'Prepare for tomorrow...';
    }

    // Lessons tomorrow - 6
    if (DateTime.now().isAfterOrSame(currentDay?.dayEnd) && (nextDay?.hasLessons ?? false)) {
      return "Tomorrow's the day!";
    }

    // No lessons today - 5
    if (!(currentDay?.hasLessons ?? false)) {
      return 'No lessons today!';
    }

    // Good morning - 3
    if (currentDay?.dayStart != null &&
        DateTime.now().isBeforeOrSame(currentDay!.dayStart) &&
        DateTime.now().difference(currentDay.dayStart!) > Duration(hours: 1)) {
      return "Don't forget the obentō!";
    }

    // The last lesson - 2
    if (currentLesson != null && (currentDay?.lessonsStripped.lastOrDefault()?.any((x) => x == currentLesson) ?? false)) {
      return "You're on the finish line!";
    }

    // Ambient - during the day - 1
    if (currentDay?.dayStart != null &&
            DateTime.now().isBeforeOrSame(currentDay!.dayStart) &&
            DateTime.now().difference(currentDay.dayStart!) <= Duration(hours: 1) ||
        (currentLesson != null && nextLesson != null)) {
      return "Keep yourself safe...";
    }

    // Lucy number - today - 0
    if (DateTime.now().isBeforeOrSame(currentDay?.dayStart) &&
        Share.session.data.student.account.number == Share.session.data.student.mainClass.unit.luckyNumber &&
        !Share.session.data.student.mainClass.unit.luckyNumberTomorrow) {
      return "You're the lucky one!";
    }

    // Lucy number - tomorrow - 0
    if (DateTime.now().isAfterOrSame(currentDay?.dayEnd) &&
        Share.session.data.student.account.number == Share.session.data.student.mainClass.unit.luckyNumber &&
        Share.session.data.student.mainClass.unit.luckyNumberTomorrow) {
      return "You'll be lucky tomorrow!";
    }

    // Other options, possibly?
    return '';
  }
}

extension DateTimeExtension on DateTime {
  DateTime asDate({bool utc = false}) => utc ? DateTime.utc(year, month, day) : DateTime(year, month, day);
}

extension ColorsExtension on Grade {
  Color asColor() => switch (asValue.round()) {
        6 => CupertinoColors.systemTeal,
        5 => CupertinoColors.systemGreen,
        4 => Color(0xFF76FF03),
        3 => CupertinoColors.systemOrange,
        2 => CupertinoColors.systemRed,
        1 => CupertinoColors.destructiveRed,
        _ => CupertinoColors.inactiveGray
      };
}

extension ListExtension on List<TextSpan> {
  Iterable<TextSpan> intersperse(TextSpan element) sync* {
    for (int i = 0; i < length; i++) {
      yield this[i];
      if (length != i + 1) yield element;
    }
  }
}

extension ListAppendExtension on Iterable<Widget> {
  List<Widget> appendIf(Widget element, bool condition) {
    if (!condition) return toList();
    return append(element).toList();
  }
}
