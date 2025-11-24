extends Control

# Wrapping tracker with operators list and date pickers

var current_user = {}
var current_session_id = -1

# Session data
var operators_list = []  # List of {name: String, id: int, is_manual: bool, paused: bool, pause_reason: String}
var selected_product = {}
var selected_supplier = {}
var selected_order = {}
var quantity_multiplier = 0  # Number of boxes (e.g., 120 boxes)
var quantity_per_box = 0    # Punnets per box (e.g., 12 punnets)
var pick_date = ""
var delivery_date = ""
var batch_code = ""
var session_active = false
var session_paused = false
var session_pause_reason = ""

# Quality Control data
var session_defects = []
var bad_product_count = 0
var bad_wrap_count = 0

func _ready():
	current_user = DataStore.get_current_user()

	if current_user.is_empty():
		get_tree().change_scene_to_file("res://LoginScreen.tscn")
		return

	# Initialize dates
	initialize_dates()

	# Add current user as first operator
	add_operator_from_user(current_user.id, current_user.username)

	# Check if there's a selected order from OrderSelectPopup
	check_for_selected_order()

	update_ui()
	connect_buttons()
	setup_popups()

func connect_buttons():
	%BackBtn.pressed.connect(_on_back_pressed)
	%AddOperatorBtn.pressed.connect(_on_add_operator_pressed)
	%AddManualOperatorBtn.pressed.connect(_on_add_manual_operator_pressed)
	%ChangeProductBtn.pressed.connect(_on_change_product_pressed)
	%ChangeQuantityBtn.pressed.connect(_on_change_quantity_pressed)
	%ChangeSupplierBtn.pressed.connect(_on_change_supplier_pressed)
	%SelectOrderBtn.pressed.connect(_on_select_order_pressed)

	# Date buttons
	%PickDateDecBtn.pressed.connect(_on_pick_date_dec)
	%PickDateIncBtn.pressed.connect(_on_pick_date_inc)
	%DeliveryDateDecBtn.pressed.connect(_on_delivery_date_dec)
	%DeliveryDateIncBtn.pressed.connect(_on_delivery_date_inc)

	# Action buttons
	%StartWrappingBtn.pressed.connect(_on_start_wrapping_pressed)
	%TakePictureBtn.pressed.connect(_on_take_picture_pressed)
	%PauseResumeBtn.pressed.connect(_on_pause_resume_pressed)
	%FinishWrappingBtn.pressed.connect(_on_finish_wrapping_pressed)

	# Defect buttons
	%AddBadProductBtn.pressed.connect(_on_add_bad_product_pressed)
	%AddBadWrapBtn.pressed.connect(_on_add_bad_wrap_pressed)
	%AddCustomReasonBtn.pressed.connect(_on_add_custom_reason_pressed)
	%GenerateRM415Btn.pressed.connect(_on_generate_rm415_pressed)

func setup_popups():
	# Setup popup close handlers
	%AddOperatorPopup.close_requested.connect(func(): %AddOperatorPopup.hide())
	%ManualOperatorPopup.close_requested.connect(func(): %ManualOperatorPopup.hide())
	%ChangeProductPopup.close_requested.connect(func(): %ChangeProductPopup.hide())
	%ChangeSupplierPopup.close_requested.connect(func(): %ChangeSupplierPopup.hide())
	%QuantityPopup.close_requested.connect(func(): %QuantityPopup.hide())
	%TakePicturePopup.close_requested.connect(func(): %TakePicturePopup.hide())
	%PauseResumePopup.close_requested.connect(func(): %PauseResumePopup.hide())
	%PauseReasonPopup.close_requested.connect(func(): %PauseReasonPopup.hide())
	%OperatorManagePopup.close_requested.connect(func(): %OperatorManagePopup.hide())
	if has_node("%OrderSelectPopup"):
		%OrderSelectPopup.close_requested.connect(func(): %OrderSelectPopup.hide())

func initialize_dates():
	var date_dict = Time.get_datetime_dict_from_system()
	pick_date = format_date_dict(date_dict)

	# Delivery date is next day
	var next_day_unix = Time.get_unix_time_from_system() + 86400
	var next_day_dict = Time.get_datetime_dict_from_unix_time(int(next_day_unix))
	delivery_date = format_date_dict(next_day_dict)

