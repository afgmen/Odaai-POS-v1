# PRD: Multi-Layer Approval System - Web Implementation

> Version: 1.0  
> Author: Mama (PM)  
> Created: 2026-02-25  
> Requester: Jin  
> Status: Draft  

---

## 1. Overview

### 1.1 Background
Currently, the Multi-Layer Approval System in the Oda platform is implemented through **email-based web links**. Approvers receive approval requests via email and perform approve/reject actions through web links.

### 1.2 Objectives
Implement this system **directly within the web application** to reduce email dependency and support real-time approval processes.

### 1.3 Scope
Convert all requirements from the existing 8 feature documents to web UI:

| # | Original Document | Core Feature |
|---|----------|----------|
| 1 | [OFA] Add "Multiplayer approval" feature on the Admin | Multi-layer approval toggle setting per company in Admin |
| 2 | [OFD, OFM] "Approval setting" feature on the Settings | Create/edit/delete/sort approval layer list |
| 3 | [OFD, OFM] "Approval request" feature in the Buy order | Create and manage approval requests in purchase orders |
| 4 | [OFD, OFM] Approve order by email template | Approval process via email/web link |
| 5 | Add a "Branch" selection when creating approver | Approver settings per branch |
| 6 | Send rejection/approval email notification | Rejection/approval email notifications |
| 7 | Improve approval request by product in an order | Partial approval/rejection by product and notes |
| 8 | [OFD, OFM] Adjust the quantity on the approval request | Modify quantity/notes in approval request |

---

## 2. Glossary

| Term | Description |
|------|------|
| Requester | The employee/buyer who creates the purchase order and requests approval |
| Approver | The approval manager registered in the approval layer |
| Approval Layer | Approval stage (Layer 1 → Layer 2 → ... → Final Layer) |
| Approval Request | A single approval request (1 request_id, multiple order_ids possible) |
| Branch | Company branch/department |
| Partial Approval | Approving only some products in an order while rejecting others |
| OFA | Oda For Admin |
| OFD | Oda For Desktop |
| OFM | Oda For Mobile |

---

## 3. Functional Requirements

### 3.1 Admin Settings - Multi-Layer Approval Toggle

**Path:** Admin > Companies > Company mngt > Company detail > Setting tab

| Item | Detail |
|------|------|
| Setting Name | Multi-layer approval |
| Description | Allow user to implement a multi-layer approval process for buy orders |
| Type | Toggle (On/Off) |
| Position | Below Profit setting |
| Default | Off |
| Off | Existing single-layer approval (Role permission based) |
| On | Multi-layer approval enabled (new feature) |
| Toast | "Multi-layer approval settings updated successfully." |

**Multi-language Support:**
- ENG: Allow user to implement a multi-layer approval process for orders.
- VIE: Cho phép người dùng triển khai quy trình phê duyệt nhiều lớp cho đơn hàng.
- KOR: 사용자가 주문에 대해 다중 계층 승인 프로세스를 구현할 수 있도록 허용합니다.

---

### 3.2 Approval Setting - Approval Layer Management

**Path:** (Web) Settings > Approval setting

**Prerequisite:** "Multi-layer approval" toggle is ON in Admin

#### 3.2.1 Page Structure

- **Header:** Approval setting
- **Section Label:** Approval layer list
- **Buttons:**
  - `Create layer` - Add new layer (create N+1 after current Layer N)
  - `Sort layer` - Open layer sorting popup
  - `Cancel` - Revert all changes since last save (always active)
  - `Save` - Save current UI/data (active only when there are changes)

**Save Toast:** "Approval layer has been updated successfully."

#### 3.2.2 Layer Creation/Editing

| Field | Required | Editable | Type | Value/Rules |
|------|------|---------|------|---------|
| Layer no | - | NO | System | Auto-generated (Layer 1, Layer 2, ...) |
| Layer name | YES | YES | Text | Placeholder: "Enter layer name" |
| Delete layer | - | - | Icon | Hide layer on click (not applied until Save) |
| Approver name | YES | YES | Text | Placeholder: "Enter name" |
| Approver email | YES | YES | Text | Placeholder: "Enter email" |
| Branch | YES | YES | Single select | "All" (default) or specific branch |

