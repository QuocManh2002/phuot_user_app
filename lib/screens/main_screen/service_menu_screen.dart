import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:collection/collection.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:phuot_app/screens/main_screen/service_main_screen.dart';
import 'package:sizer2/sizer2.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/global_constant.dart';
import '../../core/constants/urls.dart';
import '../../models/menu_item_cart.dart';
import '../../models/order_input_model.dart';
import '../../service/plan_service.dart';
import '../../service/product_service.dart';
import '../../view_models/plan_viewmodels/plan_detail.dart';
import '../../view_models/product.dart';
import '../../widgets/order_screen_widget/menu_item_card.dart';
import '../loading_screen/service_menu_loading_screen.dart';
import 'cart.dart';

class ServiceMenuScreen extends StatefulWidget {
  const ServiceMenuScreen({required this.inputModel, super.key});
  final OrderInputModel inputModel;

  @override
  State<ServiceMenuScreen> createState() => _ServiceMenuScreenState();
}

class _ServiceMenuScreenState extends State<ServiceMenuScreen> {
  ProductService productService = ProductService();
  PlanService planService = PlanService();
  PlanDetail? plan;
  List<ProductViewModel> list = [];
  List<ItemCart> items = [];
  String note = "";
  String title = "";
  bool isLoading = true;
  double total = 0;
  final List<List<ProductViewModel>> _listResult = [];

  var currencyFormat = NumberFormat.currency(symbol: 'đ', locale: 'vi_VN');

  @override
  void initState() {
    super.initState();
    setUpData();
  }

  void findSumCombinations(List<ProductViewModel> roomList, int targetSum,
      {List<ProductViewModel> combination = const [], int startIndex = 0}) {
    int currentSum = 0;
    for (var element in combination) {
      currentSum += element.partySize!;
    }
    if (currentSum == targetSum) {
      _listResult.add(combination);
      return;
    }

    if (currentSum > targetSum) {
      return;
    }

    for (int i = startIndex; i < roomList.length; i++) {
      List<ProductViewModel> newCombination = List.from(combination)
        ..add(roomList[i]);
      findSumCombinations(roomList, targetSum,
          combination: newCombination, startIndex: i);
    }
  }

  getTotal() {
    return total *
            widget.inputModel.holidayServingDates!.length *
            (1 + widget.inputModel.holidayUpPCT! / 100) +
        total *
            (widget.inputModel.servingDates!.length -
                widget.inputModel.holidayServingDates!.length);
  }

  List<ProductViewModel> getResult(List<List<ProductViewModel>> list) {
    List<ProductViewModel> listRoomsCheapest = [];
    double minPriceRooms = 0;
    for (var element in list[0]) {
      minPriceRooms += element.price;
    }
    for (final rooms in list) {
      double price = 0;
      for (var element in rooms) {
        price += element.price;
      }
      if (price <= minPriceRooms) {
        minPriceRooms = price;
        listRoomsCheapest = rooms;
      }
    }
    return listRoomsCheapest;
  }

