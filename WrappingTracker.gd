extends Control

# Product types with crate/box configurations
const PRODUCTS = {
	"433g Cups": {
		"punnets_per_crate": 12,
		"punnets_per_box": 1,
		"package_type": "cup"
	},
	"300g Cups": {
		"punnets_per_crate": 16,
		"punnets_per_box": 1,
		"package_type": "cup"
	},
	"150g Buttons": {
		"punnets_per_crate": 16,
		"punnets_per_box": 1,
		"package_type": "button"
	},
	"250g Flats": {
		"punnets_per_crate": 6,
		"punnets_per_box": 1,
		"package_type": "flat"
	},
	"150g Sliced": {
		"punnets_per_crate": 8,
		"punnets_per_box": 1,
		"package_type": "sliced",
		"source_product": "300g Cups",
		"conversion_ratio": 4  # 1 crate of 300g = 4 boxes of sliced
	}
}

# State variables
var current_operator = ""
var current_role = ""
var session_date = ""
var batch_code = ""

# Inventory tracking
var inventory = {
	"pallets_in": 0,
	"crates_in": 0,
	"leftovers_in": 0,
	"class2_crates": 0,
	"damaged_punnets": 0,
	"crates_used": 0,
	"crates_remaining": 0
}

# Harvest date tracking (array of {crates: int, harvest_date: String})
var harvest_batches = []

# Current wrapping session
var current_product = ""
var current_supplier = ""
var wrapping_sessions = []  # Track multiple products wrapped

# RM415 data
var rm415_entries = []

@onready var operator_label = %OperatorLabel
@onready var date_label = %DateLabel
@onready var batch_label = %BatchLabel
@onready var inventory_display = %InventoryDisplay

func _ready():
	session_date = Time.get_date_string_from_system()
	update_ui()

	# Connect buttons
	%BackBtn.pressed.connect(_on_back_pressed)
	%SelectOperatorBtn.pressed.connect(_on_select_operator_pressed)
	%AddIncomingBtn.pressed.connect(_on_add_incoming_pressed)
	%AddLeftoversBtn.pressed.connect(_on_add_leftovers_pressed)
	%MarkClass2Btn.pressed.connect(_on_mark_class2_pressed)
	%MarkDamagedBtn.pressed.connect(_on_mark_damaged_pressed)
	%StartWrappingBtn.pressed.connect(_on_start_wrapping_pressed)
	%EndSessionBtn.pressed.connect(_on_end_session_pressed)
	%GenerateRM415Btn.pressed.connect(_on_generate_rm415_pressed)

func update_ui():
	operator_label.text = current_operator if not current_operator.is_empty() else "No operator selected"
	if not current_role.is_empty():
		operator_label.text += " (%s)" % current_role

	date_label.text = "Date: %s" % session_date
	batch_label.text = "Batch: %s" % (batch_code if not batch_code.is_empty() else "Not set")

	# Update inventory display
	var inv_text = "=== INVENTORY ===\n"
	inv_text += "Pallets In: %d (= %d crates)\n" % [inventory.pallets_in, inventory.pallets_in * 55]
	inv_text += "Additional Crates: %d\n" % inventory.crates_in
	inv_text += "Leftovers: %d crates\n" % inventory.leftovers_in
	inv_text += "---\n"
	inv_text += "Total Available: %d crates\n" % get_total_crates()
	inv_text += "Class 2: %d crates\n" % inventory.class2_crates
	inv_text += "Damaged Punnets: %d\n" % inventory.damaged_punnets
	inv_text += "---\n"
	inv_text += "Used: %d crates\n" % inventory.crates_used
	inv_text += "Remaining: %d crates" % get_remaining_crates()

	inventory_display.text = inv_text

	# Enable/disable buttons based on state
	%StartWrappingBtn.disabled = current_operator.is_empty()
	%GenerateRM415Btn.disabled = wrapping_sessions.is_empty()

func get_total_crates() -> int:
	return (inventory.pallets_in * 55) + inventory.crates_in + inventory.leftovers_in

func get_remaining_crates() -> int:
	return get_total_crates() - inventory.crates_used - inventory.class2_crates

