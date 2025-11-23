# Box Folding Tracker - Complete Package

## ✅ Everything Included - Ready to Run!

This is a complete, standalone Godot project for box folding tracking.

## 📦 What's Included

### Scripts (.gd files)
- ✅ **BoxFolding.gd** - Main box folding logic
- ✅ **AddCustomPopup.gd** - Number pad for custom amounts
- ✅ **BoxOperatorPopup.gd** - Operator selection
- ✅ **BoxTypePopup.gd** - Box type selection
- ✅ **MainMenu.gd** - Main menu navigation

### Scenes (.tscn files)
- ✅ **BoxFolding.tscn** - Main interface
- ✅ **AddCustomPopup.tscn** - Number pad popup
- ✅ **BoxOperatorPopup.tscn** - Operator picker
- ✅ **BoxTypePopup.tscn** - Box type picker
- ✅ **MainMenu.tscn** - Start screen

### Project Files
- ✅ **project.godot** - Godot configuration (viewport scaling fixed!)
- ✅ **icon.svg** - Application icon
- ✅ **README.md** - This file

## 🚀 How to Use

### Method 1: Open as New Project
1. Extract this zip to a new folder
2. Open Godot 4.3+
3. Click "Import"
4. Navigate to the extracted folder
5. Select `project.godot`
6. Click "Import & Edit"
7. Press **F5** to run!

### Method 2: Copy Into Existing Project
1. Extract this zip
2. Copy all files into your existing project folder
3. In Godot, click Project > Reload Current Project
4. Open `MainMenu.tscn` and press F6 to test

## 🎮 Features

### Custom Amount Entry
- Number pad for entering any amount (10, 20, 73, 80, etc.)
- Quick preset buttons: +10, +20, +40, +80
- Backspace and Clear buttons

### Automatic Pallet Tracking
- Calculates pallets automatically
- Shows: "1 full pallet + 18 boxes (1.23 total)"
- Celebration notification when pallet completes!

### Timer & Session Tracking
- Start/Stop timer
- Track folding time
- Save sessions with all data

### Works for Everyone
- Some people fold 10 at a time ✅
- Some fold 20 at a time ✅
- Some fold 80 at a time ✅
- Enter whatever you actually did!

## 📊 Box Types Configured

- **6kg Green (Small boxes)** - 80 per pallet
- **12kg Green (Big boxes)** - 40 per pallet

## 👥 Operators Pre-configured

- John, Sarah, Mike, Emma, David, Lisa, Tom, Anna

*Edit `BoxOperatorPopup.gd` line 4 to add your actual operators*

## 🎯 Usage Workflow

1. **Start App** - See main menu
2. **Click "Start Box Folding"**
3. **Select your name**
4. **Select box type** (6kg or 12kg)
5. **Start timer**
6. **Fold some boxes**
7. **Click "Add Custom Amount"**
8. **Enter amount** (use number pad or presets)
9. **System shows pallet progress**
10. **Keep folding and adding**
11. **🎉 Get notification when pallet completes!**
12. **Click "Save Session"** when done
13. **Reset** for next session

## 🔧 Customization

### Change Operators
Edit `BoxOperatorPopup.gd` line 4:
```gdscript
var operators = ["Your", "Operator", "Names", "Here"]
```

### Change Box Types
Edit `BoxFolding.gd` lines 4-14:
```gdscript
const BOX_TYPES = {
	"Your Box Name": {
		"weight": "12kg",
		"per_pallet": 40
	}
}
```

### Change Preset Buttons
Edit `AddCustomPopup.gd` line 6:
```gdscript
var presets = [10, 20, 40, 80]  # Change these numbers
```

## 🐛 Troubleshooting

### Error: "Parse Error"
- Make sure you're using Godot 4.3 or newer
- Check that all .tscn files are in the project root

### Error: "File not found"
- Verify all .gd and .tscn files are in the same folder
- Reload the project (Project > Reload Current Project)

### UI too big/small
- Adjust `project.godot` window override settings
- Current: 540x1200 (50% of mobile resolution)

### Scripts not connecting
- Right-click each .tscn file → "Edit Script"
- Verify the script path matches

## 📱 Mobile Export

To export for Android:
1. Project > Export
2. Add Android export template
3. Configure settings
4. Export APK
5. Install on device

## 🎨 UI Design

- **Dark theme** - Easy on eyes
- **Large buttons** - Touch-friendly (100-140px height)
- **Clear layout** - Logical flow
- **Scrollable** - Works on small screens
- **Viewport scaled** - Looks right in debug mode

## 💾 Data Structure

When you save a session, it creates:
```gdscript
{
  "operator": "John",
  "box_type": "6kg Green (Small boxes)",
  "count": 90,
  "time": 900,  # seconds
  "timestamp": "2025-11-23 14:30:00"
}
```

Currently prints to console. Next step: save to database!

## 🚀 Next Steps (Phase 2)

To add multi-user sync:
1. Build Node.js server
2. Add WebSocket connection
3. Send sessions to server
4. Update inventory in real-time
5. Desktop dashboard for monitoring

## ✅ Testing Checklist

- [ ] Project opens without errors
- [ ] Main menu displays
- [ ] Can start box folding
- [ ] Can select operator
- [ ] Can select box type
- [ ] "Add Custom" button works
- [ ] Number pad appears
- [ ] Can enter custom amount
- [ ] Preset buttons work (+10, +20, etc.)
- [ ] Count updates correctly
- [ ] Pallet calculation shows
- [ ] Notification appears at 40/80
- [ ] Timer starts/stops
- [ ] Reset button works
- [ ] Save session works (check console)

## 📝 File Structure

```
box_folding_complete/
├── project.godot              # Project config
├── icon.svg                   # App icon
│
├── MainMenu.gd                # Main menu logic
├── MainMenu.tscn              # Main menu UI
│
├── BoxFolding.gd              # Main logic
├── BoxFolding.tscn            # Main UI
│
├── AddCustomPopup.gd          # Number pad logic
├── AddCustomPopup.tscn        # Number pad UI
│
├── BoxOperatorPopup.gd        # Operator picker logic
├── BoxOperatorPopup.tscn      # Operator picker UI
│
├── BoxTypePopup.gd            # Box type picker logic
├── BoxTypePopup.tscn          # Box type picker UI
│
└── README.md                  # This file
```

## 🎯 Key Features Summary

✅ Custom amount entry (any number)
✅ Quick presets (+10, +20, +40, +80)
✅ Automatic pallet calculation
✅ Pallet complete notifications
✅ Timer tracking
✅ Session saving
✅ Works for all folding speeds
✅ Clean, touch-friendly UI
✅ Viewport scaling fixed
✅ All unique names (%) used

## 💡 Tips

- Use **custom amount** for actual folding sessions
- Use **presets** for quick testing
- Use **+1/-1** for corrections
- **Reset** clears everything for new session
- **Save** records the session (check Output tab)

## 🎉 Example Session

```
1. John selects his name
2. Selects "6kg Small boxes"
3. Starts timer
4. Folds for 15 minutes
5. Clicks "Add Custom"
6. Enters "73" on number pad
7. System shows: "0 full + 73 boxes (0.91 pallets)"
8. Folds more
9. Adds "25" more
10. System shows: "1 full + 18 boxes (1.23 pallets)"
11. 🎉 "Pallet Complete!" notification
12. Clicks "Save Session"
13. Data printed to console
```

---

**Ready to track box folding efficiently!** 📦✨

**No more errors - everything included!** 🎉
