import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeInputBox extends StatelessWidget {
  final String label;
  final int value;
  final Function(int) onChanged;
  final int? maxValue;

  const TimeInputBox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller =
        TextEditingController(text: value.toString());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: value > 0
                    ? () {
                        onChanged(value - 1);
                      }
                    : null,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (text) {
                    final newValue = int.tryParse(text) ?? 0;
                    if (maxValue != null && newValue > maxValue!) {
                      controller.text = maxValue.toString();
                      onChanged(maxValue!);
                    } else {
                      onChanged(newValue);
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: maxValue == null || value < maxValue!
                    ? () {
                        onChanged(value + 1);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
