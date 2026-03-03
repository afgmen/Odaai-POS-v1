import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';

import '../../../../providers/database_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/presentation/screens/pin_login_screen.dart';
import '../../../tables/data/tables_providers.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../widgets/barcode_input_modal.dart';
import '../widgets/cart_panel.dart';
import '../widgets/category_filter.dart';
import '../widgets/payment_modal.dart';
import '../widgets/product_card.dart';
import '../../../kds/presentation/screens/kds_mode_selection_screen.dart';
import '../../data/models/order_type.dart';

/// POS 메인 화면
/// Phase 3: tableId, orderType, existingSaleId 파라미터 추가
class PosMainScreen extends ConsumerStatefulWidget {
  /// Floor Plan에서 전달되는 테이블 정보
  final int? tableId;
  final String? tableNumber;
  /// 주문 유형 초기값 (dineIn, takeaway, phoneDelivery, platformDelivery)
  final OrderType? orderType;
  /// 기존 Sale ID (추가 주문 시)
  final int? existingSaleId;

  const PosMainScreen({
    super.key,
    this.tableId,
    this.tableNumber,
    this.orderType,
    this.existingSaleId,
  });

  @override
  ConsumerState<PosMainScreen> createState() => _PosMainScreenState();
}

class _PosMainScreenState extends ConsumerState<PosMainScreen> {
  late OrderType _selectedOrderType;

  @override
  void initState() {
    super.initState();
    // 외부에서 orderType이 전달되면 사용, 없으면 기본값 dineIn
    _selectedOrderType = widget.orderType ?? OrderType.dineIn;
  }

  bool get _isDineInWithTable =>
      _selectedOrderType == OrderType.dineIn && widget.tableId != null;

  @override
  Widget build(BuildContext context) {
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
          // 항상 표시되는 주문 유형 선택 바
          _OrderTypeSelectorBar(
            selectedType: _selectedOrderType,
            tableNumber: widget.tableNumber,
            existingSaleId: widget.existingSaleId,
            showBackButton: widget.tableId != null,
            onTypeSelected: (type) => setState(() => _selectedOrderType = type),
          ),
          Expanded(child: LayoutBuilder(
        builder: (context, constraints) {
          final deviceType = ResponsiveHelper.getDeviceType(constraints.maxWidth);
          final isWide = deviceType != DeviceType.mobile;

          if (isWide) {
            // ── 태블릿/데스크탑: 좌(카테고리+상품) + 우(장바구니) ──
            return Row(
              children: [
                // 좌측: 카테고리 + 상품 그리드
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 12),
                      SizedBox(
                        width: ResponsiveHelper.getCategoryFilterWidth(deviceType),
                        child: CategoryFilter(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _ProductGrid(width: constraints.maxWidth - 300 - 140)),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                // 우측: 장바구니 사이드 패널
                SizedBox(
                  width: ResponsiveHelper.getCartPanelWidth(deviceType),
                  child: CartPanel(
                    onCheckout: _isDineInWithTable
                        ? () => _handleSendToKitchen(context, ref)
                        : () => _showPaymentModal(context, orderType: _selectedOrderType, tableId: widget.tableId),
                    isSidePanel: true,
                    orderType: _selectedOrderType,
                    tableId: widget.tableId,
                  ),
                ),
              ],
            );
          } else {
            // ── 모바일: 상단(상품) + 하단(장바구니) ──
            return Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: CategoryFilter(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _ProductGrid(width: constraints.maxWidth - 140)),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                CartPanel(
                  onCheckout: _isDineInWithTable
                      ? () => _handleSendToKitchen(context, ref)
                      : () => _showPaymentModal(context, orderType: _selectedOrderType, tableId: widget.tableId),
                  isSidePanel: false,
                  orderType: _selectedOrderType,
                  tableId: widget.tableId,
                ),
              ],
            );
          }
        },
      )),
        ],
      ),
    );
  }
}

