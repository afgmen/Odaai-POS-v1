import 'package:flutter/material.dart';

/// PIN 입력 패드 위젯
class PinPadWidget extends StatelessWidget {
  final String pin;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;
  final bool obscureText;

  const PinPadWidget({
    super.key,
    required this.pin,
    this.maxLength = 6,
    required this.onChanged,
    this.onSubmit,
    this.obscureText = true,
  });

  void _onNumberTap(String number) {
    if (pin.length < maxLength) {
      onChanged(pin + number);
    }
  }

  void _onBackspace() {
    if (pin.isNotEmpty) {
      onChanged(pin.substring(0, pin.length - 1));
    }
  }

  void _onSubmitTap() {
    if (pin.length >= 4 && onSubmit != null) {
      onSubmit!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN 입력 표시
        _buildPinDisplay(context),
        const SizedBox(height: 24),
        // 숫자 패드
        _buildNumberPad(context),
      ],
    );
  }

  Widget _buildPinDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxLength, (index) {
          final hasValue = index < pin.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasValue
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumberPad(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton(context, '1'),
              _buildNumberButton(context, '2'),
              _buildNumberButton(context, '3'),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton(context, '4'),
              _buildNumberButton(context, '5'),
              _buildNumberButton(context, '6'),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton(context, '7'),
              _buildNumberButton(context, '8'),
              _buildNumberButton(context, '9'),
            ],
          ),
          const SizedBox(height: 12),
          // Row 4: Backspace, 0, Submit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                icon: Icons.backspace_outlined,
                onPressed: _onBackspace,
              ),
              _buildNumberButton(context, '0'),
              _buildActionButton(
                context,
                icon: Icons.check,
                onPressed: pin.length >= 4 ? _onSubmitTap : null,
                color: pin.length >= 4
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return InkWell(
      onTap: () => _onNumberTap(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.grey.shade100,
          border: Border.all(
            color: color != null ? color : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: onPressed != null ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
