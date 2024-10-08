import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phuot_app/core/constants/urls.dart';
import 'package:phuot_app/screens/location_screen/location_screen.dart';
import 'package:phuot_app/view_models/location_viewmodels/location_card.dart';
import 'package:sizer2/sizer2.dart';
import 'package:transparent_image/transparent_image.dart';

class FilterLocationCard extends StatelessWidget {
  const FilterLocationCard({super.key, required this.location});
  final LocationCardViewModel location;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => LocationScreen(locationId: location.id)));
      },
      child: Container(
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              blurRadius: 3,
              color: Colors.black12,
              offset: Offset(1, 3),
            )
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        height: 15.h,
        width: double.infinity,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.hardEdge,
          elevation: 2,
          child: Row(children: [
            Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(14)),
                child: CachedNetworkImage(
                    height: 15.h,
                    width: 15.h,
                    fit: BoxFit.cover,
                    imageUrl: '$baseBucketImage${location.imagePaths[0]}',
                    placeholder: (context, url) =>
                        Image.memory(kTransparentImage),
                    errorWidget: (context, url, error) => Image.network(
                          'https://th.bing.com/th/id/R.e61db6eda58d4e57acf7ef068cc4356d?rik=oXCsaP5FbsFBTA&pid=ImgRaw&r=0',
                          height: 15.h,
                          width: 15.h,
                          fit: BoxFit.cover,
                        ))),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  Text(location.name,
                      overflow: TextOverflow.clip,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
               
                  // RatingBar.builder(
                  //     ignoreGestures: true,
                  //     itemSize: 20,
                  //     allowHalfRating: true,
                  //     itemCount: 5,
                  //     initialRating: location.rating.toDouble(),
                  //     maxRating: 5,
                  //     itemBuilder: (context, index) => const Icon(
                  //           Icons.star,
                  //           color: Colors.amber,
                  //         ),
                  //     onRatingUpdate: (_) {}),
               
                  Text(
                    location.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
            SizedBox(width: 1.w,)
          ]),
        ),
      ),
    );
  }
}
