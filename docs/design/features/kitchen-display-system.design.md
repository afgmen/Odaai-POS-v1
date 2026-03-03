# Kitchen Display System (KDS) Design Document

> **Summary**: Detailed technical design for real-time web-based kitchen display system with WebSocket communication
>
> **Project**: Oda POS
> **Version**: 1.0.0
> **Author**: AI Development Team
> **Date**: 2026-02-08
> **Status**: Draft
> **Planning Doc**: [kitchen-display-system.plan.md](../01-plan/features/kitchen-display-system.plan.md)

### Pipeline References

| Phase | Document | Status |
|-------|----------|--------|
| Phase 1 | Schema Definition | N/A |
| Phase 2 | Coding Conventions | ✅ (Flutter/Dart conventions in CLAUDE.md) |
| Phase 3 | Mockup | N/A (using Material Design 3) |
| Phase 4 | API Spec | ✅ (WebSocket protocol defined in this document) |

> **Note**: This feature follows Flutter/Dart conventions established in existing POS codebase.

---

## 1. Overview

### 1.1 Design Goals

1. **Real-time Communication**: <1 second latency for order transmission from POS to KDS
2. **Reliability**: Auto-reconnect on network interruption, zero data loss
3. **Scalability**: Support 50+ concurrent orders without performance degradation
4. **Usability**: Readable from 2 meters away, touch-friendly for tablets
5. **Maintainability**: Shared codebase with POS, reusable components
6. **Offline Resilience**: Continue operation during brief network interruptions using local database

### 1.2 Design Principles

- **Single Source of Truth**: SQLite database as the authoritative data source
- **Optimistic UI**: Update UI immediately, sync in background
- **Graceful Degradation**: Fall back to database polling if WebSocket fails
- **Component Reusability**: Share UI components between POS and KDS where possible
- **Testability**: Decouple business logic from UI for easy unit testing

---

## 2. Architecture

### 2.1 Component Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      Oda POS System                           │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐         ┌─────────────────┐            │
│  │   POS Flutter   │         │  KDS Flutter    │            │
│  │   Desktop App   │         │   Web App       │            │
│  │                 │         │                 │            │
│  │  ┌───────────┐  │         │  ┌───────────┐  │            │
│  │  │ Checkout  │──┼──┐   ┌──┼─▶│  Order    │  │            │
│  │  │  Screen   │  │  │   │  │  │   Card    │  │            │
│  │  └───────────┘  │  │   │  │  └───────────┘  │            │
│  │                 │  │   │  │                 │            │
│  │  ┌───────────┐  │  │   │  │  ┌───────────┐  │            │
│  │  │ WebSocket │  │  │   │  │  │ WebSocket │  │            │
│  │  │  Client   │◀─┼──┼───┼──┼─▶│  Client   │  │            │
│  │  └───────────┘  │  │   │  │  └───────────┘  │            │
│  └─────────────────┘  │   │  └─────────────────┘            │
│           │            │   │            │                    │
│           ▼            │   │            ▼                    │
│  ┌────────────────────┐│   │   ┌────────────────────┐       │
│  │ KitchenOrdersDao  ││   │   │ KitchenOrdersDao  │       │
│  └────────────────────┘│   │   └────────────────────┘       │
│           │            │   │            │                    │
└───────────┼────────────┘   │   ┌────────┼────────────────────┘
            │                │   │        │
            │                ▼   ▼        │
            │       ┌─────────────────┐   │
            │       │  WebSocket      │   │
            └──────▶│  Server         │◀──┘
                    │  (Dart shelf)   │
                    └─────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  SQLite DB      │
                    │  (Shared)       │
                    │                 │
                    │ kitchen_orders  │
                    │ sales           │
                    │ sale_items      │
                    └─────────────────┘
```

### 2.2 Data Flow

#### Order Creation Flow (POS → KDS)

```
1. User completes checkout in POS
   ↓
2. POS saves sale to SQLite (sales + sale_items tables)
   ↓
3. POS creates kitchen_order record (status: pending)
   ↓
4. POS sends order_created message via WebSocket
   ↓
5. WebSocket Server broadcasts to all connected KDS clients
   ↓
6. KDS receives message and updates local state
   ↓
7. KDS queries kitchen_orders table for full details
   ↓
8. UI updates to display new order card
```

#### Order Status Update Flow (KDS → POS)

```
1. Kitchen staff taps "Start Preparing" button
   ↓
