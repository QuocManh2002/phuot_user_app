import 'package:greenwheel_user_app/view_models/plan_viewmodels/plan_schedule_item.dart';

class PlanSchedule{
  final DateTime date;
  final List<PlanScheduleItem> items;

  const PlanSchedule({required this.date, required this.items});
}