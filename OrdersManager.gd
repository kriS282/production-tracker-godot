extends Control

# Orders management for supervisors/managers

var current_user = {}
var orders = []

@onready var orders_list = %OrdersList

func _ready():
	current_user = DataStore.get_current_user()

	if current_user.is_empty() or not DataStore.user_has_task("orders"):
		get_tree().change_scene_to_file("res://MainMenu.tscn")
		return

	connect_buttons()
	load_orders()

func connect_buttons():
	%BackBtn.pressed.connect(_on_back_pressed)
	%NewOrderBtn.pressed.connect(_on_new_order_pressed)
	%RefreshBtn.pressed.connect(_on_refresh_pressed)

func load_orders():
	orders = DataStore.get_all_orders()
	update_orders_list()

func update_orders_list():
	# Clear existing
	for child in orders_list.get_children():
		child.queue_free()

	# Add orders
	for order in orders:
		var order_panel = create_order_panel(order)
		orders_list.add_child(order_panel)

	if orders.is_empty():
		var label = Label.new()
		label.text = "No orders yet. Click 'New Order' to create one."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		orders_list.add_child(label)

func create_order_panel(order: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	var customer_name = order.get("customer_name", "Unknown")
	title.text = "Order #%d - %s" % [order.id, customer_name]
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var delivery = Label.new()
	delivery.text = "Delivery: %s | Status: %s" % [order.delivery_date, order.status.capitalize()]
	delivery.add_theme_font_size_override("font_size", 20)
	vbox.add_child(delivery)

	# Display products
	if order.has("products") and not order.products.is_empty():
		var products_label = Label.new()
		products_label.text = "Products:"
		products_label.add_theme_font_size_override("font_size", 20)
		vbox.add_child(products_label)

		for prod in order.products:
			var prod_label = Label.new()
			prod_label.text = "  • %s - %s" % [prod.product_name, prod.quantity]
			prod_label.add_theme_font_size_override("font_size", 18)
			vbox.add_child(prod_label)
	elif order.has("product"):
		# Legacy single-product orders
		var prod_label = Label.new()
		prod_label.text = "Product: %s - %s" % [order.product, order.get("quantity", "N/A")]
		prod_label.add_theme_font_size_override("font_size", 18)
		vbox.add_child(prod_label)

	return panel

func _on_back_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_new_order_pressed():
	%NewOrderPopup.popup_centered()

func _on_refresh_pressed():
	load_orders()
	show_notification("Orders refreshed")

func show_notification(message: String):
	%NotificationLabel.text = message
	%NotificationLabel.show()
	await get_tree().create_timer(2.0).timeout
	%NotificationLabel.hide()

func create_order_from_popup(order_data: Dictionary):
	order_data["created_by"] = current_user.id
	DataStore.create_order(order_data)
	load_orders()
	var product_count = order_data.products.size() if order_data.has("products") else 1
	show_notification("Order created: %s (%d product%s)" % [
		order_data.customer_name,
		product_count,
		"s" if product_count != 1 else ""
	])
