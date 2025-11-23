extends Control

# Control panel for managing customers, products, and suppliers

var current_user = {}
var customers = []
var products = []
var suppliers = []

@onready var customers_list = %CustomersList
@onready var products_list = %ProductsList
@onready var suppliers_list = %SuppliersList

func _ready():
	current_user = DataStore.get_current_user()

	if current_user.is_empty() or not current_user.is_admin:
		get_tree().change_scene_to_file("res://MainMenu.tscn")
		return

	connect_buttons()
	load_all_data()

func connect_buttons():
	%BackBtn.pressed.connect(_on_back_pressed)

	# Customer buttons
	%NewCustomerBtn.pressed.connect(_on_new_customer_pressed)
	%RefreshCustomersBtn.pressed.connect(_on_refresh_customers_pressed)

	# Product buttons
	%NewProductBtn.pressed.connect(_on_new_product_pressed)
	%RefreshProductsBtn.pressed.connect(_on_refresh_products_pressed)

	# Supplier buttons
	%NewSupplierBtn.pressed.connect(_on_new_supplier_pressed)
	%RefreshSuppliersBtn.pressed.connect(_on_refresh_suppliers_pressed)

func load_all_data():
	load_customers()
	load_products()
	load_suppliers()

# CUSTOMER MANAGEMENT

func load_customers():
	customers = DataStore.get_all_customers()
	update_customers_list()

func update_customers_list():
	for child in customers_list.get_children():
		child.queue_free()

	for customer in customers:
		var customer_panel = create_customer_panel(customer)
		customers_list.add_child(customer_panel)

func create_customer_panel(customer: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label = Label.new()
	name_label.text = customer.name
	name_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(name_label)

	var full_name_label = Label.new()
	full_name_label.text = customer.full_name
	full_name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(full_name_label)

	if customer.notes != "":
		var notes_label = Label.new()
		notes_label.text = customer.notes
		notes_label.add_theme_font_size_override("font_size", 18)
		vbox.add_child(notes_label)

	# Edit button
	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.custom_minimum_size = Vector2(120, 100)
	edit_btn.add_theme_font_size_override("font_size", 24)
	edit_btn.pressed.connect(func(): edit_customer(customer))
	hbox.add_child(edit_btn)

	# Delete button
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(120, 100)
	delete_btn.add_theme_font_size_override("font_size", 24)
	delete_btn.pressed.connect(func(): delete_customer(customer))
	hbox.add_child(delete_btn)

	return panel

func edit_customer(customer: Dictionary):
	%CustomerEditPopup.populate_customer(customer)
	%CustomerEditPopup.popup_centered()

func delete_customer(customer: Dictionary):
	DataStore.delete_customer(customer.id)
	load_customers()
	show_notification("Customer deleted: %s" % customer.name)

# PRODUCT MANAGEMENT

func load_products():
	products = DataStore.get_all_products()
	update_products_list()

func update_products_list():
	for child in products_list.get_children():
		child.queue_free()

	for product in products:
		var product_panel = create_product_panel(product)
		products_list.add_child(product_panel)

func create_product_panel(product: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label = Label.new()
	name_label.text = product.name
	name_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(name_label)

	var customer = DataStore.get_customer_by_id(product.customer_id)
	var customer_label = Label.new()
	customer_label.text = "Customer: %s" % customer.name
	customer_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(customer_label)

	var details_label = Label.new()
	details_label.text = "Type: %s | Weight: %s | Boxes/Crate: %d" % [
		product.product_type,
		product.target_weight,
		product.boxes_per_crate
	]
	details_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(details_label)

	# Edit button
	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.custom_minimum_size = Vector2(120, 100)
	edit_btn.add_theme_font_size_override("font_size", 24)
	edit_btn.pressed.connect(func(): edit_product(product))
	hbox.add_child(edit_btn)

	# Delete button
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(120, 100)
	delete_btn.add_theme_font_size_override("font_size", 24)
	delete_btn.pressed.connect(func(): delete_product(product))
	hbox.add_child(delete_btn)

	return panel

func edit_product(product: Dictionary):
	%ProductEditPopup.populate_product(product)
	%ProductEditPopup.popup_centered()

func delete_product(product: Dictionary):
	DataStore.delete_product(product.id)
	load_products()
	show_notification("Product deleted: %s" % product.name)

# SUPPLIER MANAGEMENT

func load_suppliers():
	suppliers = DataStore.get_all_suppliers()
	update_suppliers_list()

func update_suppliers_list():
	for child in suppliers_list.get_children():
		child.queue_free()

	for supplier in suppliers:
		var supplier_panel = create_supplier_panel(supplier)
		suppliers_list.add_child(supplier_panel)

func create_supplier_panel(supplier: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label = Label.new()
	name_label.text = supplier.name
	name_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(name_label)

	if supplier.contact != "":
		var contact_label = Label.new()
		contact_label.text = "Contact: %s" % supplier.contact
		contact_label.add_theme_font_size_override("font_size", 20)
		vbox.add_child(contact_label)

	if supplier.notes != "":
		var notes_label = Label.new()
		notes_label.text = supplier.notes
		notes_label.add_theme_font_size_override("font_size", 18)
		vbox.add_child(notes_label)

	# Edit button
	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.custom_minimum_size = Vector2(120, 100)
	edit_btn.add_theme_font_size_override("font_size", 24)
	edit_btn.pressed.connect(func(): edit_supplier(supplier))
	hbox.add_child(edit_btn)

	# Delete button
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(120, 100)
	delete_btn.add_theme_font_size_override("font_size", 24)
	delete_btn.pressed.connect(func(): delete_supplier(supplier))
	hbox.add_child(delete_btn)

	return panel

func edit_supplier(supplier: Dictionary):
	%SupplierEditPopup.populate_supplier(supplier)
	%SupplierEditPopup.popup_centered()

func delete_supplier(supplier: Dictionary):
	DataStore.delete_supplier(supplier.id)
	load_suppliers()
	show_notification("Supplier deleted: %s" % supplier.name)

# BUTTON HANDLERS

func _on_back_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_new_customer_pressed():
	%CustomerEditPopup.clear_form()
	%CustomerEditPopup.popup_centered()

func _on_refresh_customers_pressed():
	load_customers()
	show_notification("Customers refreshed")

func _on_new_product_pressed():
	%ProductEditPopup.clear_form()
	%ProductEditPopup.popup_centered()

func _on_refresh_products_pressed():
	load_products()
	show_notification("Products refreshed")

func _on_new_supplier_pressed():
	%SupplierEditPopup.clear_form()
	%SupplierEditPopup.popup_centered()

func _on_refresh_suppliers_pressed():
	load_suppliers()
	show_notification("Suppliers refreshed")

func show_notification(message: String):
	%NotificationLabel.text = message
	%NotificationLabel.show()
	await get_tree().create_timer(2.0).timeout
	%NotificationLabel.hide()
