# Production Manager - Complete System Architecture

## 🎉 Major Restructuring Complete!

Your app has been transformed from a simple box folding tracker into a **comprehensive Production Manager** system with:

- ✅ User authentication & role-based access control
- ✅ Orders management system
- ✅ Simplified wrapping tracker (RM415-focused)
- ✅ Quality control defect tracking
- ✅ Admin panel for user/task management
- ✅ JSON-based data persistence

---

## 🔐 Authentication System

### Default Login:
```
Username: admin
Password: admin
```

**IMPORTANT**: Change this password after first login!

### How It Works:
1. App starts at `LoginScreen.tscn`
2. User enters credentials
3. Password is hashed (SHA-256) and verified
4. On success → Main Menu
5. User stays logged in until logout

---

## 👥 User Management

### Roles:
- **Manager** - Full access to all features
- **Packing Supervisor** - Wrapping, quality control, view orders
- **Picking Supervisor** - Quality control, view inventory
- **General Staff** - Assigned specific tasks
- **Picker** - Limited access

### Tasks:
- `wrapping` - Access to wrapping tracker
- `folding` - Access to box folding
- `orders` - Can create/view orders
- `quality_control` - Can track defects
- `admin` - Full user management (requires is_admin = true)

### User Structure:
```json
{
  "id": 1,
  "username": "admin",
  "password_hash": "hashed_password",
  "role": "Manager",
  "tasks": ["wrapping", "orders", "admin", "quality_control", "folding"],
  "is_admin": true
}
```

---

## 📋 Main Menu (Role-Based)

The main menu now shows different options based on user's tasks:

```
Production Manager
Welcome, [username]
Role: [role]

[Buttons visible based on tasks:]
📦 Box Folding        (if "folding" in tasks)
🍄 Wrapping           (if "wrapping" in tasks)
📋 Orders             (if "orders" in tasks)
✓ Quality Control     (if "quality_control" in tasks)
⚙ Admin Panel         (if is_admin == true)

← Logout
```

---

## 📦 Orders Management System

**File**: `OrdersManager.gd` (scene file needed)

### Purpose:
Supervisors/managers create orders that auto-populate wrapping sessions

### Features:
- Create new orders with:
  - Product (433g cups, 300g cups, etc.)
  - Quantity (e.g., "160x16")
  - Customer (default: Lidl RDC Mullingar)
  - Delivery date
  - Harvest date (optional)
  - Supplier (RM, McKenna, Other)
  - Batch code (auto-generated)
- View all orders (pending/completed)
- Order status tracking
- Orders appear in wrapping tracker for selection

### Order Structure:
```json
{
  "id": 1,
  "product": "300g Cups",
  "quantity": "160x16",
  "customer": "Lidl RDC Mullingar",
  "delivery_date": "2025-11-24",
  "harvest_date": "2025-11-22",
  "supplier": "RM",
  "batch_code": "L4405",
  "status": "pending",
  "created_by": 1
}
```

---

## 🍄 Simplified Wrapping Tracker

**File**: `WrappingTrackerNew.gd` (scene file needed)

### Complete Redesign - Focus on RM415 Core Data:

**Removed** (from old version):
- ❌ Complex inventory management popups
- ❌ Pallets/crates calculations
- ❌ Multiple harvest batch tracking
- ❌ Class 2 / damaged tracking (moved to Quality Control)

**Simplified** (new version):
- ✅ Product
- ✅ Supplier
- ✅ Quantity
- ✅ Harvest Date
- ✅ Delivery Date
- ✅ Batch Code
- ✅ Crates Wrapped (simple counter)

### Two Input Methods:

1. **From Order** (Recommended):
   - Click "Select Order"
   - Choose pending order
   - All fields auto-populated
   - Start wrapping!

2. **Manual Entry**:
   - Click "Manual Entry"
   - Fill in product, supplier, quantity, dates
   - Batch code auto-generated
   - Start wrapping!

### UI Layout:
```
=== WRAPPING TRACKER ===

[Order Info Display]
Product: 300g Cups
Supplier: RM
Quantity: 160x16
Harvest Date: 2025-11-22
Delivery Date: 2025-11-24
Batch: L4405

Crates Wrapped: 0
[- 1] [+ 1]

[📋 Select Order]  [✍ Manual Entry]
[✓ Quality Control]
[■ End Session]
[📄 Generate RM415]

← Back
```

---

## ✓ Quality Control (Defect Tracking)

**File**: `QualityControl.gd` (scene file needed)

### Purpose:
Real-time tracking of product and wrapping defects

### Features:

**Bad Product Reasons** (customizable):
- Bruised
- Discolored
- Too Small
- Too Large
- Damaged
- Foreign Object
- [+ Add Custom]

**Bad Wrap Reasons** (customizable):
- Torn Film
- Loose Wrap
- Poor Seal
- Wrinkled
- Incorrect Weight
- Missing Label
- [+ Add Custom]

### Workflow:
1. Worker notices defect during wrapping
2. Opens Quality Control screen
3. Clicks "Add Bad Product" or "Add Bad Wrap"
4. Selects reason from dropdown (or adds custom)
5. Enters quantity
6. Adds optional notes
7. Defect recorded with timestamp
8. Return to wrapping

### Daily Summary:
```
=== TODAY'S DEFECTS ===

Bad Product: 23
Bad Wrap: 7

[Recent Defects List]
Bad Product - Bruised (×15)
Bad Wrap - Torn Film (×5)
...
```

---

## ⚙ Admin Panel

**File**: `AdminPanel.gd` (scene file needed)

### Purpose:
User and permission management (admin-only)

### Features:

**User Management**:
- View all users
- Create new users
- Edit user details:
  - Username
  - Password (hashed)
  - Role
  - Assigned tasks
  - Admin status
