
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sizer2/sizer2.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/urls.dart';
import '../../../helpers/goong_request.dart';
import '../../../helpers/util.dart';
import '../../../main.dart';
import '../../../service/plan_service.dart';
import '../../../view_models/location.dart';
import '../../../view_models/plan_viewmodels/plan_create.dart';
import '../../../view_models/plan_viewmodels/search_start_location_result.dart';
import '../../../widgets/plan_screen_widget/craete_plan_header.dart';
import '../../../widgets/plan_screen_widget/search_location_result_card.dart';
import '../../../widgets/style_widget/button_style.dart';
import '../../../widgets/style_widget/dialog_style.dart';
import '../locate_start_location.dart';
import 'select_start_date_screen.dart';

class SelectStartLocationScreen extends StatefulWidget {
  const SelectStartLocationScreen(
      {super.key,
      required this.isCreate,
      this.plan,
      required this.location,
      required this.isClone});
  final bool isCreate;
  final PlanCreate? plan;
  final LocationViewModel location;
  final bool isClone;

  @override
  State<SelectStartLocationScreen> createState() =>
      _SelectStartLocationScreenState();
}

class _SelectStartLocationScreenState extends State<SelectStartLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  var distanceText = '';
  var durationText = '';
  double? distanceValue;
  double? durationValue;
  List<SearchStartLocationResult> _resultList = [];
  bool isShowResult = false;
  CircleAnnotationManager? _circleAnnotationManagerStart;
  PolylinePoints polylinePoints = PolylinePoints();
  PointLatLng? _selectedLocation;
  String? defaultAddress = '';
  PointLatLng? defaultLatLng;
  bool _isSelectedLocation = false;
  final PlanService _planService = PlanService();

  _getRouteInfo() async {
    var jsonResponse = await getRouteInfo(_selectedLocation!,
        PointLatLng(widget.location.latitude, widget.location.longitude));
    if (jsonResponse != null) {
      setState(() {
        durationText = jsonResponse['routes'][0]['legs'][0]['duration']['text'];
        distanceText = jsonResponse['routes'][0]['legs'][0]['distance']['text'];
        durationValue =
            jsonResponse['routes'][0]['legs'][0]['duration']['value'] / 3600;
        distanceValue =
            jsonResponse['routes'][0]['legs'][0]['distance']['value'] / 1000;
      });
      if (widget.plan == null) {
        sharedPreferences.setString('plan_duration_text', durationText);
        sharedPreferences.setString('plan_distance_text', distanceText);
        sharedPreferences.setDouble('plan_duration_value', durationValue!);
        sharedPreferences.setDouble('plan_distance_value', distanceValue!);
      } else {
        widget.plan?.travelDuration = DateFormat.Hm().format(DateTime(
          0,
          0,
          0,
        ).add(Duration(seconds: (durationValue! * 3600).toInt())));
        widget.plan?.travelDistanceText = distanceText;
        widget.plan?.travelDurationText = durationText;
        widget.plan?.travelDistanceValue = distanceValue;
        widget.plan?.travelDurationValue = durationValue;
      }
    }
  }

  _onSelectLocation(PointLatLng selectedLocation) async {
    if (!await Utils().checkLoationInSouthSide(
        lon: selectedLocation.longitude, lat: selectedLocation.latitude)) {
      DialogStyle().basicDialog(
          // ignore: use_build_context_synchronously
          context: context,
          title: 'Xin hãy chọn địa điểm trong lãnh thổ Việt Nam',
          type: DialogType.warning);
    } else {
      setState(() {
        _isSelectedLocation = true;
      });
      _selectedLocation = selectedLocation;
      _getRouteInfo();
      if (widget.plan == null) {
        sharedPreferences.setDouble(
            'plan_start_lat', _selectedLocation!.latitude);
        sharedPreferences.setDouble(
            'plan_start_lng', _selectedLocation!.longitude);
      } else {
        widget.plan?.departCoordinate = _selectedLocation;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    defaultAddress = sharedPreferences.getString('defaultAddress');
    final defaultCoordinate =
        sharedPreferences.getStringList('defaultCoordinate');
    defaultLatLng = PointLatLng(double.parse(defaultCoordinate![0]),
        double.parse(defaultCoordinate[1]));
    if (widget.isCreate) {
      setUpDataCreate();
    } else {
      setUpDataUpdate();
    }
  }

  setUpDataUpdate() {
    _searchController.text = widget.plan!.departAddress!;
    _onSelectLocation(widget.plan!.departCoordinate!);
  }

  setUpDataCreate() async {
    double? planDistance = sharedPreferences.getDouble('plan_distance_value');
    if (widget.isClone) {
      _searchController.selection =
          TextSelection.fromPosition(const TextPosition(offset: 0));
    }
    if (planDistance != null) {
      double? planDuration = sharedPreferences.getDouble('plan_duration_value');
      setState(() {
        durationValue = planDuration!;
        distanceValue = planDistance;
      });
    }
    double? startLat = sharedPreferences.getDouble('plan_start_lat');
    if (startLat != null) {
      double? startLng = sharedPreferences.getDouble('plan_start_lng');
      _selectedLocation = PointLatLng(startLat, startLng!);
      String? tempText = sharedPreferences.getString('plan_distance_text');
      if (tempText != null) {
        distanceText = sharedPreferences.getString('plan_distance_text')!;
        distanceValue = sharedPreferences.getDouble('plan_distance_value');
        durationText = sharedPreferences.getString('plan_duration_text')!;
        durationValue = sharedPreferences.getDouble('plan_duration_value');
      } else {
        _onSelectLocation(_selectedLocation!);
      }

      setState(() {
        _searchController.text =
            sharedPreferences.getString('plan_start_address')!;
        _isSelectedLocation = true;
      });
    }
  }

  onSearchLocation() async {
    if (_searchController.text.trim().isEmpty) {
      DialogStyle().basicDialog(
          context: context,
          title: 'Hãy nhập nội dung tìm kiếm',
          type: DialogType.warning);
    } else {
      var result = await getSearchResult(_searchController.text);
      if (result == [] || result == null) {
        DialogStyle().basicDialog(
            // ignore: use_build_context_synchronously
            context: context,
            title: 'Không tìm thấy địa điểm',
            desc: 'Hãy tìm kiếm địa điểm khác',
            type: DialogType.warning);
      } else {
        List<SearchStartLocationResult> resultList =
            List<SearchStartLocationResult>.from(result["results"]
                .map((e) => SearchStartLocationResult.fromJson(e))).toList();
        setState(() {
          _resultList = resultList;
          isShowResult = true;
        });
      }
    }
  }

  Widget buildMapInfoWidget() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: primaryColor, width: 1.5),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          boxShadow: const [
            BoxShadow(blurRadius: 1, offset: Offset(2, 4), color: Colors.black)
          ]),
      child: Column(children: [
        SizedBox(
          height: 1.h,
        ),
        Text(
          'Khoảng cách: $distanceText',
          style: const TextStyle(fontSize: 16),
        ),
        SizedBox(
          height: 1.h,
        ),
        Text(
          'Thời gian di chuyển: $durationText (dự kiến)',
          style: const TextStyle(fontSize: 16),
        ),
        SizedBox(
          height: 1.h,
        ),
      ]),
    );
  }

  callback(PointLatLng? point, String? address) async {
    setState(() {
      _searchController.text = address!;
    });
    _onSelectLocation(point!);
    if (widget.plan == null) {
      sharedPreferences.setString('plan_start_address', _searchController.text);
    } else {
      widget.plan?.departAddress = _searchController.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Lên kế hoạch'),
        leading: BackButton(
          onPressed: () {
            _planService.handleQuitCreatePlanScreen(() {
              Navigator.of(context).pop();
            }, context);
          },
        ),
        actions: [
          InkWell(
            onTap: () {
              _planService.handleShowPlanInformation(
                  context, widget.location, widget.isClone, widget.plan);
            },
            overlayColor: const MaterialStatePropertyAll(Colors.transparent),
            child: Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                backpack,
                fit: BoxFit.fill,
                height: 32,
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 2.w, bottom: 3.h, right: 2.w),
        child: Column(
          children: [
            const CreatePlanHeader(
                stepNumber: 1, stepName: 'Địa điểm xuất phát'),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: const BorderRadius.all(Radius.circular(14))),
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.streetAddress,
                cursorColor: primaryColor,
                maxLines: 1,
                autofocus: true,
                onTap: () {},
                decoration: InputDecoration(
                    suffixIcon: IconButton(
                        onPressed: onSearchLocation,
                        icon: const Icon(
                          Icons.search,
                          color: primaryColor,
                          size: 32,
                        )),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(14))),
                    border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(14)))),
              ),
            ),
            SizedBox(
              height: 1.h,
            ),
            InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              onTap: () {
                setState(() {
                  _searchController.text =
                      defaultAddress == null || defaultAddress!.isEmpty
                          ? 'Không có dữ liệu'
                          : defaultAddress!;
                });
                if (widget.plan == null) {
                  sharedPreferences.setString(
                      'plan_start_address',
                      defaultAddress == null || defaultAddress!.isEmpty
                          ? 'Không có dữ liệu'
                          : defaultAddress!);
                } else {
                  widget.plan?.departAddress =
                      defaultAddress == null || defaultAddress!.isEmpty
                          ? 'Không có dữ liệu'
                          : defaultAddress;
                }
                _onSelectLocation(defaultLatLng!);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(14),
                  ),
                  border:
                      Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 3,
                      color: Colors.black12,
                      offset: Offset(1, 3),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(children: [
                    Icon(Icons.my_location,
                        color: redColor.withOpacity(0.8), size: 32),
                    SizedBox(
                      width: 2.w,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 4,
                        ),
                        const Text(
                          'Vị trí mặc định',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          width: 75.w,
                          child: Text(
                            defaultAddress == null || defaultAddress!.isEmpty
                                ? 'Không có dữ liệu'
                                : defaultAddress!,
                            style: const TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        )
                      ],
                    )
                  ]),
                ),
              ),
            ),
            if (isShowResult)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.5), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 3,
                        color: Colors.black12,
                        offset: Offset(1, 3),
                      )
                    ],
                  ),
                  child: Column(children: [
                    for (final rs in _resultList)
                      InkWell(
                          onTap: () async {
                            if (_circleAnnotationManagerStart != null) {
                              await _circleAnnotationManagerStart!.deleteAll();
                            }
                            await _onSelectLocation(
                                PointLatLng(rs.lat, rs.lng));

                            setState(() {
                              isShowResult = false;
                              _searchController.text = rs.address;
                            });
                          },
                          child: SearchLocationResultCard(
                            item: rs,
                            list: _resultList,
                          ))
                  ]),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => LocateStartLocation(
                            location: widget.location,
                            callback: callback,
                          )));
                },
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(14),
                    ),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.5), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 3,
                        color: Colors.black12,
                        offset: Offset(1, 3),
                      )
                    ],
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(children: [
                      const Icon(
                        Icons.map,
                        size: 32,
                      ),
                      SizedBox(
                        width: 2.w,
                      ),
                      const Text(
                        'Chọn từ bản đồ',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      )
                    ]),
                  ),
                ),
              ),
            ),
            if (_isSelectedLocation)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.5), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 3,
                        color: Colors.black12,
                        offset: Offset(1, 3),
                      )
                    ],
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(children: [
                      const Icon(
                        Icons.directions_car,
                        size: 32,
                      ),
                      SizedBox(
                        width: 2.w,
                      ),
                      const Text(
                        'Quãng đường di chuyển',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        distanceText == '' || distanceText == 'null'
                            ? ''
                            : distanceText,
                        style: const TextStyle(fontSize: 15),
                      ),
                      SizedBox(
                        width: 1.h,
                      )
                    ]),
                  ),
                ),
              ),
            if (_isSelectedLocation)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.5), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 3,
                        color: Colors.black12,
                        offset: Offset(1, 3),
                      )
                    ],
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(children: [
                      const Icon(
                        Icons.watch_later,
                        size: 32,
                      ),
                      SizedBox(
                        width: 2.w,
                      ),
                      const Text(
                        'Thời gian di chuyển',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        durationText,
                        style: const TextStyle(fontSize: 15),
                      ),
                      SizedBox(
                        width: 1.h,
                      )
                    ]),
                  ),
                ),
              )
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        child: ElevatedButton(
          style: elevatedButtonStyle,
          onPressed: () {
            if (durationText.isEmpty) {
              DialogStyle().basicDialog(
                  context: context,
                  title: 'Hãy chọn địa điểm xuất phát cho chuyến đi',
                  type: DialogType.warning);
            } else {
              Navigator.push(
                  context,
                  PageTransition(
                      child: SelectStartDateScreen(
                        isCreate: widget.isCreate,
                        location: widget.location,
                        plan: widget.plan,
                        isClone: widget.isClone,
                      ),
                      type: PageTransitionType.rightToLeft));
            }
          },
          child: const Text('Tiếp tục'),
        ),
      ),
    ));
  }
}