**Rules:**
- 1 layer - multiple approvers: if any one approves, move to next layer
- Can add (+icon) and remove (-icon) approvers
- Branch selection cannot be cleared (must always have a value)
- To assign the same approver to multiple branches, must add separately for each branch

#### 3.2.3 Branch Selection Rules

| User Type | "All" Option | Branch List |
|------------|-----------|------------|
| Company or HQ staff | Enabled | All branches of the company |
| Branch staff | Disabled | Only branches assigned to that staff |

#### 3.2.4 Layer Sorting (Sort)

- Clicking "Sort layer" button displays popup
- **Title:** Sort approval layer
- **Table:** Layer no. (before sort), Layer no. (after sort - fixed values 1,2,3...), Layer name
- Users can change order via drag or swap
- Layer no. maintains sequential order after sorting (1, 2, 3...)

#### 3.2.5 Activity Log
- Record layer changes in activity log (same as existing method)

---

### 3.3 Buy Order - Approval Request

**Prerequisite:** "Multi-layer approval" toggle is ON in Admin

#### 3.3.1 Approval Request on Order Creation

**Path:** Buy > Buy order > Create buy order / Buy > Favorite > Create order

| Case | Action |
|------|------|
| Approval layer = null (not configured) | Alert popup: "You have not configured a multi-layer approval. Please create an approval layer list to send the order to the approvers." / Cancel: Close popup / OK: Navigate to Approval setting page |
| Approval layer ≠ null | After order creation, send to 1st approver |
| Excel import | Created as Draft status (no approval status) |

**Multiple Supplier Handling:**
- Single supplier: 1 order → 1 request_id, 1 order_id → 1 email + 1 web link
- Multiple suppliers: N orders → 1 request_id, N order_ids → 1 email + 1 web link (containing multiple orders)

**Note:** Users without Approve Order permission can still create orders and send them to approvers

#### 3.3.2 Order List (Buy Order List)

**All Tab:**
- Confirm "Waiting for approval" notification is hidden

**Draft Tab:**
- Change description text: "Please select order(s) that need to be requested for approval"
- Hide "…" menu icon at end of each row
- **Add New Column:** "Approval status" (between Status and Amount)
  - Values:
    - `-` : Draft status, before approval request
    - `Waiting` (Confirmed color): Approval process in progress
    - `Rejected` (Cancelled color): Approval rejected

**"Request for approval" Button (replaces existing "Approve and send order"):**
- Default: Disabled
- When Draft order selected: Enabled

| Selection State | Action |
|----------|------|
| Layer = null | Use case 1.1 (unconfigured alert) |
| Selected orders ≠ Waiting & ≠ Rejected | Confirmation popup: "Do you want to request approval for order(s)?" → On Confirm, send to 1st approver |
| Selection includes Waiting or Rejected orders | Warning popup: Display list of those orders + "You cannot request approval for the following orders as they have been approved or are currently in the approval process." |

#### 3.3.3 Order Detail - Actions and Status

| Approval Status | Available Actions |
|----------------|-----------|
| `-` (not requested) | Existing actions + Request approval |
| Waiting | No actions available |
| Denied/Rejected | Existing actions + Request approval (re-request) |
| Approved | → Move to Unconfirmed tab |

#### 3.3.4 Order Detail - Approval Process Section

**Position:** Between Order status and Order Amount

**Display Information:**
- For each layer:
  - Approver: Name and email (previous/next)
  - Action time
  - Status (Approved/Rejected/Waiting)
  - Note (memo entered during approval)

**Branch Integration:**
- Branch = "All": Display approvers from all company branches
- Branch = specific branch: Display only approvers mapped to that branch
- If layer has 0 approvers for that branch, hide that layer

---

### 3.4 Web-Based Approval Processing (Existing Email Web Link → Web App Implementation)

> **Core Change:** Previously approved/rejected via email → web link, now handled directly within web app

#### 3.4.1 Approval Request Web Page

**Display Information:**
- Approval process (approval status per layer)
- Created at (request creation time)
- Order information
- Product list

