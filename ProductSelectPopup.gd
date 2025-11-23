extends Window

# Popup for selecting a product and quantity for an order

var customer_id = -1
var available_products = []

@onready var product_dropdown = %ProductDropdown
@onready var quantity_input = %QuantityInput

func _ready():
	%SelectBtn.pressed.connect(_on_select_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func show_for_customer(cust_id: int):
	customer_id = cust_id
	load_products()
	popup_centered()

func load_products():
	product_dropdown.clear()
	available_products = DataStore.get_products_by_customer(customer_id)

	if available_products.is_empty():
		var customer = DataStore.get_customer_by_id(customer_id)
		%ErrorLabel.text = "No products found for %s. Add products in Control Panel." % customer.name
		%ErrorLabel.show()
		%SelectBtn.disabled = true
		return

	for product in available_products:
		product_dropdown.add_item(product.name, product.id)

	if product_dropdown.item_count > 0:
		product_dropdown.selected = 0

	%ErrorLabel.hide()
	%SelectBtn.disabled = false
	quantity_input.text = ""

func _on_select_pressed():
	if product_dropdown.selected < 0:
		show_error("Please select a product")
		return

	var quantity = quantity_input.text.strip_edges()
	if quantity.is_empty():
		show_error("Please enter quantity (e.g., 160x16)")
		return

	var product_id = product_dropdown.get_item_id(product_dropdown.selected)
	var product_name = product_dropdown.get_item_text(product_dropdown.selected)

	get_parent().add_product_to_order(product_id, product_name, quantity)
	quantity_input.text = ""
	hide()

func _on_cancel_pressed():
	hide()

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
