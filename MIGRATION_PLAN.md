# Production Manager - Migration Plan

## Overview

This document outlines a systematic approach to completing the Production Manager system. The plan is organized in phases to minimize risk and ensure each component is properly tested before moving to the next.

---

## Current State Assessment

### ✅ Completed
- Authentication system (LoginScreen)
- DataStore with JSON persistence
- User management logic
- Order management logic
- Quality control defect tracking logic
- Box Folding tracker (fully functional)
- Old wrapping tracker (functional but needs replacement)

### ⚠️ In Progress
- New simplified wrapping tracker (logic complete, UI needed)
- Admin panel (logic complete, UI needed)
- Orders manager (logic complete, UI needed)
- Quality Control screen (logic complete, UI needed)

### ❌ Missing
- All .tscn scene files for new features
- Popup dialog scenes
- Integration between components
- Automated tests
- UI consistency and polish

---

## Phase 1: Core Infrastructure (Week 1)

**Priority**: CRITICAL - Required for basic functionality

### 1.1 Set Up Testing Framework
**Duration**: 1-2 days

- [ ] Install GUT (Godot Unit Test) addon
- [ ] Configure test directory structure
- [ ] Create base test utilities
- [ ] Set up CI/CD pipeline (optional)

**Files to create**:
```
tests/
├── unit/
│   ├── test_datastore.gd
│   ├── test_authentication.gd
│   └── test_order_management.gd
├── integration/
│   ├── test_login_flow.gd
│   ├── test_order_workflow.gd
│   └── test_wrapping_workflow.gd
└── test_helpers.gd
```

### 1.2 Create Core Popup Scenes
**Duration**: 2-3 days

Build the essential popup dialogs that multiple screens depend on:

1. **OrderSelectPopup.tscn** (Priority: HIGH)
   - List of pending orders
   - Search/filter functionality
   - Select button for each order
   - Dependencies: OrdersManager, WrappingTrackerNew

2. **NewOrderPopup.tscn** (Priority: HIGH)
   - Product dropdown (from DataStore.PRODUCTS)
   - Supplier dropdown
   - Customer input (default: Lidl RDC Mullingar)
   - Quantity input
   - Harvest date picker
   - Delivery date picker
   - Cancel/Create buttons

3. **ManualEntryPopup.tscn** (Priority: HIGH)
   - Same fields as NewOrderPopup but for wrapping sessions
   - Auto-generates batch code

**Testing checkpoint**:
- [ ] All popups display correctly
- [ ] Input validation works
- [ ] Cancel/confirm buttons work
- [ ] Data passes to parent screens correctly

---

## Phase 2: Orders Management System (Week 1-2)

**Priority**: HIGH - Drives the wrapping workflow

### 2.1 Build OrdersManager Scene
**Duration**: 2 days

**OrdersManager.tscn structure**:
```
OrdersManager (Control)
├── Header
│   └── Label: "Orders Management"
├── OrdersList (ScrollContainer)
│   └── VBoxContainer
│       └── [OrderCard × n]
├── ButtonsContainer
│   ├── NewOrderButton
│   ├── FilterButtons (Pending/Completed/All)
│   └── BackButton
└── NewOrderPopup (Popup)
```

**Features**:
- Display orders grouped by status
- Color-coded status indicators
- Quick stats (total orders, pending, completed)
- Search/filter functionality
- Create new order button

**Files to create**:
- `OrdersManager.tscn`
- `tests/unit/test_order_management.gd`
- `tests/integration/test_order_workflow.gd`

### 2.2 Testing Requirements
- [ ] Create order successfully
- [ ] Order appears in pending list
- [ ] Order data persists after app restart
- [ ] Filter by status works
- [ ] Search by product/batch works
- [ ] Can't create order with missing required fields

---

## Phase 3: Simplified Wrapping Tracker (Week 2)

**Priority**: HIGH - Core production feature

### 3.1 Build WrappingTrackerNew Scene
**Duration**: 2-3 days

**WrappingTrackerNew.tscn structure**:
```
WrappingTrackerNew (Control)
├── Header
│   └── Label: "Wrapping Tracker"
├── OrderInfoDisplay (VBoxContainer)
│   ├── ProductLabel
│   ├── SupplierLabel
│   ├── QuantityLabel
│   ├── HarvestDateLabel
│   ├── DeliveryDateLabel
│   └── BatchCodeLabel
├── CratesCounter (HBoxContainer)
│   ├── Label: "Crates Wrapped:"
│   ├── MinusButton [-1]
│   ├── CountLabel
│   └── PlusButton [+1]
├── ActionsContainer
│   ├── SelectOrderButton
│   ├── ManualEntryButton
│   ├── QualityControlButton
│   ├── EndSessionButton
│   ├── GenerateRM415Button
│   └── BackButton
└── Popups
    ├── OrderSelectPopup
    └── ManualEntryPopup
```