func format_date_dict(date_dict: Dictionary) -> String:
	return "%02d/%02d/%02d" % [date_dict.day, date_dict.month, date_dict.year % 100]

func parse_date_string(date_str: String) -> Dictionary:
	var parts = date_str.split("/")
	if parts.size() != 3:
		return {}

	var day = parts[0].to_int()
	var month = parts[1].to_int()
	var year = 2000 + parts[2].to_int()  # Assume 20xx

	return {
		"day": day,
		"month": month,
		"year": year,
		"hour": 12,
		"minute": 0,
		"second": 0
	}

func date_to_iso(date_str: String) -> String:
	var date_dict = parse_date_string(date_str)
	if date_dict.is_empty():
		return ""
	return "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]

func update_ui():
	# Update operators list
	update_operators_list()

	# Update product info
	if selected_product.is_empty():
		%ProductNameLabel.text = "(Select Product)"
		%ProductBarcodeLabel.text = ""
		%QuantityLabel.text = "Quantity: --"
	else:
		%ProductNameLabel.text = selected_product.name
		var barcode = selected_product.get("barcode", "")
		%ProductBarcodeLabel.text = barcode if not barcode.is_empty() else "No barcode"

		if quantity_multiplier > 0 and quantity_per_box > 0:
			%QuantityLabel.text = "%d × %d" % [quantity_multiplier, quantity_per_box]
		elif quantity_per_box > 0:
			%QuantityLabel.text = "%d per box" % quantity_per_box
		else:
			%QuantityLabel.text = "--"

	# Update supplier with PN
	if selected_supplier.is_empty():
		%SupplierLabel.text = "Supplier: (Select Supplier)"
	else:
		var pn = selected_supplier.get("pn", "")
		var supplier_text = selected_supplier.name
		if not pn.is_empty():
			supplier_text += " (PN%s)" % pn
		%SupplierLabel.text = supplier_text

	# Update dates
	%PickDateDisplay.text = pick_date
	%DeliveryDateDisplay.text = delivery_date

	# Update defect counters
	%BadProductLabel.text = "Bad Product: %d" % bad_product_count
	%BadWrapLabel.text = "Bad Wrap: %d" % bad_wrap_count

	# Update batch code display
	if batch_code.is_empty():
		%BatchCodeLabel.text = "Batch: (Auto-generated on start)"
	else:
		%BatchCodeLabel.text = "Batch: %s" % batch_code

	# Enable/disable buttons based on state
	var has_operators = not operators_list.is_empty()
	var has_product = not selected_product.is_empty()
	var has_supplier = not selected_supplier.is_empty()
	var has_quantity = quantity_multiplier > 0 and quantity_per_box > 0
	var ready_to_start = has_operators and has_product and has_supplier and has_quantity

	%ChangeProductBtn.disabled = not has_operators
	%ChangeQuantityBtn.disabled = not has_product
	%ChangeSupplierBtn.disabled = not has_operators
	%StartWrappingBtn.disabled = not ready_to_start or session_active
	%TakePictureBtn.disabled = not session_active
	%PauseResumeBtn.disabled = not session_active
	%FinishWrappingBtn.disabled = not session_active
	%AddBadProductBtn.disabled = not session_active
	%AddBadWrapBtn.disabled = not session_active
	%AddCustomReasonBtn.disabled = not session_active
	%GenerateRM415Btn.disabled = not session_active

	# Update pause button text
	if session_paused:
		%PauseResumeBtn.text = "Resume"
	else:
		%PauseResumeBtn.text = "Pause / Break"

	# Update button colors
	if ready_to_start and not session_active:
		%StartWrappingBtn.modulate = Color(0.2, 0.8, 0.2)
	else:
		%StartWrappingBtn.modulate = Color(0.5, 0.5, 0.5)

	if session_active:
		%FinishWrappingBtn.modulate = Color(0.8, 0.2, 0.2)
	else:
		%FinishWrappingBtn.modulate = Color(0.5, 0.5, 0.5)

func update_operators_list():
	# Clear existing operator items
	for child in %OperatorsList.get_children():
		child.queue_free()

	# Create item for each operator - now clickable with pause status
	for operator_data in operators_list:
		var panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 15)
		panel.add_child(hbox)

		# Make the name clickable
		var name_btn = Button.new()
		var status_text = ""
		if operator_data.paused:
			status_text = " (PAUSED: %s)" % operator_data.pause_reason
		name_btn.text = operator_data.name + status_text
		name_btn.add_theme_font_size_override("font_size", 28)
		name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if operator_data.paused:
			name_btn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
		name_btn.pressed.connect(func(): show_operator_popup(operator_data))
		hbox.add_child(name_btn)

		%OperatorsList.add_child(panel)

