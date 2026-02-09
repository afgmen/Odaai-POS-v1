# Kitchen Display System (KDS) Planning Document

> **Summary**: Real-time web-based kitchen display system for receiving and managing orders from POS
>
> **Project**: Oda POS
> **Version**: 1.0.0
> **Author**: AI Development Team
> **Date**: 2026-02-08
> **Status**: Draft

---

## 1. Overview

### 1.1 Purpose

The Kitchen Display System (KDS) enables kitchen staff to receive orders in real-time from the POS system, manage order preparation status, and track order timing. This eliminates paper tickets, reduces errors, and improves kitchen workflow efficiency.

**Key Benefits:**
- Real-time order transmission from POS to kitchen
- Digital order tracking (Preparing → Ready → Completed)
- Visual priority indicators based on order age
- Support for order modifications and special requests
- Multi-device support (tablets, monitors, any browser)

### 1.2 Background

**Current Pain Points:**
- No automated kitchen notification when orders are placed
- Manual coordination required between POS and kitchen
- Difficult to track order status and timing
- Paper-based systems prone to errors and loss

**Business Value:**
- Faster order fulfillment (estimated 20-30% improvement)
- Reduced order errors
- Better customer satisfaction through timely service
- Scalable solution for multiple kitchen stations

### 1.3 Related Documents

- Requirements: This document (Phase 1 Plan)
- References:
  - Existing POS System: `/Users/JINLee/Documents/AI-coding/Odaai-POS/oda_pos`
  - Database Schema: `lib/database/app_database.dart`

---

## 2. Scope

### 2.1 In Scope

- [x] **Real-time Order Display**: Web-based interface showing incoming orders
- [x] **Order Status Management**: Kitchen staff can mark orders as Preparing/Ready/Completed
- [x] **Priority & Timing**: Visual indicators for order age, color-coded urgency
- [x] **Order Modifications Display**: Show special requests, allergies, customizations
- [x] **WebSocket Communication**: Real-time bidirectional communication between POS and KDS
- [x] **Responsive UI**: Works on tablets (10"+), monitors (24"+), and mobile (6"+)
- [x] **Multi-language Support**: English, Korean, Vietnamese (matching POS)
- [x] **Local Network Operation**: Works on same WiFi/LAN without internet

### 2.2 Out of Scope

- Multiple Station Routing (future v2.0): Different screens for grill, fryer, drinks
- Kitchen Printer Integration: Remains a separate manual process
- Inventory Deduction: Handled by POS, not KDS
- Recipe Display: Not included in v1.0
- Customer Notifications: Handled separately by POS
- Voice Alerts/Sound Notifications: Future enhancement

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | Display new orders within 1 second of POS submission | High | Pending |
| FR-02 | Allow kitchen staff to update order status (Preparing/Ready/Completed) | High | Pending |
| FR-03 | Show order age in minutes with color coding (0-5min green, 5-10min yellow, 10+ red) | High | Pending |
| FR-04 | Display order items with quantity, name, and modifications | High | Pending |
| FR-05 | Show customer name/table number for order identification | High | Pending |
| FR-06 | Support touch interaction for tablets and monitors | High | Pending |
| FR-07 | Persist order status across browser refresh | Medium | Pending |
| FR-08 | Filter orders by status (All/Preparing/Ready/Completed) | Medium | Pending |
| FR-09 | Show order receipt number for reference | Medium | Pending |
| FR-10 | Display special instructions prominently (allergies, customizations) | High | Pending |
| FR-11 | Auto-hide completed orders after 5 minutes | Low | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| **Performance** | Order display latency < 1 second | WebSocket round-trip timing |
| **Reliability** | 99.9% uptime during business hours | Error rate monitoring |
| **Usability** | Readable from 2 meters away | Font size 18px+ |
| **Scalability** | Support 50+ concurrent orders | Load testing |
| **Network** | Works on local network (no internet required) | Offline testing |
| **Compatibility** | Works on Chrome, Safari, Firefox (latest 2 versions) | Browser testing |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] POS can send orders to KDS via WebSocket
- [ ] KDS displays orders in real-time
- [ ] Kitchen staff can update order status
- [ ] Order timing and priority indicators work correctly
- [ ] Special instructions display prominently
- [ ] Works on tablets and large monitors
- [ ] Multi-language support (EN/KO/VI)
- [ ] Unit tests for order processing logic
- [ ] Integration tests for POS-KDS communication
- [ ] Documentation completed (setup guide)

### 4.2 Quality Criteria

- [ ] WebSocket connection auto-reconnects on failure
- [ ] Zero data loss during network interruptions
- [ ] No UI lag with 50+ orders displayed
- [ ] Touch targets minimum 44x44px (accessibility)
- [ ] Color contrast meets WCAG 2.1 AA standards

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Network interruption** | High | Medium | Implement auto-reconnect, queue orders locally |
| **WebSocket compatibility** | Medium | Low | Fallback to Server-Sent Events (SSE) |
| **Browser compatibility** | Low | Low | Test on major browsers, use standard Web APIs |
| **Database sync conflicts** | Medium | Medium | Use optimistic locking, timestamp-based conflict resolution |
| **Kitchen staff training** | Low | Medium | Provide simple UI, on-screen help tooltips |
| **Multiple KDS instances** | High | High | Implement proper state synchronization via DB |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure (`components/`, `lib/`, `types/`) | Static sites, portfolios, landing pages | ☐ |
| **Dynamic** | Feature-based modules, services layer | Web apps with backend, SaaS MVPs | ☑ |
| **Enterprise** | Strict layer separation, DI, microservices | High-traffic systems, complex architectures | ☐ |

