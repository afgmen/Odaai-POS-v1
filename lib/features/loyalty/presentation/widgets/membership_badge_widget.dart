import 'package:flutter/material.dart';
import '../../../../database/app_database.dart';

/// 멤버십 등급 배지 위젯 (작은 버전)
class MembershipBadgeWidget extends StatelessWidget {
  final MembershipTier tier;
  final double size;

  const MembershipBadgeWidget({
    super.key,
    required this.tier,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.4,
        vertical: size * 0.2,
      ),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${tier.colorHex.substring(1)}')),
        borderRadius: BorderRadius.circular(size * 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTierIcon(tier.tierCode),
            color: Colors.white,
            size: size * 0.6,
          ),
          SizedBox(width: size * 0.15),
          Text(
            _getTierName(tier.tierCode),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTierIcon(String tierCode) {
    switch (tierCode) {
      case 'bronze':
        return Icons.military_tech;
      case 'silver':
        return Icons.shield;
      case 'gold':
        return Icons.workspace_premium;
      case 'platinum':
        return Icons.diamond;
      default:
        return Icons.star;
    }
  }

  String _getTierName(String tierCode) {
    switch (tierCode) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      default:
        return tierCode.toUpperCase();
    }
  }
}