func add_operator_from_user(user_id: int, user_name: String):
	# Check if already in list
	for op in operators_list:
		if op.id == user_id and not op.is_manual:
			return

	operators_list.append({
		"id": user_id,
		"name": user_name,
		"is_manual": false,
		"paused": false,
		"pause_reason": ""
	})
	update_ui()
	show_notification("Added operator: %s" % user_name)

func add_manual_operator(operator_name: String) -> int:
	# Create in DataStore first
	var operator_id = DataStore.create_operator(operator_name)

	# Add to local list
	operators_list.append({
		"id": operator_id,
		"name": operator_name,
		"is_manual": true,
		"paused": false,
		"pause_reason": ""
	})
	update_ui()
	show_notification("Added manual operator: %s" % operator_name)
	return operator_id

func remove_operator(operator_data: Dictionary):
	operators_list.erase(operator_data)
	update_ui()
	show_notification("Removed operator: %s" % operator_data.name)

func pause_operator(operator_data: Dictionary, reason: String):
	for i in range(operators_list.size()):
		if operators_list[i] == operator_data:
			operators_list[i].paused = true
			operators_list[i].pause_reason = reason
			break
	update_ui()
	show_notification("%s paused: %s" % [operator_data.name, reason])

func resume_operator(operator_data: Dictionary):
	for i in range(operators_list.size()):
		if operators_list[i] == operator_data:
			operators_list[i].paused = false
			operators_list[i].pause_reason = ""
			break
	update_ui()
	show_notification("%s resumed" % operator_data.name)

func show_operator_popup(operator_data: Dictionary):
	populate_operator_manage_popup(operator_data)
	%OperatorManagePopup.popup_centered()

func check_for_selected_order():
	# Check if OrderSelectPopup has set a selected order
	# This would be set via a global/autoload if implemented
	pass

func _on_select_order_pressed():
	%OrderSelectPopup.popup_centered()

func _on_add_operator_pressed():
	populate_add_operator_popup()
	%AddOperatorPopup.popup_centered()

func _on_add_manual_operator_pressed():
	populate_manual_operator_popup()
	%ManualOperatorPopup.popup_centered()

func _on_change_quantity_pressed():
	populate_quantity_popup()
	%QuantityPopup.popup_centered()

func populate_manual_operator_popup():
	# Clear existing content
	for child in %ManualOperatorPopup.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	%ManualOperatorPopup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Add Manual Operator"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "For workers without Android devices"
	desc.add_theme_font_size_override("font_size", 20)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var name_input = LineEdit.new()
	name_input.placeholder_text = "Enter operator name"
	name_input.custom_minimum_size = Vector2(0, 60)
	name_input.add_theme_font_size_override("font_size", 28)
	vbox.add_child(name_input)

	var add_btn = Button.new()
	add_btn.text = "Add Operator"
	add_btn.custom_minimum_size = Vector2(0, 70)
	add_btn.add_theme_font_size_override("font_size", 28)
	add_btn.pressed.connect(func():
		if not name_input.text.is_empty():
			add_manual_operator(name_input.text)
			%ManualOperatorPopup.hide()
	)
	vbox.add_child(add_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): %ManualOperatorPopup.hide())
	vbox.add_child(cancel_btn)

