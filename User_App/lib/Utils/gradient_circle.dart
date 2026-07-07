import 'package:flutter/material.dart';

class GradientCircleAvatar extends StatelessWidget {
  const GradientCircleAvatar({super.key, this.isSelectedItem = false});
  final bool isSelectedItem;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20, // Size of the avatar
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelectedItem
            ? const LinearGradient(
                colors: [Color(0XFFFF9914), Color(0XFFFF3B01)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        border: isSelectedItem
            ? null
            : Border.all(
                color: const Color(0XFF595959),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.1), // Thickness of the gradient border
        child: isSelectedItem
            ? Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Colors.white, // Background for the inner gradient circle
                ),
                child: Center(
                  child: Container(
                    width: 9.3, // Size of the smaller circle
                    height: 9.3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0XFFFF9914), Color(0XFFFF3B01)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
