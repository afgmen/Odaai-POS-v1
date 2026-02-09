import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../domain/services/loyalty_service.dart';

/// 포인트 사용 모달
class PointUseModal extends StatefulWidget {
  final Customer customer;
  final double saleAmount;
  final LoyaltyService loyaltyService;
  final Function(int pointsToUse) onConfirm;

  const PointUseModal({
    super.key,
    required this.customer,
    required this.saleAmount,
    required this.loyaltyService,
    required this.onConfirm,
  });

  @override
  State<PointUseModal> createState() => _PointUseModalState();
}

class _PointUseModalState extends State<PointUseModal> {
  final _pointsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  int? _maxAllowedPoints;
  int? _minPoints;
  int? _pointUnit;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.loyaltyService.getAllSettings();
    setState(() {
      _minPoints = int.parse(settings['min_redeem_points'] ?? '1000');
      final maxPercent = int.parse(settings['max_redeem_percent'] ?? '50');
      _pointUnit = int.parse(settings['point_unit'] ?? '100');
      _maxAllowedPoints = (widget.saleAmount * maxPercent / 100).floor();
    });
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  void _useMaxPoints() {
    if (_maxAllowedPoints == null) return;
    final maxUsable = _maxAllowedPoints! > widget.customer.points
        ? widget.customer.points
        : _maxAllowedPoints!;

    // 포인트 단위로 내림
    final pointUnit = _pointUnit ?? 100;
    final roundedPoints = (maxUsable ~/ pointUnit) * pointUnit;

    _pointsController.text = roundedPoints.toString();
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _validateAndConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    final pointsToUse = int.tryParse(_pointsController.text) ?? 0;

    // 서비스로 검증
    final validation = await widget.loyaltyService.validatePointRedeem(
      customerId: widget.customer.id,
      pointsToUse: pointsToUse,
      saleAmount: widget.saleAmount,
    );

    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.message;
      });
      return;
    }

    // 확인
    if (mounted) {
      Navigator.of(context).pop();
      widget.onConfirm(pointsToUse);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀
              Row(
                children: [
                  const Icon(Icons.stars, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    '포인트 사용',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 고객 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.customer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.customer.membershipTier.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('보유 포인트'),
                        Text(
                          '${currencyFormat.format(widget.customer.points)}P',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 결제 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '결제 금액',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${currencyFormat.format(widget.saleAmount)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 사용 제한 안내
              if (_minPoints != null && _maxAllowedPoints != null && _pointUnit != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                          const SizedBox(width: 8),
                          Text(
                            '사용 제한',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• 최소 ${currencyFormat.format(_minPoints)}P 이상\n'
                        '• 최대 ${currencyFormat.format(_maxAllowedPoints)}P까지\n'
                        '• ${currencyFormat.format(_pointUnit)}P 단위로 사용',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // 포인트 입력
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: '사용 포인트',
                        suffixText: 'P',
                        border: const OutlineInputBorder(),
                        errorText: _errorMessage,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '포인트를 입력하세요';
                        }
                        final points = int.tryParse(value);
                        if (points == null || points <= 0) {
                          return '올바른 포인트를 입력하세요';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _useMaxPoints,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('최대 사용'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _validateAndConfirm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('사용'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