func populate_quantity_popup():
	# Clear existing content
	for child in %QuantityPopup.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	%QuantityPopup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Set Wrapping Quantity"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	if not selected_product.is_empty():
		var product_label = Label.new()
		product_label.text = "Product: %s" % selected_product.name
		product_label.add_theme_font_size_override("font_size", 24)
		product_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(product_label)

		var boxes_per_crate = selected_product.get("boxes_per_crate", 12)
		var info_label = Label.new()
		info_label.text = "%d punnets per box" % boxes_per_crate
		info_label.add_theme_font_size_override("font_size", 20)
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(info_label)

	var multiplier_label = Label.new()
	multiplier_label.text = "Number of boxes to wrap:"
	multiplier_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(multiplier_label)

	var multiplier_input = SpinBox.new()
	multiplier_input.min_value = 1
	multiplier_input.max_value = 1000
	multiplier_input.value = quantity_multiplier if quantity_multiplier > 0 else selected_product.get("boxes_per_crate", 12)
	multiplier_input.custom_minimum_size = Vector2(0, 60)
	multiplier_input.add_theme_font_size_override("font_size", 28)
	vbox.add_child(multiplier_input)

	var set_btn = Button.new()
	set_btn.text = "Set Quantity"
	set_btn.custom_minimum_size = Vector2(0, 70)
	set_btn.add_theme_font_size_override("font_size", 28)
	set_btn.pressed.connect(func():
		quantity_multiplier = int(multiplier_input.value)
		quantity_per_box = selected_product.get("boxes_per_crate", 12)
		update_ui()
		%QuantityPopup.hide()
	)
	vbox.add_child(set_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): %QuantityPopup.hide())
	vbox.add_child(cancel_btn)

func populate_operator_manage_popup(operator_data: Dictionary):
	# Clear existing content
	for child in %OperatorManagePopup.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	%OperatorManagePopup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = operator_data.name
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Pause/Resume button
	if operator_data.paused:
		var resume_btn = Button.new()
		resume_btn.text = "Resume Wrapping"
		resume_btn.custom_minimum_size = Vector2(0, 80)
		resume_btn.add_theme_font_size_override("font_size", 28)
		resume_btn.pressed.connect(func():
			resume_operator(operator_data)
			%OperatorManagePopup.hide()
		)
		vbox.add_child(resume_btn)
	else:
		var pause_btn = Button.new()
		pause_btn.text = "Pause Operator"
		pause_btn.custom_minimum_size = Vector2(0, 80)
		pause_btn.add_theme_font_size_override("font_size", 28)
		pause_btn.pressed.connect(func():
			show_pause_reason_popup(operator_data)
			%OperatorManagePopup.hide()
		)
		vbox.add_child(pause_btn)

	# Remove button
	var remove_btn = Button.new()
	remove_btn.text = "Remove Operator"
	remove_btn.custom_minimum_size = Vector2(0, 80)
	remove_btn.add_theme_font_size_override("font_size", 28)
	remove_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	remove_btn.pressed.connect(func():
		remove_operator(operator_data)
		%OperatorManagePopup.hide()
	)
	vbox.add_child(remove_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): %OperatorManagePopup.hide())
	vbox.add_child(cancel_btn)

func show_pause_reason_popup(operator_data: Dictionary):
	populate_pause_reason_popup(operator_data, false)
	%PauseReasonPopup.popup_centered()

func populate_add_operator_popup():
	# Clear existing content
	for child in %AddOperatorPopup.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	%AddOperatorPopup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Select Operator"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(list_vbox)

	# Get all users
	var users = DataStore.get_all_users()
	for user in users:
		var btn = Button.new()
		btn.text = "%s (%s)" % [user.username, user.role.capitalize()]
		btn.custom_minimum_size = Vector2(0, 70)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(func():
			add_operator_from_user(user.id, user.username)
			%AddOperatorPopup.hide()
		)
		list_vbox.add_child(btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): %AddOperatorPopup.hide())
	vbox.add_child(cancel_btn)

func _on_change_product_pressed():
	populate_change_product_popup()
	%ChangeProductPopup.popup_centered()

func populate_change_product_popup():
	# Clear existing content
	for child in %ChangeProductPopup.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	%ChangeProductPopup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Select Product"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 500)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(list_vbox)

	# Get all products
	var products = DataStore.get_all_products()
	for product in products:
		var customer = DataStore.get_customer_by_id(product.customer_id)
		var customer_name = customer.name if customer else "Unknown"

		var btn = Button.new()
		var barcode_text = ""
		if product.get("barcode", "") != "":
			barcode_text = " | " + product.barcode
		btn.text = "%s - %s\n%s | %d per BOX%s" % [
			customer_name,
			product.name,
			product.target_weight,
			product.get("boxes_per_crate", 12),
			barcode_text
		]
		btn.custom_minimum_size = Vector2(550, 90)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 22)
		btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		btn.pressed.connect(func():
			set_product(product)
			%ChangeProductPopup.hide()
		)
		list_vbox.add_child(btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): %ChangeProductPopup.hide())
	vbox.add_child(cancel_btn)