2. KDS updates kitchen_orders.status in SQLite
   ↓
3. KDS sends order_status_updated message via WebSocket
   ↓
4. WebSocket Server broadcasts to all clients (including POS)
   ↓
5. POS receives update (optional, for dashboard display)
   ↓
6. All KDS instances sync to show updated status
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| **KDS Web App** | WebSocket Client, KitchenOrdersDao | Display and manage orders |
| **POS App** | WebSocket Client, KitchenOrdersDao | Send orders to kitchen |
| **WebSocket Server** | Dart shelf, SQLite | Real-time message broadcasting |
| **KitchenOrdersDao** | Drift ORM, SQLite | Database access layer |
| **SQLite DB** | None | Persistent data storage |

**New Dependencies to Add:**
```yaml
# pubspec.yaml
dependencies:
  shelf: ^1.4.0              # HTTP server framework
  shelf_web_socket: ^1.0.4   # WebSocket support
  web_socket_channel: ^2.4.0 # WebSocket client
```

---

## 3. Data Model

### 3.1 Entity Definition

```dart
// Domain Entity: lib/features/kds/domain/entities/kitchen_order.dart
class KitchenOrder {
  final int id;
  final int saleId;                  // Reference to sales table
  final String receiptNumber;
  final String? customerName;
  final String? tableNumber;
  final KitchenOrderStatus status;   // pending, preparing, ready, completed
  final List<KitchenOrderItem> items;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const KitchenOrder({
    required this.id,
    required this.saleId,
    required this.receiptNumber,
    this.customerName,
    this.tableNumber,
    required this.status,
    required this.items,
    this.specialInstructions,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  // Helper: Calculate order age in minutes
  int get ageInMinutes {
    return DateTime.now().difference(createdAt).inMinutes;
  }

  // Helper: Get priority color
  Color get priorityColor {
    if (ageInMinutes <= 5) return Colors.green;
    if (ageInMinutes <= 10) return Colors.orange;
    return Colors.red;
  }
}

class KitchenOrderItem {
  final String productName;
  final int quantity;
  final String? modifications;  // e.g., "No onions", "Extra cheese"

  const KitchenOrderItem({
    required this.productName,
    required this.quantity,
    this.modifications,
  });
}

enum KitchenOrderStatus {
  pending,     // New order, not started
  preparing,   // Kitchen staff working on it
  ready,       // Ready for pickup/serving
  completed,   // Delivered to customer
  cancelled;   // Order cancelled from POS

  String toLocalizedString(AppLocalizations l10n) {
    switch (this) {
      case pending:
        return l10n.orderStatusPending;
      case preparing:
        return l10n.orderStatusPreparing;
      case ready:
        return l10n.orderStatusReady;
      case completed:
        return l10n.orderStatusCompleted;
      case cancelled:
        return l10n.orderStatusCancelled;
    }
  }
}
```

### 3.2 Entity Relationships

```
[Sales] 1 ──── 1 [KitchenOrders]
   │
   └── 1 ──── N [SaleItems]
                    │
                    └── (mapped to) KitchenOrderItem[]
```

**Relationship Rules:**
- Each `Sale` has exactly one `KitchenOrder` (1:1)
- Each `KitchenOrder` contains multiple `KitchenOrderItem` (1:N, stored as JSON)
- `KitchenOrderItem` is derived from `SaleItems` but stored denormalized for performance

### 3.3 Database Schema

```dart
// lib/database/tables/kitchen_orders.dart
@DataClassName('KitchenOrderTable')
class KitchenOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().unique()();  // Foreign key to Sales
  TextColumn get receiptNumber => text()();
  TextColumn get customerName => text().nullable()();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get status => text()();  // pending, preparing, ready, completed, cancelled
  TextColumn get itemsJson => text()();  // JSON array of KitchenOrderItem
  TextColumn get specialInstructions => text().nullable()();
  IntColumn get createdAt => integer()();  // Unix timestamp (milliseconds)
  IntColumn get updatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Indexes for performance
CREATE INDEX idx_kitchen_orders_status ON kitchen_orders(status);
CREATE INDEX idx_kitchen_orders_created_at ON kitchen_orders(created_at);
CREATE INDEX idx_kitchen_orders_sale_id ON kitchen_orders(sale_id);
```

