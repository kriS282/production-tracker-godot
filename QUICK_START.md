# Production Tracker - Quick Start Guide

## ✅ Phase 1 Complete!

Your wrapping tracker is now **fully functional** and ready to test in Godot!

## 🚀 How to Run:

### 1. Open in Godot
```bash
1. Open Godot 4.3 or newer
2. Click "Import"
3. Navigate to this folder
4. Select project.godot
5. Click "Import & Edit"
```

### 2. Run the App
```bash
Press F5 to run the project
```

You'll see the **Production Tracker** main menu with two options:
- 📦 Start Box Folding (existing feature)
- 🍄 Start Wrapping (NEW!)

## 📋 Testing the Wrapping Tracker

### Full Workflow Test:

1. **Click "Start Wrapping"**

2. **Select Operator & Role**
   - Click "Select Operator & Role"
   - Choose an operator from dropdown
   - Choose a role (Manager, Packing Supervisor, etc.)
   - Click "Confirm"

3. **Add Incoming Inventory**
   - Click "+ Add Incoming Pallets/Crates"
   - Enter: 3 pallets
   - Enter: 6 additional crates
   - Enter harvest date (e.g., 2025-11-23)
   - Click "Add Inventory"
   - You should see: **171 total crates** (3×55 + 6)

4. **Add Leftovers** (optional)
   - Click "+ Add Leftovers from Yesterday"
   - Enter: 6 crates
   - Click "Add"

5. **Mark Quality Issues** (optional)
   - Click "⚠ Mark Crates as Class 2"
   - Enter: 2 crates
   - Click "Mark"

   - Click "✗ Mark Damaged Punnets"
   - Enter: 7 punnets
   - Click "Mark"

6. **Start Wrapping Session**
   - Click "▶ Start Wrapping Product"
   - Select product: "300g Cups"
   - Select supplier: "RM"
   - Enter order: "160x16"
   - Enter crates used: 150
   - Click "Start Wrapping"

7. **Generate RM415 Form**
   - Click "📄 Generate RM415 Form"
   - Fill in product, supplier, batch
   - Check all punnet label items (6 checkboxes)
   - Check all box label items (4 checkboxes)
   - Check "Print Quality Good"
   - Check "Labels Match Box Details"
   - Click "✍ Sign Document"
   - Draw your signature with mouse/touch
   - Click "Save Signature"
   - Click "📄 Generate Form"

   **Form saved to:** `user://rm415_[batch]_[date].html`

8. **End Session**
   - Click "■ End Session & Save"
   - Session data saved to console

## 📂 Where to Find Generated Forms:

On Windows:
```
%APPDATA%/Godot/app_userdata/production-tracker-godot/
```

On Linux:
```
~/.local/share/godot/app_userdata/production-tracker-godot/
```

On macOS:
```
~/Library/Application Support/Godot/app_userdata/production-tracker-godot/
```

## 🎯 What's Working:

✅ **Inventory Tracking**
- Incoming pallets (auto-convert to crates @ 55/pallet)
- Additional crates
- Leftover tracking
- Harvest date association
- Quality control (Class 2, damaged punnets)
- Auto-calculation of usage and remaining

✅ **Wrapping Sessions**
- Product selection (5 types pre-configured)
- Supplier selection (RM, McKenna, Other)
- Order tracking
- Crates used tracking

✅ **Digital Signatures**
- Draw with mouse or touch
- Smooth line rendering
- Save as PNG (base64 encoded)

✅ **RM415 Form Generation**
- Punnet label checks (6 items)
- Box label checks (4 items + 2 quality)
- Digital signature integration
- HTML output (printable)

## 📊 Example Workflow Output:

```
=== INVENTORY ===
Pallets In: 3 (= 165 crates)
Additional Crates: 6
Leftovers: 0 crates
---
Total Available: 171 crates
Class 2: 2 crates
Damaged Punnets: 7
---
Used: 150 crates
Remaining: 19 crates
```

## 🔧 Configuration:

### Add More Operators:
Edit `OperatorRolePopup.gd` line 14:
```gdscript
var operators = [
	"Your", "Operator", "Names", "Here"
]
```

### Add More Products:
Edit `WrappingTracker.gd` lines 4-26 to add new products with their crate configurations.

### Change Roles:
Edit `OperatorRolePopup.gd` line 6:
```gdscript
var roles = [
	"Manager",
	"Your Custom Role",
	...
]
```

## 🐛 Known Limitations (TODO):

1. **No Database** - Data only saved to console, not persisted
2. **No PDF Export** - Forms generate as HTML only
3. **No Server Sync** - No mobile-to-desktop synchronization yet
4. **Additional Forms Not Built**:
   - QR2 (Metal Detection)
   - QR4 (Daily Production Checks)
   - RM057 (Incoming Product Record)
   - RM550 (Dispatch Record)
   - QR1 (Line Clearance/Changeover)
   - QR11 (Cleaning Schedule)

## 🚀 Next Steps:

### Immediate (Database Integration):
1. Add SQLite database
2. Persist wrapping sessions
3. Store inventory history
4. Query past sessions

### Phase 2 (Additional Forms):
1. Build RM057 - Incoming Product Record
2. Build RM550 - Dispatch Record
3. Auto-link incoming/dispatch data

### Phase 3 (Daily Checks):
1. Build QR4 - 17-point pre-production audit
2. Add date coder verification
3. Add scale calibration checks
4. Add knife/sharps tracking
5. Add temperature monitoring

### Phase 4 (Quality Control):
1. Build QR2 - Metal detection tracking
2. Start/end checks
3. Hourly checks
4. Series metal detection

### Phase 5 (Maintenance):
1. Build QR1 - Changeover tracking
2. Build QR11 - Cleaning schedule
3. Daily/weekly/monthly/quarterly tasks

### Phase 6 (Server Integration):
1. Node.js backend
2. Port forwarding setup
3. Mobile device connection
4. Real-time sync
5. Desktop dashboard

## 📝 Testing Checklist:

- [ ] App opens without errors
- [ ] Main menu shows both options
- [ ] Wrapping tracker loads
- [ ] Can select operator & role
- [ ] Can add incoming inventory
- [ ] Inventory calculates correctly
- [ ] Can mark Class 2 crates
- [ ] Can mark damaged punnets
- [ ] Can start wrapping session
- [ ] Product dropdown works
- [ ] Supplier dropdown works
- [ ] Can generate RM415 form
- [ ] All checklists show correctly
- [ ] Signature pad appears
- [ ] Can draw signature
- [ ] Form generates successfully
- [ ] HTML file created in user folder
- [ ] End session saves data

## 💡 Tips:

- Open the **Output** console in Godot (bottom panel) to see session data
- Check the user data folder for generated HTML forms
- Forms are printable - just open in browser and print
- Signature images are embedded as base64 in HTML

## 🎉 You're Ready!

The wrapping tracker is **fully functional** for Phase 1. You can now:

1. Track incoming inventory with harvest dates
2. Manage quality issues
3. Record wrapping sessions
4. Generate RM415 forms with digital signatures
5. Print forms from HTML

**Next:** Let me know what you'd like to add next - database persistence, additional forms, or server integration!

---

For detailed technical documentation, see `WRAPPING_TRACKER_STATUS.md`
