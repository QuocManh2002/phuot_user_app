import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:phuot_app/core/constants/colors.dart';
import 'package:phuot_app/core/constants/urls.dart';
import 'package:phuot_app/service/plan_service.dart';
import 'package:phuot_app/view_models/plan_viewmodels/plan_schedule.dart';
import 'package:phuot_app/widgets/plan_screen_widget/plan_schedule_activity_view.dart';
import 'package:phuot_app/widgets/plan_screen_widget/plan_schedule_title.dart';
import 'package:sizer2/sizer2.dart';

class PLanScheduleWidget extends StatefulWidget {
  const PLanScheduleWidget(
      {super.key,
      required this.schedule,
      required this.planId,
      required this.endDate,
      required this.planType,
      required this.isLeader,
      required this.orders,
      required this.startDate});
  final int planId;
  final List<dynamic> schedule;
  final DateTime startDate;
  final DateTime endDate;
  final String planType;
  final bool isLeader;
  final List? orders;

  @override
  State<PLanScheduleWidget> createState() => _PLanScheduleWidgetState();
}

class _PLanScheduleWidgetState extends State<PLanScheduleWidget> {
  double _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);
  List<PlanSchedule> _scheduleList = [];
  final PlanService _planService = PlanService();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
    setUpData();
  }

  setUpData() async {
    setState(() {
      _scheduleList = _planService.getPlanScheduleFromJsonNew(
          widget.schedule,
          widget.startDate,
          widget.endDate.difference(widget.startDate).inDays + 1);
    });

    PlanSchedule? todaySchedule = _scheduleList.firstWhereOrNull((element) =>
        element.date!.isBefore(DateTime.now()) &&
        element.date!.difference(DateTime.now()).inDays == 0);
    if (todaySchedule != null) {
      setState(() {
        _currentPage =
            DateTime.now().difference(_scheduleList.first.date!).inDays + 1;
      });
    }
  }

  Widget getPageView(int index) {
    return SizedBox(
      width: 100.w,
      child: _scheduleList[index].items.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  emptyPlan,
                  width: 60.w,
                ),
                const SizedBox(
                  height: 12,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'Bạn không có lịch trình nào trong ngày này',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            )
          : SingleChildScrollView(
              child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: _scheduleList[index].items.length,
              itemBuilder: (context, itemIndex) => PlanScheduleActivityView(
                order: widget.orders!.firstWhereOrNull((e) =>
                    e.uuid == _scheduleList[index].items[itemIndex].orderUUID),
                item: _scheduleList[index].items[itemIndex],
                isLeader: widget.isLeader,
                planType: widget.planType,
              ),
            )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  showDatePicker(
                      context: context,
                      initialDate: _scheduleList.first.date,
                      firstDate: _scheduleList.first.date!,
                      lastDate: _scheduleList.last.date!,
                      locale: const Locale('vi', 'VN'),
                      builder: (context, child) {
                        return Theme(
                            data: ThemeData().copyWith(
                                colorScheme: const ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: Colors.white)),
                            child: child!);
                      }).then((value) {
                    if (value != null) {
                      _scheduleList.map((e) {
                      });
                      setState(() {
                        _currentPage = _scheduleList
                            .indexOf(_scheduleList.firstWhere((element) =>
                                DateTime(value.year, value.month, value.day)
                                    .difference(DateTime(element.date!.year,
                                        element.date!.month, element.date!.day))
                                    .inDays ==
                                0))
                            .toDouble();
                        _pageController.animateToPage(_currentPage.toInt(),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.linear);
                      });
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    height: 40,
                    width: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 3,
                            color: Colors.black12,
                            offset: Offset(2, 4),
                          )
                        ],
                        shape: BoxShape.circle),
                    child: Image.asset(calendarSearch, fit: BoxFit.contain),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(
            height: 14.h,
            child: ListView.builder(
              itemCount: _scheduleList.length,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: false,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.all(1.w),
                child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    onTap: () {
                      setState(() {
                        _currentPage = index.toDouble();
                        _pageController.animateToPage(index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.bounceIn);
                      });
                    },
                    child: PlanScheduleTitle(
                      index: index,
                      date: _scheduleList[index].date!,
                      isSelected: _currentPage == index.toDouble(),
                    )),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                for (int index = 0; index < _scheduleList.length; index++)
                  getPageView(index)
              ],
            ),
          )
        ],
      ),
    );
  }
}