**Action Buttons:**

| Button | Action |
|------|------|
| Approve All | Approve all orders - show confirmation popup |
| Reject All | Reject all orders - rejection reason input popup (required, text) |
| Approve (individual) | Approve individual order |
| Reject (individual) | Reject individual order |

**Note Field on Approval:**
- Label: Note
- Required: NO
- Type: Text
- Placeholder: "Enter note"

#### 3.4.2 Approval Flow

```
Requester creates order
  → Notify Layer 1 approver
    → Layer 1 approves → Notify Layer 2 approver
      → Layer 2 approves → ... → Final Layer approves
        → Order status: Draft → Unconfirmed
        → Send to supplier
```

**Approval Rules:**
- Mid-layer approval → Automatically notify next layer
- Final layer approval → Draft → Unconfirmed status change
- Rejection → Order status: Draft (no approval status) + Rejected display → Can re-request (restart from 1st layer)
- Rejection reason required on reject (popup, text field)

#### 3.4.3 Re-accessing Completed Approvals
- When re-accessing already approved/rejected request: View details only (no actions)

---

### 3.5 Partial Approval/Rejection by Product

#### 3.5.1 Rejecting Products

**Rules:**
- Approvers can **reject specific products** in an order (minimum 1 product must be approved)
- If single approval request contains multiple orders, **cannot reject all orders** → Must reject the entire request to reject all
- Rejected products are removed from order before forwarding to next layer

**Example:**
```
Approval request: Order #1 (10 items) + Order #2 (3 items)
Layer 1: Approve all
Layer 2: Reject 1 product in Order #1, approve rest
  → Forward to Layer 3: Order #1 (9 items) + Order #2 (3 items)
  → Send rejection notification to Requester and Layer 1
  → Rejected product can be re-ordered in new order if needed
```

**When Entire Order is Rejected:**
```
Layer 2: Reject all products in Order #2
  → Entire approval request rejected
  → Requester can delete Order #2 and re-request only Order #1
```

#### 3.5.2 Order Detail & History Recording

For rejected products:
- Reflect product removal in order detail
- Record in order history: `"{approver_name} ({approver_email}) (WEBLINK) removed the rejected item."`
- Color: Red

#### 3.5.3 Rejected Product Email Notification

When rejection occurs → Notify Requester + all previous layer approvers

---

### 3.6 Adjust Quantity on Approval Request

#### 3.6.1 Editable Fields

Approvers can directly edit on approval web page:

| Field | Description |
|------|------|
| Qty (quantity) | Can change quantity (Qty = 0 equals product removal) |
| Product note | Add/edit note per product |

**Rules:**
- Qty = 0 && Product note = NULL → Approve button disabled
- When Qty changed → Order total section auto-recalculates
- On Reject: Ignore qty/note changes (keep original values)
- On Approve: Save changes + record order history + send email notification

#### 3.6.2 Order History Recording

When modification occurs:
- Description: `"{approver_name} ({approver_email}) (WEBLINK) updated order"`
- Detail: `"Updated {number_of_edited_product} product(s)"`
- Color: Red
- "Show detail" link to view before/after changes

#### 3.6.3 Email Notification

On approval with qty/note changes → Update notification to Requester + all previous layer approvers

---

### 3.7 Notification System

> **Web Implementation:** Maintain email notifications, also add **in-app notifications** within web app

#### 3.7.1 Approval Request Notification (to Next Layer)

**Trigger:** Previous layer approval completed / New request created
**Recipients:** Next layer approvers (for that branch)
**Email:**
- Sender: Oda - Order.so easy
- Subject: `You have new approval request (#{request_id}) from {staff_name}`
- Header: New approval request
- Body: `Hi {approver_name}, You have 1 new approval request from {staff_name}. Please review and take action on this request by clicking the link: {weblink}`

#### 3.7.2 Rejection Notification

