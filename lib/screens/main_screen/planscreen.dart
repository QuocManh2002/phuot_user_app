import 'package:flutter/material.dart';
import 'package:greenwheel_user_app/screens/loading_screen/plan_loading_screen.dart';
import 'package:greenwheel_user_app/service/plan_service.dart';
import 'package:greenwheel_user_app/view_models/plan_viewmodels/plan_card.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/empty_plan.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/plan_card.dart';
import 'package:greenwheel_user_app/widgets/plan_screen_widget/tab_button.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> with TickerProviderStateMixin {
  final PlanService _planService = PlanService();
  List<PlanCardViewModel> _onGoingPlans = [];
  List<PlanCardViewModel> _canceledPlans = [];
  List<PlanCardViewModel> _futuredPlans = [];
  List<PlanCardViewModel> _historyPlans = [];
  List<List<PlanCardViewModel>> _totalPlans = [];

  int _selectedTab = 0;

  bool isLoading = true;
  late TabController tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _setUpData();
    tabController = TabController(length: 4, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    tabController.dispose();
  }

  _setUpData() async {
    List<PlanCardViewModel> onGoingPlans = [];
    List<PlanCardViewModel> canceledPlans = [];
    List<PlanCardViewModel> historyPlans = [];
    List<PlanCardViewModel> futurePlans = [];
    List<PlanCardViewModel>? totalPlans = await _planService.getPlanCards();

    if (totalPlans != null) {
      for (final plan in totalPlans) {
        // switch (plan.status) {
        //   case "CANCELED":
        //     canceledPlans.add(plan);
        //     break;
        //   case "DRAFT":
        //     draftPlans.add(plan);
        //     break;
        //   case "FUTURE":
        //     futurePlans.add(plan);
        //     break;
        //   case "VERIFIED":
        //     onGoingPlans.add(plan);
        //     break;
        //   case "FINISHED":
        //     historyPlans.add(plan);
        //     break;
        //   case "ONGOING":
        //     onGoingPlans.add(plan);
        //     break;
        //   case "PAST":
        //     historyPlans.add(plan);
        //     break;
        // }
        if (plan.startDate.isAfter(DateTime.now())) {
          futurePlans.add(plan);
        } else if (plan.startDate.isBefore(DateTime.now()) &&
            plan.endDate.isAfter(DateTime.now())) {
          onGoingPlans.add(plan);
        } else if (plan.endDate.isBefore(DateTime.now())) {
          historyPlans.add(plan);
        }
      }
      setState(() {
        _canceledPlans = canceledPlans;
        _futuredPlans = futurePlans;
        _onGoingPlans = onGoingPlans;
        _historyPlans = historyPlans;
        _totalPlans.add(_futuredPlans);
        _totalPlans.add(_onGoingPlans);
        _totalPlans.add(historyPlans);        
        _totalPlans.add(canceledPlans);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Kế hoạch",
          style: TextStyle(
              color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const PlanLoadingScreen()
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 16,
                        ),
                        InkWell(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          onTap: () {
                            setState(() {
                              _selectedTab = 0;
                            });
                          },
                          child: TabButton(
                            text: 'Sắp đến',
                            isSelected: _selectedTab == 0,
                            index: 0,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        InkWell(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          onTap: () {
                            setState(() {
                              _selectedTab = 1;
                            });
                          },
                          child: TabButton(
                            text: 'Đang diễn ra',
                            isSelected: _selectedTab == 1,
                            index: 1,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        InkWell(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          onTap: () {
                            setState(() {
                              _selectedTab = 2;
                            });
                          },
                          child: TabButton(
                            text: 'Lịch sử',
                            isSelected: _selectedTab == 2,
                            index: 2,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        InkWell(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          onTap: () {
                            setState(() {
                              _selectedTab = 3;
                            });
                          },
                          child: TabButton(
                            text: 'Đã hủy',
                            isSelected: _selectedTab == 3,
                            index: 3,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                      child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: _totalPlans[_selectedTab].isEmpty
                        ? const EmptyPlan()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _totalPlans[_selectedTab].length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: PlanCard(plan: _totalPlans[_selectedTab][index]),
                              );
                            },
                          ),
                  ))
                ],
              ),
            ),
    ));
  }
}
