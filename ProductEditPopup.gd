extends Window

# Popup for adding/editing products

var editing_product = null
var product_types = ["cups", "buttons", "flats", "sliced", "chestnuts", "portobello"]
var packaging_types = ["crates", "chips"]

func _ready():
	%CancelBtn.pressed.connect(_on_cancel_pressed)
	%SaveBtn.pressed.connect(_on_save_pressed)
	populate_dropdowns()

func populate_dropdowns():
	# Populate customer dropdown
	%CustomerDropdown.clear()
	var customers = DataStore.get_all_customers()
	for customer in customers:
		%CustomerDropdown.add_item(customer.name, customer.id)

	# Populate product type dropdown
	%ProductTypeDropdown.clear()
	for ptype in product_types:
		%ProductTypeDropdown.add_item(ptype.capitalize())

	# Populate packaging type dropdown
	%PackagingTypeDropdown.clear()
	for pkg_type in packaging_types:
		%PackagingTypeDropdown.add_item(pkg_type.capitalize())

func populate_product(product: Dictionary):
	editing_product = product
	populate_dropdowns()

	%NameInput.text = product.name
	%TargetWeightInput.text = product.target_weight
	%PunnetInput.text = product.punnet
	%BoxesPerCrateInput.text = str(product.boxes_per_crate)
	%PunnetsPerBoxInput.text = str(product.punnets_per_box)
	%BarcodeInput.text = product.get("barcode", "")

	# Set customer dropdown
	for i in range(%CustomerDropdown.item_count):
		if %CustomerDropdown.get_item_id(i) == product.customer_id:
			%CustomerDropdown.selected = i
			break

	# Set product type dropdown
	var type_index = product_types.find(product.product_type)
	if type_index != -1:
		%ProductTypeDropdown.selected = type_index

	# Set packaging type dropdown
	var pkg_type = product.get("packaging_type", "crates")
	var pkg_index = packaging_types.find(pkg_type)
	if pkg_index != -1:
		%PackagingTypeDropdown.selected = pkg_index

	title = "Edit Product"
	%SaveBtn.text = "Save Changes"

func clear_form():
	editing_product = null
	populate_dropdowns()

	%NameInput.text = ""
	%TargetWeightInput.text = ""
	%PunnetInput.text = "Standard punnet"
	%BoxesPerCrateInput.text = "12"
	%PunnetsPerBoxInput.text = "1"
	%BarcodeInput.text = ""

	if %CustomerDropdown.item_count > 0:
		%CustomerDropdown.selected = 0
	if %ProductTypeDropdown.item_count > 0:
		%ProductTypeDropdown.selected = 0
	if %PackagingTypeDropdown.item_count > 0:
		%PackagingTypeDropdown.selected = 0

	title = "New Product"
	%SaveBtn.text = "Create Product"
	%ErrorLabel.hide()

func _on_cancel_pressed():
	hide()

func _on_save_pressed():
	var product_name = %NameInput.text.strip_edges()
	var target_weight = %TargetWeightInput.text.strip_edges()
	var punnet = %PunnetInput.text.strip_edges()
	var boxes_per_crate_text = %BoxesPerCrateInput.text.strip_edges()
	var punnets_per_box_text = %PunnetsPerBoxInput.text.strip_edges()
	var barcode = %BarcodeInput.text.strip_edges()

	if product_name == "":
		show_error("Product name is required")
		return

	if target_weight == "":
		show_error("Target weight is required")
		return

	if %CustomerDropdown.selected == -1:
		show_error("Please select a customer")
		return

	if %ProductTypeDropdown.selected == -1:
		show_error("Please select a product type")
		return

	if %PackagingTypeDropdown.selected == -1:
		show_error("Please select a packaging type")
		return

	var boxes_per_crate = boxes_per_crate_text.to_int()
	if boxes_per_crate <= 0:
		show_error("Boxes per crate must be a positive number")
		return

	var punnets_per_box = punnets_per_box_text.to_int()
	if punnets_per_box <= 0:
		show_error("Punnets per box must be a positive number")
		return

	var customer_id = %CustomerDropdown.get_item_id(%CustomerDropdown.selected)
	var product_type = product_types[%ProductTypeDropdown.selected]
	var packaging_type = packaging_types[%PackagingTypeDropdown.selected]

	var product_data = {
		"name": product_name,
		"customer_id": customer_id,
		"product_type": product_type,
		"target_weight": target_weight,
		"punnet": punnet,
		"packaging_type": packaging_type,
		"boxes_per_crate": boxes_per_crate,
		"punnets_per_box": punnets_per_box,
		"barcode": barcode
	}

	if editing_product:
		# Update existing
		DataStore.update_product(editing_product.id, product_data)
	else:
		# Create new
		DataStore.create_product(product_data)

	hide()
	get_parent().load_products()

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
