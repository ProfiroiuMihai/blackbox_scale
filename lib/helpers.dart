import 'package:flutter/material.dart';

void showSpinnerLoadingModal({
  required BuildContext context,
  required String title,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _SpinnerModalContent(
          title: title,
        );
      },
    );

class _SpinnerModalContent extends StatelessWidget {
  const _SpinnerModalContent({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MediaQuery.of(context).viewPadding,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
            )
          ],
        ),
      ),
    );
  }
}
