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
@onready var supplier_dropdown = %SupplierDropdown
@onready var quantity_input = %QuantityInput
@onready var harvest_input = %HarvestInput
@onready var delivery_input = %DeliveryInput
@onready var batch_input = %BatchInput

func _ready():
	# Populate dropdowns
	for product in products:
		product_dropdown.add_item(product)

	for supplier in suppliers:
		supplier_dropdown.add_item(supplier)

	# Set defaults
	harvest_input.text = Time.get_date_string_from_system()
	delivery_input.text = get_tomorrow_date()
	batch_input.text = generate_batch_code()

	%StartBtn.pressed.connect(_on_start_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func get_tomorrow_date() -> String:
	var time = Time.get_unix_time_from_system() + 86400
	var date_dict = Time.get_datetime_dict_from_unix_time(int(time))
	return "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]

func generate_batch_code() -> String:
	"""Generate batch code for delivery date"""
	if delivery_input and not delivery_input.text.is_empty():
		return DataStore.generate_batch_code_for_date(delivery_input.text)
	else:
		return DataStore.generate_batch_code_for_date("")

func _on_start_pressed():
	if product_dropdown.selected < 0 or supplier_dropdown.selected < 0:
		show_error("Please select product and supplier")
		return

	if quantity_input.text.is_empty():
		show_error("Please enter quantity")
		return

	# Validate batch code against delivery date
	var validation = DataStore.validate_batch_code_for_date(batch_input.text, delivery_input.text)
	if not validation.valid:
		show_error(validation.message + "\nUsing expected: " + validation.expected_code)
		batch_input.text = validation.expected_code

	var data = {
		"product": products[product_dropdown.selected],
		"supplier": suppliers[supplier_dropdown.selected],
		"quantity": quantity_input.text,
		"harvest_date": harvest_input.text,
		"delivery_date": delivery_input.text,
		"batch_code": batch_input.text
	}

	get_parent().start_session_manual(data)
	reset_form()
	hide()

func _on_cancel_pressed():
	hide()

func reset_form():
	product_dropdown.selected = -1
	supplier_dropdown.selected = -1
	quantity_input.text = ""
	harvest_input.text = Time.get_date_string_from_system()
	delivery_input.text = get_tomorrow_date()
	batch_input.text = generate_batch_code()

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
	await get_tree().create_timer(2.0).timeout
	%ErrorLabel.hide()
