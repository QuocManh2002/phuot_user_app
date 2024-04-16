// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:greenwheel_user_app/core/constants/colors.dart';
import 'package:greenwheel_user_app/core/constants/combo_date_plan.dart';
import 'package:greenwheel_user_app/core/constants/urls.dart';
import 'package:greenwheel_user_app/helpers/util.dart';
import 'package:greenwheel_user_app/main.dart';
import 'package:greenwheel_user_app/screens/loading_screen/plan_detail_loading_screen.dart';
import 'package:greenwheel_user_app/screens/main_screen/tabscreen.dart';
import 'package:greenwheel_user_app/screens/payment_screen/success_payment_screen.dart';
import 'package:greenwheel_user_app/screens/plan_screen/create_plan/select_combo_date_screen.dart';
import 'package:greenwheel_user_app/screens/plan_screen/history_order_screen.dart';
import 'package:greenwheel_user_app/service/order_service.dart';
import 'package:greenwheel_user_app/service/traveler_service.dart';
import 'package:greenwheel_user_app/view_models/location_viewmodels/emergency_contact.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/detail_plan_surcharge_note.dart';
import 'package:greenwheel_user_app/screens/plan_screen/join_confirm_plan_screen.dart';
import 'package:greenwheel_user_app/screens/plan_screen/plan_pdf_view_screen.dart';
import 'package:greenwheel_user_app/screens/plan_screen/share_plan_screen.dart';
import 'package:greenwheel_user_app/service/location_service.dart';
import 'package:greenwheel_user_app/service/plan_service.dart';
import 'package:greenwheel_user_app/service/product_service.dart';
import 'package:greenwheel_user_app/view_models/order.dart';
import 'package:greenwheel_user_app/view_models/order_detail.dart';
import 'package:greenwheel_user_app/view_models/plan_member.dart';
import 'package:greenwheel_user_app/view_models/plan_viewmodels/plan_create.dart';
import 'package:greenwheel_user_app/view_models/plan_viewmodels/plan_detail.dart';
import 'package:greenwheel_user_app/view_models/product.dart';
import 'package:greenwheel_user_app/view_models/supplier.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/base_information.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/confirm_plan_bottom_sheet.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/detail_plan_service_widget.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/plan_schedule.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/tab_icon_button.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sizer2/sizer2.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../widgets/style_widget/button_style.dart';

class DetailPlanNewScreen extends StatefulWidget {
  const DetailPlanNewScreen(
      {super.key,
      required this.planId,
      this.isFromHost,
      this.isClone,
      required this.planType,
      required this.isEnableToJoin});
  final int planId;
  final bool isEnableToJoin;
  final bool? isFromHost;
  final String planType;
  final bool? isClone;

  @override
  State<DetailPlanNewScreen> createState() => _DetailPlanScreenState();
}

