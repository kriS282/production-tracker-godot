extends Window

var orders = []

@onready var orders_list = %OrdersListContainer

func _ready():
	%CancelBtn.pressed.connect(_on_cancel_pressed)
	load_orders()

func load_orders():
	orders = DataStore.get_pending_orders()
	update_orders_list()

func update_orders_list():
	# Clear existing
	for child in orders_list.get_children():
		child.queue_free()

	if orders.is_empty():
		var label = Label.new()
		label.text = "No pending orders available"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		orders_list.add_child(label)
		return

	# Add order buttons
	for order in orders:
		var order_btn = create_order_button(order)
		orders_list.add_child(order_btn)

func create_order_button(order: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 100)
	btn.add_theme_font_size_override("font_size", 24)

	var text = "%s - %s\n" % [order.product, order.quantity]
	text += "Delivery: %s | Supplier: %s" % [
		order.delivery_date,
		order.get("supplier", "N/A")
	]
	btn.text = text

	btn.pressed.connect(func(): select_order(order))

	return btn

func select_order(order: Dictionary):
	get_parent().start_session_from_order(order)
	hide()

func _on_cancel_pressed():
	hide()
