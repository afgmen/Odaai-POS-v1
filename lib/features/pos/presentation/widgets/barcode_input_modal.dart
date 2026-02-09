import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/database_providers.dart';
import '../../providers/cart_provider.dart';

/// 수동 바코드 입력 모달
/// - 바코드 / SKU 입력 후 즉시 조회 → 장바구니 추가
/// - 연속 스캔 모드: 입력 후 자동 초기화하여 반복 입력 가능
class BarcodeScanInputModal extends ConsumerStatefulWidget {
  const BarcodeScanInputModal({super.key});

  @override
  ConsumerState<BarcodeScanInputModal> createState() => _BarcodeScanInputModalState();
}

class _BarcodeScanInputModalState extends ConsumerState<BarcodeScanInputModal> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _continuousMode = true; // 기본값: 연속 모드 ON
  String? _lastMessage;        // 마지막 조회 결과 메시지
  Color _lastMessageColor = AppTheme.textPrimary;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    // 모달 열리면 즉시 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── 바코드 조회 & 장바구니 추가 ──────────────
  Future<void> _lookup() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final dao = ref.read(productsDaoProvider);

    // 1) 바코드로 정확 매칭, 미매칭이면 SKU로 재조회
    Product? product = await dao.getProductByBarcode(input);
    product ??= await dao.getProductBySku(input);

    if (!mounted) return;

    if (product != null) {
      if (product.stock > 0) {
        ref.read(cartProvider.notifier).addItem(product);
        setState(() {
          _lastMessage = l10n.addedToCartMsg(product!.name);
          _lastMessageColor = AppTheme.success;
        });
      } else {
        setState(() {
          _lastMessage = l10n.outOfStockMsg(product!.name);
          _lastMessageColor = AppTheme.error;
        });
      }
    } else {
      setState(() {
        _lastMessage = l10n.productNotFoundMsg(input);
        _lastMessageColor = AppTheme.error;
      });
    }

    // 연속 모드: 입력란 초기화 후 다시 포커스
    if (_continuousMode) {
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 드래그 핸들 ─────────────────────────
          Center(
            child: SizedBox(
              width: 36,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 타이틀 행 ───────────────────────────
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppTheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                l10n.barcodeSkuInput,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              // 닫기 버튼
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── 입력란 + 조회 버튼 ──────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _lookup(),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.qr_code, size: 22, color: AppTheme.textDisabled),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintText: l10n.barcodeOrSku,
                    hintStyle: const TextStyle(fontSize: 16, color: AppTheme.textDisabled),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 조회 버튼
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _lookup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.lookup, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),

          // ── 연속 스캔 모드 토글 ──────────────────
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 26,
                child: Switch.adaptive(
                  value: _continuousMode,
                  onChanged: (v) => setState(() => _continuousMode = v),
                  activeThumbColor: AppTheme.primary,
                  activeTrackColor: AppTheme.primary.withValues(alpha: 0.4),
                  inactiveTrackColor: AppTheme.divider,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.continuousScanMode,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.autoResetAfterInput,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),

          // ── 조회 결과 메시지 ─────────────────────
          const SizedBox(height: 16),
          if (_lastMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _lastMessageColor == AppTheme.success
                    ? const Color(0xFFE6FAF2)   // 성공: 연한 초록
                    : const Color(0xFFFDEBEB),  // 실패: 연한 빨강
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _lastMessageColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _lastMessage!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _lastMessageColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── 안내 텍스트 ───────────────────────────
          Text(
            l10n.barcodeScannerHelp,
            style: const TextStyle(fontSize: 12, color: AppTheme.textDisabled),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