**JSON Structure for `itemsJson`:**
```json
[
  {
    "productName": "Burger",
    "quantity": 2,
    "modifications": "No onions, extra pickles"
  },
  {
    "productName": "French Fries",
    "quantity": 1,
    "modifications": null
  }
]
```

---

## 4. WebSocket Protocol Specification

### 4.1 Connection

**Server Address:**
```
ws://localhost:8080/ws/kitchen
```

**Authentication:**
- No authentication required for v1.0 (local network only)
- Future: Add JWT token authentication

**Connection Flow:**
```
1. Client connects to ws://localhost:8080/ws/kitchen
2. Server accepts connection and adds to broadcast list
3. Client sends "ping" every 30 seconds
4. Server responds with "pong"
5. If ping timeout (60s), server closes connection
6. Client auto-reconnects on disconnect
```

### 4.2 Message Format

All messages follow this structure:

```typescript
interface WebSocketMessage {
  type: string;           // Message type identifier
  payload: any;           // Message-specific data
  timestamp: number;      // Unix timestamp (ms)
  messageId?: string;     // Optional unique ID for deduplication
}
```

### 4.3 Message Types

#### 4.3.1 `order_created` (POS → Server → All KDS)

Sent when a new order is created in POS.

**Direction:** POS → Server → All KDS clients

**Payload:**
```json
{
  "type": "order_created",
  "payload": {
    "orderId": 123,
    "saleId": 456,
    "receiptNumber": "ODA-20260208-001",
    "customerName": "John Doe",
    "tableNumber": "A-5",
    "items": [
      {
        "productName": "Burger",
        "quantity": 2,
        "modifications": "No onions"
      },
      {
        "productName": "French Fries",
        "quantity": 1,
        "modifications": null
      }
    ],
    "specialInstructions": "Allergy: peanuts",
    "createdAt": 1707379200000
  },
  "timestamp": 1707379200500
}
```

**KDS Action:**
1. Insert/update local `kitchen_orders` table
2. Refresh order list UI
3. Play notification sound (optional)
4. Show toast: "New order: {receiptNumber}"

#### 4.3.2 `order_status_updated` (KDS → Server → All clients)

Sent when kitchen staff updates order status.

**Direction:** KDS → Server → All KDS + POS

**Payload:**
```json
{
  "type": "order_status_updated",
  "payload": {
    "orderId": 123,
    "status": "preparing",  // or "ready", "completed", "cancelled"
    "updatedAt": 1707379300000
  },
  "timestamp": 1707379300500
}
```

**KDS Action:**
1. Update local `kitchen_orders.status` and `updatedAt`
2. Update UI to reflect new status
3. If status = "completed", set `completedAt` timestamp

**POS Action (optional):**
1. Update order dashboard display (future feature)

#### 4.3.3 `order_cancelled` (POS → Server → All KDS)

Sent when an order is cancelled from POS.

**Direction:** POS → Server → All KDS

**Payload:**
```json
{
  "type": "order_cancelled",
  "payload": {
    "orderId": 123,
    "reason": "Customer requested cancellation",
    "cancelledAt": 1707379400000
  },
  "timestamp": 1707379400500
}
```

**KDS Action:**
1. Update status to "cancelled"
2. Gray out order card or move to cancelled section
3. Show notification: "Order {receiptNumber} cancelled"

#### 4.3.4 `ping` / `pong` (Heartbeat)

**Direction:** Client → Server (ping), Server → Client (pong)

**Payload:**
```json
{
  "type": "ping",
  "payload": {},
  "timestamp": 1707379500000
}

{
  "type": "pong",
  "payload": {},
  "timestamp": 1707379500100
}
```

**Purpose:**
- Keep connection alive
- Detect disconnections
- Measure network latency

**Interval:** 30 seconds

#### 4.3.5 `sync_request` (Client → Server)

Request full order list synchronization (on reconnect).

**Direction:** Client → Server

**Payload:**
```json
{
  "type": "sync_request",
  "payload": {
    "since": 1707379000000  // Unix timestamp, get orders created/updated after this
  },
  "timestamp": 1707379600000
}
```

**Server Response:**
```json
{
  "type": "sync_response",
  "payload": {
    "orders": [
      // Array of full KitchenOrder objects
    ]
  },
  "timestamp": 1707379600100
}
```

### 4.4 Error Handling

**Error Message Format:**
```json
{
  "type": "error",
  "payload": {
    "code": "INVALID_MESSAGE",
    "message": "Message type not recognized",
    "originalMessage": { /* original message */ }
  },
  "timestamp": 1707379700000
}
```