  setUpData() async {
    list = await productService.getProductsBySupplierId(
        widget.inputModel.supplier!.id,
        widget.inputModel.session == null
            ? widget.inputModel.period!
            : widget.inputModel.session!.enumName);

    if (list.isNotEmpty) {
      setState(() {
        isLoading = false;
      });
    }
    note = widget.inputModel.iniNote ?? "";

    if (widget.inputModel.serviceType!.id == 1) {
      title = "Món ăn";
      if (widget.inputModel.currentCart != null) {
        List<int> qtys = [];
        for (final item in widget.inputModel.currentCart!) {
          int index = widget.inputModel.currentCart!.indexOf(item);
          qtys.add(item.qty = (widget.inputModel.numberOfMember! /
                  list
                      .firstWhere((element) => element.id == item.product.id)
                      .partySize!)
              .ceil());
          updateCart(
              list.firstWhere((element) => element.id == item.product.id),
              qtys[index]);
        }
      }
    } else if (widget.inputModel.serviceType!.id == 2) {
      title = "Phòng nghỉ";
      if (widget.inputModel.currentCart != null) {
        List<int> qtys = [];
        for (final item in widget.inputModel.currentCart!) {
          int index = widget.inputModel.currentCart!.indexOf(item);
          qtys.add(item.qty = (widget.inputModel.numberOfMember! /
                  list
                      .firstWhere((element) => element.id == item.product.id)
                      .partySize!)
              .ceil());
          updateCart(
              list.firstWhere((element) => element.id == item.product.id),
              qtys[index]);
        }
      } else {
        final groupRoomList = list.groupListsBy(
          (element) => element.partySize,
        );
        List<ProductViewModel> sourceList = [];
        for (final roomList in groupRoomList.values) {
          roomList.sort(
            (a, b) => a.price.compareTo(b.price),
          );
          sourceList.add(roomList.first);
        }
        findSumCombinations(sourceList, widget.inputModel.numberOfMember!);
        List<ProductViewModel> rs = getResult(_listResult);
        Map gr = rs.groupListsBy((element) => element.id);
        for (final item in gr.keys) {
          updateCart(list.firstWhere((element) => element.id == item),
              rs.where((element) => element.id == item).toList().length);
        }
      }
    } else {
      title = 'Thuê phương tiện';
      if (widget.inputModel.currentCart != null) {
        List<int> qtys = [];
        for (final item in widget.inputModel.currentCart!) {
          int index = widget.inputModel.currentCart!.indexOf(item);
          qtys.add(item.qty = (widget.inputModel.numberOfMember! /
                  list
                      .firstWhere((element) => element.id == item.product.id)
                      .partySize!)
              .ceil());
          updateCart(
              list.firstWhere((element) => element.id == item.product.id),
              qtys[index]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            widget.inputModel.supplier!.name!,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (widget.inputModel.isOrder!)
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                      value: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_square,
                            color: Colors.blue,
                          ),
                          SizedBox(
                            width: 1.w,
                          ),
                          const Text(
                            'Thay đổi nhà cung cấp',
                            style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NotoSans'),
                          )
                        ],
                      ))
                ],
                onSelected: (value) {
                  if (value == 0) {
                    Navigator.pushReplacement(
                        context,
                        PageTransition(
                            child: ServiceMainScreen(
                              inputModel: widget.inputModel,
                            ),
                            type: PageTransitionType.rightToLeft));
                  }
                },
              )
          ],
        ),
        body: isLoading
            ? const ServiceMenuLoadingScreen()
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        SizedBox(
                          height: 30.h,
                          width: double.infinity,
                          child: Image.network(
                            '$baseBucketImage${widget.inputModel.supplier!.thumbnailUrl!}',
                            fit: BoxFit.fitWidth,
                            height: 30.h,
                          ),
                        ),
                        Container(
                            margin: EdgeInsets.only(top: 20.h),
                            width: 90.w,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 3,
                                  color: Colors.black12,
                                  offset: Offset(2, 4),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 1.h),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.inputModel.supplier!.name!,
                                      overflow: TextOverflow.clip,
                                      style: const TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  widget.inputModel.supplier!.standard != null
                                      ? Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 0.25.h),
                                          alignment: Alignment.centerLeft,
                                          child: RatingBar.builder(
                                              itemCount: 5,
                                              itemSize: 25,
                                              initialRating: widget.inputModel
                                                  .supplier!.standard!,
                                              allowHalfRating: true,
                                              ignoreGestures: true,
                                              unratedColor:
                                                  Colors.grey.withOpacity(0.5),
                                              itemBuilder: (context, index) =>
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                  ),
                                              onRatingUpdate: (value) {}),
                                        )
                                      : SizedBox(
                                          height: 0.5.h,
                                        ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.phone,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                        SizedBox(
                                          width: 2.w,
                                        ),
                                        Text(
                                          '0${widget.inputModel.supplier!.phone!.substring(2)}',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 0.5.h,
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.home,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                        SizedBox(
                                          width: 2.w,
                                        ),
                                        SizedBox(
                                          width: 70.w,
                                          child: Text(
                                            widget
                                                .inputModel.supplier!.address!,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black54),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 14),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    (widget.inputModel.serviceType!.id == 5)
                        ? Padding(
                            padding: const EdgeInsets.only(left: 14, top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Check-in ${widget.inputModel.session!.name.toLowerCase()}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'NotoSans',
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                if (widget.inputModel.isOrder == null ||
                                    !widget.inputModel.isOrder!)
                                  const Text(
                                    "Chúng tôi đã đề xuất cho bạn combo phòng có giá hợp lý nhất ứng với số lượng thành viên của chuyến đi.",
                                    style: TextStyle(color: Colors.grey),
                                  )
                              ],
                            ),
                          )
                        : Container(),
                    const SizedBox(
                      width: 8,
                    ),
                    (widget.inputModel.serviceType!.id == 1)
                        ? Padding(
                            padding: const EdgeInsets.only(left: 14, top: 10),
                            child: Text(
                              "Phục vụ vào ${widget.inputModel.session!.name.toLowerCase()}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontFamily: 'NotoSans',
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(),
                    const SizedBox(
                      width: 8,
                    ),
                    ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        int? qty;
                        ItemCart? itemCart =
                            getItemCartByMenuItemId(list[index].id);
                        if (itemCart != null) {
                          qty = itemCart.qty;
                        }
                        return MenuItemCard(
                          product: list[index],
                          quantity: qty,
                          serviceType: widget.inputModel.serviceType!,
                          numberOfMember: widget.inputModel.numberOfMember!,
                          updateCart: updateCart,
                        );
                      },
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: Visibility(
          visible: total != 0,
          child: Container(
            height: 10.h,
            width: double.infinity,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: 90.w,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => CartScreen(
                            startDate: widget.inputModel.startDate!,
                            endDate: widget.inputModel.endDate!,
                            numberOfMember: widget.inputModel.numberOfMember!,
                            supplier: widget.inputModel.supplier!,
                            list: items,
                            total: total,
                            serviceType: widget.inputModel.serviceType!,
                            note: note,
                            orderGuid: widget.inputModel.orderGuid,
                            isOrder: widget.inputModel.isOrder,
                            session: widget.inputModel.session!,
                            servingDates: widget.inputModel.servingDates,
                            callbackFunction:
                                widget.inputModel.callbackFunction!,
                            availableGcoinAmount:
                                widget.inputModel.availableGcoinAmount,
                            holidayServingDates:
                                widget.inputModel.holidayServingDates,
                            holidayUpPCT: widget.inputModel.holidayUpPCT,
                            finalTotal: widget.inputModel.isOrder == null ||
                                    !widget.inputModel.isOrder!
                                ? total
                                : getTotal(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Background color
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Giỏ hàng',
                            style: TextStyle(
                              color: Colors.white, // Text color
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(
                              width:
                                  10), // Add a space between the text and dot
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Colors.white, // Dot color
                            size: 10,
                          ),
                          const SizedBox(
                              width:
                                  10), // Add a space between the dot and the price
                          Text(
                            currencyFormat.format(total),
                            style: const TextStyle(
                              color: Colors.white, // Text color
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: widget.inputModel.isOrder != null &&
                widget.inputModel.isOrder!
            ? DraggableFab(
                child: FloatingActionButton(
                backgroundColor: primaryColor.withOpacity(0.9),
                foregroundColor: Colors.white,
                key: UniqueKey(),
                shape: const CircleBorder(),
                onPressed: () {
                  final totalOrder = getTotal();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Tổng quan chi phí đơn hàng'),
                      titleTextStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSans'),
                      content: SizedBox(
                        width: 100.w,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ngân sách hiện tại',
                                  style: TextStyle(
                                      fontSize: 14, fontFamily: 'NotoSans'),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 25.w,
                                  child: Text(
                                    NumberFormat.simpleCurrency(
                                            locale: 'vi_VN',
                                            decimalDigits: 0,
                                            name: '')
                                        .format(widget
                                            .inputModel.availableGcoinAmount),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NotoSans'),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: SvgPicture.asset(
                                    gcoinLogo,
                                    height: 18,
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 0.02.h,
                            ),
                            Divider(
                              thickness: 1,
                              color: Colors.grey.withOpacity(0.7),
                            ),
                            SizedBox(
                              height: 0.02.h,
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Đơn giá theo ngày',
                                style: TextStyle(
                                    fontSize: 14, fontFamily: 'NotoSans'),
                              ),
                            ),
                            for (final date in widget.inputModel.servingDates!)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 3.w,
                                  ),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(date),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'NotoSans',
                                    ),
                                  ),
                                  if (widget.inputModel.holidayServingDates!
                                      .contains(date))
                                    const Text(
                                      ' (Ngày lễ)',
                                      style: TextStyle(
                                          fontSize: 12, fontFamily: 'NotoSans'),
                                    ),
                                  const Spacer(),
                                  Text(
                                    NumberFormat.simpleCurrency(
                                            locale: 'vi_VN',
                                            name: 'đ',
                                            decimalDigits: 0)
                                        .format(widget
                                                .inputModel.holidayServingDates!
                                                .contains(date)
                                            ? total *
                                                (1 +
                                                    widget.inputModel
                                                            .holidayUpPCT! /
                                                        100)
                                            : total),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NotoSans'),
                                  )
                                ],
                              ),
                            SizedBox(
                              height: 0.02.h,
                            ),
                            Divider(
                              thickness: 1,
                              color: Colors.grey.withOpacity(0.7),
                            ),
                            SizedBox(
                              height: 0.02.h,
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Tổng cộng',
                                  style: TextStyle(
                                      fontSize: 14, fontFamily: 'NotoSans'),
                                ),
                                const Spacer(),
                                Text(
                                  NumberFormat.simpleCurrency(
                                          locale: 'vi_VN',
                                          name: 'đ',
                                          decimalDigits: 0)
                                      .format(totalOrder),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 0.1.h,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Giá trị quy đổi',
                                  style: TextStyle(
                                      fontSize: 14, fontFamily: 'NotoSans'),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 30.w,
                                  child: Text(
                                    NumberFormat.simpleCurrency(
                                            locale: 'vi_VN',
                                            decimalDigits: 0,
                                            name: '')
                                        .format(totalOrder /
                                            GlobalConstant().VND_CONVERT_RATE),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NotoSans'),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: SvgPicture.asset(
                                    gcoinLogo,
                                    height: 15,
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 0.1.h,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ngân sách mới',
                                  style: TextStyle(
                                      fontSize: 14, fontFamily: 'NotoSans'),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 30.w,
                                  child: Text(
                                    NumberFormat.simpleCurrency(
                                            locale: 'vi_VN',
                                            decimalDigits: 0,
                                            name: '')
                                        .format(widget.inputModel
                                                .availableGcoinAmount! -
                                            totalOrder /
                                                GlobalConstant()
                                                    .VND_CONVERT_RATE),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NotoSans'),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: SvgPicture.asset(
                                    gcoinLogo,
                                    height: 15,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.attach_money),
              ))
            : null,
      ),
    );
  }

  ItemCart? getItemCartByMenuItemId(int selectId) {
    try {
      return items.firstWhere((cart) => cart.product.id == selectId);
    } catch (e) {
      return null;
    }
  }

  void updateCart(ProductViewModel prod, int qty) {
    setState(() {
      final existingItemIndex =
          items.indexWhere((cartItem) => cartItem.product.id == prod.id);

      if (existingItemIndex != -1) {
        final existingItem = items[existingItemIndex];
        total -= existingItem.product.price * existingItem.qty!;

        if (qty != 0) {
          total += prod.price * qty;
          items[existingItemIndex] = ItemCart(product: prod, qty: qty);
        } else {
          items.removeAt(existingItemIndex);
        }
      } else if (qty != 0) {
        if (items.length == GlobalConstant().ORDER_ITEM_MAX_COUNT) {
          AwesomeDialog(
                  context: context,
                  animType: AnimType.leftSlide,
                  dialogType: DialogType.warning,
                  title:
                      'Đơn hàng chỉ được đặt tối đa ${GlobalConstant().ORDER_ITEM_MAX_COUNT} loại sản phẩm',
                  titleTextStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSans',
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  btnOkColor: Colors.amber,
                  btnOkOnPress: () {},
                  btnOkText: 'OK')
              .show();
        } else {
          items.add(ItemCart(product: prod, qty: qty));
          total += prod.price * qty;
        }
      }

      if (items.isEmpty) {
        note = "";
      }
    });
  }
}
