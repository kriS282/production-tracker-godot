extends Window

var products = [
	"433g Cups",
	"300g Cups",
	"150g Buttons",
	"250g Flats",
	"150g Sliced"
]

var suppliers = [
	"RM",
	"McKenna",
	"Other"
]

@onready var product_dropdown = %ProductDropdown
@onready var supplier_dropdown = %SupplierDropdown
@onready var order_input = %OrderInput
@onready var crates_used_input = %CratesUsedInput
@onready var parent_tracker = get_parent()

func _ready():
	# Populate dropdowns
	for product in products:
		product_dropdown.add_item(product)

	for supplier in suppliers:
		supplier_dropdown.add_item(supplier)

	# Connect buttons
	%StartBtn.pressed.connect(_on_start_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func _on_start_pressed():
	if product_dropdown.selected >= 0 and supplier_dropdown.selected >= 0:
		var product = products[product_dropdown.selected]
		var supplier = suppliers[supplier_dropdown.selected]
		var order = order_input.text
		var crates_used = int(crates_used_input.text) if crates_used_input.text.is_valid_int() else 0

		parent_tracker.start_wrapping_session(product, supplier, order)

		if crates_used > 0:
			parent_tracker.record_crates_used(crates_used)

		# Reset
		order_input.text = ""
		crates_used_input.text = "0"
		hide()

func _on_cancel_pressed():
	hide()