**Trigger:** Rejection occurs at any layer
**Recipients:** Requester (if staff email exists) + all previous layer approvers
**Email:**
- Subject: `Approval request (#{request_id}) has been rejected by {approver_name} ({approver_email})`
- Header: Approval request rejected
- Body: `Hi {name}, Approval request (#{request_id}) has been rejected by {approver_name} ({approver_email}) at YYYY-MM-DD HH:MM:SS. To view the details of this request, click the link: {weblink}`

#### 3.7.3 Final Approval Notification

**Trigger:** Approval completed at final layer
**Recipients:** Requester + all approvers
**Email:**
- Subject: `Approval request (#{request_id}) has been approved by {approver_name} ({approver_email})`
- Header: Approval request approved
- Body: Includes approval time

**Note:** Maintain existing supplier email notifications

#### 3.7.4 Email Language
- Send emails based on Requester's language setting

---

### 3.8 Approval Request List

**Path:** Buy > Buy order > Approval request (sub-menu)

Manage approval request history in list format:
- Request ID
- Request creation date
- Requester
- List of included orders
- Current approval status
- Current layer

---

### 3.9 Migration (Data Transfer)

Existing approver data:
- Current approvers → Automatically set Branch = "All"
- Preserve existing approval process data

---

## 4. Web Implementation Additions/Changes

### 4.1 Email Web Link → Web App Page Transition

| Existing (Email-based) | New (Web-based) |
|-------------------|---------------|
| Receive approval request via email | In-app notification + Email (parallel) |
| Click web link → External approval page | Navigate to approval page within web app |
| Web link token-based authentication | Web app login session-based authentication |
| Has expiration time (same as existing) | Login session maintained (no expiration) |

### 4.2 Add In-App Notifications

- Display approval request notifications in web app notification bell icon
- Real-time notifications (WebSocket or polling)
- Click notification to navigate to corresponding approval request page

### 4.3 Dashboard

- Display count of pending approval requests
- Display recent approval/rejection history

---

## 5. Pages/Screens List (Web Pages)

| # | Page | Path | User |
|---|--------|------|--------|
| 1 | Admin - Multi-layer approval settings | Admin > Companies > Setting | Admin |
| 2 | Approval Setting (Layer management) | Settings > Approval setting | Company Staff |
| 3 | Sort Layer popup | (within Approval Setting) | Company Staff |
| 4 | Buy Order List - Draft tab | Buy > Buy order > Draft | Buyer |
| 5 | Buy Order Detail - Approval Process | Buy > Buy order > Detail | Buyer |
| 6 | Approval Request Page (approval processing) | /approval/{request_id} | Approver |
| 7 | Approval Request List | Buy > Approval request | All |
| 8 | Reject Reason popup | (within Approval Request Page) | Approver |
| 9 | Approve with Note popup | (within Approval Request Page) | Approver |
| 10 | Qty/Note editing (inline) | (within Approval Request Page) | Approver |

---

## 6. API Endpoints (Proposal)

```
# Admin
PUT   /api/admin/companies/{id}/settings/multi-layer-approval

# Approval Setting
GET   /api/approval/layers
POST  /api/approval/layers
PUT   /api/approval/layers
PUT   /api/approval/layers/sort
DELETE /api/approval/layers/{layerId}

# Approval Request
POST  /api/approval/requests                    # Create approval request
GET   /api/approval/requests                    # List approval requests
GET   /api/approval/requests/{requestId}        # Approval request detail
POST  /api/approval/requests/{requestId}/approve # Approve
POST  /api/approval/requests/{requestId}/reject  # Reject

# Product-level actions
POST  /api/approval/requests/{requestId}/orders/{orderId}/products/{productId}/reject  # Reject product
PUT   /api/approval/requests/{requestId}/orders/{orderId}/products/{productId}          # Modify qty/note

# Notifications
GET   /api/notifications/approval               # List approval-related notifications
```

---

## 7. Data Model (Proposal)

