import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:greenwheel_user_app/constants/colors.dart';
import 'package:greenwheel_user_app/constants/urls.dart';
import 'package:greenwheel_user_app/main.dart';
import 'package:greenwheel_user_app/screens/payment_screen/success_payment_screen.dart';
import 'package:greenwheel_user_app/screens/plan_screen/input_companion_name_screen.dart';
import 'package:greenwheel_user_app/service/plan_service.dart';
import 'package:greenwheel_user_app/view_models/plan_viewmodels/plan_detail.dart';
import 'package:greenwheel_user_app/widgets/style_widget/button_style.dart';
import 'package:intl/intl.dart';
import 'package:sizer2/sizer2.dart';

class JoinConfirmPlanScreen extends StatefulWidget {
  const JoinConfirmPlanScreen(
      {super.key,
      required this.plan,
      required this.isPublic,
      this.callback,
      this.onPublicizePlan,
      required this.isConfirm});
  final PlanDetail plan;
  final bool isPublic;
  final bool isConfirm;
  final void Function(bool isFromJoinScreen, int? amount)? onPublicizePlan;
  final void Function()? callback;

  @override
  State<JoinConfirmPlanScreen> createState() => _JoinPlanScreenState();
}

class _JoinPlanScreenState extends State<JoinConfirmPlanScreen> {
  PlanService _planService = PlanService();
  int weight = 1;
  double? newBalance;
  List<String> companionNames = [];
  bool isEnableToAdd = false;
  bool isEnableToSubtract = false;

