import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:greenwheel_user_app/core/constants/colors.dart';
import 'package:greenwheel_user_app/core/constants/urls.dart';
import 'package:greenwheel_user_app/screens/plan_screen/list_order_screen.dart';
import 'package:greenwheel_user_app/service/location_service.dart';
import 'package:greenwheel_user_app/view_models/order.dart';
import 'package:greenwheel_user_app/view_models/plan_viewmodels/plan_detail.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/plan_order_card.dart';
import 'package:intl/intl.dart';
import 'package:sizer2/sizer2.dart';

class DetailPlanServiceWidget extends StatefulWidget {
  const DetailPlanServiceWidget(
      {super.key,
      required this.plan,
      required this.isLeader,
      required this.tempOrders,
      required this.total,
      this.orderList,
      required this.onGetOrderList});
  final PlanDetail plan;
  final bool isLeader;
  final void Function() onGetOrderList;
  final List<OrderViewModel>? orderList;
  final List<OrderViewModel> tempOrders;
  final double total;

  @override
  State<DetailPlanServiceWidget> createState() =>
      _DetailPlanServiceWidgetState();
}

class _DetailPlanServiceWidgetState extends State<DetailPlanServiceWidget>
    with TickerProviderStateMixin {
  late TabController tabController;
  LocationService _locationService = LocationService();
  List<OrderViewModel> roomOrderList = [];
  List<OrderViewModel> foodOrderList = [];
  List<OrderViewModel> movingOrderList = [];
  bool isShowTotal = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setUpData();
  }

  setUpData() {
    tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final orderGroups =
        widget.orderList!.groupListsBy((element) => element.type);
    roomOrderList = orderGroups['LODGING'] ?? [];
    foodOrderList = orderGroups['MEAL'] ?? [];
    movingOrderList = orderGroups['MOVING'] ?? [];
    isShowTotal =
        widget.plan.status != 'PENDING' && widget.plan.status != 'REGISTERING';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Các đơn dịch vụ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )),
              const Spacer(),
              if (widget.isLeader)
                TextButton(
                    onPressed: () async {
                      if (widget.plan.status == 'READY') {
                        final rs = await _locationService.GetLocationById(
                            widget.plan.locationId!);
                        if (rs != null) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (ctx) => ListOrderScreen(
                                    availableGcoinAmount:
                                        widget.plan.actualGcoinBudget,
                                    planId: widget.plan.id!,
                                    orders: widget.tempOrders,
                                    startDate: widget.plan.startDate!,
                                    callback: widget.onGetOrderList,
                                    endDate: widget.plan.endDate!,
                                    memberLimit: widget.plan.memberCount!,
                                    location: rs,
                                  )));
                        }
                      }
                    },
                    child: Text(
                      'Đi đặt hàng',
                      style: TextStyle(
                        color: widget.plan.status == 'READY'
                            ? primaryColor
                            : Colors.grey,
                      ),
                    ))
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          TabBar(
              controller: tabController,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(
                  icon: const Icon(Icons.hotel),
                  text: '(${roomOrderList.length})',
                ),
                Tab(
                  icon: const Icon(Icons.restaurant),
                  text: '(${foodOrderList.length})',
                ),
                Tab(
                  icon: const Icon(Icons.directions_car),
                  text: '(${movingOrderList.length})',
                )
              ]),
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: roomOrderList.isEmpty &&
                    foodOrderList.isEmpty &&
                    widget.plan.surcharges!.isEmpty
                ? 0.h
                : 35.h,
            child: TabBarView(controller: tabController, children: [
              ListView.builder(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                itemCount: roomOrderList.length,
                itemBuilder: (context, index) {
                  return PlanOrderCard(
                      isShowQuantity: true,
                      order: roomOrderList[index],
                      isLeader: widget.isLeader);
                },
              ),
              ListView.builder(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                itemCount: foodOrderList.length,
                itemBuilder: (context, index) {
                  return PlanOrderCard(
                      isShowQuantity: true,
                      order: foodOrderList[index],
                      isLeader: widget.isLeader);
                },
              ),
              ListView.builder(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                itemCount: movingOrderList.length,
                itemBuilder: (context, index) {
                  return PlanOrderCard(
                      isShowQuantity: true,
                      order: movingOrderList[index],
                      isLeader: widget.isLeader);
                },
              )
            ]),
          ),
          const SizedBox(
            height: 8,
          ),
          if (widget.isLeader)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    color: Colors.grey.withOpacity(0.2)),
                child: Column(
                  children: [
                    buildAmountInfo(
                        'Ngân sách dự tính:',
                        widget.plan.gcoinBudgetPerCapita! *
                            widget.plan.maxMemberCount!),
                    buildAmountInfo(
                        'Ngân sách đã thu:',
                        widget.plan.gcoinBudgetPerCapita! *
                            widget.plan.memberCount!),
                    if (isShowTotal)
                    buildAmountInfo(
                        'Ngân sách hiện tại:', widget.plan.actualGcoinBudget!),
                    if (isShowTotal)
                      buildAmountInfo(
                          'Đã chi:',
                          widget.plan.status == 'PENDING' ||
                                  widget.plan.status == 'REGISTERING'
                              ? 0
                              : widget.total / 100),
                    // buildAmountInfo('Bình quân ban đầu:',
                    //     widget.plan.gcoinBudgetPerCapita!),
                    // if (isShowTotal)
                    //   buildAmountInfo(
                    //       'Bình quân đã chi:',
                    //       widget.plan.status == 'PENDING' ||
                    //               widget.plan.status == 'REGISTERING'
                    //           ? 0
                    //           : ((widget.total / widget.plan.memberCount!) /
                    //                   100)
                    //               .ceil()),
                    if (isShowTotal)
                      buildAmountInfo(
                          'Số tiền cần phải bù:',
                          widget.plan.maxMemberCount! * widget.plan.gcoinBudgetPerCapita! - 
                          widget.plan.memberCount! * widget.plan.gcoinBudgetPerCapita!
                          ),
                    
                    // buildAmountInfo('Số tiền hoàn lại:', widget.plan.displayGcoinBudget! / widget.plan.memberCount! * 
                    // + widget.plan.actualGcoinBudget! - widget.plan.displayGcoinBudget!
                    // )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  buildAmountInfo(String title, num amount) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              NumberFormat.simpleCurrency(
                      locale: 'vi-VN', decimalDigits: 0, name: "")
                  .format(amount),
              style: const TextStyle(fontSize: 18),
            ),
            SvgPicture.asset(
              gcoin_logo,
              height: 20,
            ),
          ],
        ),
      );
}