**Rationale**: Dynamic level is appropriate because:
- KDS requires backend integration (WebSocket server, database)
- Feature-based structure fits our order management domain
- Not complex enough to justify Enterprise-level architecture
- Aligns with existing Flutter POS architecture (features/, providers/, services/)

### 6.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| **Frontend Framework** | Flutter Web / Next.js / React / Vue | **Flutter Web** | Reuse existing codebase, shared components with POS |
| **State Management** | Riverpod / Provider / Bloc / GetX | **Riverpod** | Already used in POS, consistent architecture |
| **Real-time Communication** | WebSocket / SSE / Polling | **WebSocket** | Bidirectional, low latency, efficient |
| **Backend** | Embedded HTTP Server / External Node.js | **Dart shelf + WebSocket** | Simpler deployment, single technology stack |
| **Database** | Shared SQLite / Separate DB | **Shared SQLite** | Real-time sync, single source of truth |
| **Styling** | Material Design / Custom CSS | **Material Design 3** | Consistent with POS, built-in Flutter |
| **Deployment** | Separate Web Server / Embedded in POS | **Separate Web Server** | Independent scaling, kitchen-only access |

### 6.3 Clean Architecture Approach

```
Selected Level: Dynamic

Folder Structure:
oda_pos/
├── lib/
│   ├── features/
│   │   ├── pos/              # Existing POS features
│   │   ├── kds/              # NEW: Kitchen Display System
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── websocket_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── kitchen_order.dart
│   │   │   │   └── repositories/
│   │   │   │       └── order_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── kitchen_order.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── order_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_orders.dart
│   │   │   │       └── update_order_status.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── kitchen_display_screen.dart
│   │   │       ├── widgets/
│   │   │       │   ├── order_card.dart
│   │   │       │   ├── order_timer.dart
│   │   │       │   └── status_filter.dart
│   │   │       └── providers/
│   │   │           ├── orders_provider.dart
│   │   │           └── websocket_provider.dart
│   ├── core/
│   │   ├── network/
│   │   │   └── websocket_client.dart  # NEW
│   │   └── theme/
│   └── database/
│       ├── tables/
│       │   └── kitchen_orders.dart     # NEW
│       └── daos/
│           └── kitchen_orders_dao.dart  # NEW
├── kds_server/                          # NEW: Separate WebSocket server
│   ├── main.dart
│   ├── websocket_handler.dart
│   └── routes.dart
└── web/
    └── kds_index.html                   # NEW: KDS web entry point
```

**Layer Responsibilities:**
- **Presentation**: UI components, state management, user interactions
- **Domain**: Business logic, use cases, entity definitions
- **Data**: External data sources (WebSocket, SQLite), repository implementations
- **Core**: Shared utilities (WebSocket client, theme, i18n)

---

## 7. Convention Prerequisites

### 7.1 Existing Project Conventions

Check which conventions already exist in the project:

- [x] `CLAUDE.md` has coding conventions section (Flutter/Dart conventions)
- [ ] `docs/01-plan/conventions.md` exists (Phase 2 output)
- [ ] `CONVENTIONS.md` exists at project root
- [x] Analysis options (`.analysis_options.yaml`)
- [ ] Prettier configuration (`.prettierrc`) - Not applicable for Dart
- [x] Dart SDK configuration (`pubspec.yaml`)

**Existing Conventions to Follow:**
- Flutter 3.10.8+ with Dart 3.0+
- Riverpod 2.5.1 for state management
- Drift 2.16.0 for database ORM
- Material Design 3 theme
- Feature-based folder structure
- Repository pattern for data access

### 7.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **Naming** | Existing (snake_case files, PascalCase classes) | WebSocket message format | High |
| **Folder structure** | Existing (features/, core/, database/) | kds/ feature structure | High |
| **WebSocket Protocol** | Missing | Message types, payload structure | High |
| **Order Status Enum** | Missing | Status values (pending/preparing/ready/completed) | High |
| **Error handling** | Existing (try-catch, Result pattern) | WebSocket error handling | Medium |
| **Color coding** | Missing | Order age color rules | Medium |

### 7.3 Environment Variables Needed

| Variable | Purpose | Scope | To Be Created |
|----------|---------|-------|:-------------:|
| `KDS_WS_PORT` | WebSocket server port (default: 8080) | Server | ☑ |
| `KDS_DB_PATH` | Shared SQLite database path | Server | ☑ |
| `KDS_AUTO_HIDE_MINUTES` | Minutes before auto-hiding completed orders | Client | ☑ |
| `KDS_MAX_ORDERS_DISPLAY` | Max orders to display simultaneously | Client | ☑ |