**Error Codes:**
| Code | Description | Action |
|------|-------------|--------|
| `INVALID_MESSAGE` | Message format invalid | Log error, ignore message |
| `ORDER_NOT_FOUND` | Order ID doesn't exist | Request sync |
| `CONNECTION_FAILED` | WebSocket connection error | Auto-reconnect |
| `TIMEOUT` | Ping timeout | Close and reconnect |

---

## 5. UI/UX Design

### 5.1 Screen Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Header: Kitchen Display System         [Filter: All ▼]  [⚙]   │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Order #001  │  │ Order #002  │  │ Order #003  │             │
│  │ Table A-5   │  │ Table B-2   │  │ Takeout     │             │
│  │ 2 items     │  │ 3 items     │  │ 1 item      │             │
│  │ ⏱ 5 min     │  │ ⏱ 12 min   │  │ ⏱ 3 min     │             │
│  │ [PREPARING] │  │ [READY]     │  │ [PENDING]   │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐                               │
│  │ Order #004  │  │ Order #005  │                               │
│  │ ...         │  │ ...         │                               │
│  └─────────────┘  └─────────────┘                               │
│                                                                   │
├──────────────────────────────────────────────────────────────────┤
│  Footer: Connected • 5 pending orders • Last updated: 10:32 AM  │
└──────────────────────────────────────────────────────────────────┘
```

**Expanded Order Card (on tap):**
```
┌───────────────────────────────────────────────────────┐
│  Order #001                              ⏱ 5 min     │
│  Table A-5 • John Doe                                 │
├───────────────────────────────────────────────────────┤
│  2x Burger                                            │
│      └─ No onions, extra pickles                      │
│                                                        │
│  1x French Fries                                      │
│                                                        │
│  ⚠️ Special: Allergy - peanuts                        │
├───────────────────────────────────────────────────────┤
│  [Start Preparing]  [Mark Ready]  [Complete]          │
└───────────────────────────────────────────────────────┘
```

### 5.2 User Flow

```
KDS Opens in Browser
   ↓
Connects to WebSocket Server
   ↓
Loads Pending Orders from Database
   ↓
Displays Order Cards in Grid
   ↓
Kitchen Staff Interaction:
   ├─→ Tap Order Card → Expand Details
   ├─→ Tap "Start Preparing" → Status = preparing
   ├─→ Tap "Mark Ready" → Status = ready
   └─→ Tap "Complete" → Status = completed, hide after 5 min
