extends Window

var products = [
	"433g Cups",
	"300g Cups",
	"150g Buttons",
	"250g Flats",
	"150g Sliced"
]

var suppliers = ["RM", "McKenna", "Other"]

@onready var product_dropdown = %ProductDropdown
@onready var quantity_input = %QuantityInput
@onready var customer_input = %CustomerInput
@onready var delivery_input = %DeliveryInput
@onready var harvest_input = %HarvestInput
@onready var supplier_dropdown = %SupplierDropdown
@onready var batch_input = %BatchInput

func _ready():
	# Populate dropdowns
	for product in products:
		product_dropdown.add_item(product)

	for supplier in suppliers:
		supplier_dropdown.add_item(supplier)

	# Set defaults
	customer_input.text = "Lidl RDC Mullingar"
	delivery_input.text = get_tomorrow_date()
	harvest_input.text = Time.get_date_string_from_system()
	batch_input.text = generate_batch_code()

	%CreateBtn.pressed.connect(_on_create_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func get_tomorrow_date() -> String:
	var time = Time.get_unix_time_from_system() + 86400  # +1 day
	var date_dict = Time.get_datetime_dict_from_unix_time(int(time))
	return "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]

func generate_batch_code() -> String:
	var date_dict = Time.get_datetime_dict_from_system()
	var week = date_dict.get("week", 1)
	var weekday = date_dict.get("weekday", 1)
	var dispatch_weekday = (weekday % 7) + 1
	return "L%02d%02d" % [week, dispatch_weekday]

func _on_create_pressed():
	if product_dropdown.selected < 0 or quantity_input.text.is_empty():
		show_error("Please select product and enter quantity")
		return

	var order_data = {
		"product": products[product_dropdown.selected],
		"quantity": quantity_input.text,
		"customer": customer_input.text,
		"delivery_date": delivery_input.text,
		"harvest_date": harvest_input.text,
		"supplier": suppliers[supplier_dropdown.selected] if supplier_dropdown.selected >= 0 else "",
		"batch_code": batch_input.text
	}

	get_parent().create_order_from_popup(order_data)
	reset_form()
	hide()

func _on_cancel_pressed():
	hide()

func reset_form():
	product_dropdown.selected = -1
	quantity_input.text = ""
	customer_input.text = "Lidl RDC Mullingar"
	delivery_input.text = get_tomorrow_date()
	harvest_input.text = Time.get_date_string_from_system()
	batch_input.text = generate_batch_code()

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
	await get_tree().create_timer(3.0).timeout
	%ErrorLabel.hide()
