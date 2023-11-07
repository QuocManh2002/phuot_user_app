import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:greenwheel_user_app/constants/colors.dart';
import 'package:greenwheel_user_app/constants/service_types.dart';
import 'package:greenwheel_user_app/constants/supplier_orders.dart';
import 'package:greenwheel_user_app/models/location.dart';
import 'package:greenwheel_user_app/models/plan_item.dart';
import 'package:greenwheel_user_app/screens/main_screen/home.dart';
import 'package:greenwheel_user_app/screens/main_screen/planscreen.dart';
import 'package:greenwheel_user_app/screens/main_screen/service_main_screen.dart';
import 'package:greenwheel_user_app/screens/main_screen/tabscreen.dart';
import 'package:greenwheel_user_app/view_models/location.dart';
import 'package:greenwheel_user_app/widgets/button_style.dart';
import 'package:greenwheel_user_app/widgets/confirm_plan_dialog.dart';
import 'package:greenwheel_user_app/widgets/custom_plan_item.dart';
import 'package:greenwheel_user_app/widgets/supplier_order_card.dart';
import 'package:greenwheel_user_app/widgets/test_screen.dart';
import 'package:sizer2/sizer2.dart';
import 'package:transparent_image/transparent_image.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen(
      {super.key,
      required this.location,
      required this.endDate,
      required this.numberOfMember,
      required this.startDate,
      required this.duration});
  final LocationViewModel location;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfMember;
  final int duration;

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  List<Widget> listLuutru = [];
  List<Widget> listFood = [];
  List<PlanItem> planDetail = [];
  late TextEditingController newItemController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    newItemController = TextEditingController();
    setUpData();
  }

  void removeItem(String item, List<String> list) {
    setState(() {
      list.remove(item);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    tabController.dispose();
    newItemController.dispose();
  }

  void addItem(List<String> list) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Hoạt động mới"),
              content: TextField(
                // key: ValueKey(),
                controller: newItemController,
                autofocus: true,
                cursorColor: primaryColor,
                decoration: const InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor)),
                ),
              ),
              actions: [
                OutlinedButton.icon(
                    icon: const Icon(
                      Icons.add,
                      color: primaryColor,
                    ),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: primaryColor,
                          width: 1.8,
                        ),
                        foregroundColor: primaryColor),
                    onPressed: () async {
                      String dupItem = "";
                      if (newItemController.text.isNotEmpty) {
                        bool check = list.any(
                            (element) => element == newItemController.text);
                        if (check) {
                          dupItem = newItemController.text;
                          AwesomeDialog(
                              context: context,
                              dialogType: DialogType.warning,
                              body: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  "     Bạn vừa thêm một hoạt động đã có trước đó trong ngày, hãy chắc chắn rằng bạn muốn thêm hoạt động này trước khi xác nhận kế hoạch!",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              btnOkColor: Colors.orange,
                              btnOkOnPress: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  list.add(dupItem);
                                });
                                newItemController.clear();
                              }).show();
                        } else {
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                          setState(() {
                            list.add(newItemController.text);
                          });

                          newItemController.clear();
                        }
                      }
                    },
                    label: const Text(
                      "Thêm",
                      style: TextStyle(color: primaryColor),
                    ))
              ],
            ));
  }

  setUpData() {
    planDetail = planItems(widget.duration + 1);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        title: const Text(
          "Lập kế hoạch",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Hero(
                      tag: widget.location.id,
                      child: FadeInImage(
                        placeholder: MemoryImage(kTransparentImage),
                        height: 35.h,
                        image: NetworkImage(
                            json.decode(widget.location.imageUrls)[0]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )),
                  const SizedBox(
                    height: 32,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Chuyến đi ${widget.location.name}",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          height: 1.8,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                              textAlign: TextAlign.start,
                              text: TextSpan(
                                  text: "Khởi hành:  ",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                        text:
                                            '${widget.startDate.day}/${widget.startDate.month}/${widget.startDate.year}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.normal))
                                  ])),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                              textAlign: TextAlign.start,
                              text: TextSpan(
                                  text: "Kết thúc:     ",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                        text:
                                            '${widget.endDate.day}/${widget.endDate.month}/${widget.endDate.year}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.normal))
                                  ])),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                              textAlign: TextAlign.start,
                              text: TextSpan(
                                  text: "Thành viên: ",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                        text: '${widget.numberOfMember} người',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.normal))
                                  ])),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          height: 1.8,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              "Lịch trình",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            )),
                        const SizedBox(
                          height: 16,
                        ),
                        for (int i = 0; i <= widget.duration; i++)
                          CustomPlanItem(
                            title: planDetail[i].title,
                            details: planDetail[i].details,
                            onDismiss: removeItem,
                            onAddNewItem: addItem,
                          ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          height: 1.8,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              "Các loại dịch vụ",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            )),
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
                                text: "(${listLuutru.length})",
                                icon: const Icon(Icons.bed),
                              ),
                              Tab(
                                text: "(${listFood.length})",
                                icon: const Icon(Icons.restaurant),
                              )
                            ]),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          height: 35.h,
                          child:
                              TabBarView(controller: tabController, children: [
                            ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: listLuutru.length,
                              itemBuilder: (context, index) {
                                return listLuutru[index];
                              },
                            ),
                            ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: listFood.length,
                              itemBuilder: (context, index) {
                                return listFood[index];
                              },
                            ),
                          ]),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          height: 5.h,
                          width: 18.h,
                          child: ElevatedButton.icon(
                            label: const Text("Tìm & đặt"),
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              print(tabController.index);
                              switch (tabController.index) {
                                case 0:
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (ctx) => ServiceMainScreen(
                                      serviceType: services[1],
                                      location: widget.location,
                                    ),
                                  ));
                                  break;
                                case 1:
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (ctx) => ServiceMainScreen(
                                      serviceType: services[0],
                                      location: widget.location,
                                    ),
                                  ));
                                  break;
                              }
                              // Navigator.of(context).push(MaterialPageRoute(
                              //     builder: (ctx) => const TestScreen()));
                            },
                            style: elevatedButtonStyle,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          height: 1.8,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 6.h,
              child: ElevatedButton(
                onPressed: () {
                  AwesomeDialog(
                          context: context,
                          dialogType: DialogType.noHeader,
                          animType: AnimType.topSlide,
                          btnOkColor: primaryColor,
                          btnOkText: "Lưu",
                          desc: "Lưu kế hoạch thành công",
                          body: Container(
                            alignment: Alignment.topLeft,
                            height: 50.h,
                            child: ConfirmPlan(
                              duration: widget.duration,
                              endDate: widget.endDate,
                              location: widget.location,
                              numberOfMember: widget.numberOfMember,
                              planDetail: planDetail,
                              startDate: widget.startDate,
                              orders: supplier_orders,
                            ),
                          ),
                          btnOkOnPress: () {
                            AwesomeDialog(
                                context: context,
                                dialogType: DialogType.success,
                                body: Text("Tạo kế hoạch thành công"),
                                btnOkColor: primaryColor,
                                btnOkOnPress: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (ctx) => const TabScreen(
                                            pageIndex: 1,
                                          )));
                                }).show();
                          },
                          btnCancelText: "Chỉnh sửa",
                          btnCancelOnPress: () {},
                          btnCancelColor: secondaryColor)
                      .show();
                },
                style: elevatedButtonStyle,
                child: const Text(
                  "Lưu kế hoạch",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }
}