- Delete users (can't delete yourself)

**Task Assignment**:
Admins can grant/revoke tasks:
- ☐ Wrapping
- ☐ Box Folding
- ☐ Orders Management
- ☐ Quality Control
- ☐ Admin Access

### Example User Creation:
```
Username: sarah
Password: sarah123
Role: Packing Supervisor
Tasks:
  ✓ Wrapping
  ✓ Quality Control
  ✓ Orders
  ☐ Box Folding
  ☐ Admin

☐ Grant Admin Privileges
```

---

## 💾 Data Storage (DataStore.gd)

### JSON-Based Persistence:
**Location**: `user://production_data.json`

### Data Structure:
```json
{
  "users": [...],
  "orders": [...],
  "wrapping_sessions": [...],
  "inventory": [...],
  "quality_defects": [...],
  "rm415_forms": [...],
  "current_user": {...},
  "defect_reasons": {
    "bad_product": [...],
    "bad_wrap": [...]
  }
}
```

### Key Methods:
```gdscript
# User Management
DataStore.authenticate_user(username, password)
DataStore.get_current_user()
DataStore.create_user(...)
DataStore.logout()

# Orders
DataStore.create_order(order_data)
DataStore.get_pending_orders()
DataStore.update_order_status(id, status)

# Wrapping Sessions
DataStore.create_wrapping_session(data)
DataStore.end_wrapping_session(id, crates)

# Quality Defects
DataStore.add_defect(defect_data)
DataStore.add_defect_reason(type, reason)

# Permissions
DataStore.user_has_task(task_name)
```

---

## 🚀 Complete Workflow Example

### Scenario: Manager creates order, worker wraps it

1. **Manager** logs in
   - Sees: Orders, Admin Panel, All features
   - Goes to Orders

2. **Manager creates order:**
   ```
   Product: 300g Cups
   Quantity: 160x16
   Customer: Lidl RDC Mullingar
   Delivery: 2025-11-24
   Harvest: 2025-11-22
   Supplier: RM
   ```
   - Order saved as "pending"

3. **Worker** (Sarah - Packing Supervisor) logs in
   - Sees: Wrapping, Quality Control
   - Goes to Wrapping

4. **Worker starts wrapping:**
   - Clicks "Select Order"
   - Chooses "300g Cups - 160x16"
   - All fields auto-fill
   - Clicks confirm
   - Session starts

5. **During wrapping:**
   - Worker wraps crates
   - Clicks "+ 1" for each crate wrapped
   - Notices 5 bruised mushrooms
   - Opens Quality Control
   - Adds: Bad Product - Bruised (×5)
   - Returns to wrapping

6. **End of session:**
   - Worker wrapped 150 crates
   - Clicks "End Session"
   - Order marked "completed"

7. **Generate RM415:**
   - Worker clicks "Generate RM415"
   - Fills checklist
   - Signs digitally
   - Form saved

---

## ⚠️ What Still Needs to Be Done

### 1. Scene Files (.tscn) Required:
- `OrdersManager.tscn`
- `AdminPanel.tscn`
- `QualityControl.tscn`
- `WrappingTrackerNew.tscn` (to replace old one)

### 2. Popup Dialogs Needed:
- `NewOrderPopup.tscn` - Order creation form
- `NewUserPopup.tscn` - User creation form
- `EditUserPopup.tscn` - User editing form
- `BadProductPopup.tscn` - Bad product defect entry
- `BadWrapPopup.tscn` - Bad wrap defect entry
- `CustomReasonPopup.tscn` - Add custom defect reason
- `OrderSelectPopup.tscn` - Select from pending orders
- `ManualEntryPopup.tscn` - Manual wrapping data entry

### 3. Integration Work:
- Connect new WrappingTrackerNew to RM415Generator
- Update RM415Generator to work with simplified data
- Create proper popup dialogs with forms
- Test complete workflow end-to-end

### 4. UI Polish:
- Make all screens match box folding tracker visual style
- Consistent button sizes and layouts
- Proper spacing and margins
- Mobile-friendly touch targets

---

## 📝 Next Steps

### Option A: Complete the Scene Files (Recommended)
Create all .tscn files so the new system is runnable

### Option B: Test Incremental
Build one screen at a time:
1. Orders Manager first
2. Then simplified Wrapping Tracker
3. Then Quality Control
4. Finally Admin Panel

### Option C: Keep Old System Alongside New
- Rename WrappingTracker.tscn → WrappingTrackerOld.tscn
- Keep both versions available
- Gradually migrate features

---

## 🎯 Key Improvements Over Old System

| Feature | Old System | New System |
|---------|-----------|------------|
| **Login** | None | ✅ Full authentication |
| **Users** | Single user | ✅ Multi-user with roles |
| **Orders** | None | ✅ Full order management |
| **Wrapping** | Complex inventory | ✅ Simplified RM415 focus |
| **Quality** | Mixed with wrapping | ✅ Dedicated QC screen |
| **Admin** | None | ✅ User/task management |
| **Data** | Console only | ✅ JSON persistence |
| **Access Control** | None | ✅ Role & task based |

---

## 💡 Design Philosophy

**Old Wrapping Tracker**:
- One screen trying to do everything
- Complex inventory calculations
- Many popups and fields
- Overwhelming for users

**New Production Manager**:
- Focused screens for each task
- Simple, clear data entry
- Orders drive the workflow
- Quality control separate
- Admin tools for management
- Role-based security

**Result**: Cleaner, more professional, easier to use!

---

## 📊 Current Status

- **Code Complete**: 70%
- **UI Complete**: 20% (main screens need .tscn files)
- **Integration**: 40%
- **Testing**: 0%

**Next session**: Build all required .tscn scene files!
