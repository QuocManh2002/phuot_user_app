import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phuot_app/core/constants/colors.dart';
import 'package:sizer2/sizer2.dart';
class TabIconButton extends StatelessWidget {
  const TabIconButton(
      {super.key,
      required this.index,
      required this.isSelected,
      required this.iconDefaultUrl,
      required this.iconSelectedUrl,
      this.hasHeight,
      required this.text});
  final String text;
  final bool isSelected;
  final int index;
  final String iconDefaultUrl;
  final String iconSelectedUrl;
  final bool? hasHeight;


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 11.h,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 3,
            color: Colors.black12,
            offset: Offset(2, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 12,),
          SvgPicture.asset(
            isSelected ? iconSelectedUrl : iconDefaultUrl,
            height: 30,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 4,),
          SizedBox(
            child: Text(
              text,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'NotoSans',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : primaryColor),
            ),
          ),
          

        ],
      ),
    );
  }
}
