extends Control

# Wrapping tracker with operator selection and tabbed defect tracking

var current_user = {}
var current_session_id = -1
var selected_order = {}

# Session data
var current_operator = ""
var product = ""
var supplier = ""
var quantity = ""
var harvest_date = ""
var delivery_date = ""
var batch_code = ""
var crates_wrapped = 0

# Quality Control data
var session_defects = []
var bad_product_count = 0
var bad_wrap_count = 0

func _ready():
	current_user = DataStore.get_current_user()

	if current_user.is_empty():
		get_tree().change_scene_to_file("res://LoginScreen.tscn")
		return

	update_ui()
	connect_buttons()

func connect_buttons():
	%BackBtn.pressed.connect(_on_back_pressed)
	%SelectOperatorBtn.pressed.connect(_on_select_operator_pressed)
	%SelectProductBtn.pressed.connect(_on_select_product_pressed)
	%IncrementCratesBtn.pressed.connect(_on_increment_crates)
	%DecrementCratesBtn.pressed.connect(_on_decrement_crates)
	%AddBadProductBtn.pressed.connect(_on_add_bad_product_pressed)
	%AddBadWrapBtn.pressed.connect(_on_add_bad_wrap_pressed)
	%AddCustomReasonBtn.pressed.connect(_on_add_custom_reason_pressed)
	%EndSessionBtn.pressed.connect(_on_end_session_pressed)
	%GenerateRM415Btn.pressed.connect(_on_generate_rm415_pressed)

func update_ui():
	# Operator section
	%OperatorLabel.text = current_operator if not current_operator.is_empty() else "No operator selected"

	# Product section
	if product.is_empty():
		%ProductInfoLabel.text = "No product selected"
	else:
		%ProductInfoLabel.text = "%s\nSupplier: %s | Quantity: %s\nHarvest: %s | Delivery: %s" % [
			product, supplier, quantity, harvest_date, delivery_date
		]

	# Crates counter
	%CratesLabel.text = "Crates: %d" % crates_wrapped

	# QC counters
	%BadProductLabel.text = "Bad Product: %d" % bad_product_count
	%BadWrapLabel.text = "Bad Wrap: %d" % bad_wrap_count

	# Enable/disable buttons
	var has_operator = not current_operator.is_empty()
	var has_product = not product.is_empty()
	var session_active = current_session_id >= 0

	%SelectProductBtn.disabled = not has_operator
	%IncrementCratesBtn.disabled = not session_active
	%DecrementCratesBtn.disabled = not session_active or crates_wrapped <= 0
	%AddBadProductBtn.disabled = not session_active
	%AddBadWrapBtn.disabled = not session_active
	%AddCustomReasonBtn.disabled = not session_active
	%EndSessionBtn.disabled = not session_active
	%GenerateRM415Btn.disabled = not session_active

func _on_select_operator_pressed():
	%OperatorPopup.popup_centered()

func set_operator(operator_name: String):
	current_operator = operator_name
	update_ui()
	show_notification("Operator: %s" % operator_name)

func _on_select_product_pressed():
	%ProductSetupPopup.popup_centered()

func set_product_info(data: Dictionary):
	product = data.product
	supplier = data.supplier
	quantity = data.quantity
	harvest_date = data.harvest_date
	delivery_date = data.delivery_date
	batch_code = data.get("batch_code", generate_batch_code())

	create_wrapping_session()
	update_ui()
	show_notification("Started: %s" % product)

func create_wrapping_session():
	var session_data = {
		"order_id": selected_order.get("id", -1),
		"user_id": current_user.id,
		"operator": current_operator,
		"product": product,
		"supplier": supplier,
		"quantity_wrapped": quantity,
		"harvest_date": harvest_date,
		"delivery_date": delivery_date,
		"batch_code": batch_code,
		"crates_used": 0
	}

	current_session_id = DataStore.create_wrapping_session(session_data)

func generate_batch_code() -> String:
	var date_dict = Time.get_datetime_dict_from_system()
	var week = date_dict.get("week", 1)
	var weekday = date_dict.get("weekday", 1)
	var dispatch_weekday = (weekday % 7) + 1
	return "L%02d%02d" % [week, dispatch_weekday]

func _on_increment_crates():
	crates_wrapped += 1
	update_ui()

func _on_decrement_crates():
	if crates_wrapped > 0:
		crates_wrapped -= 1
		update_ui()

func _on_add_bad_product_pressed():
	var reasons = DataStore.get_defect_reasons("bad_product")
	%BadProductPopup.set_reasons(reasons)
	%BadProductPopup.popup_centered()

func _on_add_bad_wrap_pressed():
	var reasons = DataStore.get_defect_reasons("bad_wrap")
	%BadWrapPopup.set_reasons(reasons)
	%BadWrapPopup.popup_centered()

func _on_add_custom_reason_pressed():
	%CustomReasonPopup.popup_centered()

func add_defect(defect_type: String, reason: String, defect_quantity: int, notes: String = ""):
	if current_session_id < 0:
		return

	var defect_data = {
		"session_id": current_session_id,
		"defect_type": defect_type,
		"defect_reason": reason,
		"quantity": defect_quantity,
		"notes": notes,
		"user_id": current_user.id
	}

	DataStore.add_defect(defect_data)
	session_defects.append(defect_data)

	if defect_type == "bad_product":
		bad_product_count += defect_quantity
	elif defect_type == "bad_wrap":
		bad_wrap_count += defect_quantity

	update_ui()
	show_notification("Defect: %s - %s (×%d)" % [defect_type.replace("_", " ").capitalize(), reason, defect_quantity])

func add_custom_reason(defect_type: String, reason: String):
	DataStore.add_defect_reason(defect_type, reason)
	show_notification("Custom reason added: %s" % reason)

func _on_end_session_pressed():
	if current_session_id >= 0:
		DataStore.end_wrapping_session(current_session_id, crates_wrapped)

		if not selected_order.is_empty():
			DataStore.update_order_status(selected_order.id, "completed")

		show_notification("Session ended. %d crates wrapped." % crates_wrapped)
		reset_session()

func _on_generate_rm415_pressed():
	%RM415Popup.populate_form(product, supplier, batch_code)
	%RM415Popup.popup_centered()

func reset_session():
	current_session_id = -1
	selected_order = {}
	current_operator = ""
	product = ""
	supplier = ""
	quantity = ""
	harvest_date = ""
	delivery_date = ""
	batch_code = ""
	crates_wrapped = 0
	session_defects.clear()
	bad_product_count = 0
	bad_wrap_count = 0
	update_ui()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func show_notification(message: String):
	%NotificationLabel.text = message
	%NotificationLabel.show()
	await get_tree().create_timer(3.0).timeout
	%NotificationLabel.hide()
