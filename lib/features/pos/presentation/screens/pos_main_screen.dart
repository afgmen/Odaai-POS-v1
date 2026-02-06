import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/presentation/screens/pin_login_screen.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../widgets/barcode_input_modal.dart';
import '../widgets/cart_panel.dart';
import '../widgets/category_filter.dart';
import '../widgets/payment_modal.dart';
import '../widgets/product_card.dart';

/// POS 메인 화면
class PosMainScreen extends ConsumerWidget {
  const PosMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _PosAppBar(
        searchQuery: searchQuery,
        onSearchChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
        onSearchClear: () => ref.read(searchQueryProvider.notifier).state = '',
        onScanPressed: () => _showBarcodeScanModal(context, ref),
        onBarcodeSsubmit: (barcode) => _handleBarcodeSubmit(context, ref, barcode),
      ),
      body: Column(
        children: [
          // ─── 메인 콘텐츠 영역 ──────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 좌측: 카테고리 필터 ──────────
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: CategoryFilter(),
                ),
                const SizedBox(width: 12),

                // ── 중앙: 상품 그리드 ─────────────
                Expanded(
                  child: _ProductGrid(),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),

          // ─── 하단: 장바구니 패널 ────────────────
          CartPanel(
            onCheckout: () => _showPaymentModal(context),
          ),
        ],
      ),
    );
  }
}

/// POS AppBar (검색 + 바코드 스캔 버튼)
/// StatefulWidget으로 구현하여 TextEditingController를 적절히 관리
class _PosAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onScanPressed;
  final ValueChanged<String> onBarcodeSsubmit; // Enter 키 시 바코드 즉시 조회

  const _PosAppBar({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onScanPressed,
    required this.onBarcodeSsubmit,
  });

  @override
  Size get preferredSize => const Size.fromHeight(110);

  @override
  State<_PosAppBar> createState() => _PosAppBarState();
}

class _PosAppBarState extends State<_PosAppBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(_PosAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 검색 키워드가 변경될 때(예: 바코드 스캔 결과) 컨트롤러 동기화
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = widget.searchQuery;

    return AppBar(
      backgroundColor: AppTheme.cardWhite,
      elevation: 0,
      toolbarHeight: 110,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 상단 로고 + 오프라인 표시 + 직원 정보 ──────
            Row(
              children: [
                const Icon(Icons.point_of_sale, color: AppTheme.primary, size: 22),
                const SizedBox(width: 6),
                const Text(
                  'Oda POS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 12),
                // 오프라인 배지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '● 오프라인',
                    style: TextStyle(fontSize: 11, color: Color(0xFF856404), fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                // 직원 정보 + 로그아웃 버튼
                const _EmployeeInfo(),
                const Spacer(),
                // 직원명
                const Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'admin',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ─── 검색 바 + 바코드 스캔 버튼 ──────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        widget.onBarcodeSsubmit(value.trim());
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.primary, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textDisabled),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: widget.onSearchClear,
                              icon: const Icon(Icons.close, size: 18, color: AppTheme.textDisabled),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintText: '상품명, SKU, 바코드 검색...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textDisabled),
                    ),
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                // ── 바코드 스캔 버튼 ──────────────
                InkWell(
                  onTap: widget.onScanPressed,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_enhance_outlined, size: 22, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.divider),
      ),
    );
  }
}

/// 상품 그리드
class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(searchResultsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_outlined, size: 56, color: AppTheme.textDisabled),
                const SizedBox(height: 12),
                const Text(
                  '상품이 없습니다',
                  style: TextStyle(fontSize: 16, color: AppTheme.textDisabled),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => ProductCard(product: products[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
            const SizedBox(height: 8),
            Text('오류 발생: $err', style: const TextStyle(color: AppTheme.error)),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// 모달 & 바코드 핸들러 함수들
// ────────────────────────────────────────────────────────

/// 결제 모달 표시
void _showPaymentModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const PaymentModal(),
  );
}

/// 검색바 Enter 키 → 바코드/SKU 즉시 조회 → 장바구니 추가
/// USB 바코드 스캔기 연동 핵심 패턴
Future<void> _handleBarcodeSubmit(BuildContext context, WidgetRef ref, String input) async {
  final dao = ref.read(productsDaoProvider);

  // 바코드로 정확 매칭, 미매칭이면 SKU로 재조회
  Product? product = await dao.getProductByBarcode(input);
  product ??= await dao.getProductBySku(input);

  if (!context.mounted) return;

  if (product != null) {
    if (product.stock > 0) {
      ref.read(cartProvider.notifier).addItem(product);
      _showSnackBar(context, '${product.name}을(를) 장바구니에 추가했습니다', AppTheme.success);
    } else {
      _showSnackBar(context, '${product.name}은(는) 현재 품절 중입니다', AppTheme.error);
    }
    // 조회 성공 시 검색바 초기화
    ref.read(searchQueryProvider.notifier).state = '';
  } else {
    // 상품 없음 → 검색 키워드로 남겨서 검색 결과 표시
    ref.read(searchQueryProvider.notifier).state = input;
    _showSnackBar(context, '[$input] 상품을 찾을 수 없습니다', AppTheme.warning);
  }
}

/// 수동 바코드 입력 모달 표시 (스캔 버튼 클릭 시)
void _showBarcodeScanModal(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const BarcodeScanInputModal(),
  );
}

/// Snackbar 표시 헬퍼 (색상 지정 가능)
void _showSnackBar(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
}

/// 직원 정보 + 로그아웃 버튼
class _EmployeeInfo extends ConsumerWidget {
  const _EmployeeInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEmployee = ref.watch(currentEmployeeProvider);

    if (currentEmployee == null) return const SizedBox.shrink();

    return Row(
      children: [
        // 직원 정보
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: currentEmployee.role == 'admin' ? AppTheme.primary : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                currentEmployee.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              if (currentEmployee.role == 'admin') ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 로그아웃 버튼
        IconButton(
          onPressed: () => _showLogoutConfirmation(context, ref),
          icon: const Icon(Icons.logout, size: 20, color: AppTheme.textSecondary),
          tooltip: '로그아웃',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: const Text('로그아웃 하시겠습니까?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              // 장바구니 초기화
              ref.read(cartProvider.notifier).clear();
              // 할인 초기화
              ref.read(discountValueProvider.notifier).state = 0;
              ref.read(promotionProductIdProvider.notifier).state = null;
              // 현재 직원 초기화
              ref.read(currentEmployeeProvider.notifier).state = null;

              // PIN 로그인 화면으로 이동
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const PinLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
