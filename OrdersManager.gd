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
	title.text = "%s - %s" % [order.product, order.quantity]
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var delivery = Label.new()
	delivery.text = "Delivery: %s | Status: %s" % [order.delivery_date, order.status.capitalize()]
	vbox.add_child(delivery)

	if order.has("supplier") and not order.supplier.is_empty():
		var supplier = Label.new()
		supplier.text = "Supplier: %s" % order.supplier
		vbox.add_child(supplier)

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
	show_notification("Order created: %s" % order_data.product)
