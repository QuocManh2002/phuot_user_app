import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer2/sizer2.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/urls.dart';
import '../../helpers/goong_request.dart';
import '../../helpers/image_handler.dart';
import '../../helpers/util.dart';
import '../../service/traveler_service.dart';
import '../../view_models/customer.dart';
import '../../view_models/plan_viewmodels/search_start_location_result.dart';
import '../../widgets/style_widget/button_style.dart';
import '../../widgets/style_widget/text_form_field_widget.dart';
import '../authentication_screen/select_default_address.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key, required this.traveler, required this.callback});
  final TravelerViewModel traveler;
  final void Function() callback;

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  XFile? myImage;
  String? avatarLink;
  final CustomerService _customerService = CustomerService();

  bool isMale = true;
  PointLatLng? _selectedAddressLatLng;

  @override
  void initState() {
    super.initState();
    avatarLink = widget.traveler.avatarUrl;
    nameController.text = widget.traveler.name;
    isMale = widget.traveler.isMale;
    _selectedAddressLatLng = widget.traveler.defaultCoordinate;
    addressController.text =
        widget.traveler.defaultAddress ?? 'Không có địa chỉ';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
            style: elevatedButtonStyle,
            onPressed: () async {
              final rs = await _customerService.updateTravelerProfile(
                  TravelerViewModel(
                      id: widget.traveler.id,
                      name: nameController.text,
                      isMale: isMale,
                      prestigePoint: widget.traveler.prestigePoint,
                      avatarUrl: '$baseBucketImage$avatarLink',
                      phone: widget.traveler.phone,
                      balance: widget.traveler.balance,
                      defaultAddress: addressController.text,
                      defaultCoordinate: _selectedAddressLatLng));
              if (rs != null) {
                if (_selectedAddressLatLng != null) {
                  Utils().saveDefaultAddressToSharedPref(
                      addressController.text, _selectedAddressLatLng!);
                }
                AwesomeDialog(
                    // ignore: use_build_context_synchronously
                    context: context,
                    animType: AnimType.bottomSlide,
                    dialogType: DialogType.success,
                    title: 'Cập nhật thông tin thành công',
                    titleTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSans',
                    )).show();

                Future.delayed(const Duration(seconds: 1), () {
                  widget.callback();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                });
              }
            },
            child: const Text('Lưu thông tin')),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 5.h,
              ),
              InkWell(
                splashColor: Colors.transparent,
                onTap: () async {
                  final String? avatarPath =
                      await ImageHandler().handlePickImage(context);
                  if (avatarPath != null) {
                    setState(() {
                      avatarLink = avatarPath;
                    });
                  }
                },
                child: Container(
                  width: 100.w,
                  alignment: Alignment.center,
                  child: Container(
                      height: 20.h,
                      width: 20.h,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: CachedNetworkImage(
                        height: 20.h,
                        width: 20.h,
                        fit: BoxFit.cover,
                        key: UniqueKey(),
                        placeholder: (context, url) =>
                            Image.memory(kTransparentImage),
                        errorWidget: (context, url, error) => SvgPicture.asset(
                          widget.traveler.isMale
                              ? maleDefaultAvatar
                              : femaleDefaultAvatar,
                          fit: BoxFit.cover,
                        ),
                        imageUrl: '$baseBucketImage$avatarLink',
                      )),
                ),
              ),
              SizedBox(
                height: 5.h,
              ),
              defaultTextFormField(
                controller: nameController,
                inputType: TextInputType.name,
                text: 'Tên người dùng',
                hinttext: 'Nguyễn Văn A',
                maxLength: 30,
                onValidate: (value) {
                  if (value!.isEmpty) {
                    return "Tên của người dùng không được để trống";
                  } else if (value.length < 4 || value.length > 30) {
                    return "Tên của người dùng phải có độ dài từ 4-30 kí tự";
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 3.h,
              ),
              TextFormFieldWithLength(
                readonly: true,
                controller: addressController,
                inputType: TextInputType.streetAddress,
                text: 'Địa chỉ',
                hinttext: '113 Hồng Lĩnh, ...',
                maxLength: 120,
                maxline: 3,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => SelectDefaultAddress(
                            callback: callback,
                          )));
                },
                onValidate: (value) {
                  if (value!.isEmpty) {
                    return "Địa chỉ mặc định không được để trống";
                  } else if (value.length < 20 || value.length > 120) {
                    return "Địa chỉ mặc định phải có độ dài từ 20-120 kí tự";
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 2.h,
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Giới tính",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 1.h,
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          isMale = true;
                        });
                      },
                      child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: isMale
                                  ? primaryColor.withOpacity(0.2)
                                  : Colors.white,
                              border: Border.all(color: primaryColor, width: 1),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8))),
                          child: const Text(
                            "Nam",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          )),
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          isMale = false;
                        });
                      },
                      child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: !isMale
                                  ? primaryColor.withOpacity(0.2)
                                  : Colors.white,
                              border: Border.all(color: primaryColor, width: 1),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8))),
                          child: const Text(
                            "Nữ",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }

  callback(SearchStartLocationResult? selectedAddress,
      PointLatLng? selectedLatLng) async {
    if (selectedAddress != null) {
      if (selectedAddress.address.length < 3 ||
          selectedAddress.address.length > 120) {
        handleInvalidAddress();
      } else {
        setState(() {
          addressController.text = selectedAddress.address;
          _selectedAddressLatLng =
              PointLatLng(selectedAddress.lat, selectedAddress.lng);
        });
      }
    } else {
      var result = await getPlaceDetail(selectedLatLng!);
      if (result != null) {
        if (result['results'][0]['formatted_address'].length < 3 ||
            result['results'][0]['formatted_address'].length > 120) {
          handleInvalidAddress();
        } else {
          setState(() {
            _selectedAddressLatLng = selectedLatLng;
            addressController.text = result['results'][0]['formatted_address'];
          });
        }
      }
    }
  }

  handleInvalidAddress() => AwesomeDialog(
        context: context,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        btnOkColor: Colors.amber,
        btnOkOnPress: () {},
        btnOkText: 'OK',
        title: 'Độ dài địa chỉ mặc định phải từ 3 - 120 ký tự',
        titleTextStyle: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSans'),
        animType: AnimType.leftSlide,
        dialogType: DialogType.warning,
      ).show();
}
