import 'package:flutter/material.dart';

/// Một câu hỏi về thanh toán.
class PaymentFaqItem extends StatelessWidget {
  const PaymentFaqItem({
    super.key,
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(answer),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}