```
approval_settings
  - company_id
  - multi_layer_enabled (boolean)

approval_layers
  - id
  - company_id
  - layer_no (integer)
  - layer_name (string)
  - created_at, updated_at

approval_layer_approvers
  - id
  - layer_id
  - approver_name (string)
  - approver_email (string)
  - branch_id (nullable, null = "All")
  - created_at, updated_at

approval_requests
  - id (request_id)
  - company_id
  - requester_id
  - requester_name
  - requester_email
  - current_layer_no
  - status (waiting / approved / rejected)
  - created_at, updated_at

approval_request_orders
  - request_id
  - order_id

approval_actions
  - id
  - request_id
  - layer_no
  - approver_name
  - approver_email
  - action (approve / reject)
  - note (nullable)
  - rejected_reason (nullable)
  - action_at

approval_product_actions
  - id
  - action_id
  - order_id
  - product_id
  - action (approve / reject / edit)
  - original_qty
  - new_qty (nullable)
  - original_note
  - new_note (nullable)
  - rejection_reason (nullable)
```

---

## 8. Non-Functional Requirements

| Item | Requirement |
|------|---------|
| Performance | Approval page load < 2 seconds |
| Security | Only approver can perform actions (session-based authentication) |
| Responsive | Desktop + Mobile support |
| Multi-language | Support for 3 languages: ENG, VIE, KOR |
| Real-time | Immediate notification to relevant parties on approval status change |
| Compatibility | Maintain existing email notifications (parallel with web notifications) |

---

## 9. Acceptance Criteria

### 9.1 Admin Settings
- [ ] Multi-layer approval toggle On/Off functional
- [ ] Toast message displayed on toggle change
- [ ] 3 languages supported

### 9.2 Approval Setting
- [ ] Can create/edit/delete layers
- [ ] Can sort layers
- [ ] Can select Branch (Company Staff: All + all branches / Branch Staff: assigned branches only)
- [ ] Can add/remove approvers
- [ ] Cancel: Revert changes / Save: Save + Toast

### 9.3 Buy Order - Approval Request
- [ ] Alert popup when layer not configured
- [ ] Auto send to 1st Layer on order creation
- [ ] Approval status column displayed in Draft tab
- [ ] Request for approval button functionality (warning for Waiting/Rejected orders)
- [ ] Draft → Unconfirmed status transition on approval completion

### 9.4 Approval Processing (Web Page)
- [ ] Approve All / Reject All functionality
- [ ] Individual order Approve / Reject functionality
- [ ] Note input available on Approve
- [ ] Reason required on Reject
- [ ] Auto notify next layer on approval completion
- [ ] View-only access on re-accessing processed requests

### 9.5 Partial Approval
- [ ] Can reject by product (minimum 1 approval required)
- [ ] Rejected products → Removed when forwarding to next layer
- [ ] Rejection recorded in order history
- [ ] Rejection email notification sent

### 9.6 Quantity Adjustment
- [ ] Can modify Qty and Product note on approval page
- [ ] Qty = 0 has product removal effect
- [ ] Order total auto-recalculates on change
- [ ] Changes ignored on Reject
- [ ] Modification history recorded and notification sent

### 9.7 Notifications
- [ ] Approval request email sent (next layer)
- [ ] Rejection email sent (Requester + previous layers)
- [ ] Final approval email sent (Requester + all approvers)
- [ ] In-app notifications displayed in web app
- [ ] Email language = Requester language setting

### 9.8 Migration
- [ ] Existing approvers → Branch = "All" auto-set
- [ ] Existing data integrity preserved

---

## 10. Implementation Phases (Development Priority)

### Phase 1 - Basic Settings and Approval Flow
1. Admin Multi-layer approval toggle (3.1)
2. Approval Setting page (3.2)
3. Buy Order approval request (3.3)
4. Web-based approval processing page (3.4)

### Phase 2 - Branch-based Approval and Notifications
5. Branch selection feature (3.2.3)
6. Notification system - Email + In-app (3.7)

### Phase 3 - Product-level Approval and Quantity Adjustment
7. Partial approval/rejection by product (3.5)
8. Quantity/note adjustment (3.6)
9. Approval request list (3.8)

### Phase 4 - Migration and QA
10. Data Migration (3.9)
11. Integration testing and QA

---

## Change History

| Date | Version | Changes | Author |
|------|------|----------|--------|
| 2026-02-25 | 1.0 | Initial PRD creation (8 documents consolidated) | Mama |