func set_product(product: Dictionary):
	selected_product = product
	quantity_per_box = product.get("boxes_per_crate", 12)
	update_ui()
	show_notification("Selected: %s" % product.name)

func _on_change_supplier_pressed():
	populate_change_supplier_popup()
	%ChangeSupplierPopup.popup_centered()

func populate_change_supplier_popup():
	# Clear existing content
	for child in %ChangeSupplierPopup.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	%ChangeSupplierPopup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Select Supplier"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(list_vbox)

	# Get all suppliers
	var suppliers = DataStore.get_all_suppliers()
	for supplier in suppliers:
		var btn = Button.new()
		var pn_text = ""
		if supplier.get("pn", "") != "":
			pn_text = " (PN: %s)" % supplier.pn
		btn.text = "%s%s" % [supplier.name, pn_text]
		btn.custom_minimum_size = Vector2(0, 70)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(func():
			set_supplier(supplier)
			%ChangeSupplierPopup.hide()
		)
		list_vbox.add_child(btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): %ChangeSupplierPopup.hide())
	vbox.add_child(cancel_btn)

func set_supplier(supplier: Dictionary):
	selected_supplier = supplier
	update_ui()
	show_notification("Selected: %s" % supplier.name)

func _on_pick_date_dec():
	adjust_date("pick", -1)

func _on_pick_date_inc():
	# Can't go above today
	var date_dict = parse_date_string(pick_date)
	if date_dict.is_empty():
		return

	var pick_unix = Time.get_unix_time_from_datetime_dict(date_dict)
	var today_unix = Time.get_unix_time_from_system()

	# Allow increment if pick date is before today
	if pick_unix < today_unix - 3600:  # Give 1 hour buffer
		adjust_date("pick", 1)

func _on_delivery_date_dec():
	adjust_date("delivery", -1)

func _on_delivery_date_inc():
	adjust_date("delivery", 1)

func adjust_date(date_type: String, days: int):
	var current_date = pick_date if date_type == "pick" else delivery_date
	var date_dict = parse_date_string(current_date)

	if date_dict.is_empty():
		return

	var current_unix = Time.get_unix_time_from_datetime_dict(date_dict)
	var new_unix = current_unix + (days * 86400)
	var new_date_dict = Time.get_datetime_dict_from_unix_time(int(new_unix))
	var new_date_str = format_date_dict(new_date_dict)

	if date_type == "pick":
		pick_date = new_date_str
	else:
		delivery_date = new_date_str

	update_ui()

func _on_start_wrapping_pressed():
	if operators_list.is_empty() or selected_product.is_empty() or selected_supplier.is_empty():
		show_notification("Please select operators, product, and supplier first")
		return

	# Generate batch code
	batch_code = generate_batch_code()

	# Build operator names list
	var operator_names = []
	for op in operators_list:
		operator_names.append(op.name)

	# Create wrapping session
	var session_data = {
		"order_id": selected_order.get("id", -1),
		"user_id": current_user.id,
		"operator": ", ".join(operator_names),
		"product": selected_product.name,
		"supplier": selected_supplier.name,
		"quantity_wrapped": "%dx%d" % [quantity_multiplier, quantity_per_box],
		"pick_date": date_to_iso(pick_date),
		"delivery_date": date_to_iso(delivery_date),
		"batch_code": batch_code,
		"crates_used": 0
	}

	current_session_id = DataStore.create_wrapping_session(session_data)
	session_active = true
	session_paused = false

	update_ui()
	show_notification("Wrapping session started!")

func _on_take_picture_pressed():
	populate_take_picture_popup()
	%TakePicturePopup.popup_centered()

func populate_take_picture_popup():
	# Clear existing content
	for child in %TakePicturePopup.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	%TakePicturePopup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Take Picture"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Picture type buttons
	var types = ["First Label", "Box Label", "Last Label"]
	for pic_type in types:
		var btn = Button.new()
		btn.text = pic_type
		btn.custom_minimum_size = Vector2(0, 80)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(func():
			take_picture(pic_type)
			%TakePicturePopup.hide()
		)
		vbox.add_child(btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): %TakePicturePopup.hide())
	vbox.add_child(cancel_btn)

func take_picture(pic_type: String):
	# Placeholder for camera functionality
	show_notification("Taking picture: %s" % pic_type)
	# TODO: Implement actual camera capture

