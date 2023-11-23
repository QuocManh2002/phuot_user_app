import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:greenwheel_user_app/config/graphql_config.dart';
import 'package:greenwheel_user_app/main.dart';
import 'package:greenwheel_user_app/view_models/order_create.dart';
import 'package:intl/intl.dart';

class OrderService extends Iterable {
  static GraphQlConfig config = GraphQlConfig();
  // GraphQLClient client = config.clientToQuery();

  Future<bool> addOrder(OrderCreateViewModel order) async {
    try {
      List<Map<String, dynamic>> details = order.details.map((detail) {
        return {
          'key': detail.productId,
          'value': detail.quantity,
        };
      }).toList();
      String? userToken = sharedPreferences.getString("userToken");
      final HttpLink httpLink = HttpLink("http://52.76.14.50/graphql");

      final AuthLink authLink =
          AuthLink(getToken: () async => 'Bearer $userToken');

      final Link link = authLink.concat(httpLink);

      GraphQLClient client = GraphQLClient(
        cache: GraphQLCache(),
        link: link,
      );
      final QueryResult result = await client.query(
        QueryOptions(
          fetchPolicy: FetchPolicy.noCache,
          document: gql('''
          mutation CreateOrder(\$input: CreateOrderModelInput!) {
  createOrder(model: \$input) {
    planId
    id
    from
    to
    note
    rating
    comment
    transactionId
    statusLog {
      status
    }
  }
}

        '''),
          variables: {
            "input": {
              "planId": order.planId,
              "from": DateFormat('yyyy-MM-dd').format(order.pickupDate),
              "to": order.returnDate != null
                  ? DateFormat('yyyy-MM-dd').format(order.returnDate!)
                  : null,
              "note": order.note ?? "",
              "details": details,
            },
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception);
      }

      final int? orderId = result.data?['createOrder']["id"];
      if (orderId == null) {
        return false;
      }
      return true;
    } catch (error) {
      throw Exception(error);
    }
  }

  @override
  // TODO: implement iterator
  Iterator get iterator => throw UnimplementedError();
}