```

### 5.3 Component List

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `KitchenDisplayScreen` | `lib/features/kds/presentation/screens/` | Main container, WebSocket connection |
| `OrderCard` | `lib/features/kds/presentation/widgets/` | Display single order summary |
| `OrderCardExpanded` | `lib/features/kds/presentation/widgets/` | Full order details modal |
| `OrderTimer` | `lib/features/kds/presentation/widgets/` | Real-time elapsed time display |
| `StatusFilter` | `lib/features/kds/presentation/widgets/` | Filter buttons (All/Preparing/Ready) |
| `OrderItemList` | `lib/features/kds/presentation/widgets/` | List of items in order |
| `SpecialInstructionsChip` | `lib/features/kds/presentation/widgets/` | Highlighted badge for special requests |
| `ConnectionStatusIndicator` | `lib/features/kds/presentation/widgets/` | WebSocket connection status |

### 5.4 Color Coding (Order Age)

| Age | Color | Meaning |
|-----|-------|---------|
| 0-5 min | Green (#4CAF50) | Fresh order, on track |
| 5-10 min | Orange (#FF9800) | Attention needed |
| 10+ min | Red (#F44336) | Urgent, delayed |

### 5.5 Typography

| Element | Font Size | Weight | Color |
|---------|-----------|--------|-------|
| Order number | 20px | Bold | Primary |
| Table/Customer | 16px | Medium | Gray-700 |
| Item name | 18px | Medium | Gray-900 |
| Modifications | 14px | Regular | Gray-600 |
| Timer | 16px | Bold | Dynamic (green/orange/red) |
| Button text | 16px | Medium | White |

**Accessibility:**
- Minimum touch target: 48x48 dp (Material Design)
- Color contrast ratio: 4.5:1 (WCAG AA)
- Font size: Minimum 16px for body text

---

## 6. Error Handling

### 6.1 Error Scenarios

| Error | Cause | Handling |
|-------|-------|----------|
| **WebSocket connection failed** | Server down, network issue | Show reconnecting indicator, retry every 5s |
| **Order not found in DB** | Sync issue, DB corruption | Request full sync from server |
| **Invalid message format** | Protocol mismatch, version incompatibility | Log error, ignore message, show warning |
| **Database write failed** | Disk full, permission issue | Retry 3 times, show error toast |
| **Order already completed** | Duplicate status update | Silently ignore, log warning |

### 6.2 Error Response Format

```dart
class KdsError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  const KdsError({
    required this.code,
    required this.message,
    this.details,
    required this.timestamp,
  });
}
```

**Error Codes:**
```dart
enum KdsErrorCode {
  connectionFailed,
  orderNotFound,
  invalidMessage,
  databaseError,
  syncFailed,
  unknownError,
}
```

### 6.3 User-Facing Error Messages

| Error Code | User Message (EN) | User Message (KO) |
|------------|-------------------|-------------------|
| `connectionFailed` | "Connection lost. Reconnecting..." | "연결이 끊겼습니다. 재연결 중..." |
| `orderNotFound` | "Order not found. Refreshing..." | "주문을 찾을 수 없습니다. 새로고침 중..." |
| `databaseError` | "Failed to save. Please try again." | "저장 실패. 다시 시도해주세요." |
| `syncFailed` | "Sync failed. Check connection." | "동기화 실패. 연결을 확인하세요." |

---

## 7. Security Considerations

- [ ] **Local Network Only**: WebSocket server binds to `0.0.0.0:8080` (accessible on LAN)
- [ ] **No Internet Exposure**: Firewall rules prevent external access
- [ ] **Input Validation**: Sanitize all incoming WebSocket messages
- [ ] **SQL Injection Prevention**: Use Drift parameterized queries
- [ ] **XSS Prevention**: Sanitize HTML rendering in Flutter (auto-handled)
- [ ] **Rate Limiting**: Limit message frequency to prevent DoS (future)
- [ ] **HTTPS/WSS**: Not required for local network (future: optional TLS)

**Future Security Enhancements (v2.0):**
- JWT authentication for WebSocket connections
- Role-based access control (kitchen staff vs manager)
- Audit logging for all order status changes
- TLS/SSL for encrypted communication

---

## 8. Test Plan

### 8.1 Test Scope

| Type | Target | Tool |
|------|--------|------|
| **Unit Test** | Business logic (order status transitions) | Flutter test framework |
| **Widget Test** | UI components (OrderCard, OrderTimer) | Flutter widget testing |
| **Integration Test** | WebSocket communication | Mockito + websocket_channel |
| **E2E Test** | Full POS→KDS flow | Manual testing |
| **Load Test** | 50+ concurrent orders | Custom load generator |

### 8.2 Test Cases (Key)

**Happy Path:**
- [x] POS creates order → KDS receives and displays within 1 second
- [x] Kitchen staff marks order as "preparing" → Status updates in DB and UI
- [x] Kitchen staff marks order as "ready" → UI moves to ready section
- [x] Kitchen staff marks order as "completed" → Order hidden after 5 minutes

**Error Scenarios:**
- [x] WebSocket disconnects → Auto-reconnect within 5 seconds
- [x] Database unavailable → Show error message, retry
- [x] Invalid message received → Log error, ignore message
- [x] Order already completed → Silently ignore duplicate update

**Edge Cases:**
- [x] Order created with 0 items → Show error in UI
- [x] Order with very long special instructions (>500 chars) → Truncate with "..."
- [x] 100+ orders displayed → UI remains responsive (pagination)
- [x] Network interruption during order creation → Order queued and sent on reconnect

### 8.3 Performance Benchmarks

| Metric | Target | Measurement |
|--------|--------|-------------|
| Order display latency | <1 second | WebSocket round-trip time |
| UI frame rate | 60 FPS | Flutter DevTools profiler |
| Memory usage (50 orders) | <200 MB | Dart Observatory |
| Database query time | <50 ms | Drift query profiler |
| WebSocket reconnect time | <5 seconds | Timer |

---

## 9. Clean Architecture (Flutter)

### 9.1 Layer Structure

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | UI, widgets, state management (Riverpod) | `lib/features/kds/presentation/` |
| **Domain** | Business logic, entities, use cases | `lib/features/kds/domain/` |
| **Data** | Repositories, data sources (WebSocket, DB) | `lib/features/kds/data/` |
| **Core** | Shared utilities (theme, i18n, network) | `lib/core/` |

### 9.2 Dependency Rules

```
┌────────────────────────────────────────────────────────────┐
│                 Flutter Clean Architecture                  │
├────────────────────────────────────────────────────────────┤
│                                                             │
│   Presentation ──→ Domain ←── Data                          │
│        │              ▲           │                         │
│        │              │           │                         │
│        └──────────────┴───────────┘                         │
│                       │                                     │
│                    Core (shared)                            │
│                                                             │
│   Rule: Domain is independent (no Flutter/Drift imports)   │
│         Data implements Domain interfaces                   │
│         Presentation depends on Domain, not Data            │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### 9.3 File Import Rules