func populate_pause_reason_popup(operator_data: Dictionary, is_session_pause: bool):
	# Clear existing content
	for child in %PauseReasonPopup.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	%PauseReasonPopup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Select Pause Reason"
	if is_session_pause:
		title.text = "Pause Entire Session"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(list_vbox)

	# Get pause reasons from DataStore
	var reasons = DataStore.get_pause_reasons()
	for reason in reasons:
		var btn = Button.new()
		btn.text = reason
		btn.custom_minimum_size = Vector2(0, 70)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(func():
			if is_session_pause:
				pause_session(reason)
			else:
				pause_operator(operator_data, reason)
			%PauseReasonPopup.hide()
		)
		list_vbox.add_child(btn)

	# Add custom reason button
	var custom_btn = Button.new()
	custom_btn.text = "+ Add Custom Reason"
	custom_btn.custom_minimum_size = Vector2(0, 70)
	custom_btn.add_theme_font_size_override("font_size", 28)
	custom_btn.pressed.connect(func():
		show_custom_pause_reason_popup(operator_data, is_session_pause)
		%PauseReasonPopup.hide()
	)
	list_vbox.add_child(custom_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): %PauseReasonPopup.hide())
	vbox.add_child(cancel_btn)

func show_custom_pause_reason_popup(operator_data: Dictionary, is_session_pause: bool):
	var popup = Window.new()
	popup.title = "Custom Pause Reason"
	popup.size = Vector2(600, 300)
	add_child(popup)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	popup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Enter Custom Reason"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var reason_input = LineEdit.new()
	reason_input.placeholder_text = "Enter pause reason"
	reason_input.custom_minimum_size = Vector2(0, 60)
	reason_input.add_theme_font_size_override("font_size", 28)
	vbox.add_child(reason_input)

	var add_btn = Button.new()
	add_btn.text = "Add & Use Reason"
	add_btn.custom_minimum_size = Vector2(0, 70)
	add_btn.add_theme_font_size_override("font_size", 28)
	add_btn.pressed.connect(func():
		if not reason_input.text.is_empty():
			DataStore.add_pause_reason(reason_input.text)
			if is_session_pause:
				pause_session(reason_input.text)
			else:
				pause_operator(operator_data, reason_input.text)
			popup.queue_free()
	)
	vbox.add_child(add_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): popup.queue_free())
	vbox.add_child(cancel_btn)

	popup.popup_centered()

func pause_session(reason: String):
	session_paused = true
	session_pause_reason = reason
	update_ui()
	show_notification("Session paused: %s" % reason)

func resume_session():
	session_paused = false
	session_pause_reason = ""
	update_ui()
	show_notification("Session resumed")

func _on_pause_resume_pressed():
	if session_paused:
		resume_session()
	else:
		# Show pause reason popup for session-wide pause
		var dummy_operator = {"name": "Session", "id": -1}
		populate_pause_reason_popup(dummy_operator, true)
		%PauseResumePopup.popup_centered()


func _on_finish_wrapping_pressed():
	if current_session_id >= 0:
		DataStore.end_wrapping_session(current_session_id, quantity_multiplier)
		show_notification("Wrapping session finished!")
		reset_session()

func reset_session():
	current_session_id = -1
	session_active = false
	session_paused = false
	session_pause_reason = ""
	operators_list.clear()
	# Re-add current user
	add_operator_from_user(current_user.id, current_user.username)
	selected_product = {}
	selected_supplier = {}
	selected_order = {}
	quantity_multiplier = 0
	quantity_per_box = 0
	batch_code = ""
	session_defects.clear()
	bad_product_count = 0
	bad_wrap_count = 0
	initialize_dates()
	update_ui()

func generate_batch_code() -> String:
	var date_dict = Time.get_datetime_dict_from_system()
	var week = date_dict.get("week", 1)
	var weekday = date_dict.get("weekday", 1)
	var dispatch_weekday = (weekday % 7) + 1
	return "L%02d%02d" % [week, dispatch_weekday]

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

func _on_generate_rm415_pressed():
	%RM415Popup.populate_form(selected_product.get("name", ""), selected_supplier.get("name", ""), batch_code)
	%RM415Popup.popup_centered()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func show_notification(message: String):
	%NotificationLabel.text = message
	%NotificationLabel.show()
	await get_tree().create_timer(3.0).timeout
	%NotificationLabel.hide()
