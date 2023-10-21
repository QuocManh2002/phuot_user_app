import 'package:greenwheel_user_app/models/tag.dart';

class Location {
  Location(
      {required this.id,
      required this.description,
      required this.imageUrl,
      required this.name,
      required this.numberOfRating,
      required this.rating, 
      required this.tags,
      required this.hotlineNumber,
      required this.lifeGuardNumber,
      required this.lifeGuardAddress,
      required this.clinicNumber,
      required this.clinicAddress});

  final String id;
  final String name;
  final double rating;
  final String imageUrl;
  final int numberOfRating;
  final String description;
  final List<Tag> tags;
  final String hotlineNumber;
  final String lifeGuardNumber;
  final String lifeGuardAddress;
  final String clinicNumber;
  final String clinicAddress;
}
