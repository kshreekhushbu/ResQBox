import 'package:flutter/material.dart';

// import 'package:tejpandit/Screens/Samajika/DevalayaSettings/join_temple.dart';
import 'custom_image_widget.dart';
import 'mediaquery.dart';

class NoData extends StatelessWidget {
  final String image;
  final bool isShowAddDevalayaButton;
  const NoData({
    super.key,
    required this.image,
    this.isShowAddDevalayaButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomImage(image: image),
        if (isShowAddDevalayaButton)
          Positioned(
              bottom: Sizes.height * .035,
              left: Sizes.width * .045,
              child: Container())
        //  const AddMissingDevalayaButton()),
      ],
    );
  }
}