func _on_back_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_select_operator_pressed():
	%OperatorRolePopup.popup_centered()

func _on_add_incoming_pressed():
	%IncomingInventoryPopup.popup_centered()

func _on_add_leftovers_pressed():
	%LeftoversPopup.popup_centered()

func _on_mark_class2_pressed():
	%Class2Popup.popup_centered()

func _on_mark_damaged_pressed():
	%DamagedPopup.popup_centered()

func _on_start_wrapping_pressed():
	%WrappingSessionPopup.popup_centered()

func _on_end_session_pressed():
	# Calculate final remaining inventory
	inventory.crates_remaining = get_remaining_crates()

	# Save session data
	var session_data = {
		"date": session_date,
		"operator": current_operator,
		"role": current_role,
		"batch": batch_code,
		"inventory": inventory.duplicate(),
		"harvest_batches": harvest_batches.duplicate(),
		"sessions": wrapping_sessions.duplicate()
	}

	print("Session saved:", session_data)
	print("TODO: Save to SQLite database")

	# Show confirmation
	show_notification("Session saved! Remaining: %d crates" % inventory.crates_remaining)

func _on_generate_rm415_pressed():
	%RM415GeneratorPopup.popup_centered()

func set_operator(operator_name: String, role: String):
	current_operator = operator_name
	current_role = role
	update_ui()

func add_incoming_inventory(pallets: int, crates: int, harvest_date: String):
	inventory.pallets_in += pallets
	inventory.crates_in += crates

	# Track harvest date
	var total_crates = (pallets * 55) + crates
	if total_crates > 0:
		harvest_batches.append({
			"crates": total_crates,
			"harvest_date": harvest_date
		})

	update_ui()
	show_notification("Added %d pallets + %d crates (Harvest: %s)" % [pallets, crates, harvest_date])

func add_leftovers(crates: int):
	inventory.leftovers_in += crates
	update_ui()
	show_notification("Added %d leftover crates" % crates)

func mark_class2(crates: int):
	inventory.class2_crates += crates
	update_ui()
	show_notification("Marked %d crates as Class 2" % crates)

func mark_damaged(punnets: int):
	inventory.damaged_punnets += punnets
	update_ui()
	show_notification("%d punnets marked as damaged" % punnets)

func start_wrapping_session(product: String, supplier: String, order_quantity: String):
	var session = {
		"product": product,
		"supplier": supplier,
		"order": order_quantity,
		"start_time": Time.get_time_string_from_system()
	}
	wrapping_sessions.append(session)
	current_product = product
	current_supplier = supplier

	update_ui()
	show_notification("Started wrapping: %s" % product)

func record_crates_used(crates: int):
	inventory.crates_used += crates
	update_ui()

func generate_rm415(product: String, supplier: String, batch: String):
	var rm415_data = {
		"date": session_date,
		"product": product,
		"supplier": supplier,
		"batch": batch,
		"operator": current_operator,
		"punnet_checks": {
			"product_name": false,
			"weight": false,
			"quantity": false,
			"use_by_date": false,
			"day_code": false,
			"pn": false
		},
		"box_checks": {
			"product_name": false,
			"weight": false,
			"quantity": false,
			"day_code": false,
			"print_quality_good": false,
			"labels_match_box": false
		},
		"signature": null  # Will be set by signature pad
	}

	rm415_entries.append(rm415_data)
	return rm415_data

func show_notification(message: String):
	%NotificationLabel.text = message
	%NotificationLabel.show()
	await get_tree().create_timer(3.0).timeout
	%NotificationLabel.hide()

func calculate_batch_code(_dispatch_date: String = "") -> String:
	# Format: LWWdd (Week + Day)
	# Example: L4405 = Week 44, Thursday (+1 for Friday)
	# Note: Currently uses system date, dispatch_date parameter reserved for future use
	var date_dict = Time.get_datetime_dict_from_system()
	var week = date_dict.get("week", 1)
	var weekday = date_dict.get("weekday", 1)

	# Add 1 for next day dispatch
	var dispatch_weekday = (weekday % 7) + 1

	return "L%02d%02d" % [week, dispatch_weekday]