**Features**:
- Two input methods (Order selection or Manual entry)
- Simple crate counter
- Link to Quality Control
- Link to RM415 generation
- Session tracking

### 3.2 Integration with Existing Systems

**Connect to**:
1. **OrdersManager**: Pull pending orders
2. **QualityControl**: Open from wrapping screen
3. **RM415Generator**: Pass wrapping data

**Files to update**:
- `RM415Generator.gd` - Update to work with simplified data structure
- `MainMenu.tscn` - Add button for WrappingTrackerNew
- `DataStore.gd` - Add session management methods

### 3.3 Testing Requirements
- [ ] Select order populates all fields correctly
- [ ] Manual entry creates valid session
- [ ] Batch code auto-generates correctly (LWWdd format)
- [ ] Crate counter increments/decrements
- [ ] End session marks order as completed
- [ ] Session data persists
- [ ] Quality Control button opens QC screen
- [ ] Generate RM415 passes correct data

---

## Phase 4: Quality Control Screen (Week 3)

**Priority**: MEDIUM - Important for production tracking

### 4.1 Build QualityControl Scene
**Duration**: 2 days

**QualityControl.tscn structure**:
```
QualityControl (Control)
├── Header
│   └── Label: "Quality Control"
├── TodaysSummary (Panel)
│   ├── BadProductCount
│   └── BadWrapCount
├── DefectButtons
│   ├── AddBadProductButton
│   └── AddBadWrapButton
├── RecentDefectsList (ScrollContainer)
│   └── VBoxContainer
│       └── [DefectCard × n]
├── BackButton
└── Popups
    ├── BadProductPopup
    ├── BadWrapPopup
    └── CustomReasonPopup
```

### 4.2 Build Supporting Popups

**BadProductPopup.tscn**:
- Reason dropdown (with custom reasons)
- Quantity input
- Notes field
- Add custom reason button
- Cancel/Confirm buttons

**BadWrapPopup.tscn**:
- Same structure as BadProductPopup
- Different reason list

**CustomReasonPopup.tscn**:
- Text input for new reason
- Cancel/Add buttons

### 4.3 Testing Requirements
- [ ] Add bad product defect
- [ ] Add bad wrap defect
- [ ] Custom reasons save and appear in dropdown
- [ ] Daily summary calculates correctly
- [ ] Recent defects display chronologically
- [ ] Defects persist after app restart
- [ ] Can access from wrapping screen

---

## Phase 5: Admin Panel (Week 3-4)

**Priority**: MEDIUM - Required for user management

### 5.1 Build AdminPanel Scene
**Duration**: 2 days

**AdminPanel.tscn structure**:
```
AdminPanel (Control)
├── Header
│   └── Label: "Admin Panel"
├── TabContainer
│   ├── UsersTab
│   │   ├── UsersList (ScrollContainer)
│   │   └── AddUserButton
│   └── SystemTab (future)
├── BackButton
└── Popups
    ├── NewUserPopup
    └── EditUserPopup
```

### 5.2 Build User Management Popups

**NewUserPopup.tscn**:
- Username input
- Password input
- Confirm password input
- Role dropdown
- Task checkboxes:
  - [ ] Wrapping
  - [ ] Box Folding
  - [ ] Orders Management
  - [ ] Quality Control
  - [ ] Admin Access
- Grant admin privileges checkbox
- Cancel/Create buttons

**EditUserPopup.tscn**:
- Same as NewUserPopup
- Pre-populated with existing data
- Delete user button (with confirmation)