class _DetailPlanScreenState extends State<DetailPlanNewScreen>
    with TickerProviderStateMixin {
  bool isLoading = true;
  PlanService _planService = PlanService();
  LocationService _locationService = LocationService();
  ProductService _productService = ProductService();
  CustomerService _customerService = CustomerService();
  OrderService _orderService = OrderService();
  PlanDetail? _planDetail;
  List<PlanMemberViewModel> _planMembers = [];
  double total = 0;
  int _selectedTab = 0;
  bool _isPublic = false;
  bool _isEnableToInvite = false;
  bool _isEnableToOrder = false;
  List<ProductViewModel> products = [];
  List<OrderViewModel>? tempOrders = [];
  List<OrderViewModel> orderList = [];
  bool isLeader = false;
  Widget? activeWidget;
  bool _isAlreadyJoin = false;
  var currencyFormat =
      NumberFormat.simpleCurrency(locale: 'vi_VN', name: '', decimalDigits: 0);
  bool _isEnableToConfirm = false;
  String comboDateText = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setupData();
    sharedPreferences.setInt('planId', widget.planId);
  }

  setupData() async {
    setState(() {
      isLoading = true;
    });
    _planDetail = null;
    final plan = await _planService.GetPlanById(widget.planId, widget.planType);
    List<int> productIds = [];
    if (plan != null) {
      setState(() {
        _planDetail = plan;
        isLoading = false;
      });
      isLeader = sharedPreferences.getInt('userId') == _planDetail!.leaderId;
      products = await _productService.getListProduct(productIds);
      tempOrders = await _orderService.getTempOrderFromSchedule(
          _planDetail!.schedule!, _planDetail!.startDate!);
      _isPublic = _planDetail!.joinMethod != 'NONE';
      _isEnableToInvite = _planDetail!.status == 'REGISTERING';
      getOrderList();
      await getPlanMember();
      if (_planDetail != null) {
        setState(() {
          isLoading = false;
        });
      }
      _isEnableToConfirm = _planDetail!.status == 'REGISTERING';
    }
    var tempDuration = DateFormat.Hm().parse(_planDetail!.travelDuration!);
    final startTime = DateTime(0, 0, 0, _planDetail!.utcDepartAt!.hour,
        _planDetail!.utcDepartAt!.minute, 0);
    final arrivedTime = startTime
        .add(Duration(hours: tempDuration.hour))
        .add(Duration(minutes: tempDuration.minute));
    final rs = Utils().getNumOfExpPeriod(
        arrivedTime, _planDetail!.numOfExpPeriod!, startTime, null, true);
    var comboDate = listComboDate.firstWhere(
        (element) => element.duration == _planDetail!.numOfExpPeriod!);
    comboDateText =
        '${comboDate.numberOfDay} ngày ${rs['numOfExpPeriod'] != _planDetail!.numOfExpPeriod ? comboDate.numberOfNight + 1 : comboDate.numberOfNight} đêm';
  }

  getPlanMember() async {
    final memberList = await _planService.getPlanMember(
        widget.planId, widget.planType, context);
    _planMembers = [];
    for (final mem in memberList) {
      if (mem.status == 'JOINED') {
        int type = 0;
        if (mem.accountId == _planDetail!.leaderId) {
          type = 1;
        } else if (mem.accountId == sharedPreferences.getInt('userId')) {
          type = 2;
        } else {
          type = 3;
        }
        _planMembers.add(PlanMemberViewModel(
            name: mem.name,
            memberId: mem.memberId,
            phone: mem.phone,
            status: mem.status,
            companions: mem.companions,
            accountId: mem.accountId,
            accountType: type,
            isMale: mem.isMale,
            imagePath: mem.imagePath,
            weight: mem.weight));
      }
    }
    _isAlreadyJoin = _planMembers.any((element) =>
        element.accountId == sharedPreferences.getInt('userId')! &&
        element.status == 'JOINED');
  }

  getTempOrder() => _planDetail!.tempOrders!.map((e) {
        final Map<String, dynamic> cart = e['cart'];
        ProductViewModel sampleProduct = products.firstWhere(
            (element) => element.id.toString() == cart.entries.first.key);
        return OrderViewModel(
            id: e['id'],
            details: cart.entries.map((e) {
              final product = products
                  .firstWhere((element) => element.id.toString() == e.key);
              return OrderDetailViewModel(
                  id: product.id,
                  productId: product.id,
                  productName: product.name,
                  price: product.price.toDouble(),
                  unitPrice: product.price.toDouble(),
                  quantity: e.value);
            }).toList(),
            note: e['note'],
            serveDates: e["serveDates"],
            total: e['total'].toDouble(),
            createdAt: DateTime.now(),
            supplier: SupplierViewModel(
                type: sampleProduct.supplierType,
                id: sampleProduct.supplierId!,
                name: sampleProduct.supplierName,
                phone: sampleProduct.supplierPhone,
                thumbnailUrl: sampleProduct.supplierThumbnailUrl,
                address: sampleProduct.supplierAddress),
            type: e['type'],
            period: e['period']);
      }).toList();

  getOrderList() async {
    var _total = 0.0;
    if (_planDetail!.status == 'REGISTERING' ||
        _planDetail!.status == 'PENDING') {
      orderList = tempOrders!;
    } else {
      final rs =
          await _planService.getOrderCreatePlan(widget.planId, widget.planType);
      if (rs != null) {
        setState(() {
          orderList = rs['orders'];
          _planDetail!.actualGcoinBudget = rs['currentBudget'].toInt();
        });
      }
    }
    _total = orderList.fold(0, (sum, obj) => sum + obj.total!);
    setState(() {
      total = _total;
    });
  }

  updatePlan() async {
    final location =
        await _locationService.GetLocationById(_planDetail!.locationId!);
    if (location != null) {
      PlanCreate _plan = PlanCreate(
          surcharges: _planDetail!.surcharges,
          travelDuration: _planDetail!.travelDuration,
          departAt: _planDetail!.utcDepartAt,
          departAddress: _planDetail!.departureAddress,
          locationId: _planDetail!.locationId,
          locationName: _planDetail!.locationName,
          maxMemberCount: _planDetail!.maxMemberCount,
          maxMemberWeight: _planDetail!.maxMemberWeight,
          name: _planDetail!.name,
          savedContacts: json.encode(_planDetail!.savedContacts!
              .map((e) => EmergencyContactViewModel().toJson(e))
              .toList()),
          note: _planDetail!.note,
          endDate: _planDetail!.endDate,
          startDate: _planDetail!.startDate,
          departCoordinate: PointLatLng(
              _planDetail!.startLocationLat!, _planDetail!.startLocationLng!),
          numOfExpPeriod: _planDetail!.numOfExpPeriod,
          savedContactIds: [],
          arrivedAt: _planDetail!.utcStartAt,
          schedule: json.encode(_planDetail!.schedule));
      sharedPreferences.setInt('planId', widget.planId);
      Navigator.of(context).pop();
      Navigator.push(
          context,
          PageTransition(
              child: SelectComboDateScreen(
                isCreate: false,
                location: location,
                plan: _plan,
                isClone: false,
              ),
              type: PageTransitionType.rightToLeft));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            floatingActionButton: _planDetail == null ||
                    (_planDetail != null && _planDetail!.memberCount! == 0) ||
                    _planDetail!.joinMethod == 'NONE'
                ? null
                : isLeader
                    ? SpeedDial(
                        animatedIcon: AnimatedIcons.menu_close,
                        backgroundColor: primaryColor.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        activeBackgroundColor: redColor.withOpacity(0.9),
                        children: [
                          if (_isEnableToInvite)
                            SpeedDialChild(
                                child: const Icon(Icons.send),
                                labelStyle: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                label: 'Mời',
                                onTap: _isEnableToInvite ? onInvite : () {},
                                labelBackgroundColor: _isEnableToInvite
                                    ? Colors.blue.withOpacity(0.8)
                                    : Colors.white30,
                                foregroundColor: Colors.white,
                                backgroundColor: _isEnableToInvite
                                    ? Colors.blue
                                    : const Color.fromARGB(97, 15, 7, 7)),
                          if (_isEnableToConfirm)
                            SpeedDialChild(
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  size: 30,
                                ),
                                label: 'Chốt',
                                onTap: _isEnableToConfirm
                                    ? onConfirmMember
                                    : () {},
                                labelStyle: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                labelBackgroundColor: _isEnableToConfirm
                                    ? primaryColor.withOpacity(0.8)
                                    : Colors.white30,
                                foregroundColor: Colors.white,
                                backgroundColor: _isEnableToConfirm
                                    ? primaryColor
                                    : Colors.white38),
                          SpeedDialChild(
                              child: const Icon(Icons.share),
                              labelStyle: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              onTap: () {
                                sharedPreferences.setInt(
                                    'plan_id_pdf', _planDetail!.id!);
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (ctx) =>
                                        const PlanPdfViewScreen()));
                              },
                              label: 'Chia sẻ',
                              labelBackgroundColor:
                                  Colors.amber.withOpacity(0.8),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.amber),
                          if (DateTime.now().isBefore(_planDetail!.endDate!) &&
                              DateTime.now().isAfter(_planDetail!.utcDepartAt!
                                  .add(Duration(
                                      hours: DateFormat.Hm()
                                          .parse(_planDetail!.travelDuration!)
                                          .hour))
                                  .add(Duration(
                                      minutes: DateFormat.Hm()
                                          .parse(_planDetail!.travelDuration!)
                                          .minute))))
                            SpeedDialChild(
                                child: const Icon(Icons.check),
                                labelStyle: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                onTap: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      content: SizedBox(
                                        height: 10.h,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                  var coordinate =
                                      await _planService.getCurrentLocation();
                                  if (coordinate != null) {
                                    final rs = await _planService.verifyPlan(
                                        widget.planId, coordinate, context);
                                    if (rs != null) {
                                      Navigator.of(context).pop();
                                      AwesomeDialog(
                                              context: context,
                                              animType: AnimType.leftSlide,
                                              dialogType: DialogType.success,
                                              title: 'Đã xác nhận kế hoạch',
                                              padding: const EdgeInsets.all(12),
                                              titleTextStyle: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'NotoSans'))
                                          .show();
                                      setupData();
                                      Future.delayed(const Duration(seconds: 1),
                                          () {
                                        Navigator.of(context).pop();
                                      });
                                    }
                                  }
                                },
                                label: 'Xác nhận kế hoạch',
                                labelBackgroundColor:
                                    primaryColor.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                backgroundColor: primaryColor),
                          if (_planDetail!.status == 'COMPLETED')
                            SpeedDialChild(
                                child: const Icon(Icons.print),
                                labelStyle: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                onTap: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      content: SizedBox(
                                        height: 10.h,
                                        child:const Center(
                                          child:  CircularProgressIndicator(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                  final rs = await _planService.publishPlan(
                                      widget.planId, context);
                                  if (rs != null) {
                                    Navigator.of(context).pop();
                                    AwesomeDialog(
                                            context: context,
                                            animType: AnimType.leftSlide,
                                            dialogType: DialogType.success,
                                            title: 'Đã xuất bản kế hoạch',
                                            padding: const EdgeInsets.all(12),
                                            titleTextStyle: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'NotoSans'))
                                        .show();
                                    setupData();
                                    Future.delayed(const Duration(seconds: 1),
                                        () {
                                      Navigator.of(context).pop();
                                    });
                                  }
                                },
                                label: 'Xuất bản kế hoạch',
                                labelBackgroundColor:
                                    primaryColor.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                backgroundColor: primaryColor),
                        ],
                      )
                    : _isAlreadyJoin
                        ? FloatingActionButton(
                            shape: const CircleBorder(),
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.share),
                            onPressed: () {
                              sharedPreferences.setInt(
                                  'plan_id_pdf', _planDetail!.id!);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (ctx) => const PlanPdfViewScreen()));
                            })
                        : null,
            appBar: AppBar(
              title: Text(
                _planDetail != null ? _planDetail!.name! : '',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              leading: BackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: const ButtonStyle(
                    foregroundColor: MaterialStatePropertyAll(Colors.white)),
              ),
              actions: [
                PopupMenuButton(
                  itemBuilder: (ctx) => [
                    if (isLeader && _planDetail!.status == 'PENDING')
                      const PopupMenuItem(
                        value: 0,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_square,
                              color: Colors.blueAccent,
                              size: 32,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Chỉnh sửa',
                              style: TextStyle(
                                  color: Colors.blueAccent, fontSize: 18),
                            )
                          ],
                        ),
                      ),
                    if (!isLeader &&
                        (_planDetail!.status == 'PENDING' ||
                            _planDetail!.status == 'REGISTERING'))
                      const PopupMenuItem(
                        value: 1,
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.amber,
                              size: 32,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Rời khỏi',
                              style:
                                  TextStyle(color: Colors.amber, fontSize: 18),
                            )
                          ],
                        ),
                      ),
                    if (isLeader &&
                        (_planDetail!.status == 'PENDING' ||
                            _planDetail!.status == 'REGISTERING'))
                      const PopupMenuItem(
                        value: 2,
                        child: Row(
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Huỷ kế hoạch',
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 18),
                            )
                          ],
                        ),
                      ),
                    if (isLeader &&
                        _planDetail!.status != 'PENDING' &&
                        _planDetail!.status != 'REGISTERING')
                      const PopupMenuItem(
                        value: 3,
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: Colors.blueAccent,
                              size: 32,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Lịch sử đơn hàng',
                              style: TextStyle(
                                  color: Colors.blueAccent, fontSize: 18),
                            )
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 0:
                        updatePlan();
                        break;
                      case 1:
                        handleQuitPlan();
                        break;
                      case 2:
                        handleCancelPlan();
                        break;
                      case 3:
                        handleHistoryOrder();
                        break;
                    }
                  },
                )
              ],
            ),
            body: isLoading
                ? const PlanDetailLoadingScreen()
                : RefreshIndicator(
                    onRefresh: () async {
                      await setupData();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                              child: Column(
                            children: [
                              CachedNetworkImage(
                                height: 25.h,
                                width: double.infinity,
                                fit: BoxFit.fill,
                                imageUrl:
                                    '$baseBucketImage${_planDetail!.imageUrls![0]}',
                                placeholder: (context, url) =>
                                    Image.memory(kTransparentImage),
                                errorWidget: (context, url, error) =>
                                    FadeInImage.assetNetwork(
                                  height: 15.h,
                                  width: 15.h,
                                  fit: BoxFit.cover,
                                  placeholder: 'No Image',
                                  image:
                                      'https://th.bing.com/th/id/R.e61db6eda58d4e57acf7ef068cc4356d?rik=oXCsaP5FbsFBTA&pid=ImgRaw&r=0',
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 70.w,
                                          child: Text(
                                            _planDetail!.locationName!,
                                            overflow: TextOverflow.clip,
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'NotoSans',
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Text(
                                          comboDateText,
                                          overflow: TextOverflow.clip,
                                          style: const TextStyle(
                                              fontFamily: 'NotoSans',
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (!_isAlreadyJoin &&
                                            _planDetail!.gcoinBudgetPerCapita !=
                                                0)
                                          Row(
                                            children: [
                                              Text(
                                                NumberFormat.simpleCurrency(
                                                        locale: 'vi_VN',
                                                        decimalDigits: 0,
                                                        name: '')
                                                    .format(_planDetail!
                                                        .gcoinBudgetPerCapita),
                                                overflow: TextOverflow.clip,
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'NotoSans',
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SvgPicture.asset(
                                                gcoin_logo,
                                                height: 25,
                                              ),
                                              const Text(
                                                ' /',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'NotoSans',
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const Icon(
                                                Icons.person,
                                                color: primaryColor,
                                                size: 25,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      children: [
                                        if (!widget.isEnableToJoin && isLeader)
                                          CupertinoSwitch(
                                            value: _isPublic,
                                            activeColor: primaryColor,
                                            onChanged: (value) async {
                                              setState(() {
                                                _isPublic = !_isPublic;
                                              });
                                              onPublicizePlan();
                                            },
                                          ),
                                        Text(
                                          _isPublic ? 'Công khai' : 'Riêng tư',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'NotoSans',
                                              color: _isPublic
                                                  ? primaryColor
                                                  : Colors.grey),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Container(
                                  height: 1.8,
                                  color: Colors.grey.withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          onTap: () {
                                            setState(() {
                                              _selectedTab = 0;
                                            });
                                          },
                                          child: TabIconButton(
                                            iconDefaultUrl:
                                                basic_information_green,
                                            iconSelectedUrl:
                                                basic_information_white,
                                            text: 'Thông tin',
                                            isSelected: _selectedTab == 0,
                                            index: 0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          onTap: () {
                                            setState(() {
                                              _selectedTab = 1;
                                            });
                                          },
                                          child: TabIconButton(
                                            iconDefaultUrl: schedule_green,
                                            iconSelectedUrl: schedule_white,
                                            text: 'Lịch trình',
                                            isSelected: _selectedTab == 1,
                                            index: 1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          onTap: () {
                                            setState(() {
                                              _selectedTab = 2;
                                            });
                                          },
                                          child: TabIconButton(
                                            iconDefaultUrl: service_green,
                                            iconSelectedUrl: service_white,
                                            text: 'Dịch vụ',
                                            isSelected: _selectedTab == 2,
                                            index: 2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          onTap: () {
                                            setState(() {
                                              _selectedTab = 3;
                                            });
                                          },
                                          child: TabIconButton(
                                            iconDefaultUrl: surcharge_green,
                                            iconSelectedUrl: surcharge_white,
                                            text: 'Phụ thu & ghi chú',
                                            isSelected: _selectedTab == 3,
                                            index: 3,
                                          ),
                                        ),
                                      ),
                                    ]),
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Container(
                                  child: _selectedTab == 2
                                      ? buildServiceWidget()
                                      : _selectedTab == 1
                                          ? buildScheduleWidget()
                                          : _selectedTab == 0
                                              ? buildInforWidget()
                                              : buildSurchagreNoteWidget()),
                              SizedBox(
                                height: 2.h,
                              )
                            ],
                          )),
                        ),
                        if ((widget.isFromHost == null || widget.isFromHost!) &&
                                widget.isEnableToJoin &&
                                !_isAlreadyJoin ||
                            widget.planType == 'PUBLISH')
                          buildNewFooter()
                      ],
                    ),
                  )));
  }

  buildSurchagreNoteWidget() => DetailPlanSurchargeNote(
        plan: _planDetail!,
      );

  buildServiceWidget() => DetailPlanServiceWidget(
      plan: _planDetail!,
      isLeader: isLeader,
      tempOrders: tempOrders!,
      orderList: orderList,
      planType: widget.planType,
      total: total,
      onGetOrderList: setupData);

  buildInforWidget() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Thông tin cơ bản',
              style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          BaseInformationWidget(
            plan: _planDetail!,
            members: _planMembers,
            refreshData: setupData,
            isLeader: isLeader,
            planType: widget.planType,
          ),
        ],
      );
  buildScheduleWidget() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Lịch trình",
                  style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                )),
            const SizedBox(
              height: 16,
            ),
            SizedBox(
              height: 60.h,
              child: PLanScheduleWidget(
                planId: widget.planId,
                isLeader: isLeader,
                planType: widget.planType,
                schedule: _planDetail!.schedule!,
                startDate: _planDetail!.startDate!,
                endDate: _planDetail!.endDate!,
              ),
            ),
          ],
        ),
      );
  onInvite() async {
    var enableToShare = checkEnableToShare();
    if (enableToShare['status']) {
      // await getPlanMember();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => SharePlanScreen(
                joinMethod: _planDetail!.joinMethod!,
                isFromHost: _planDetail!.leaderId ==
                    sharedPreferences.getInt('userId')!,
                planMembers: _planMembers,
                isEnableToJoin: widget.isEnableToJoin,
                planId: widget.planId,
              )));
    } else {
      AwesomeDialog(
              context: context,
              dialogType: DialogType.warning,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'Không thể chia sẻ kế hoạch',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSans'),
                      ),
                      SizedBox(
                        height: 1.h,
                      ),
                      Text(
                        enableToShare['message'],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSans',
                            color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              btnOkColor: Colors.orange,
              btnOkText: 'Ok',
              btnOkOnPress: () {})
          .show();
    }
  }

  onJoinPlan(bool isPublic) async {
    var emerList = [];
    if (_planDetail!.memberCount == _planDetail!.maxMemberCount) {
      AwesomeDialog(
              context: context,
              animType: AnimType.bottomSlide,
              dialogType: DialogType.error,
              title: 'Không thể gia nhập chuyến đi',
              titleTextStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              desc: 'Chuyến đi đã đủ số lượng thành viên tham gia',
              descTextStyle: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              btnOkColor: redColor,
              btnOkOnPress: () {},
              btnOkText: 'OK')
          .show();
    } else {
      final int balance = await _customerService
          .getTravelerBalance(sharedPreferences.getInt('userId')!);
      if (balance >= _planDetail!.gcoinBudgetPerCapita!) {
        for (final emer in _planDetail!.savedContacts!) {
          emerList.add({
            "name": emer.name,
            "phone": emer.phone,
            "address": emer.address,
            "imageUrl": emer.imageUrl,
            "type": emer.type
          });
        }
        // List<dynamic>? _schedule =
        //     await _planService.getPlanSchedule(widget.planId, widget.planType);
        // if (_schedule != null) {
        final rs = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) => SizedBox(
                  height: 90.h,
                  child: ConfirmPlanBottomSheet(
                    isInfo: false,
                    isFromHost: isLeader,
                    plan: PlanCreate(
                      departAddress: _planDetail!.departureAddress,
                      schedule: json.encode(_planDetail!.schedule),
                      savedContacts: json.encode(emerList),
                      name: _planDetail!.name,
                      maxMemberCount: _planDetail!.maxMemberCount,
                      startDate: _planDetail!.startDate,
                      endDate: _planDetail!.endDate,
                      travelDuration: _planDetail!.travelDuration,
                      departAt: _planDetail!.utcDepartAt,
                      note: _planDetail!.note,
                    ),
                    locationName: _planDetail!.locationName!,
                    orderList: tempOrders,
                    onCompletePlan: () {},
                    listSurcharges: _planDetail!.surcharges!
                        .map((e) => e.toJson())
                        .toList(),
                    isJoin: true,
                    onJoinPlan: () {
                      confirmJoin(isPublic);
                    },
                    onCancel: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _isPublic = false;
                      });
                    },
                  ),
                ));
        if (rs == null) {
          setState(() {
            _isPublic = false;
          });
        }
        // }
      } else {
        AwesomeDialog(
                context: context,
                animType: AnimType.leftSlide,
                dialogType: DialogType.error,
                title: 'Số dư của bạn không đủ để tham gia kế hoạch này',
                titleTextStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSans'),
                desc: 'Vui lòng nạp thêm GCOIN',
                descTextStyle: const TextStyle(
                    fontSize: 17, fontFamily: 'NotoSans', color: Colors.grey),
                btnOkColor: Colors.red,
                btnOkOnPress: () {
                  Navigator.push(
                      context,
                      PageTransition(
                          child: const TabScreen(pageIndex: 4),
                          type: PageTransitionType.rightToLeft));
                },
                btnOkText: 'Nạp thêm',
                btnCancelColor: Colors.amber,
                btnCancelOnPress: () {},
                btnCancelText: 'Huỷ')
            .show();
      }
    }
  }

  confirmJoin(bool isPublic) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => JoinConfirmPlanScreen(
              plan: _planDetail!,
              isPublic: isPublic,
              isConfirm: false,
              isView: false,
              onPublicizePlan: handlePublicizePlan,
            )));
  }

  Widget buildNewFooter() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
            alignment: Alignment.center,
            height: 6.h,
            child: ElevatedButton(
              onPressed: () {
                if (widget.planType == 'PUBLISH') {
                  onClonePlan();
                } else {
                  if (!_isAlreadyJoin) {
                    onJoinPlan(false);
                  }
                }
              },
              style: elevatedButtonStyle.copyWith(
                  backgroundColor: MaterialStatePropertyAll(
                      _isAlreadyJoin ? Colors.grey : primaryColor)),
              child: Text(
                widget.planType == 'PUBLISH'
                    ? "Sao chép kế hoạch"
                    : "Tham gia kế hoạch",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            )),
      );

  checkEnableToShare() {
    var enableToShare = {
      'status': true,
      'message': 'Kế hoạch đủ điều kiện để chia sẻ'
    };
    if (_planDetail!.maxMemberCount == _planMembers.length) {
      return {
        'status': false,
        'message': 'Đã đủ số lượng thành viên của chuyến đi'
      };
    }
    return enableToShare;
  }

  onConfirmMember() async {
    if (_planDetail!.memberCount! < _planDetail!.maxMemberCount!) {
      AwesomeDialog(
              context: context,
              animType: AnimType.bottomSlide,
              dialogType: DialogType.warning,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      'Chuyến đi chưa đủ thành viên',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        const Text(
                          'Số lượng thành viên',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          '${_planDetail!.memberCount! < 10 ? '0${_planDetail!.memberCount}' : _planDetail!.memberCount}/${_planDetail!.maxMemberCount! < 10 ? '0${_planDetail!.maxMemberCount}' : _planDetail!.maxMemberCount}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'Thời gian',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(_planDetail!.utcDepartAt!)} - ${DateFormat('dd/MM/yyyy').format(_planDetail!.endDate!)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'Chi phí tham gia',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          '${currencyFormat.format(_planDetail!.gcoinBudgetPerCapita)} GCOIN',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      'Thanh toán thêm ${currencyFormat.format(_planDetail!.gcoinBudgetPerCapita)}${_planDetail!.maxMemberCount! - _planDetail!.memberCount! > 1 ? ' x ${_planDetail!.maxMemberCount! - _planDetail!.memberCount!} = ${currencyFormat.format(_planDetail!.gcoinBudgetPerCapita! * (_planDetail!.maxMemberCount! - _planDetail!.memberCount!))}' : ''}GCOIN để chốt số lượng thành viên cho chuyến đi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              ),
              btnOkColor: Colors.blue,
              btnOkOnPress: () {
                Navigator.push(
                    context,
                    PageTransition(
                        child: JoinConfirmPlanScreen(
                            callback: callbackConfirmMember,
                            plan: _planDetail!,
                            isView: false,
                            isPublic: false,
                            isConfirm: true),
                        type: PageTransitionType.rightToLeft));
              },
              btnOkText: 'Chơi',
              btnCancelColor: Colors.amber,
              btnCancelOnPress: () {},
              btnCancelText: 'Huỷ')
          .show();
    } else if (_planDetail!.memberCount == _planDetail!.maxMemberCount) {
      confirmMember();
    }
  }

  confirmMember() async {
    final rs = await _planService.confirmMember(widget.planId, context);
    if (rs != 0) {
      AwesomeDialog(
        context: context,
        animType: AnimType.rightSlide,
        dialogType: DialogType.success,
        title: 'Đã chốt số lượng thành viên của chuyến đi',
        titleTextStyle:
            const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.all(12),
      ).show();
      Future.delayed(const Duration(milliseconds: 1500), () {
        Navigator.of(context).pop();
        setState(() {
          _planDetail!.status = 'READY';
          _isEnableToInvite = false;
          _isEnableToOrder = true;
        });
      });
    }
  }

  callbackConfirmMember() {
    setupData();
  }

  handleQuitPlan() {
    bool isBlock = false;
    AwesomeDialog(
            context: context,
            dialogType: DialogType.question,
            btnOkColor: Colors.deepOrangeAccent,
            btnOkText: 'Rời khỏi',
            btnOkOnPress: () {
              onQuitPlan(isBlock);
            },
            body: StatefulBuilder(
              builder: (context, setState) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Text(
                      'Rời khỏi ${_planDetail!.name}',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    Row(
                      children: [
                        Checkbox(
                          activeColor: primaryColor,
                          value: isBlock,
                          onChanged: (value) {
                            setState(() {
                              isBlock = !isBlock;
                            });
                          },
                        ),
                        SizedBox(
                          width: 55.w,
                          child: const Text(
                            'Ngăn mọi người mời bạn tham gia lại chuyến đi này',
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                                fontFamily: 'NotoSans',
                                color: Colors.grey,
                                fontSize: 15),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            btnCancelText: 'Huỷ',
            btnCancelColor: Colors.blue,
            btnCancelOnPress: () {})
        .show();
  }

  onQuitPlan(bool isBlock) async {
    final memberId = _planMembers
        .firstWhere((element) =>
            element.accountId == sharedPreferences.getInt('userId'))
        .memberId;
    final rs = await _planService.removeMember(memberId, isBlock, context);
    if (rs != 0) {
      AwesomeDialog(
              context: context,
              animType: AnimType.leftSlide,
              dialogType: DialogType.info,
              padding: const EdgeInsets.all(12),
              title: 'Đã rời khỏi chuyến đi',
              titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSans'))
          .show();

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            PageTransition(
                child: const TabScreen(pageIndex: 1),
                type: PageTransitionType.rightToLeft),
            (route) => false);
      });
    }
  }

  handleCancelPlan() {
    AwesomeDialog(
            context: context,
            animType: AnimType.leftSlide,
            dialogType: DialogType.question,
            title: 'Bạn có chắc chắn muốn huỷ kế hoạch "${_planDetail!.name}"',
            titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSans'),
            padding: const EdgeInsets.all(10),
            btnOkColor: Colors.deepOrangeAccent,
            btnOkOnPress: onCancelPlan,
            btnOkText: 'Có',
            btnCancelColor: Colors.blue,
            btnCancelOnPress: () {},
            btnCancelText: 'Không')
        .show();
  }

  onCancelPlan() async {
    int? rs = await _planService.cancelPlan(widget.planId, context);
    if (rs != 0) {
      AwesomeDialog(
              context: context,
              animType: AnimType.leftSlide,
              dialogType: DialogType.info,
              padding: const EdgeInsets.all(12),
              title: 'Đã huỷ kế hoạch "${_planDetail!.name}"',
              titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSans'))
          .show();

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            PageTransition(
                child: const TabScreen(pageIndex: 1),
                type: PageTransitionType.rightToLeft),
            (route) => false);
      });
    }
  }

  onPublicizePlan() async {
    if (_planDetail!.memberCount! == 0) {
      final rs = await AwesomeDialog(
          context: context,
          animType: AnimType.bottomSlide,
          dialogType: DialogType.info,
          title:
              'Bạn phải tham gia chuyến đi này để có thể công khai chuyến đi',
          titleTextStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          btnOkColor: Colors.blue,
          btnOkOnPress: () {
            onJoinPlan(true);
          },
          btnOkText: 'Tham gia',
          btnCancelColor: Colors.orange,
          btnCancelText: 'Huỷ',
          btnCancelOnPress: () {
            setState(() {
              _isPublic = false;
            });
          }).show();
      if (rs == null) {
        setState(() {
          _isPublic = false;
        });
      }
    } else {
      if (_planDetail!.joinMethod == 'NONE') {
        handlePublicizePlan(false, null);
      } else {
        final rs = await _planService.updateJoinMethod(
            _planDetail!.id!, 'NONE', context);
        if (rs) {
          setState(() {
            _planDetail!.joinMethod = 'NONE';
          });
        }
      }
    }
  }

  handlePublicizePlan(bool isFromJoinScreen, int? amount) async {
    await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white.withOpacity(0.94),
        builder: (ctx) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cách chia sẻ chuyến đi',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSans'),
                  ),
                  SizedBox(
                    height: 1.h,
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: InkWell(
                        onTap: () async {
                          final rs = await _planService.updateJoinMethod(
                              _planDetail!.id!, 'INVITE', context);
                          if (rs) {
                            setState(() {
                              _planDetail!.joinMethod = 'INVITE';
                            });
                            Navigator.of(context).pop();
                            if (isFromJoinScreen) {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (ctx) => SuccessPaymentScreen(
                                            amount: amount!,
                                            planId: widget.planId,
                                          )),
                                  (route) => false);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.withOpacity(0.7)),
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Mời',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey),
                              )
                            ],
                          ),
                        ),
                      )),
                      SizedBox(
                        width: 2.h,
                      ),
                      Expanded(
                          child: InkWell(
                        onTap: () async {
                          final rs = await _planService.updateJoinMethod(
                              _planDetail!.id!, 'SCAN', context);
                          if (rs) {
                            setState(() {
                              _planDetail!.joinMethod = 'SCAN';
                            });
                            Navigator.of(context).pop();
                            if (isFromJoinScreen) {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (ctx) => SuccessPaymentScreen(
                                            amount: amount!,
                                            planId: widget.planId,
                                          )),
                                  (route) => false);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.orange.withOpacity(0.7)),
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.qr_code,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'QR',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey),
                              )
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ));
  }

  handleHistoryOrder() {
    Navigator.push(
        context,
        PageTransition(
            child: HistoryOrderScreen(
              planId: widget.planId,
            ),
            type: PageTransitionType.rightToLeft));
  }

  onClonePlan() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          height: 10.h,
          child: const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
    final location =
        await _locationService.GetLocationById(_planDetail!.locationId!);
    String? locationName = sharedPreferences.getString('plan_location_name');
    if (locationName != null) {
      Navigator.of(context).pop();
      Utils().handleAlreadyDraft(context, location!, locationName, true, _planDetail);
    } else {
      Utils().setUpDataClonePlan(_planDetail!);
      Navigator.of(context).pop();
      Navigator.push(
          context,
          PageTransition(
              child: SelectComboDateScreen(location: location!, isCreate: true, isClone: true,),
              type: PageTransitionType.rightToLeft));
    }
  }
}
