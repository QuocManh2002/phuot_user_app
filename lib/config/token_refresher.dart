import 'package:greenwheel_user_app/main.dart';

class TokenRefresher {
  static Future<void> refreshToken() async {
    // Check if the user is already signed in
    await auth.currentUser!.getIdToken(true).then(
          (value) => {
            // tokenController.text = value.token ?? "";
            sharedPreferences.setString('userToken', value!),
            print(auth.currentUser),
            print(value),
          },
        );
  }
}