### 5.3 Testing Requirements
- [ ] Create new user
- [ ] User can log in with new credentials
- [ ] Edit user details
- [ ] Change user role
- [ ] Assign/revoke tasks
- [ ] Delete user (can't delete self)
- [ ] Can't delete last admin
- [ ] Password hashing works correctly
- [ ] Task permissions enforce correctly

---

## Phase 6: UI Consistency & Polish (Week 4)

**Priority**: MEDIUM - Important for user experience

### 6.1 Design System
**Duration**: 1 day

Create consistent styling across all screens:

**Create `theme.tres`**:
```gdscript
# Colors
PRIMARY_COLOR = Color("#2c3e50")
SECONDARY_COLOR = Color("#34495e")
ACCENT_COLOR = Color("#3498db")
SUCCESS_COLOR = Color("#2ecc71")
WARNING_COLOR = Color("#f39c12")
DANGER_COLOR = Color("#e74c3c")
TEXT_COLOR = Color("#ecf0f1")
DISABLED_COLOR = Color("#7f8c8d")

# Fonts
HEADING_FONT_SIZE = 24
BODY_FONT_SIZE = 16
BUTTON_FONT_SIZE = 18

# Spacing
MARGIN = 20
PADDING = 15
BUTTON_HEIGHT = 120
BUTTON_SPACING = 15
```

### 6.2 Apply Consistent Styling
**Duration**: 2-3 days

Update all screens to use theme:
- [ ] LoginScreen
- [ ] MainMenu
- [ ] BoxFolding (already good - use as reference)
- [ ] WrappingTrackerNew
- [ ] OrdersManager
- [ ] QualityControl
- [ ] AdminPanel
- [ ] All popups

### 6.3 Mobile Optimization

- [ ] Touch target sizes (min 100x100px)
- [ ] Scrollable containers where needed
- [ ] Proper viewport scaling
- [ ] Test on different screen sizes
- [ ] Landscape/portrait support

### 6.4 Accessibility

- [ ] Clear visual hierarchy
- [ ] Sufficient color contrast
- [ ] Large, readable fonts
- [ ] Clear error messages
- [ ] Loading indicators where needed

---

## Phase 7: Integration Testing (Week 4-5)

**Priority**: HIGH - Ensure everything works together

### 7.1 End-to-End Workflow Tests

**Test Scenario 1: Complete Order Workflow**
```
1. Manager logs in
2. Creates new order
3. Logs out
4. Worker logs in
5. Opens wrapping tracker
6. Selects order
7. Wraps crates
8. Adds quality defect
9. Ends session
10. Generates RM415
11. Verify order marked complete
12. Verify defect recorded
13. Verify RM415 generated
```

**Test Scenario 2: Manual Entry Workflow**
```
1. Worker logs in
2. Opens wrapping tracker
3. Manual entry
4. Fills all fields
5. Wraps crates
6. Ends session
7. Generates RM415
8. Verify session saved
9. Verify RM415 generated
```

**Test Scenario 3: Admin Workflow**
```
1. Admin logs in
2. Creates new user
3. Assigns tasks
4. Logs out
5. New user logs in
6. Verify correct menu options
7. Verify can access assigned features
8. Verify can't access unassigned features
```

### 7.2 Data Persistence Tests

- [ ] Create order → Restart app → Order still exists
- [ ] Create user → Restart app → User can log in
- [ ] Add defect → Restart app → Defect in history
- [ ] Wrap session → Restart app → Session in records

### 7.3 Permission Tests

- [ ] Manager sees all features
- [ ] Packing Supervisor sees: wrapping, QC, orders
- [ ] Picker sees limited features
- [ ] Non-admin can't access admin panel
- [ ] User without "orders" task can't create orders

---

## Phase 8: Migration from Old to New (Week 5)

**Priority**: LOW - Only after new system is stable

### 8.1 Data Migration

**If old wrapping data exists**:
1. Create migration script
2. Map old data structure to new
3. Import historical sessions
4. Verify data integrity

### 8.2 Deprecation Plan

1. Keep both WrappingTracker and WrappingTrackerNew
2. Add "Beta" label to new version
3. Collect user feedback
4. After 2 weeks of stable use:
   - Remove old WrappingTracker
   - Rename WrappingTrackerNew → WrappingTracker
   - Update all references

---

## Phase 9: Documentation & Training (Week 5-6)

**Priority**: MEDIUM - Important for adoption

### 9.1 User Documentation

Create `USER_GUIDE.md`:
- Login instructions
- How to create orders
- How to wrap products
- How to record defects
- How to generate forms
- Troubleshooting

### 9.2 Admin Documentation

Create `ADMIN_GUIDE.md`:
- User management
- Role assignment
- Task permissions
- Data backup/restore
- System maintenance

### 9.3 Developer Documentation

Create `DEVELOPER_GUIDE.md`:
- Architecture overview
- Data structures
- Adding new features
- Testing guidelines
- Deployment process

---

## Testing Strategy

### Unit Tests (tests/unit/)

**test_datastore.gd**:
- [ ] User authentication
- [ ] Password hashing
- [ ] Create/read/update/delete users
- [ ] Create/read/update orders
- [ ] Add/read defects
- [ ] Permission checking

**test_authentication.gd**:
- [ ] Valid login
- [ ] Invalid login
- [ ] Password hashing
- [ ] Session persistence
- [ ] Logout

**test_order_management.gd**:
- [ ] Create order
- [ ] Update order status
- [ ] Get pending orders
- [ ] Get completed orders
- [ ] Batch code generation

### Integration Tests (tests/integration/)

**test_login_flow.gd**:
- [ ] Login → Main menu → Features visible
- [ ] Logout → Return to login
- [ ] Invalid login → Error message

**test_order_workflow.gd**:
- [ ] Create order → Appears in list
- [ ] Select order → Populates wrapping screen
- [ ] End session → Order marked complete

**test_wrapping_workflow.gd**:
- [ ] Manual entry → Create session
- [ ] Wrap crates → Counter updates
- [ ] End session → Data saved
- [ ] Generate RM415 → Form created

### Manual Testing Checklist

**Before each release**:
- [ ] All automated tests pass
- [ ] Login/logout works
- [ ] Each role sees correct menu
- [ ] Create order works
- [ ] Wrapping tracker works (both modes)
- [ ] Quality control works
- [ ] Admin panel works
- [ ] Data persists after restart
- [ ] No errors in console
- [ ] UI looks good on mobile
- [ ] Performance is acceptable

---

## Risk Management

### High-Risk Items

1. **Data loss**:
   - Mitigation: Implement auto-save every 30 seconds
   - Backup data before migrations
   - Version control for data files

2. **UI breaks on different screen sizes**:
   - Mitigation: Test on multiple devices
   - Use responsive layouts
   - Scrollable containers

3. **Performance with large datasets**:
   - Mitigation: Implement pagination
   - Lazy loading for lists
   - Index frequently accessed data

4. **Authentication vulnerabilities**:
   - Mitigation: Use SHA-256 for passwords
   - Implement session timeouts
   - Input validation

### Rollback Plan

If critical issues arise:
1. Keep old system available
2. Document breaking changes
3. Create data export functionality
4. Have rollback script ready

---

## Success Metrics

### Phase Completion Criteria

Each phase is complete when:
- [ ] All features implemented
- [ ] All tests passing
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] User acceptance testing passed