  onChangeWeight(bool isAdd) {
    if (isAdd &&
        weight < widget.plan.maxMemberWeight! &&
        weight < widget.plan.maxMember - widget.plan.memberCount!) {
      setState(() {
        weight += 1;
      });
      if (!isEnableToSubtract) {
        setState(() {
          isEnableToSubtract = true;
        });
      }
      if (weight == widget.plan.maxMemberWeight ||
          weight == widget.plan.maxMember - widget.plan.memberCount!) {
        setState(() {
          isEnableToAdd = false;
        });
      }
    } else if (!isAdd && weight > 1) {
      setState(() {
        weight -= 1;
      });
      if (weight == 1) {
        setState(() {
          isEnableToSubtract = false;
        });
      }
      if (!isEnableToAdd) {
        setState(() {
          isEnableToAdd = true;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.isConfirm) {
      weight = widget.plan.maxMember - widget.plan.memberCount!;
    }
    isEnableToAdd = !(weight == widget.plan.maxMemberWeight! ||
        weight == widget.plan.maxMember - widget.plan.memberCount!);
    isEnableToSubtract = weight > 1;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Xác nhận tham gia'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 12),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 2.h,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: primaryColor.withOpacity(0.7), width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(12))),
                child: Row(
                  children: [
                    const Text(
                      'Số dư của bạn',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      NumberFormat.simpleCurrency(
                              locale: 'vi-VN', decimalDigits: 0, name: "")
                          .format(sharedPreferences.getDouble('userBalance')),
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    SvgPicture.asset(
                      gcoin_logo,
                      height: 28,
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 1.5.h,
              ),
              Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Thông tin chuyến đi',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54),
                  )),
              SizedBox(
                height: 0.7.h,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: primaryColor.withOpacity(0.7), width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(12))),
                child: Column(children: [
                  SizedBox(
                    height: 1.h,
                  ),
                  Row(
                    children: [
                      const Text(
                        'Chuyến đi',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 60.w,
                        child: Text(
                          widget.plan.name!,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                      )
                    ],
                  ),
                  buildDivider(),
                  Row(
                    children: [
                      const Text(
                        'Địa điểm',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 60.w,
                        child: Text(
                          widget.plan.locationName,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                      )
                    ],
                  ),
                  buildDivider(),
                  Row(
                    children: [
                      const Text(
                        'Thời gian',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 60.w,
                        child: Text(
                          '${DateFormat('dd/MM/yyyy').format(widget.plan.departureDate!)} - ${DateFormat('dd/MM/yyyy').format(widget.plan.endDate!)}',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                      )
                    ],
                  ),
                  buildDivider(),
                  Row(
                    children: [
                      const Text(
                        'Số người tối đa',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 30.w,
                        child: Text(
                          widget.plan.maxMember < 10
                              ? '0${widget.plan.maxMember}'
                              : widget.plan.maxMember.toString(),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 1.h,
                  )
                ]),
              ),
              SizedBox(
                height: 1.5.h,
              ),
              Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Chi tiết thanh toán',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54),
                  )),
              SizedBox(
                height: 0.7.h,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: primaryColor.withOpacity(0.7), width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(12))),
                child: Column(
                  children: [
                    SizedBox(
                      height: 1.h,
                    ),
                    Row(
                      children: [
                        const Text(
                          'Chi phí tham gia',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 40.w,
                          child: Text(
                            NumberFormat.simpleCurrency(
                                    locale: 'vi-VN', decimalDigits: 0, name: "")
                                .format(widget.plan.gcoinBudgetPerCapita),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black),
                          ),
                        ),
                        SizedBox(
                          width: 1.h,
                        ),
                        SvgPicture.asset(
                          gcoin_logo,
                          height: 30,
                        )
                      ],
                    ),
                    buildDivider(),
                    Row(
                      children: [
                        const Text(
                          'Người đại diện',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 40.w,
                          child: Text(
                            sharedPreferences.getString('userName')!,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    buildDivider(),
                    Row(
                      children: [
                        const Text(
                          'Số người của nhóm bạn',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const Spacer(),
                        if (!widget.isConfirm)
                          InkWell(
                            overlayColor: const MaterialStatePropertyAll(
                                Colors.transparent),
                            onTap: () {
                              onChangeWeight(false);
                            },
                            child: Icon(
                              Icons.remove,
                              color: isEnableToSubtract
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        SizedBox(
                          width: 0.5.h,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              border: widget.isConfirm
                                  ? const Border()
                                  : Border.all(color: Colors.grey, width: 1.5),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8))),
                          alignment: Alignment.center,
                          width: 6.h,
                          child: Text(
                            weight.toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 0.5.h,
                        ),
                        if (!widget.isConfirm)
                          InkWell(
                            overlayColor: const MaterialStatePropertyAll(
                                Colors.transparent),
                            onTap: () {
                              onChangeWeight(true);
                            },
                            child: Icon(
                              Icons.add,
                              color: isEnableToAdd ? Colors.black : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    buildDivider(),
                    Row(
                      children: [
                        const Text(
                          'Tạm tính',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          NumberFormat.simpleCurrency(
                                  locale: 'vi-VN', decimalDigits: 0, name: "")
                              .format(
                                  weight * widget.plan.gcoinBudgetPerCapita!),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                        SizedBox(
                          width: 1.h,
                        ),
                        SvgPicture.asset(
                          gcoin_logo,
                          height: 30,
                        )
                      ],
                    ),
                    SizedBox(
                      height: 1.h,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 2.h,
              ),
              if (weight > 1 && !widget.isConfirm)
                Container(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: elevatedButtonStyle.copyWith(
                      padding: const MaterialStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                      minimumSize: MaterialStatePropertyAll(Size(40.w, 5.h)),
                      maximumSize: MaterialStatePropertyAll(Size(40.w, 5.h)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => InputCompanionNameScreen(
                                initNames: companionNames,
                                weight: weight - 1,
                                callback: callback,
                              )));
                    },
                    child: const Text(
                      'Nhập thông tin',
                    ),
                  ),
                ),
              const Spacer(),
              Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const Spacer(),
                      Text(
                        NumberFormat.simpleCurrency(
                                locale: 'vi-VN', decimalDigits: 0, name: "")
                            .format(weight * widget.plan.gcoinBudgetPerCapita!),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      SizedBox(
                        width: 1.h,
                      ),
                      SvgPicture.asset(
                        gcoin_logo,
                        height: 30,
                      )
                    ],
                  ),
                  // SizedBox(
                  //   height: 1.h,
                  // ),
                  // Row(
                  //   children: [
                  //     const Text(
                  //       'Số dư mới',
                  //       style: TextStyle(fontSize: 16, color: Colors.grey),
                  //     ),
                  //     const Spacer(),
                  //     Text(
                  //       NumberFormat.simpleCurrency(
                  //               locale: 'vi-VN', decimalDigits: 0, name: "")
                  //           .format(sharedPreferences
                  //                   .getDouble('userBalance')! -
                  //               (weight * widget.plan.gcoinBudgetPerCapita!)),
                  //       textAlign: TextAlign.end,
                  //       overflow: TextOverflow.clip,
                  //       style: const TextStyle(
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.w500,
                  //           color: Colors.black),
                  //     ),
                  //     SizedBox(
                  //       width: 1.h,
                  //     ),
                  //     SvgPicture.asset(
                  //       gcoin_logo,
                  //       height: 30,
                  //     )
                  //   ],
                  // ),
                  SizedBox(
                    height: 1.h,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!widget.isConfirm) {
                        handleJoin();
                      } else {
                        handleConfirm();
                      }
                    },
                    style: elevatedButtonStyle.copyWith(
                        minimumSize: MaterialStatePropertyAll(Size(100.w, 50))),
                    child: const Text(
                      'Thanh toán',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 1.h,
                  )
                ],
              )
            ]),
      ),
    ));
  }

  buildDivider() => Column(
        children: [
          SizedBox(
            height: 0.7.h,
          ),
          Container(
            color: Colors.grey.withOpacity(0.5),
            height: 1.2,
          ),
          SizedBox(
            height: 0.7.h,
          ),
        ],
      );

  handleJoin() {
    if (companionNames.length < weight - 1) {
      AwesomeDialog(
        context: context,
        animType: AnimType.leftSlide,
        dialogType: DialogType.warning,
        title: 'Chưa đầy đủ tên thành viên của nhóm',
        titleTextStyle:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        btnOkColor: Colors.amber,
        btnOkText: 'Ok',
        btnOkOnPress: () {},
      ).show();
    } else if (companionNames.length > weight - 1) {
      AwesomeDialog(
        context: context,
        animType: AnimType.leftSlide,
        dialogType: DialogType.warning,
        title: 'Số lượng thành viên đã thay đổi',
        titleTextStyle: const TextStyle(
            fontFamily: 'NotoSans', fontSize: 18, fontWeight: FontWeight.bold),
        desc: 'Cập nhật lại thông tin thành viên để thanh toán',
        descTextStyle: const TextStyle(
            fontSize: 16, color: Colors.grey, fontFamily: 'NotoSans'),
        btnOkColor: Colors.amber,
        btnOkOnPress: () {},
        btnOkText: 'Ok',
      ).show();
    } else {
      AwesomeDialog(
              context: context,
              animType: AnimType.leftSlide,
              dialogType: DialogType.question,
              title:
                  'Thanh toán ${NumberFormat.simpleCurrency(locale: 'vi-VN', decimalDigits: 0, name: "").format(widget.plan.gcoinBudgetPerCapita)}${weight != 1 ? 'x $weight = ${NumberFormat.simpleCurrency(locale: 'vi-VN', decimalDigits: 0, name: "").format(widget.plan.gcoinBudgetPerCapita! * weight)}' : ''}GCOIN',
              titleTextStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              btnOkColor: Colors.blue,
              btnOkText: 'Chơi',
              btnOkOnPress: () async {
                final rs = await _planService.joinPlan(
                    widget.plan.id, weight, companionNames);
                if (rs != null) {
                  if (widget.isPublic) {
                    widget.onPublicizePlan!(true, widget.plan.gcoinBudgetPerCapita! * weight);
                  } else {
                    handleJoinSuccess();
                  }

                  // AwesomeDialog(
                  //   // ignore: use_build_context_synchronously
                  //   context: context,
                  //   dialogType: DialogType.success,
                  //   animType: AnimType.topSlide,
                  //   showCloseIcon: true,
                  //   title: "Tham gia kế hoạch thành công",
                  //   desc: "Ấn tiếp tục để trở về",
                  //   btnOkText: "Tiếp tục",
                  //   btnOkOnPress: () async {
                  //     if (widget.isPublic) {
                  //       widget.onPublicizePlan!(true);
                  //     } else {
                  //       handleJoinSuccess();
                  //     }
                  //     final rs = sharedPreferences.getDouble('userBalance')! -
                  //         (widget.plan.gcoinBudgetPerCapita! * weight);
                  //     sharedPreferences.setDouble('userBalance', rs);
                  //   },
                  // ).show();
                }
              },
              btnCancelColor: Colors.deepOrangeAccent,
              btnCancelOnPress: () {},
              btnCancelText: 'Huỷ')
          .show();
    }
  }

  handleConfirm() {
    AwesomeDialog(
            context: context,
            animType: AnimType.leftSlide,
            dialogType: DialogType.question,
            title:
                'Thanh toán ${NumberFormat.simpleCurrency(locale: 'vi-VN', decimalDigits: 0, name: "").format(widget.plan.gcoinBudgetPerCapita)}${widget.plan.maxMember - widget.plan.memberCount! > 1 ? ' x ${widget.plan.maxMember - widget.plan.memberCount!} = ${NumberFormat.simpleCurrency(locale: 'vi-VN', decimalDigits: 0, name: "").format(widget.plan.gcoinBudgetPerCapita! * (widget.plan.maxMember - widget.plan.memberCount!))}' : ''} GCOIN',
            titleTextStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            btnOkColor: Colors.blue,
            btnOkText: 'Chơi',
            btnOkOnPress: () async {
              final rs = await _planService.confirmMember(widget.plan.id);
              if (rs != 0) {
                AwesomeDialog(
                   // ignore: use_build_context_synchronously
                  context: context,
                  dialogType: DialogType.success,
                  animType: AnimType.topSlide,
                  showCloseIcon: true,
                  title: "Đã chốt số lượng thành viên",
                  desc: "Ấn tiếp tục để trở về",
                  btnOkText: "Tiếp tục",
                  btnOkOnPress: () {
                    final rs = sharedPreferences.getDouble('userBalance')! -
                        (widget.plan.gcoinBudgetPerCapita! *
                            (widget.plan.maxMember - widget.plan.memberCount!));
                    sharedPreferences.setDouble('userBalance', rs);
                    widget.callback!();
                    Navigator.of(context).pop();
                  },
                ).show();
              }
            },
            btnCancelColor: Colors.deepOrangeAccent,
            btnCancelOnPress: () {},
            btnCancelText: 'Huỷ')
        .show();
  }

  callback(List<String> names) {
    companionNames = names;
  }

  handleJoinSuccess() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (ctx) => SuccessPaymentScreen(
                  amount: widget.plan.gcoinBudgetPerCapita! * weight,
                )),
        (route) => false);
  }
}
