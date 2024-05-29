import 'dart:convert';
import 'dart:typed_data';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:collection/collection.dart';
import 'package:dart_jts/dart_jts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:greenwheel_user_app/screens/plan_screen/create_plan/select_start_location_screen.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:sizer2/sizer2.dart';

import '../core/constants/colors.dart';
import '../core/constants/combo_date_plan.dart';
import '../core/constants/global_constant.dart';
import '../core/constants/service_types.dart';
import '../core/constants/sessions.dart';
import '../main.dart';
import '../models/holiday.dart';
import '../service/order_service.dart';
import '../service/product_service.dart';
import '../service/supplier_service.dart';
import '../service/traveler_service.dart';
import '../view_models/customer.dart';
import '../view_models/location.dart';
import '../view_models/plan_viewmodels/plan_create.dart';
import '../view_models/plan_viewmodels/plan_detail.dart';
import '../view_models/plan_viewmodels/plan_schedule.dart';
import '../view_models/plan_viewmodels/plan_schedule_item.dart';
import '../view_models/plan_viewmodels/search_start_location_result.dart';
import '../view_models/product.dart';
import '../widgets/plan_screen_widget/update_order_clone_plan_bottom_sheet.dart';
import '../widgets/style_widget/dialog_style.dart';
import 'goong_request.dart';

class Utils {
  static List<Widget> modelBuilder<M>(
          List<M> models, Widget Function(int index, M model) builder) =>
      models
          .asMap()
          .map<int, Widget>(
              (index, model) => MapEntry(index, builder(index, model)))
          .values
          .toList();

  TimeOfDay convertStringToTime(String timeString) {
    final initialDateTime = DateFormat.Hms().parse(timeString);
    return TimeOfDay.fromDateTime(initialDateTime);
  }

  void clearPlanSharePref() {
    sharedPreferences.setInt("planId", 0);
    sharedPreferences.remove('plan_number_of_member');
    sharedPreferences.remove("plan_combo_date");
    sharedPreferences.remove("plan_start_lat");
    sharedPreferences.remove("plan_start_lng");
    sharedPreferences.remove("plan_distance_text");
    sharedPreferences.remove("plan_duration_text");
    sharedPreferences.remove("plan_distance_value");
    sharedPreferences.remove("plan_duration_value");
    sharedPreferences.remove('plan_start_date');
    sharedPreferences.remove('plan_end_date');
    sharedPreferences.remove('plan_schedule');
    sharedPreferences.remove('plan_saved_emergency');
    sharedPreferences.remove('numOfExpPeriod');
    sharedPreferences.remove("plan_departureTime");
    sharedPreferences.remove('plan_departureDate');
    sharedPreferences.remove('plan_closeRegDate');
    sharedPreferences.remove('plan_budget');
    sharedPreferences.remove('plan_name');
    sharedPreferences.remove('plan_start_address');
    sharedPreferences.remove('plan_temp_order');
    sharedPreferences.remove('selectedIndex');
    sharedPreferences.remove('plan_weight');
    sharedPreferences.remove('plan_note');
    sharedPreferences.remove('plan_surcharge');
    sharedPreferences.remove('notAskScheduleAgain');
    sharedPreferences.remove('initNumOfExpPeriod');
    sharedPreferences.remove('plan_max_member_weight');
    sharedPreferences.remove('plan_location_name');
    sharedPreferences.remove('plan_location_id');
    sharedPreferences.remove('plan_arrivedTime');
  }

