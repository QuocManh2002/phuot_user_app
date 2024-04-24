import 'package:flutter/material.dart';
import 'package:greenwheel_user_app/core/constants/colors.dart';
import 'package:greenwheel_user_app/screens/plan_screen/select_emergency_detail_service.dart';
import 'package:greenwheel_user_app/view_models/location_viewmodels/emergency_contact.dart';
import 'package:sizer2/sizer2.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactView extends StatelessWidget {
  const EmergencyContactView({super.key, required this.emergency});
  final EmergencyContactViewModel emergency;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => SelectEmergencyDetailService(
                emergency: emergency,
                index: 1,
                isView: true,
                callback: () {})));
      },
      child: Container(
        width: 72.w,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFFf2f2f2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60.w,
                  child: Text(
                    emergency.name ?? 'Không có thông tin',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 0.5.h,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.call,
                      color: Colors.grey,
                    ),
                    SizedBox(
                      width: 1.h,
                    ),
                    Text(
                      emergency.phone == null
                          ? 'Không có thông tin'
                          : emergency.phone!,
                      style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 16,
                          color: Colors.grey),
                    )
                  ],
                ),
                SizedBox(
                  height: 0.5.h,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.home,
                      color: Colors.grey,
                    ),
                    SizedBox(
                      width: 1.h,
                    ),
                    SizedBox(
                      width: 50.w,
                      child: Text(
                        emergency.address == null
                            ? 'Không có thông tin'
                            : emergency.address!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 16,
                            color: Colors.grey),
                      ),
                    )
                  ],
                )
              ],
            ),
            const Spacer(),
            IconButton(
                onPressed: () async {
                  final Uri url = Uri(
                      scheme: 'tel', path: '0${emergency.phone!.substring(3)}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                icon: const Icon(
                  Icons.call,
                  color: primaryColor,
                  size: 40,
                )),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
