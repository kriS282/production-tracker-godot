extends Window

# Popup for setting up product information for wrapping session

var products = []
var suppliers = []

func _ready():
	%CancelBtn.pressed.connect(_on_cancel_pressed)
	%StartBtn.pressed.connect(_on_start_pressed)
	populate_dropdowns()

func populate_dropdowns():
	# Populate products
	products = DataStore.get_all_products()
	%ProductDropdown.clear()
	for product in products:
		var customer_name = ""
		var customer = DataStore.get_customer_by_id(product.customer_id)
		if customer:
			customer_name = customer.name
		%ProductDropdown.add_item("%s - %s (%s)" % [customer_name, product.name, product.target_weight])

	# Populate suppliers
	suppliers = DataStore.get_all_suppliers()
	%SupplierDropdown.clear()
	for supplier in suppliers:
		%SupplierDropdown.add_item(supplier.name)

	# Set default dates to today
	var date_dict = Time.get_datetime_dict_from_system()
	var today = "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]
	%HarvestDateInput.text = today
	%DeliveryDateInput.text = today

func _on_cancel_pressed():
	hide()

func _on_start_pressed():
	if products.is_empty() or suppliers.is_empty():
		show_error("No products or suppliers available")
		return

	var product_idx = %ProductDropdown.selected
	var supplier_idx = %SupplierDropdown.selected
	var quantity = %QuantityInput.text.strip_edges()
	var harvest_date = %HarvestDateInput.text.strip_edges()
	var delivery_date = %DeliveryDateInput.text.strip_edges()
	var batch_code = %BatchCodeInput.text.strip_edges()

	# Validation
	if product_idx < 0 or product_idx >= products.size():
		show_error("Please select a product")
		return

	if supplier_idx < 0 or supplier_idx >= suppliers.size():
		show_error("Please select a supplier")
		return

	if quantity.is_empty():
		show_error("Please enter quantity")
		return

	if harvest_date.is_empty():
		show_error("Please enter harvest date")
		return

	if delivery_date.is_empty():
		show_error("Please enter delivery date")
		return

	# Get selected items
	var selected_product = products[product_idx]
	var selected_supplier = suppliers[supplier_idx]

	# Build data dictionary
	var data = {
		"product": selected_product.name,
		"supplier": selected_supplier.name,
		"quantity": quantity,
		"harvest_date": harvest_date,
		"delivery_date": delivery_date,
		"batch_code": batch_code
	}

	# Send to parent
	get_parent().set_product_info(data)
	hide()

	# Clear form for next time
	clear_form()

func clear_form():
	%QuantityInput.text = ""
	%BatchCodeInput.text = ""
	%ErrorLabel.hide()

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()

func _on_close_requested():
	hide()
