import 'package:fluttertoast/fluttertoast.dart';
import 'package:resqboxvendor/Utils/colors.dart';

customToast({String? message}) {
  return Fluttertoast.showToast(
    backgroundColor: AppColors.blackText,
    msg: message!,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    fontSize: 14,
  );
}