| From | Can Import | Cannot Import |
|------|-----------|---------------|
| Presentation | Domain, Core, Flutter | Data directly (use repositories) |
| Domain | Core only (no external deps) | Presentation, Data, Flutter, Drift |
| Data | Domain, Core, Drift, WebSocket | Presentation |
| Core | Nothing external | Domain, Data, Presentation |

### 9.4 This Feature's Layer Assignment

| Component | Layer | Location |
|-----------|-------|----------|
| `KitchenDisplayScreen` | Presentation | `lib/features/kds/presentation/screens/` |
| `OrderCard`, `OrderTimer` | Presentation | `lib/features/kds/presentation/widgets/` |
| `ordersProvider` | Presentation | `lib/features/kds/presentation/providers/` |
| `KitchenOrder` (entity) | Domain | `lib/features/kds/domain/entities/` |
| `OrderRepository` (interface) | Domain | `lib/features/kds/domain/repositories/` |
| `GetOrdersUseCase` | Domain | `lib/features/kds/domain/usecases/` |
| `OrderRepositoryImpl` | Data | `lib/features/kds/data/repositories/` |
| `WebSocketDataSource` | Data | `lib/features/kds/data/datasources/` |
| `KitchenOrdersDao` | Data | `lib/database/daos/` |
| `WebSocketClient` | Core | `lib/core/network/` |

---

## 10. Coding Convention Reference

> Reference: Existing Flutter/Dart conventions in `CLAUDE.md`

### 10.1 Naming Conventions

| Target | Rule | Example |
|--------|------|---------|
| **Screens** | PascalCase + `Screen` suffix | `KitchenDisplayScreen` |
| **Widgets** | PascalCase | `OrderCard`, `OrderTimer` |
| **Providers** | camelCase + `Provider` suffix | `ordersProvider`, `webSocketProvider` |
| **DAO** | PascalCase + `Dao` suffix | `KitchenOrdersDao` |
| **Entities** | PascalCase | `KitchenOrder`, `KitchenOrderItem` |
| **Files** | snake_case | `kitchen_display_screen.dart` |
| **Folders** | snake_case | `kitchen_orders/`, `websocket/` |
| **Constants** | camelCase with `k` prefix | `kDefaultPort = 8080` |

### 10.2 Import Order (Dart)

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter framework
import 'package:flutter/material.dart';

// 3. Third-party packages (alphabetical)
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// 4. Internal app imports (alphabetical)
import 'package:oda_pos/core/theme/app_theme.dart';
import 'package:oda_pos/features/kds/domain/entities/kitchen_order.dart';
import 'package:oda_pos/l10n/app_localizations.dart';

