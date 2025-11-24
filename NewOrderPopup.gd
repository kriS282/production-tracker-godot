extends Window

# Popup for creating new orders with multiple products

var selected_products = []  # Array of {product_id, product_name, quantity}

@onready var customer_dropdown = %CustomerDropdown
@onready var delivery_input = %DeliveryInput
@onready var products_list = %ProductsList

func _ready():
	populate_customer_dropdown()

	# Set defaults
	delivery_input.text = get_tomorrow_date()

	%AddProductBtn.pressed.connect(_on_add_product_pressed)
	%CreateBtn.pressed.connect(_on_create_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func populate_customer_dropdown():
	customer_dropdown.clear()
	var customers = DataStore.get_all_customers()
	for customer in customers:
		customer_dropdown.add_item(customer.name, customer.id)

	if customer_dropdown.item_count > 0:
		customer_dropdown.selected = 0

func get_tomorrow_date() -> String:
	var time = Time.get_unix_time_from_system() + 86400  # +1 day
	var date_dict = Time.get_datetime_dict_from_unix_time(int(time))
	return "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]

func _on_add_product_pressed():
	if customer_dropdown.selected < 0:
		show_error("Please select a customer first")
		return

	var customer_id = customer_dropdown.get_item_id(customer_dropdown.selected)
	%ProductSelectPopup.show_for_customer(customer_id)

func add_product_to_order(product_id: int, product_name: String, quantity: String):
	# Check if product already added
	for i in range(selected_products.size()):
		if selected_products[i].product_id == product_id:
			selected_products[i].quantity = quantity
			update_products_list()
			return

	# Add new product
	selected_products.append({
		"product_id": product_id,
		"product_name": product_name,
		"quantity": quantity
	})
	update_products_list()

func update_products_list():
	for child in products_list.get_children():
		child.queue_free()

	if selected_products.is_empty():
		var label = Label.new()
		label.text = "No products added yet. Click 'Add Product' to begin."
		label.add_theme_font_size_override("font_size", 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		products_list.add_child(label)
	else:
		for prod_data in selected_products:
			var panel = create_product_entry(prod_data)
			products_list.add_child(panel)

func create_product_entry(prod_data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label = Label.new()
	name_label.text = prod_data.product_name
	name_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(name_label)

	var qty_label = Label.new()
	qty_label.text = "Quantity: %s" % prod_data.quantity
	qty_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(qty_label)

	# Remove button
	var remove_btn = Button.new()
	remove_btn.text = "Remove"
	remove_btn.custom_minimum_size = Vector2(120, 80)
	remove_btn.add_theme_font_size_override("font_size", 20)
	remove_btn.pressed.connect(func(): remove_product(prod_data.product_id))
	hbox.add_child(remove_btn)

	return panel

func remove_product(product_id: int):
	for i in range(selected_products.size()):
		if selected_products[i].product_id == product_id:
			selected_products.remove_at(i)
			break
	update_products_list()

func _on_create_pressed():
	if customer_dropdown.selected < 0:
		show_error("Please select a customer")
		return

	if selected_products.is_empty():
		show_error("Please add at least one product")
		return

	if delivery_input.text.is_empty():
		show_error("Please enter delivery date")
		return

	var customer_id = customer_dropdown.get_item_id(customer_dropdown.selected)
	var customer_name = customer_dropdown.get_item_text(customer_dropdown.selected)

	var order_data = {
		"customer_id": customer_id,
		"customer_name": customer_name,
		"delivery_date": delivery_input.text,
		"products": selected_products.duplicate(true)
	}

	get_parent().create_order_from_popup(order_data)
	reset_form()
	hide()

func _on_cancel_pressed():
	hide()

func reset_form():
	selected_products.clear()
	update_products_list()

	populate_customer_dropdown()
	delivery_input.text = get_tomorrow_date()

	%ErrorLabel.hide()

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
	await get_tree().create_timer(3.0).timeout
	%ErrorLabel.hide()