/// 주문 유형 선택 바 — 항상 표시, 4가지 옵션 선택 가능
class _OrderTypeSelectorBar extends StatelessWidget {
  final OrderType selectedType;
  final String? tableNumber;
  final int? existingSaleId;
  final bool showBackButton;
  final ValueChanged<OrderType> onTypeSelected;

  const _OrderTypeSelectorBar({
    required this.selectedType,
    required this.onTypeSelected,
    this.tableNumber,
    this.existingSaleId,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          // 주문 유형 칩 목록
          ...OrderType.values.map((type) {
            final isSelected = selectedType == type;
            return GestureDetector(
              onTap: () => onTypeSelected(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? type.color.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? type.color : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 14,
                      color: isSelected ? type.color : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      type.displayNameEn,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? type.color : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // 테이블 번호 배지 (Floor Plan에서 진입 시)
          if (tableNumber != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selectedType.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selectedType.color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.table_restaurant, size: 13, color: selectedType.color),
                  const SizedBox(width: 4),
                  Text(
                    'Table $tableNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selectedType.color,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 추가 라운드 배지
          if (existingSaleId != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Text(
                '+ Round',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange,
                ),
              ),
            ),
          ],

          const Spacer(),

          // 뒤로가기 버튼 (Floor Plan에서 진입한 경우만)
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back to Floor Plan',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppTheme.textSecondary,
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
    final l10n = AppLocalizations.of(context)!;
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
                  child: Text(
                    '● ${l10n.offlineIndicator}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF856404), fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                // KDS 통계 배지
                const _KdsStatsBadges(),
                const SizedBox(width: 12),
                // KDS 버튼
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KdsModeSelectionScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.navKds,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 직원 정보 + 로그아웃 버튼
                const _EmployeeInfo(),
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
                      hintText: l10n.searchProductHint,
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

/// 상품 그리드 (반응형)
class _ProductGrid extends ConsumerWidget {
  final double width;
  const _ProductGrid({this.width = 400});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(searchResultsProvider);
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(width);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_outlined, size: 56, color: AppTheme.textDisabled),
                const SizedBox(height: 12),
                Text(
                  l10n.noProducts,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textDisabled),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
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
            Text(l10n.msgError(err.toString()), style: const TextStyle(color: AppTheme.error)),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// 모달 & 바코드 핸들러 함수들
// ────────────────────────────────────────────────────────

/// 주방전송 핸들러 (dineIn + tableId)
/// Sale 생성 → KitchenOrder 자동 생성 → 테이블 상태 업데이트 → FloorPlan 이동
Future<void> _handleSendToKitchen(BuildContext context, WidgetRef ref) async {
  final cart = ref.read(cartProvider);
  if (cart.isEmpty) return;

  final navigator = Navigator.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // PosMainScreen의 tableId/tableNumber 접근 (context에서 widget 찾기)
  final posScreen = context.findAncestorWidgetOfExactType<PosMainScreen>();
  if (posScreen == null) return;

  final tableId = posScreen.tableId;
  final tableNumber = posScreen.tableNumber;
  if (tableId == null) return;

  try {
    final salesDao = ref.read(salesDaoProvider);
    final tablesDao = ref.read(tablesDaoProvider);

    final subtotal = ref.read(cartSubtotalProvider);
    final discount = ref.read(cartAllDiscountProvider);
    final total = ref.read(cartTotalProvider);
    final employeeId = ref.read(currentEmployeeProvider)?.id;

    final existingSaleId = posScreen.existingSaleId;

    if (existingSaleId != null) {
      // Additional round for existing open tab
      final roundNumber = await salesDao.getNextRoundNumber(existingSaleId);
      await salesDao.addItemsToSale(
        saleId: existingSaleId,
        items: cart
            .map((item) => SaleItemsCompanion.insert(
                  saleId: 0,
                  productId: item.product.id,
                  productName: item.product.name,
                  sku: item.product.sku,
                  unitPrice: item.product.price,
                  quantity: item.quantity,
                  total: item.subtotal,
                ))
            .toList(),
        roundNumber: roundNumber,
        tableNumber: tableNumber,
      );

      // 테이블 상태 → ORDERING (reset on new round)
      await tablesDao.updateTableStatus(
        tableId: tableId,
        status: 'ORDERING',
        currentSaleId: existingSaleId,
        occupiedAt: DateTime.now(),
      );
    } else {
      // New open tab (first round)
      final sale = await salesDao.createSale(
        sale: SalesCompanion.insert(
          saleNumber: 'S${DateTime.now().millisecondsSinceEpoch}',
          paymentMethod: 'pending',
          subtotal: Value(subtotal),
          discount: Value(discount),
          total: Value(total),
          orderType: Value(OrderType.dineIn.dbValue),
          tableId: Value(tableId),
          isOpenTab: const Value(true),
          status: const Value('open'),
          employeeId: Value(employeeId),
        ),
        items: cart
            .map((item) => SaleItemsCompanion.insert(
                  saleId: 0, // overridden by createSale
                  productId: item.product.id,
                  productName: item.product.name,
                  sku: item.product.sku,
                  unitPrice: item.product.price,
                  quantity: item.quantity,
                  total: item.subtotal,
                ))
            .toList(),
        tableNumber: tableNumber,
        createKitchenOrder: true,
      );

      // 테이블 상태 → ORDERING
      await tablesDao.updateTableStatus(
        tableId: tableId,
        status: 'ORDERING',
        currentSaleId: sale.id,
        occupiedAt: DateTime.now(),
      );
    }

    // 장바구니 초기화
    ref.read(cartProvider.notifier).clear();
    ref.read(discountValueProvider.notifier).state = 0;
    ref.read(promotionProductIdProvider.notifier).state = null;

    // FloorPlanScreen으로 복귀 (push된 PosMainScreen에서 pop)
    navigator.pop();

    scaffoldMessenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Table $tableNumber 주방전송 완료'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
  } catch (e) {
    if (context.mounted) {
      scaffoldMessenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('주방전송 실패: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }
}

/// 결제 모달 표시
void _showPaymentModal(BuildContext context, {OrderType? orderType, int? tableId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaymentModal(
        orderType: orderType,
        tableId: tableId,
      ),
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

  final l10n = AppLocalizations.of(context)!;

  if (product != null) {
    if (product.stock > 0) {
      ref.read(cartProvider.notifier).addItem(product);
      _showSnackBar(context, l10n.addedToCart(product.name), AppTheme.success);
    } else {
      _showSnackBar(context, l10n.outOfStock(product.name), AppTheme.error);
    }
    // 조회 성공 시 검색바 초기화
    ref.read(searchQueryProvider.notifier).state = '';
  } else {
    // 상품 없음 → 검색 키워드로 남겨서 검색 결과 표시
    ref.read(searchQueryProvider.notifier).state = input;
    _showSnackBar(context, l10n.productNotFound(input), AppTheme.warning);
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
    final l10n = AppLocalizations.of(context)!;
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
          tooltip: l10n.logout,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.logout, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(l10n.logoutConfirm, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              // 장바구니 초기화
              ref.read(cartProvider.notifier).clear();
              // 할인 초기화
              ref.read(discountValueProvider.notifier).state = 0;
              ref.read(promotionProductIdProvider.notifier).state = null;
              // 현재 직원 초기화는 로그아웃 시 자동 처리됨
              // (Provider는 읽기 전용이므로 직접 변경 불가)

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
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

/// KDS 통계 배지 (완료, 진행중, 평균)
class _KdsStatsBadges extends ConsumerWidget {
  const _KdsStatsBadges();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatBadge(
          icon: Icons.check_circle_outline,
          label: l10n.kdsCompleted,
          value: '0',
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStatBadge(
          icon: Icons.pending_outlined,
          label: l10n.kdsInProgress,
          value: '0',
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
        _buildStatBadge(
          icon: Icons.timer_outlined,
          label: l10n.kdsAverage,
          value: '0m 0s',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