// 5. Relative imports
import '../widgets/order_card.dart';
```

### 10.3 Environment Variables

| Variable | Purpose | Default | Location |
|----------|---------|---------|----------|
| `KDS_WS_PORT` | WebSocket server port | 8080 | `.env` |
| `KDS_DB_PATH` | SQLite database path | `oda_pos.db` | `.env` |
| `KDS_AUTO_HIDE_MINUTES` | Minutes before hiding completed orders | 5 | Code constant |
| `KDS_MAX_ORDERS_DISPLAY` | Max orders per page | 50 | Code constant |

### 10.4 This Feature's Conventions

| Item | Convention Applied |
|------|-------------------|
| **Component naming** | PascalCase with descriptive suffixes (Screen, Card, Provider) |
| **File organization** | Feature-based folder structure under `lib/features/kds/` |
| **State management** | Riverpod with `StateNotifier` for complex state |
| **Error handling** | `Result<T, E>` pattern with explicit error types |
| **Async operations** | `async/await` with `FutureBuilder` or `AsyncValue` |

---

## 11. Implementation Guide

### 11.1 File Structure

```
lib/
├── features/
│   └── kds/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── websocket_datasource.dart
│       │   │   └── websocket_datasource_impl.dart
│       │   ├── models/
│       │   │   └── kitchen_order_model.dart
│       │   └── repositories/
│       │       └── order_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── kitchen_order.dart
│       │   │   └── kitchen_order_item.dart
│       │   ├── repositories/
│       │   │   └── order_repository.dart
│       │   └── usecases/
│       │       ├── get_orders.dart
│       │       ├── update_order_status.dart
│       │       └── create_kitchen_order.dart
│       └── presentation/
│           ├── screens/
│           │   └── kitchen_display_screen.dart
│           ├── widgets/
│           │   ├── order_card.dart
│           │   ├── order_card_expanded.dart
│           │   ├── order_timer.dart
│           │   ├── status_filter.dart
│           │   ├── order_item_list.dart
│           │   ├── special_instructions_chip.dart
│           │   └── connection_status_indicator.dart
│           └── providers/
│               ├── orders_provider.dart
│               ├── websocket_provider.dart
│               └── selected_filter_provider.dart
├── core/
│   └── network/
│       ├── websocket_client.dart
│       └── websocket_message.dart
├── database/
│   ├── tables/
│   │   └── kitchen_orders.dart
│   └── daos/
│       └── kitchen_orders_dao.dart
└── l10n/
    ├── app_en.arb  (add KDS strings)
    ├── app_ko.arb  (add KDS strings)
    └── app_vi.arb  (add KDS strings)

kds_server/  (Separate WebSocket server)
├── main.dart
├── handlers/
│   ├── order_handler.dart
│   └── websocket_handler.dart
├── models/
│   └── websocket_message.dart
└── utils/
    └── broadcaster.dart

web/
└── kds_index.html  (Entry point for KDS web app)
```

### 11.2 Implementation Order (7-Day Plan)

**Day 1: Database & Models**
- [x] Create `kitchen_orders` table in Drift schema
- [x] Generate Drift code with `flutter pub run build_runner build`
- [x] Create `KitchenOrder` entity and `KitchenOrderItem`
- [x] Create `KitchenOrdersDao` with CRUD operations
- [x] Unit tests for DAO

**Day 2: WebSocket Server**
- [x] Setup `kds_server/` directory with Dart shelf
- [x] Implement WebSocket handler with message routing
- [x] Implement broadcast mechanism for multiple clients
- [x] Add ping/pong heartbeat
- [x] Test server with `wscat` tool

**Day 3: WebSocket Client & Repository**
- [x] Create `WebSocketClient` in core/network
- [x] Implement auto-reconnect logic
- [x] Create `OrderRepository` interface (domain)
- [x] Create `OrderRepositoryImpl` (data layer)
- [x] Unit tests for client and repository

**Day 4: POS Integration**
- [x] Add WebSocket client to POS checkout screen
- [x] Send `order_created` message on successful payment
- [x] Create `KitchenOrder` record in database
- [x] Test POS→Server→KDS message flow

**Day 5: KDS Frontend - Basic**
- [x] Create `KitchenDisplayScreen` with order grid
- [x] Implement `OrderCard` widget with status display
- [x] Add `OrderTimer` with real-time countdown
- [x] Implement status filter (All/Preparing/Ready/Completed)

**Day 6: KDS Frontend - Advanced**
- [x] Create `OrderCardExpanded` modal for full details
- [x] Implement status update buttons (Preparing/Ready/Complete)
- [x] Add `SpecialInstructionsChip` for allergies
- [x] Implement order age color coding
- [x] Add connection status indicator

**Day 7: Testing & Polish**
- [x] Integration test: POS→KDS full flow
- [x] Load test: 50+ concurrent orders
- [x] Network interruption test (disconnect/reconnect)
- [x] Multi-language verification (EN/KO/VI)
- [x] UI/UX polish (animations, transitions)
- [x] Documentation (README, setup guide)

### 11.3 Dependencies to Install

```yaml
# pubspec.yaml
dependencies:
  # Existing dependencies...
  shelf: ^1.4.0              # HTTP server framework
  shelf_web_socket: ^1.0.4   # WebSocket support for server
  web_socket_channel: ^2.4.0 # WebSocket client

