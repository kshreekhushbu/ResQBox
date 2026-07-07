import 'package:flutter/material.dart';

class CustomRichText extends StatelessWidget {
  const CustomRichText({
    super.key,
    required this.children,
    this.textAlign = TextAlign.start,
  });
  final List<InlineSpan> children;
  final TextAlign textAlign;
  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: children),
    );
  }
}
