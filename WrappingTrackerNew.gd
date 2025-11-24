extends Control

# Wrapping tracker with operators list and date pickers

var current_user = {}
var current_session_id = -1

# Session data
var operators_list = []  # List of operator names
var selected_product = {}
var selected_supplier = {}
var quantity_crates = 0
var quantity_per_crate = 0
var pick_date = ""
var delivery_date = ""
var batch_code = ""
var session_active = false
var session_paused = false

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
	add_operator(current_user.username)

	update_ui()
	connect_buttons()
	setup_popups()

func connect_buttons():
	%BackBtn.pressed.connect(_on_back_pressed)
	%AddOperatorBtn.pressed.connect(_on_add_operator_pressed)
	%ChangeProductBtn.pressed.connect(_on_change_product_pressed)
	%ChangeSupplierBtn.pressed.connect(_on_change_supplier_pressed)

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
	%ChangeProductPopup.close_requested.connect(func(): %ChangeProductPopup.hide())
	%ChangeSupplierPopup.close_requested.connect(func(): %ChangeSupplierPopup.hide())
	%TakePicturePopup.close_requested.connect(func(): %TakePicturePopup.hide())
	%PauseResumePopup.close_requested.connect(func(): %PauseResumePopup.hide())

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

	# Update product/quantity
	if selected_product.is_empty():
		%ProductLabel.text = "Product: (Select Product)"
		%QuantityLabel.text = "Quantity: --"
	else:
		%ProductLabel.text = "Product: %s" % selected_product.name
		if quantity_crates > 0:
			%QuantityLabel.text = "Quantity: %dx%d" % [quantity_crates, quantity_per_crate]
		else:
			%QuantityLabel.text = "Quantity: %d" % quantity_per_crate

	# Update supplier
	if selected_supplier.is_empty():
		%SupplierLabel.text = "Supplier: (Select Supplier)"
	else:
		%SupplierLabel.text = "Supplier: %s" % selected_supplier.name

	# Update dates
	%PickDateDisplay.text = pick_date
	%DeliveryDateDisplay.text = delivery_date

	# Update defect counters
	%BadProductLabel.text = "Bad Product: %d" % bad_product_count
	%BadWrapLabel.text = "Bad Wrap: %d" % bad_wrap_count

	# Enable/disable buttons based on state
	var has_operators = not operators_list.is_empty()
	var has_product = not selected_product.is_empty()
	var has_supplier = not selected_supplier.is_empty()
	var ready_to_start = has_operators and has_product and has_supplier

	%ChangeProductBtn.disabled = not has_operators
	%ChangeSupplierBtn.disabled = not has_operators
	%StartWrappingBtn.disabled = not ready_to_start or session_active
	%TakePictureBtn.disabled = not session_active
	%PauseResumeBtn.disabled = not session_active
	%FinishWrappingBtn.disabled = not session_active
	%AddBadProductBtn.disabled = not session_active
	%AddBadWrapBtn.disabled = not session_active
	%AddCustomReasonBtn.disabled = not session_active
	%GenerateRM415Btn.disabled = not session_active

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

	# Create item for each operator with remove button
	for operator_name in operators_list:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 15)

		var label = Label.new()
		label.text = operator_name
		label.add_theme_font_size_override("font_size", 28)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)

		var remove_btn = Button.new()
		remove_btn.text = "X"
		remove_btn.custom_minimum_size = Vector2(60, 50)
		remove_btn.add_theme_font_size_override("font_size", 28)
		remove_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		remove_btn.pressed.connect(func(): remove_operator(operator_name))
		hbox.add_child(remove_btn)

		%OperatorsList.add_child(hbox)

func add_operator(operator_name: String):
	if not operators_list.has(operator_name):
		operators_list.append(operator_name)
		update_ui()
		show_notification("Added operator: %s" % operator_name)

func remove_operator(operator_name: String):
	operators_list.erase(operator_name)
	update_ui()
	show_notification("Removed operator: %s" % operator_name)

func _on_add_operator_pressed():
	populate_add_operator_popup()
	%AddOperatorPopup.popup_centered()

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
			add_operator(user.username)
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
	scroll.custom_minimum_size = Vector2(0, 400)
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
		btn.text = "%s - %s\n%s | %d per crate" % [
			customer_name,
			product.name,
			product.target_weight,
			product.get("boxes_per_crate", 12)
		]
		btn.custom_minimum_size = Vector2(0, 90)
		btn.add_theme_font_size_override("font_size", 24)
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
	quantity_per_crate = product.get("boxes_per_crate", 12)
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

	# Create wrapping session
	var session_data = {
		"order_id": -1,
		"user_id": current_user.id,
		"operator": ", ".join(operators_list),
		"product": selected_product.name,
		"supplier": selected_supplier.name,
		"quantity_wrapped": "%dx%d" % [quantity_crates, quantity_per_crate],
		"harvest_date": date_to_iso(pick_date),
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

func _on_pause_resume_pressed():
	populate_pause_resume_popup()
	%PauseResumePopup.popup_centered()

func populate_pause_resume_popup():
	# Clear existing content
	for child in %PauseResumePopup.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	%PauseResumePopup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Session Control"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	if session_paused:
		var resume_btn = Button.new()
		resume_btn.text = "Resume Wrapping"
		resume_btn.custom_minimum_size = Vector2(0, 80)
		resume_btn.add_theme_font_size_override("font_size", 28)
		resume_btn.pressed.connect(func():
			session_paused = false
			show_notification("Resumed wrapping")
			%PauseResumePopup.hide()
		)
		vbox.add_child(resume_btn)
	else:
		var pause_btn = Button.new()
		pause_btn.text = "Pause Wrapping"
		pause_btn.custom_minimum_size = Vector2(0, 80)
		pause_btn.add_theme_font_size_override("font_size", 28)
		pause_btn.pressed.connect(func():
			session_paused = true
			show_notification("Paused wrapping")
			%PauseResumePopup.hide()
		)
		vbox.add_child(pause_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.pressed.connect(func(): %PauseResumePopup.hide())
	vbox.add_child(cancel_btn)

func _on_finish_wrapping_pressed():
	if current_session_id >= 0:
		DataStore.end_wrapping_session(current_session_id, quantity_crates)
		show_notification("Wrapping session finished!")
		reset_session()

func reset_session():
	current_session_id = -1
	session_active = false
	session_paused = false
	operators_list.clear()
	# Re-add current user
	add_operator(current_user.username)
	selected_product = {}
	selected_supplier = {}
	quantity_crates = 0
	quantity_per_crate = 0
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