### 7.4 Pipeline Integration

This feature does NOT use the 9-phase Development Pipeline. It follows the standard PDCA cycle:

**PDCA Phases:**
1. **Plan** (This document): Requirements, architecture, scope
2. **Design**: Database schema, API design, UI mockups, WebSocket protocol
3. **Do**: Implementation (database, backend, frontend)
4. **Check**: Gap analysis, testing, verification
5. **Act**: Iteration and improvement based on gaps

---

## 8. Technical Implementation Plan

### 8.1 Database Schema Changes

**New Table: `kitchen_orders`**
```sql
CREATE TABLE kitchen_orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL UNIQUE,  -- Reference to sales table
  receipt_number TEXT NOT NULL,
  customer_name TEXT,
  table_number TEXT,
  status TEXT NOT NULL,  -- pending, preparing, ready, completed
  items_json TEXT NOT NULL,  -- JSON array of order items
  special_instructions TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  completed_at INTEGER,
  FOREIGN KEY (sale_id) REFERENCES sales(id)
);

CREATE INDEX idx_kitchen_orders_status ON kitchen_orders(status);
CREATE INDEX idx_kitchen_orders_created_at ON kitchen_orders(created_at);
```

### 8.2 WebSocket Protocol

**Message Types:**
```dart
// POS → KDS: New order created
{
  "type": "order_created",
  "payload": {
    "orderId": 123,
    "receiptNumber": "ODA-20260208-001",
    "customerName": "John Doe",
    "tableNumber": "A-5",
    "items": [
      {"name": "Burger", "quantity": 2, "modifications": "No onions"},
      {"name": "Fries", "quantity": 1, "modifications": null}
    ],
    "specialInstructions": "Allergy: peanuts",
    "createdAt": 1707379200000
  }
}

// KDS → POS: Order status updated
{
  "type": "order_status_updated",
  "payload": {
    "orderId": 123,
    "status": "preparing",  // or "ready", "completed"
    "updatedAt": 1707379300000
  }
}

// Heartbeat (every 30 seconds)
{
  "type": "ping",
  "payload": {}
}

// Server response
{
  "type": "pong",
  "payload": {}
}
```

### 8.3 Component Breakdown

**Frontend Components:**
1. `KitchenDisplayScreen` - Main container screen
2. `OrderCard` - Individual order display with status buttons
3. `OrderTimer` - Real-time elapsed time display
4. `StatusFilter` - Filter buttons (All/Preparing/Ready/Completed)
5. `OrderItemList` - List of items in an order
6. `SpecialInstructionsChip` - Highlighted badge for special requests

**Backend Components:**
1. `WebSocketServer` - Dart shelf server with WebSocket support
2. `OrderHandler` - Processes order messages
3. `KitchenOrdersDao` - Database access layer
4. `WebSocketBroadcaster` - Sends updates to all connected clients

### 8.4 Development Phases

**Phase 1: Database & Models** (Day 1)
- Create `kitchen_orders` table in Drift schema
- Define `KitchenOrder` entity and models
- Create `KitchenOrdersDao` with CRUD operations

**Phase 2: WebSocket Server** (Day 2-3)
- Implement Dart shelf WebSocket server
- Create message handlers (order_created, order_status_updated)
- Implement broadcast mechanism for multiple clients
- Add auto-reconnect logic

**Phase 3: POS Integration** (Day 4)
- Add WebSocket client to POS
- Send order_created message on successful payment
- Listen for order status updates (optional, for POS dashboard)

**Phase 4: KDS Frontend** (Day 5-6)
- Create `KitchenDisplayScreen` with order grid layout
- Implement `OrderCard` with status buttons
- Add real-time timer display
- Implement status filter and sorting

**Phase 5: Testing & Polish** (Day 7)
- Integration testing (POS → KDS flow)
- Load testing (50+ concurrent orders)
- Network interruption testing
- Multi-language verification
- UI/UX polish

---

## 9. Next Steps

1. [x] Write design document (`kitchen-display-system.design.md`)
   - Database schema details
   - API/WebSocket protocol specification
   - UI mockups and wireframes
   - State management flow diagrams

2. [ ] Team review and approval
   - Technical feasibility review
   - UX/UI design review
   - Security and performance review

3. [ ] Start implementation (PDCA Do phase)
   - Follow 5-phase development plan above
   - Daily progress tracking
   - Continuous integration testing

---

## 10. Open Questions

1. **Question**: Should KDS support multiple languages dynamically, or fixed at startup?
   **Answer**: Fixed at startup (match POS language setting)

2. **Question**: What happens if network connection drops during order transmission?
   **Answer**: Implement message queue with retry logic, persist to SQLite

3. **Question**: Should completed orders be archived or deleted?
   **Answer**: Archive in database, auto-hide from display after 5 minutes

4. **Question**: How to handle order cancellations from POS?
   **Answer**: Add "order_cancelled" message type, mark as cancelled in DB

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-08 | Initial draft | AI Development Team |
| 1.0 | 2026-02-08 | Plan approved, ready for Design phase | AI Development Team |
