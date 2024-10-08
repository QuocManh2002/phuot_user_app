import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:sizer2/sizer2.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/combo_date_plan.dart';
import '../../core/constants/plan_statuses.dart';
import '../../core/constants/urls.dart';
import '../../helpers/util.dart';
import '../../models/plan_status.dart';
import '../../view_models/plan_viewmodels/plan_detail.dart';

class DetailPlanHeader extends StatefulWidget {
  const DetailPlanHeader(
      {super.key, required this.plan, required this.isAlreadyJoin});
  final PlanDetail plan;
  final bool isAlreadyJoin;

  @override
  State<DetailPlanHeader> createState() => _DetailPlanHeaderState();
}

class _DetailPlanHeaderState extends State<DetailPlanHeader> {
  late Timer timer;
  Duration duration = const Duration();
  String comboDateText = '';
  PlanStatus? status;
  String? statusText;

  @override
  void initState() {
    super.initState();
    setUpData();
  }

  setUpData() async {
    if (widget.plan.utcRegCloseAt != null) {
      calculateTimeLeft(widget.plan.utcRegCloseAt!.toLocal());
      timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        calculateTimeLeft(widget.plan.utcRegCloseAt!.toLocal());
      });
    }
    if (widget.plan.status != null) {
      status = planStatuses
          .firstWhere((element) => element.engName == widget.plan.status);
    }

    if (status == planStatuses[4]) {
      final systemTime = await Utils().getSystemTime(context);
      setState(() {
        statusText =
            '${widget.plan.locationName} - Ngày ${systemTime.difference(widget.plan.utcStartAt!.toLocal()).inDays + 1}';
      });
    } else {
      statusText = status != null ? status!.name : '';
    }
    var tempDuration = DateFormat.Hm().parse(widget.plan.travelDuration!);
    final startTime = DateTime(0, 0, 0, widget.plan.utcDepartAt!.hour,
        widget.plan.utcDepartAt!.minute, 0);
    final arrivedTime = startTime
        .add(Duration(hours: tempDuration.hour))
        .add(Duration(minutes: tempDuration.minute));
    final rs = Utils().getNumOfExpPeriod(
        arrivedTime, widget.plan.numOfExpPeriod!, startTime, null, true);
    var comboDate = listComboDate.firstWhere(
        (element) => element.duration == widget.plan.numOfExpPeriod!);
    comboDateText =
        '${comboDate.numberOfDay} ngày ${rs['numOfExpPeriod'] != widget.plan.numOfExpPeriod ? comboDate.numberOfNight + 1 : comboDate.numberOfNight} đêm';
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.plan.locationName!,
            overflow: TextOverflow.clip,
            style: const TextStyle(
                fontSize: 20,
                fontFamily: 'NotoSans',
                fontWeight: FontWeight.bold),
          ),
          Text(
            comboDateText,
            overflow: TextOverflow.clip,
            style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          if (widget.plan.gcoinBudgetPerCapita != 0)
            SizedBox(
              height: 0.2.h,
            ),
          if (widget.plan.gcoinBudgetPerCapita != 0)
            Row(
              children: [
                Text(
                  NumberFormat.simpleCurrency(
                          locale: 'vi_VN', decimalDigits: 0, name: '')
                      .format(widget.plan.gcoinBudgetPerCapita),
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.bold),
                ),
                SvgPicture.asset(
                  gcoinLogo,
                  height: 25,
                ),
                const Text(
                  ' /',
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.bold),
                ),
                const Icon(
                  Icons.person,
                  color: primaryColor,
                  size: 25,
                ),
              ],
            ),
          SizedBox(
            height: 0.5.h,
          ),
          if (statusText != null &&
              statusText!.isNotEmpty &&
              (widget.plan.isPublished == null || !widget.plan.isPublished!))
            Container(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
              decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Text(
                statusText!,
                style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'NotoSans',
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          if (widget.plan.isPublished == null || !widget.plan.isPublished!)
            SizedBox(
              height: 0.5.h,
            ),
          if (widget.plan.utcRegCloseAt != null &&
              widget.plan.status == planStatuses[1].engName)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 0.2.h,
                ),
                Container(
                  width: 70.w,
                  color: Colors.black26,
                  height: 1,
                ),
                SizedBox(
                  height: 0.2.h,
                ),
                const Text(
                  'Thời gian đăng ký còn: ',
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'NotoSans',
                  ),
                ),
                Row(
                  children: [
                    buildCountDownWidget(
                        duration.inDays.toString().padLeft(2, '0'), 'Ngày'),
                    SizedBox(
                      width: 4.w,
                    ),
                    buildCountDownWidget(
                        duration.inHours
                            .remainder(24)
                            .toString()
                            .padLeft(2, '0'),
                        'Giờ'),
                    SizedBox(
                      width: 4.w,
                    ),
                    buildCountDownWidget(
                        duration.inMinutes
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0'),
                        'Phút')
                  ],
                )
              ],
            ),
        ],
      ),
    );
  }

  void calculateTimeLeft(DateTime deadLine) async {
    final systemTime = await Utils().getSystemTime(context);
    final minutes = deadLine.difference(systemTime).inMinutes;
    setState(() => duration = Duration(minutes: minutes));
  }

  buildCountDownWidget(String value, String title) => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                fontFamily: 'NotoSans',
                color: primaryColor.withOpacity(0.8)),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontFamily: 'NotoSans'),
          )
        ],
      );
}