  Future<String> getImageBase64Encoded(String imageUrl) async {
    Uint8List rsBytes;
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      rsBytes = response.bodyBytes;
      return base64Encode(rsBytes);
    } else {
      throw Exception('Failed to load image: $imageUrl');
    }
  }

  bool checkTimeAfterNow1Hour(TimeOfDay time, DateTime dateTime) {
    return dateTime
        .add(Duration(hours: time.hour))
        .add(Duration(minutes: time.minute))
        .isAfter(DateTime.now()
            .add(const Duration(days: 7))
            .add(const Duration(minutes: 59)));
  }

  Future<bool> checkLoationInSouthSide(
      {required double lon, required double lat}) async {
    String geoString =
        await rootBundle.loadString('assets/geojson/southside.wkt');
    var factory = GeometryFactory.withPrecisionModelSrid(
        PrecisionModel.fromType(PrecisionModel.FLOATING), 4326);
    var reader = WKTReader.withFactory(factory);
    var features = reader.read(geoString);
    var coordinate = Coordinate(lon, lat);
    var point = factory.createPoint(coordinate);
    return features!.contains(point);
  }

  saveDefaultAddressToSharedPref(
      String addressText, PointLatLng addressLatLng) {
    sharedPreferences.setString('defaultAddress', addressText);
    sharedPreferences.setStringList('defaultCoordinate', [
      addressLatLng.latitude.toString(),
      addressLatLng.longitude.toString()
    ]);
  }

  showFullyActivityTimeDialog(BuildContext context) {
    AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        btnOkColor: Colors.orange,
        btnOkText: 'Ok',
        btnOkOnPress: () {},
        body: const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Đã đủ thời gian quy định cho hoạt động của ngày này',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        )).show();
  }

  bool isValidSentence(String sentence) {
    List<String> words = sentence.split(' ');
    Map<String, int> wordFrequency = {};
    for (String word in words) {
      wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
      if (wordFrequency[word]! >= 3) {
        return false;
      }
    }
    return true;
  }

  handleServerException(String content, BuildContext context) {
    AwesomeDialog(
            context: context,
            animType: AnimType.leftSlide,
            dialogType: DialogType.error,
            title: content,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            titleTextStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            btnOkColor: Colors.red,
            btnOkText: 'Ok',
            btnOkOnPress: () {})
        .show();
  }

  getPeriodString(String period) {
    Map rs = {};
    switch (period) {
      case 'MORNING':
        rs = {'text': 'Sáng', 'value': 1};
        break;
      case 'NOON':
        rs = {'text': 'Trưa', 'value': 2};
        break;
      case 'AFTERNOON':
        rs = {'text': 'Chiều', 'value': 3};
        break;
      case 'EVENING':
        rs = {'text': 'Tối', 'value': 4};
        break;
    }
    return rs;
  }

  buildTextFromListString(List<dynamic> list) {
    var rs = '';
    for (final item in list) {
      if (item == list.last || list.length == 1) {
        rs += item!;
      } else {
        rs += '$item, ';
      }
    }
    return rs;
  }

  sortPeriodList(List<dynamic> list) =>
      list.sort((a, b) => a['value'].compareTo(b['value']));

  Widget buildIndicator(int index, int currentIndex) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.bounceInOut,
      height: 0,
      margin: const EdgeInsets.only(left: 16),
      width: currentIndex == index ? 35 : 12,
      decoration: BoxDecoration(
          color: currentIndex == index
              ? primaryColor
              : primaryColor.withOpacity(0.7),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, offset: Offset(2, 3), blurRadius: 3)
          ]),
    );
  }

  getSupplierType(String input) {
    switch (input) {
      case "FOOD_STALL":
        return "quán ăn";
      case "GROCERY_STORE":
        return "tạp hoá";
      case "HOTEL":
        return 'khách sạn';
      case "MOTEL":
        return 'nhà nghỉ';
      case "REPAIR_SHOP":
        return 'tiệm sửa xe';
      case "RESTAURANT":
        return 'nhà hàng';
      case "VEHICLE_RENTAL":
        return "Thuê phương tiện";
    }
  }

  buildServingDatesText(List<dynamic> serveDateIndexes) {
    if (serveDateIndexes.length == 1) {
      return DateFormat('dd/MM').format(DateTime.parse(serveDateIndexes[0]));
    } else {
      return '${DateFormat('dd/MM').format(DateTime.parse(serveDateIndexes[0]))} (+${serveDateIndexes.length - 1} N)';
    }
  }

  getNumOfExpPeriod(DateTime? arrivedTime, int initNumOfExpPeriod,
      DateTime startTime, DateTime? travelDuration, bool isCreate) {
    final startDateTime = DateTime(0, 0, 0, startTime.hour, startTime.minute);
    final arrivedDateTime = arrivedTime ??
        startDateTime
            .add(Duration(hours: travelDuration!.hour))
            .add(Duration(minutes: travelDuration.minute));
    if (arrivedDateTime.isAfter(DateTime(0, 0, 0, 16, 0)) &&
        arrivedDateTime.isBefore(DateTime(0, 0, 1, 6, 0))) {
      if (arrivedDateTime.isBefore(DateTime(0, 0, 0, 20, 0))) {
        return {
          'numOfExpPeriod':
              isCreate ? initNumOfExpPeriod + 1 : initNumOfExpPeriod - 1,
          'isOverDate': false
        };
      } else {
        return {'numOfExpPeriod': initNumOfExpPeriod, 'isOverDate': true};
      }
    } else {
      return {'numOfExpPeriod': initNumOfExpPeriod, 'isOverDate': false};
    }
  }

  isEndAtNoon(PlanCreate? plan) {
    final DateTime arrivedTime = plan == null
        ? DateTime.parse(sharedPreferences.getString('plan_arrivedTime')!)
        : plan.arrivedAt!;
    var dayEqualNight = (plan == null
            ? sharedPreferences.getInt('initNumOfExpPeriod')!
            : plan.numOfExpPeriod)!
        .isEven;
    var arrivedAtNight = arrivedTime.hour >= 20;
    var arrivedAtEvening = !arrivedAtNight && arrivedTime.hour >= 16;
    return (arrivedAtEvening && dayEqualNight) ||
        (!arrivedAtEvening && !dayEqualNight);
  }

  handleUpdatePlanDuration(
      void Function() onOk, void Function() onCancel, BuildContext context) {
    AwesomeDialog(
            context: context,
            animType: AnimType.leftSlide,
            dialogType: DialogType.warning,
            title: 'Thay đổi quan trọng',
            titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSans'),
            desc:
                'Thay đổi này ảnh hưởng đến lịch trình và các thành phần quan trọng của chuyến đi. Đồng ý với thay đổi, chúng tôi sẽ xoá toàn bộ lịch trình và các thành phần liên quan',
            descTextStyle: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'NotoSans',
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            btnOkText: 'Đồng ý',
            btnOkColor: Colors.amber,
            btnOkOnPress: () {
              sharedPreferences.remove('plan_schedule');
              sharedPreferences.remove('plan_surcharge');
              sharedPreferences.remove('plan_temp_order');
              onOk();
            },
            btnCancelColor: Colors.blueAccent,
            btnCancelOnPress: onCancel,
            btnCancelText: 'Huỷ')
        .show();
  }

  isConsecutiveDates(List<DateTime> dates) {
    if (dates.length <= 1) {
      return true;
    }
    dates.sort((a, b) => a.compareTo(b));
    for (int i = 1; i < dates.length; i++) {
      DateTime current = dates[i];
      DateTime previous = dates[i - 1];
      if (current.difference(previous).inDays != 1) {
        return false;
      }
    }
    return true;
  }

  getArrivedTimeFromLocal() {
    final initialDateTime =
        DateTime.parse(sharedPreferences.getString('plan_departureTime')!);
    final startTime =
        DateTime(0, 0, 0, initialDateTime.hour, initialDateTime.minute);
    final arrivedTime = startTime.add(Duration(
        seconds: (sharedPreferences.getDouble('plan_duration_value')! * 3600)
            .ceil()));
    return arrivedTime;
  }

  setUpDataClonePlan(PlanDetail plan, List<bool> options) {
    final OrderService orderService = OrderService();
    sharedPreferences.setString('plan_clone_options', json.encode(options));
    sharedPreferences.setInt('planId', plan.id!);
    sharedPreferences.setString('plan_location_name', plan.locationName!);
    sharedPreferences.setInt('plan_location_id', plan.locationId!);
    sharedPreferences.setInt('maxCombodateValue', plan.numOfExpPeriod!);
    sharedPreferences.setInt(
        'init_plan_number_of_member', plan.maxMemberCount!);

    sharedPreferences.setInt('initNumOfExpPeriod', plan.numOfExpPeriod!);
    sharedPreferences.setInt(
        'plan_combo_date',
        listComboDate
                .firstWhere(
                    (element) => element.duration == plan.numOfExpPeriod)
                .id -
            1);
    sharedPreferences.setInt('plan_number_of_member', plan.maxMemberCount!);
    sharedPreferences.setInt('plan_max_member_weight', plan.maxMemberWeight!);

    sharedPreferences.setDouble('plan_start_lat', plan.startLocationLat!);
    sharedPreferences.setDouble('plan_start_lng', plan.startLocationLng!);
    sharedPreferences.setString('plan_start_address', plan.departureAddress!);
    sharedPreferences.setString(
        'plan_departureTime', plan.utcDepartAt!.toLocal().toString());

    sharedPreferences.setString('plan_name', plan.name!);

    if (options[5]) {
      sharedPreferences.setStringList('selectedIndex',
          plan.savedContacts!.map((e) => e.providerId.toString()).toList());
    }

    if (options[6]) {
      sharedPreferences.setBool('notAskScheduleAgain', false);
      if (options[7]) {
        final availableOrder = plan.orders!
            .where((e) =>
                e.supplier!.isActive! &&
                e.details!.every((element) => element.isAvailable!))
            .toList();
        final list = availableOrder.map((order) {
          final orderDetailGroupList =
              order.details!.groupListsBy((e) => e.productId);
          final orderDetailList =
              orderDetailGroupList.entries.map((e) => e.value.first).toList();
          return orderService.convertToTempOrder(
              order.supplier!,
              order.note ?? "",
              order.type!,
              orderDetailList
                  .map((item) => {
                        'productId': item.productId,
                        'productName': item.productName,
                        'quantity': item.quantity,
                        'partySize': item.partySize,
                        'price': item.price
                      })
                  .toList(),
              order.period!,
              order.serveDates!.map((date) => date.toString()).toList(),
              order.serveDates!
                  .map((date) => DateTime.parse(date.toString())
                      .difference(DateTime(
                          plan.utcStartAt!.toLocal().year,
                          plan.utcStartAt!.toLocal().month,
                          plan.utcStartAt!.toLocal().day,
                          0,
                          0,
                          0))
                      .inDays)
                  .toList(),
              order.uuid,
              order.total! / GlobalConstant().VND_CONVERT_RATE);
        }).toList();
        for (final date in plan.schedule!) {
          for (final item in date) {
            if (item['orderUUID'] != null &&
                !availableOrder
                    .any((element) => element.uuid == item['orderUUID'])) {
              item['orderUUID'] = null;
            }
          }
        }
        sharedPreferences.setString('plan_temp_order', json.encode(list));
      } else {
        sharedPreferences.setString('plan_temp_order', '[]');

        for (final date in plan.schedule!) {
          for (final item in date) {
            if (item['orderUUID'] != null) {
              item['orderUUID'] = null;
            }
          }
        }
      }
      sharedPreferences.setString('plan_schedule', json.encode(plan.schedule));
    }

    if (options[8]) {
      sharedPreferences.setString(
          'plan_surcharge',
          json.encode(
              plan.surcharges!.map((e) => e.toJsonWithoutImage()).toList()));
    }
    sharedPreferences.setString('plan_note', plan.note ?? 'null');
  }

  handleAlreadyDraft(BuildContext context, LocationViewModel location,
      String locationName, bool isClone, PlanDetail? plan, List<bool> options) {
    DialogStyle().basicDialog(
      context: context,
      type: DialogType.question,
      title:
          'Bạn đang có bản nháp chuyến đi tại ${locationName == location.name ? 'địa điểm này' : locationName}',
      desc: 'Bạn có muốn ghi đè chuyến đi đó không ?',
      onOk: () {
        Utils().clearPlanSharePref();
        sharedPreferences.setString('plan_location_name', location.name);
        sharedPreferences.setInt('plan_location_id', location.id);
        if (isClone) {
          setUpDataClonePlan(plan!, options);
        }
        Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => SelectStartLocationScreen(
                  isCreate: true,
                  location: location,
                  isClone: isClone,
                )));
      },
      btnOkColor: Colors.deepOrangeAccent,
      btnOkText: 'Có',
      btnCancelColor: Colors.blueAccent,
      btnCancelText: 'Không',
      onCancel: () {
        if (locationName == location.name) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => SelectStartLocationScreen(
                    isCreate: true,
                    location: location,
                    isClone: isClone,
                  )));
        }
      },
    );
  }

  showInvalidScheduleAndServiceClone(BuildContext context) {
    DialogStyle().basicDialog(
      context: context,
      title: 'Không thể sao chép đơn dịch vụ nếu không sao chép lịch trình',
      type: DialogType.warning,
    );
  }

  getHolidayServingDates(List<Holiday> holidays, List<DateTime> servingDates) {
    List<DateTime> normalServingDates = [];
    List<DateTime> holidayServingDates = [];
    for (final date in servingDates) {
      if (holidays.any((element) =>
          element.from.isBefore(date) && element.to.isAfter(date) ||
          date.isAtSameMomentAs(element.from) ||
          date.isAtSameMomentAs(element.to))) {
        holidayServingDates.add(date);
      } else {
        normalServingDates.add(date);
      }
    }
    return {
      'normalServingDates': normalServingDates,
      'holidayServingDates': holidayServingDates
    };
  }

  updateTempOrder(bool isChangeByMember, int? newMaxMemberCount) async {
    final newMaxMemberCount = sharedPreferences.getInt('plan_number_of_member');
    var orderList =
        json.decode(sharedPreferences.getString('plan_temp_order') ?? '[]');
    final ProductService productService = ProductService();
    final OrderService orderService = OrderService();
    if (isChangeByMember) {
      for (final order in orderList) {
        if (order['type'] == services[1].name) {
          List<ProductViewModel> products = await productService
              .getProductsBySupplierId(order['providerId'], order['period']);
          final result = orderService.getCheapestDetailCheckinOrder(
              products, newMaxMemberCount!);
          final resultGroupBy = result.groupListsBy((element) => element.id);
          var newDetails = [];
          for (final detail in resultGroupBy.values) {
            newDetails.add({
              'productId': detail.first.id,
              'productName': detail.first.name,
              'quantity': detail.length,
              'partySize': detail.first.partySize,
              'price': detail.first.price.toDouble()
            });
          }
          order['newDetails'] = newDetails;
        } else {
          var newDetails = [];
          for (final detail in order['details']) {
            var newDetail = {
              'productId': detail['productId'],
              'productName': detail['productName'],
              'partySize': detail['partySize'],
              'price': detail['price'].toDouble()
            };
            newDetail['quantity'] =
                (newMaxMemberCount! / detail['partySize']).ceil();
            newDetails.add(newDetail);
          }
          order['newDetails'] = newDetails;
        }
        order['newTotal'] = getTempOrderTotal(order, false);
      }
    } else {
      DateTime startDate =
          DateTime.parse(sharedPreferences.getString('plan_start_date')!);
      for (final order in orderList) {
        List<DateTime> servingDates = [];
        for (final index in order['serveDateIndexes']) {
          servingDates.add(startDate.add(Duration(days: index)));
        }
        order['serveDates'] = order['serveDateIndexes']
            .map((e) =>
                startDate.add(Duration(days: e)).toString().split(' ')[0])
            .toList();
        order['newTotal'] = getTempOrderTotal(order, false);
      }
    }
    sharedPreferences.setString('plan_temp_order', json.encode(orderList));
  }

  updateScheduleAndOrder(BuildContext context, void Function() onConfirm,
      bool isChangeDate) async {
    int duration = (sharedPreferences.getInt('initNumOfExpPeriod')! / 2).ceil();
    var schedule =
        json.decode(sharedPreferences.getString('plan_schedule') ?? '[]');
    var tempOrders =
        json.decode(sharedPreferences.getString('plan_temp_order')!);
    final isPlanEndAtNoon = isEndAtNoon(null);
    var newSchedule = [];

    for (int i = 0; i < duration; i++) {
      if (i < duration - 1) {
        newSchedule.add(schedule[i]);
      }
    }
    newSchedule.add(schedule.last);

    var updatedOrders = [];
    var canceledOrders = [];
    for (final order in tempOrders) {
      final newIndexes = [];
      final invalidIndexes = [];
      for (final index in order['serveDateIndexes']) {
        if (order['type'] == services[0].name) {
          if (index < duration - 1) {
            newIndexes.add(index);
          } else if (index == duration - 1 &&
              isPlanEndAtNoon &&
              (order['period'] == sessions[0].enumName ||
                  order['period'] == sessions[1].enumName)) {
            newIndexes.add(index);
          } else {
            invalidIndexes.add(index);
          }
        } else if ((order['type'] == services[1].name ||
                order['type'] == services[2].name) &&
            index < duration - 1) {
          newIndexes.add(index);
        } else {
          invalidIndexes.add(index);
        }
      }
      if (newIndexes.isNotEmpty && newIndexes != order['serveDateIndexes']) {
        final startDate =
            DateTime.parse(sharedPreferences.getString('plan_start_date')!);
        order['newIndexes'] = newIndexes;
        order['newServeDates'] = newIndexes
            .map((e) => startDate.add(Duration(days: e)).toString())
            .toList();
        order['invalidIndexes'] = invalidIndexes;
        order['newTotal'] = getTempOrderTotal(order, true);
        updatedOrders.add(order);
      } else {
        order['cancelReason'] = 'Ngoài ngày phục vụ';
        canceledOrders.add(order);
      }
    }
    final arrivedText = sharedPreferences.getString('plan_arrivedTime');
    if (arrivedText != null) {
      final arrivedTime = DateTime.parse(arrivedText);
      final startSession = sessions.firstWhereOrNull((aTime) =>
              aTime.from <= arrivedTime.hour && aTime.to > arrivedTime.hour) ??
          sessions[0];
      bool endAtNoon = isEndAtNoon(null);
      final endSession = endAtNoon ? sessions[1] : sessions.last;

      for (final item in newSchedule[0]) {
        if (item['orderUUID'] != null) {
          final order =
              tempOrders.firstWhere((e) => e['orderUUID'] == item['orderUUID']);
          final session = sessions
              .firstWhere((element) => element.enumName == order['period']);
          if (session.index < startSession.index) {
            if (updatedOrders
                .any((element) => element['orderUUID'] == item['orderUUID'])) {
              order['newIndexes'].remove(order['newIndexes'].first);
              order['newServeDates'].remove(order['newServeDates'].first);
            } else {
              order['newIndexes'] = order['serveDateIndexes']
                  .remove(order['serveDateIndexes'].first);
              order['newServeDates'] =
                  order['serveDates'].remove(order['serveDates'].first);
              updatedOrders.add(order);
            }
            order['newTotal'] = getTempOrderTotal(order, true);
          }
        }
      }
      for (final item in newSchedule.last) {
        if (item['orderUUID'] != null) {
          final order =
              tempOrders.firstWhere((e) => e['orderUUID'] == item['orderUUID']);
          final session = sessions
              .firstWhere((element) => element.enumName == order['period']);
          if (session.index > endSession.index &&
              (order['type'] == services[0].name ||
                  order['type'] == services[2].name)) {
            if (updatedOrders
                .any((element) => element['orderUUID'] == item['orderUUID'])) {
              order['newIndexes'].remove(order['newIndexes'].last);
              order['newServeDates'].remove(order['newServeDates'].last);
            } else {
              order['newIndexes'] = order['serveDateIndexes']
                  .remove(order['serveDateIndexes'].last);
              order['newServeDates'] =
                  order['serveDates'].remove(order['serveDates'].last);
              updatedOrders.add(order);
            }
            order['newTotal'] = getTempOrderTotal(order, true);
          }
        }
      }
    }
    if (updatedOrders.isNotEmpty || canceledOrders.isNotEmpty) {
      showModalBottomSheet(
        // ignore: use_build_context_synchronously
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => UpdateOrderClonePlanBottomSheet(
          cancelOrders: canceledOrders,
          updatedOrders: updatedOrders,
          onConfirm: () async {
            for (final order in canceledOrders) {
              tempOrders.removeWhere(
                  (element) => element['orderUUID'] == order['orderUUID']);
              for (final date in newSchedule) {
                for (final item in date) {
                  if (item['orderUUID'] == order['orderUUID']) {
                    item['orderUUID'] = null;
                  }
                }
              }
            }
            for (final order in updatedOrders) {
              var temp = tempOrders.firstWhere(
                  (element) => element['orderUUID'] == order['orderUUID']);
              final index = tempOrders.indexOf(temp);
              tempOrders[index]['total'] = order['newTotal'];
              tempOrders[index]['serveDates'] = order['newServeDates'];
              tempOrders[index]['details'] = order['newDetails'];
              tempOrders[index]['serveDateIndexes'] = order['newIndexes'];

              if (isChangeDate && order['type'] == services[1].name) {
                final List<List<DateTime>> splitServeDates =
                    splitCheckInServeDates(order['newServeDates']);
                final endDate = DateTime.parse(
                    sharedPreferences.getString('plan_end_date')!);
                final startDate = DateTime.parse(
                    sharedPreferences.getString('plan_start_date')!);
                for (final dateList in splitServeDates) {
                  if (!newSchedule[dateList.first.difference(startDate).inDays]
                      .any((element) =>
                          element['orderUUID'] == order['orderUUID'])) {
                    await newSchedule[
                            dateList.first.difference(startDate).inDays]
                        .add({
                      'isStarred': false,
                      'shortDescription': 'Check-in',
                      'description': 'Check-in nhà nghỉ/khách sạn',
                      'type': 'CHECKIN',
                      'orderUUID': order['orderUUID'],
                      'duration': '00:30:00'
                    });
                  }
                  if (dateList.last == endDate) {
                    if (!newSchedule.last.any((element) =>
                        element['orderUUID'] == order['orderUUID'] &&
                        element['type'] == 'CHECKOUT')) {
                      await newSchedule.last.add({
                        'isStarred': false,
                        'shortDescription': 'Check-out',
                        'description': 'Check-out nhà nghỉ/khách sạn',
                        'type': 'CHECKOUT',
                        'orderUUID': order['orderUUID'],
                        'duration': '00:15:00'
                      });
                    }
                  } else {
                    final index =
                        dateList.last.difference(startDate).inDays + 1;
                    if (!newSchedule[index].any((element) =>
                        element['orderUUID'] == order['orderUUID'] &&
                        element['type'] == 'CHECKOUT')) {
                      await newSchedule[index].add({
                        'isStarred': false,
                        'shortDescription': 'Check-out',
                        'description': 'Check-out nhà nghỉ/khách sạn',
                        'type': 'CHECKOUT',
                        'orderUUID': order['orderUUID'],
                        'duration': '00:15:00'
                      });
                    }
                  }
                }
              }
              for (int index = 0; index < newSchedule.length; index++) {
                for (final item in newSchedule[index]) {
                  if (item['orderUUID'] != null) {
                    final order = tempOrders.firstWhere(
                        (order) => order['orderUUID'] == item['orderUUID']);
                    if (order['type'] == services[1].name) {
                      if (!(index == newSchedule.length - 1) &&
                          !order['serveDateIndexes'].contains(index)) {
                        item['orderUUID'] = null;
                      }
                    } else {
                      if (!order['serveDateIndexes'].contains(index)) {
                        item['orderUUID'] = null;
                      }
                    }
                  }
                }
              }
              order['newTotal'] = null;
              order['newServeDates'] = null;
              order['newDetails'] = null;
              order['newIndexes'] = null;
              order['invalidIndexes'] = null;
            }
            sharedPreferences.setString(
                'plan_schedule', json.encode(newSchedule));
            sharedPreferences.setString(
                'plan_temp_order', json.encode(tempOrders));
            onConfirm();
          },
        ),
      );
    } else {
      sharedPreferences.setString('plan_schedule', json.encode(newSchedule));
      onConfirm();
    }
  }

  updateProductPrice(BuildContext context, bool isUpdatePlan) async {
    var orders =
        json.decode(sharedPreferences.getString('plan_temp_order') ?? '[]');
    List<double> newPrice = [];
    final SupplierService supplierService = SupplierService();
    final ProductService productService = ProductService();
    List<int> supplierIds = [];
    List<int> productIds = [];
    List<dynamic> invalidOrders = [];
    if (orders.isNotEmpty) {
      for (final order in orders) {
        if (!supplierIds.contains(order['providerId'])) {
          supplierIds.add(order['providerId']);
        }
        for (final detail in order['details']) {
          if (!productIds.contains(detail['productId'])) {
            productIds.add(detail['productId']);
          }
        }
      }
      final invalidSupplierIds =
          await supplierService.getInvalidSupplierByIds(supplierIds, context);

      final invalidProductIds =
          // ignore: use_build_context_synchronously
          await productService.getInvalidProductByIds(productIds, context);
      for (final order in orders) {
        if (invalidSupplierIds.contains(order['providerId'])) {
          order['cancelReason'] = 'Nhà cung cấp không khả dụng';
          invalidOrders.add(order);
        } else if (order['details']
            .any((detail) => invalidProductIds.contains(detail['productId']))) {
          order['cancelReason'] = 'Sản phẩm không khả dụng';
          invalidOrders.add(order);
        }
      }
      if (invalidOrders.isNotEmpty) {
        await AwesomeDialog(
                // ignore: use_build_context_synchronously
                context: context,
                animType: AnimType.leftSlide,
                dialogType: DialogType.infoReverse,
                body: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Thông báo quan trọng',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSans'),
                        ),
                      ),
                      SizedBox(
                        height: 1.h,
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Các đơn hàng sau đã bị huỷ, hãy tạo lại cho chuyến đi thật đầy đủ nhé',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'NotoSans',
                              color: Colors.grey),
                        ),
                      ),
                      SizedBox(
                        height: 1.h,
                      ),
                      for (int index = 0; index < invalidOrders.length; index++)
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 1.h, horizontal: 2.w),
                          decoration: BoxDecoration(
                            color: index.isOdd
                                ? primaryColor.withOpacity(0.1)
                                : lightPrimaryTextColor.withOpacity(0.5),
                            borderRadius: BorderRadius.only(
                              topLeft: index == 0
                                  ? const Radius.circular(10)
                                  : Radius.zero,
                              topRight: index == 0
                                  ? const Radius.circular(10)
                                  : Radius.zero,
                              bottomLeft: index == invalidOrders.length - 1
                                  ? const Radius.circular(10)
                                  : Radius.zero,
                              bottomRight: index == invalidOrders.length - 1
                                  ? const Radius.circular(10)
                                  : Radius.zero,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                invalidOrders[index]['type'] == 'EAT'
                                    ? 'Dùng bữa tại:'
                                    : invalidOrders[index]['type'] == 'VISIT'
                                        ? 'Thuê phương tiện:'
                                        : 'Nghỉ ngơi tại:',
                                style: const TextStyle(
                                    fontSize: 13, fontFamily: 'NotoSans'),
                              ),
                              RichText(
                                  text: TextSpan(
                                      text: invalidOrders[index]
                                          ['providerName'],
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontFamily: 'NotoSans'),
                                      children: [
                                    TextSpan(
                                        text:
                                            '  (${Utils().getPeriodString(invalidOrders[index]['period'])['text']})',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                            fontFamily: 'NotoSans'))
                                  ])),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.clear_outlined,
                                    color: Colors.red,
                                    weight: 1.5,
                                  ),
                                  SizedBox(
                                    width: 1.w,
                                  ),
                                  SizedBox(
                                    width: 60.w,
                                    child: Text(
                                      invalidOrders[index]['cancelReason'],
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        )
                    ],
                  ),
                ),
                btnOkOnPress: () {
                  var schedule = json
                      .decode(sharedPreferences.getString('plan_schedule')!);
                  for (final order in invalidOrders) {
                    for (final date in schedule) {
                      for (final item in date) {
                        if (item['orderUUID'] == order['orderUUID']) {
                          item['orderUUID'] = null;
                        }
                      }
                    }
                    orders.remove(orders.firstWhere(
                        (e) => e['orderUUID'] == order['orderUUID']));
                    sharedPreferences.setString(
                        'plan_schedule', json.encode(schedule));
                  }
                },
                btnOkColor: Colors.blueAccent,
                btnOkText: 'OK')
            .show();
      } else {}
      productIds.sort();
      final products = await productService.getListProduct(productIds);
      newPrice = products.map((e) => e.price.toDouble()).toList();
      for (final order in orders) {
        for (final detail in order['details']) {
          final index = productIds.indexOf(detail['productId']);
          detail['price'] = newPrice[index];
        }
        order['total'] = getTempOrderTotal(order, false);
      }
    }
    sharedPreferences.setString('plan_temp_order', json.encode(orders));
  }

  bool isHoliday(
    DateTime date,
  ) {
    final holidaysText = sharedPreferences.getStringList('HOLIDAYS');
    List<Holiday> holidays =
        holidaysText!.map((e) => Holiday.fromJson(json.decode(e))).toList();
    return holidays.any((element) =>
        element.from.isBefore(date) && element.to.isAfter(date) ||
        date.isAtSameMomentAs(element.from) ||
        date.isAtSameMomentAs(element.to));
  }

  int getHolidayUpPct(String type) {
    switch (type) {
      case 'EAT':
        return sharedPreferences.getInt('HOLIDAY_MEAL_UP_PCT')!;
      case 'CHECKIN':
        return sharedPreferences.getInt('HOLIDAY_LODGING_UP_PCT')!;
      case 'VISIT':
        return sharedPreferences.getInt('HOLIDAY_RIDING_UP_PCT')!;
    }
    return 0;
  }

  getTempOrderTotal(dynamic order, bool isUpdate) {
    final numberHoliday =
        (isUpdate ? order['newServeDates'] : order['serveDates'])
            .where((date) => isHoliday(DateTime.parse(date)))
            .toList()
            .length;
    final upPct = getHolidayUpPct(order['type']);
    if (order['newDetails'] != null) {
      return order['newDetails'].fold(
          0,
          (previousValue, element) =>
              previousValue +
              (element['price'] * element['quantity']) *
                  ((1 + upPct / 100) * numberHoliday +
                      ((isUpdate ? order['newServeDates'] : order['serveDates'])
                              .length -
                          numberHoliday)) /
                  GlobalConstant().VND_CONVERT_RATE);
    } else {
      return order['details'].fold(
          0,
          (previousValue, element) =>
              previousValue +
              (element['price'] * element['quantity']) *
                  ((1 + upPct / 100) * numberHoliday +
                      ((isUpdate ? order['newServeDates'] : order['serveDates'])
                              .length -
                          numberHoliday)) /
                  GlobalConstant().VND_CONVERT_RATE);
    }
  }

  splitCheckInServeDates(List<String> serveDates) {
    List<List<DateTime>> result = [];
    List<DateTime> current = [DateTime.parse(serveDates[0])];
    for (int i = 1; i < serveDates.length; i++) {
      DateTime previousDateTime = DateTime.parse(serveDates[i - 1]);
      DateTime currentDateTime = DateTime.parse(serveDates[i]);
      if (currentDateTime.difference(previousDateTime).inDays == 1) {
        current.add(currentDateTime);
      } else {
        result.add(current);
        current = [currentDateTime];
      }
    }
    result.add(current);
    return result;
  }

  bool isValidPeriodOfOrder(
      PlanSchedule schedule, PlanScheduleItem item, bool isFirstDay) {
    if (item.orderUUID == null) {
      return true;
    } else {
      final orderList =
          json.decode(sharedPreferences.getString('plan_temp_order')!);
      final order =
          orderList.firstWhere((order) => order['orderUUID'] == item.orderUUID);
      final itemIndex = schedule.items.indexOf(item);
      Duration sumActivityTime = const Duration();
      DateTime? startActivityTime;
      for (int i = 0; i < itemIndex; i++) {
        sumActivityTime += schedule.items[i].activityTime!;
      }
      if (isFirstDay) {
        final arrivedTime =
            DateTime.parse(sharedPreferences.getString('plan_arrivedTime')!);
        if (arrivedTime.hour >= 20) {
          startActivityTime = DateTime(0, 0, 0, 6, 0, 0).add(sumActivityTime);
        } else {
          startActivityTime = arrivedTime.add(sumActivityTime);
        }
      } else {
        startActivityTime = DateTime(0, 0, 0, 6, 0, 0).add(sumActivityTime);
      }
      final startActivitySession = sessions.firstWhereOrNull((aTime) =>
              aTime.from <= startActivityTime!.hour &&
              aTime.to > startActivityTime.hour) ??
          sessions[0];
      final orderPeriod =
          sessions.firstWhere((session) => session.enumName == order['period']);
      return startActivitySession.index <= orderPeriod.index;
    }
  }

  handleNonDefaultAddress(void Function() onOk, BuildContext context) {
    DialogStyle().basicDialog(
        context: context,
        type: DialogType.warning,
        title: 'Không tìm thấy địa chỉ mặc định',
        desc: 'Bạn phải thêm địa chỉ mặc định để thực hiện thao tác này',
        btnOkText: 'Thêm',
        onOk: onOk,
        btnCancelColor: Colors.blue,
        btnCancelText: 'Huỷ');
  }

  callbackSelectDefaultLocation(SearchStartLocationResult? selectedAddress,
      PointLatLng? selectedLatLng, BuildContext context) async {
    bool isValid = false;
    final CustomerService customerService = CustomerService();
    String defaultAddress = '';
    if (selectedAddress != null) {
      if (selectedAddress.address.length < 3 ||
          selectedAddress.address.length > 120) {
        DialogStyle().basicDialog(
            context: context,
            title: 'Độ dài địa chỉ mặc định phải từ 3 - 120 ký tự',
            type: DialogType.warning);
      } else {
        // setState(() {
        defaultAddress = selectedAddress.address;
        // });
        isValid = true;
      }
    } else {
      var result = await getPlaceDetail(selectedLatLng!);
      if (result != null) {
        if (result['results'][0]['formatted_address'].length < 3 ||
            result['results'][0]['formatted_address'].length > 120) {
          DialogStyle().basicDialog(
              // ignore: use_build_context_synchronously
              context: context,
              title: 'Độ dài địa chỉ mặc định phải từ 3 - 120 ký tự',
              type: DialogType.warning);
        } else {
          defaultAddress = result['results'][0]['formatted_address'];
          isValid = true;
        }
      }
    }
    if (isValid) {
      final rs = await customerService.updateTravelerProfile(CustomerViewModel(
          id: 0,
          name: sharedPreferences.getString('userName')!,
          isMale: sharedPreferences.getBool('userIsMale')!,
          avatarUrl: sharedPreferences.getString('userAvatarUrl'),
          phone: sharedPreferences.getString('userPhone')!,
          balance: 0,
          defaultAddress: defaultAddress,
          defaultCoordinate: selectedAddress != null
              ? PointLatLng(selectedAddress.lat, selectedAddress.lng)
              : selectedLatLng));
      if (rs != null) {
        Utils().saveDefaultAddressToSharedPref(
            defaultAddress,
            selectedAddress == null
                ? selectedLatLng!
                : PointLatLng(selectedAddress.lat, selectedAddress.lng));
      }
    }
  }

  getMaxSumActivity(PlanSchedule schedule, bool isFirstDay, bool isLastDay) {
    if (isFirstDay) {
      final startTime =
          DateTime.parse(sharedPreferences.getString('plan_arrivedTime')!);
      if (startTime.hour >= 20 || startTime.hour < 6) {
        return GlobalConstant().MAX_SUM_ACTIVITY_TIME;
      } else {
        return DateTime(0, 0, 0, 22, 0)
            .difference(DateTime(0, 0, 0, startTime.hour, startTime.minute));
      }
    } else if (isLastDay) {
      if (isEndAtNoon(null)) {
        return const Duration(hours: 8);
      } else {
        return const Duration(hours: 14);
      }
    } else {
      return GlobalConstant().MAX_SUM_ACTIVITY_TIME;
    }
  }
}
