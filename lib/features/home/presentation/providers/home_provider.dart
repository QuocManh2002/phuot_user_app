import 'package:flutter/material.dart';
import 'package:greenwheel_user_app/features/home/business/entities/home_location_entity.dart';
import 'package:greenwheel_user_app/features/home/business/entities/home_province_entity.dart';
import 'package:greenwheel_user_app/features/home/business/usecases/get_home_location.dart';
import 'package:greenwheel_user_app/features/home/business/usecases/get_home_province.dart';
import 'package:greenwheel_user_app/features/home/business/usecases/get_home_trending_location.dart';
import 'package:greenwheel_user_app/features/home/data/datasources/home_remote_datasource.dart';
import 'package:greenwheel_user_app/features/home/data/repositories/home_repository_impl.dart';

class HomeProvider extends ChangeNotifier {
  List<HomeLocationEntity>? hot_locations = [];
  List<HomeProvinceEntity>? home_provinces;
  List<HomeLocationEntity>? home_trending_locations;
  HomeProvider({
    this.hot_locations,
    this.home_provinces,
  });

  String? cursorHotLocation;

  void getHotLocations() async {
    HomeRepositoryImpl repository =
        HomeRepositoryImpl(remoteDataSource: HomeRemoteDataSourceImpl());

    final hotLocations =
        await GetHomeLocations(repository).call(cursorHotLocation);
    if (hotLocations != null) {
      if (hotLocations.objects != null && hotLocations.objects!.isNotEmpty) {
        if (hot_locations == null || hot_locations!.isEmpty) {
          hot_locations = hotLocations.objects!;
        } else {
          hot_locations!.addAll(hotLocations.objects!);
        }
      }
      cursorHotLocation = hotLocations.cursor;
      notifyListeners();
    }
  }

  void getHomeProvinces() async {
    HomeRepositoryImpl repository =
        HomeRepositoryImpl(remoteDataSource: HomeRemoteDataSourceImpl());

    final homeProvinces = await GetHomeProvinces(repository).call();
    if (homeProvinces != null) {
      home_provinces = homeProvinces;
      notifyListeners();
    }
  }

  void getHomeTrendingLocations() async {
    HomeRepositoryImpl repository =
        HomeRepositoryImpl(remoteDataSource: HomeRemoteDataSourceImpl());
    final homeTrendingLocations =
        await GetHomeTrendingLocations(repository).call();
    if (homeTrendingLocations != null) {
      home_trending_locations = homeTrendingLocations;
      notifyListeners();
    }
  }
}
