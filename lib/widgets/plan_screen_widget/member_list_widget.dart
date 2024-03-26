import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:greenwheel_user_app/constants/colors.dart';
import 'package:greenwheel_user_app/constants/urls.dart';
import 'package:greenwheel_user_app/view_models/plan_member.dart';
import 'package:sizer2/sizer2.dart';
import 'package:transparent_image/transparent_image.dart';

class MemberListWidget extends StatelessWidget {
  const MemberListWidget(
      {super.key, required this.members, required this.onRemoveMember});
  final List<PlanMemberViewModel> members;
  final void Function(int memberId, bool isBlock) onRemoveMember;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 100.w,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.5),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              width: 10.h,
              height: 6,
            ),
            SizedBox(
              height: 1.h,
            ),
            for (final mem in members)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: 100.w,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      color: Colors.white),
                  child: Row(
                    children: [
                      Container(
                          height: 6.h,
                          width: 6.h,
                          decoration:
                              const BoxDecoration(shape: BoxShape.circle),
                          clipBehavior: Clip.hardEdge,
                          child: CachedNetworkImage(
                            key: UniqueKey(),
                            height: 6.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            imageUrl: mem.imageUrl ?? defaultUserAvatarLink,
                            placeholder: (context, url) =>
                                Image.memory(kTransparentImage),
                            errorWidget: (context, url, error) =>
                                FadeInImage.assetNetwork(
                              height: 6.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: '',
                              image: empty_plan,
                            ),
                          )),
                      SizedBox(
                        width: 1.h,
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 50.w,
                              child: Text(
                                '${mem.name} (${mem.companions == null ? 1 : mem.companions!.length + 1})',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '0${mem.phone.substring(3)}',
                              style: const TextStyle(fontSize: 19),
                            )
                          ]),
                      const Spacer(),
                      mem.accountType == 2
                          ? Container()
                          : mem.accountType == 3
                              ? PopupMenuButton(
                                  itemBuilder: (ctx) => [
                                    if(mem.companions != null)
                                    const PopupMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info,
                                            color: primaryColor,
                                            size: 32,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            'Chi tiết',
                                            style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 18),
                                          )
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 1,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.close,
                                            color: Colors.blueAccent,
                                            size: 32,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            'Xoá',
                                            style: TextStyle(
                                                color: Colors.blueAccent,
                                                fontSize: 18),
                                          )
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 2,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.block,
                                            color: redColor,
                                            size: 32,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            'Chặn',
                                            style: TextStyle(
                                                color: redColor, fontSize: 18),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 0) {
                                      if (mem.companions != null) {
                                        List<String> names = [mem.name];
                                        for (final name in mem.companions!) {
                                          names.add(name);
                                        }
                                        showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                                  content: SizedBox(
                                                    width: 100.w,
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        for (final name
                                                            in names)
                                                          Container(
                                                            width: 100.w,
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        2.h,
                                                                    vertical:
                                                                        1.h),
                                                            decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.only(
                                                                    topLeft: Radius.circular(name == names.first
                                                                        ? 12
                                                                        : 0),
                                                                    topRight: Radius.circular(name == names.first
                                                                        ? 12
                                                                        : 0),
                                                                    bottomLeft: Radius.circular(name == names.last
                                                                        ? 12
                                                                        : 0),
                                                                    bottomRight: Radius.circular(name == names.last
                                                                        ? 12
                                                                        : 0)),
                                                                color: names.indexOf(name).isOdd
                                                                    ? Colors.white
                                                                    : lightPrimaryTextColor),
                                                            child: Text(
                                                              '${names.indexOf(name) + 1}. $name',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black87,
                                                                fontFamily:
                                                                    'NotoSans',
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .clip,
                                                            ),
                                                          )
                                                      ],
                                                    ),
                                                  ),
                                                  title: const Text(
                                                    'Chi tiết thành viên',
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'NotoSans'),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                        style: const ButtonStyle(
                                                            foregroundColor:
                                                                MaterialStatePropertyAll(
                                                                    primaryColor)),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child:
                                                            const Text('Đóng'))
                                                  ],
                                                ));
                                      }
                                    } else if (value == 1) {
                                      AwesomeDialog(
                                              context: context,
                                              animType: AnimType.bottomSlide,
                                              dialogType: DialogType.question,
                                              title:
                                                  'Bạn có chắc chắn muốn xoá tài khoản này khỏi chuyến đi không ?',
                                              titleTextStyle: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                              btnOkColor: Colors.blue,
                                              btnOkText: 'Có',
                                              padding: const EdgeInsets.all(12),
                                              btnOkOnPress: () {
                                                onRemoveMember(
                                                    mem.memberId, false);
                                              },
                                              btnCancelColor: Colors.orange,
                                              btnCancelText: 'Không',
                                              btnCancelOnPress: () {})
                                          .show();
                                    } else {
                                      AwesomeDialog(
                                              context: context,
                                              animType: AnimType.bottomSlide,
                                              dialogType: DialogType.question,
                                              title:
                                                  'Bạn có chắc chắn muốn chặn tài khoản này hay không ?',
                                              titleTextStyle: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                              btnOkColor: Colors.blue,
                                              padding: const EdgeInsets.all(12),
                                              btnOkText: 'Có',
                                              btnOkOnPress: () {
                                                onRemoveMember(
                                                    mem.memberId, true);
                                              },
                                              btnCancelColor: Colors.orange,
                                              btnCancelText: 'Không',
                                              btnCancelOnPress: () {})
                                          .show();
                                    }
                                  },
                                )
                              : const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.star,
                                    color: yellowColor,
                                    size: 30,
                                  ),
                                )
                    ],
                  ),
                ),
              )
          ]),
        ),
      ),
    );
  }
}