### Final Release Criteria

Ready for production when:
- [ ] All phases complete
- [ ] 100% test coverage for critical paths
- [ ] No critical bugs
- [ ] Performance benchmarks met
- [ ] User training completed
- [ ] Admin training completed
- [ ] Backup/restore tested

---

## Timeline Summary

| Phase | Duration | Priority | Dependencies |
|-------|----------|----------|--------------|
| 1. Infrastructure | 1 week | CRITICAL | None |
| 2. Orders System | 1 week | HIGH | Phase 1 |
| 3. Wrapping Tracker | 1 week | HIGH | Phase 1, 2 |
| 4. Quality Control | 1 week | MEDIUM | Phase 1 |
| 5. Admin Panel | 1 week | MEDIUM | Phase 1 |
| 6. UI Polish | 1 week | MEDIUM | Phase 2-5 |
| 7. Integration Testing | 1 week | HIGH | Phase 2-6 |
| 8. Migration | 1 week | LOW | Phase 7 |
| 9. Documentation | 1 week | MEDIUM | Phase 7 |

**Total estimated time**: 7-9 weeks (depending on team size)

**Minimum viable product**: Phases 1-3 (3 weeks)

---

## Next Immediate Actions

1. ✅ Set up GUT testing framework
2. ✅ Create test_datastore.gd with basic tests
3. ✅ Build OrderSelectPopup.tscn
4. ✅ Build NewOrderPopup.tscn
5. ✅ Build OrdersManager.tscn
6. ✅ Test order creation workflow
7. ✅ Build WrappingTrackerNew.tscn
8. ✅ Test wrapping workflow

Start with testing infrastructure, then build features one at a time with tests for each.

---

## Notes

- This plan assumes 1-2 developers working full-time
- Adjust timeline based on actual team size
- Some phases can run in parallel with multiple developers
- User feedback should drive prioritization adjustments
- Keep the old system running until new system is proven stable

**Last Updated**: 2025-11-24