dev_dependencies:
  # Existing dev dependencies...
  mockito: ^5.4.0            # Mocking for tests
```

### 11.4 Configuration Files

**`.env` (new file):**
```bash
KDS_WS_PORT=8080
KDS_DB_PATH=oda_pos.db
KDS_AUTO_HIDE_MINUTES=5
KDS_MAX_ORDERS_DISPLAY=50
```

**`web/kds_index.html` (new file):**
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Kitchen Display System - Oda POS</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

---

## 12. Localization Strings to Add

### 12.1 English (`app_en.arb`)

```json
{
  "kdsTitle": "Kitchen Display System",
  "orderStatusPending": "Pending",
  "orderStatusPreparing": "Preparing",
  "orderStatusReady": "Ready",
  "orderStatusCompleted": "Completed",
  "orderStatusCancelled": "Cancelled",
  "filterAll": "All",
  "filterPreparing": "Preparing",
  "filterReady": "Ready",
  "filterCompleted": "Completed",
  "btnStartPreparing": "Start Preparing",
  "btnMarkReady": "Mark Ready",
  "btnComplete": "Complete",
  "orderAge": "{minutes} min",
  "specialInstructions": "Special Instructions",
  "itemModifications": "Modifications",
  "connectionStatusConnected": "Connected",
  "connectionStatusReconnecting": "Reconnecting...",
  "connectionStatusDisconnected": "Disconnected",
  "newOrderToast": "New order: {receiptNumber}",
  "orderCancelledToast": "Order {receiptNumber} cancelled",
  "noOrdersFound": "No orders found",
  "tableLabelShort": "Table"
}
```

### 12.2 Korean (`app_ko.arb`)

```json
{
  "kdsTitle": "주방 디스플레이 시스템",
  "orderStatusPending": "대기 중",
  "orderStatusPreparing": "조리 중",
  "orderStatusReady": "완료",
  "orderStatusCompleted": "제공 완료",
  "orderStatusCancelled": "취소됨",
  "filterAll": "전체",
  "filterPreparing": "조리 중",
  "filterReady": "완료",
  "filterCompleted": "제공 완료",
  "btnStartPreparing": "조리 시작",
  "btnMarkReady": "완료 표시",
  "btnComplete": "제공 완료",
  "orderAge": "{minutes}분",
  "specialInstructions": "특수 요청",
  "itemModifications": "변경 사항",
  "connectionStatusConnected": "연결됨",
  "connectionStatusReconnecting": "재연결 중...",
  "connectionStatusDisconnected": "연결 끊김",
  "newOrderToast": "신규 주문: {receiptNumber}",
  "orderCancelledToast": "주문 {receiptNumber} 취소됨",
  "noOrdersFound": "주문이 없습니다",
  "tableLabelShort": "테이블"
}
```

### 12.3 Vietnamese (`app_vi.arb`)

```json
{
  "kdsTitle": "Hệ thống hiển thị bếp",
  "orderStatusPending": "Đang chờ",
  "orderStatusPreparing": "Đang chuẩn bị",
  "orderStatusReady": "Sẵn sàng",
  "orderStatusCompleted": "Hoàn thành",
  "orderStatusCancelled": "Đã hủy",
  "filterAll": "Tất cả",
  "filterPreparing": "Đang chuẩn bị",
  "filterReady": "Sẵn sàng",
  "filterCompleted": "Hoàn thành",
  "btnStartPreparing": "Bắt đầu chuẩn bị",
  "btnMarkReady": "Đánh dấu sẵn sàng",
  "btnComplete": "Hoàn thành",
  "orderAge": "{minutes} phút",
  "specialInstructions": "Yêu cầu đặc biệt",
  "itemModifications": "Thay đổi",
  "connectionStatusConnected": "Đã kết nối",
  "connectionStatusReconnecting": "Đang kết nối lại...",
  "connectionStatusDisconnected": "Mất kết nối",
  "newOrderToast": "Đơn mới: {receiptNumber}",
  "orderCancelledToast": "Đơn {receiptNumber} đã hủy",
  "noOrdersFound": "Không tìm thấy đơn hàng",
  "tableLabelShort": "Bàn"
}
```

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-08 | Initial draft | AI Development Team |
| 1.0 | 2026-02-08 | Design approved, ready for implementation | AI Development Team |
