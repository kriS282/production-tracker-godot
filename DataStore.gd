extends Node

# Singleton for data management using JSON files
# Access via DataStore.method_name()

var data_path = "user://production_data.json"
var data = {
	"users": [],
	"customers": [],
	"products": [],
	"suppliers": [],
	"orders": [],
	"wrapping_sessions": [],
	"inventory": [],
	"quality_defects": [],
	"rm415_forms": [],
	"current_user": null,
	"operators": [],  # Manual operators that may not have user accounts yet
	"product_types": [],  # Product classifications with customer assignments
	"defect_reasons": {
		"bad_product": [
			"Bruised",
			"Discolored",
			"Too Small",
			"Too Large",
			"Damaged",
			"Foreign Object"
		],
		"bad_wrap": [
			"Torn Film",
			"Loose Wrap",
			"Poor Seal",
			"Wrinkled",
			"Incorrect Weight",
			"Missing Label"
		]
	},
	"pause_reasons": [
		"Break",
		"Lunch",
		"Bathroom",
		"Equipment Issue",
		"No Stock",
		"Cleaning"
	]
}

func _ready():
	load_data()
	create_default_admin()
	create_default_customers()
	create_default_products()
	create_default_suppliers()
	create_default_product_types()

func load_data():
	if FileAccess.file_exists(data_path):
		var file = FileAccess.open(data_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var loaded_data = json.get_data()
				# Merge loaded data with default structure to add any new keys
				for key in data.keys():
					if loaded_data.has(key):
						data[key] = loaded_data[key]
			file.close()
	save_data()  # Create file if it doesn't exist

func save_data():
	var file = FileAccess.open(data_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data, "\t")
		file.store_string(json_string)
		file.close()

func create_default_admin():
	if data.users.is_empty():
		var admin = {
			"id": 1,
			"username": "admin",
			"password_hash": "admin".sha256_text(),
			"role": "Manager",
			"tasks": ["wrapping", "orders", "admin", "quality_control"],
			"is_admin": true,
			"created_at": Time.get_datetime_string_from_system()
		}
		data.users.append(admin)
		save_data()
		print("✅ Default admin created: username='admin', password='admin'")

# User management
func create_user(username: String, password: String, role: String, tasks: Array, is_admin: bool = false) -> Dictionary:
	var user_id = data.users.size() + 1
	var user = {
		"id": user_id,
		"username": username,
		"password_hash": password.sha256_text(),
		"role": role,
		"tasks": tasks,
		"is_admin": is_admin,
		"created_at": Time.get_datetime_string_from_system()
	}
	data.users.append(user)
	save_data()
	return user

func authenticate_user(username: String, password: String) -> Dictionary:
	var password_hash = password.sha256_text()
	for user in data.users:
		if user.username == username and user.password_hash == password_hash:
			data.current_user = user
			save_data()
			return user
	return {}

func get_current_user() -> Dictionary:
	return data.current_user if data.current_user else {}

func logout():
	data.current_user = null
	save_data()

func get_all_users() -> Array:
	return data.users

func update_user(user_id: int, updates: Dictionary) -> bool:
	for i in range(data.users.size()):
		if data.users[i].id == user_id:
			for key in updates:
				data.users[i][key] = updates[key]
			save_data()
			return true
	return false

func delete_user(user_id: int) -> bool:
	for i in range(data.users.size()):
		if data.users[i].id == user_id:
			data.users.remove_at(i)
			save_data()
			return true
	return false

func user_has_task(task: String) -> bool:
	var user = get_current_user()
	if user.is_empty():
		return false
	return task in user.tasks

# Orders management
func create_order(order_data: Dictionary) -> int:
	var order_id = data.orders.size() + 1
	order_data["id"] = order_id
	order_data["created_at"] = Time.get_datetime_string_from_system()
	if not order_data.has("status"):
		order_data["status"] = "pending"
	data.orders.append(order_data)
	save_data()
	return order_id

func get_pending_orders() -> Array:
	var pending = []
	for order in data.orders:
		if order.status == "pending":
			pending.append(order)
	return pending

func get_all_orders() -> Array:
	return data.orders

func get_order_by_id(order_id: int) -> Dictionary:
	for order in data.orders:
		if order.id == order_id:
			return order
	return {}

func update_order_status(order_id: int, status: String) -> bool:
	for i in range(data.orders.size()):
		if data.orders[i].id == order_id:
			data.orders[i].status = status
			save_data()
			return true
	return false

# Wrapping sessions
func create_wrapping_session(session_data: Dictionary) -> int:
	var session_id = data.wrapping_sessions.size() + 1
	session_data["id"] = session_id
	session_data["start_time"] = Time.get_datetime_string_from_system()
	data.wrapping_sessions.append(session_data)
	save_data()
	return session_id

func end_wrapping_session(session_id: int, crates_used: int):
	for i in range(data.wrapping_sessions.size()):
		if data.wrapping_sessions[i].id == session_id:
			data.wrapping_sessions[i].end_time = Time.get_datetime_string_from_system()
			data.wrapping_sessions[i].crates_used = crates_used
			save_data()
			return

func get_user_sessions(user_id: int) -> Array:
	var sessions = []
	for session in data.wrapping_sessions:
		if session.user_id == user_id:
			sessions.append(session)
	return sessions

# Quality defects
func add_defect(defect_data: Dictionary) -> bool:
	var defect_id = data.quality_defects.size() + 1
	defect_data["id"] = defect_id
	defect_data["recorded_at"] = Time.get_datetime_string_from_system()
	data.quality_defects.append(defect_data)
	save_data()
	return true

func get_session_defects(session_id: int) -> Array:
	var defects = []
	for defect in data.quality_defects:
		if defect.session_id == session_id:
			defects.append(defect)
	return defects

func add_defect_reason(defect_type: String, reason: String):
	if not data.defect_reasons.has(defect_type):
		data.defect_reasons[defect_type] = []
	if not reason in data.defect_reasons[defect_type]:
		data.defect_reasons[defect_type].append(reason)
		save_data()

func get_defect_reasons(defect_type: String) -> Array:
	return data.defect_reasons.get(defect_type, [])

# Inventory
func add_inventory(inventory_data: Dictionary) -> bool:
	var inv_id = data.inventory.size() + 1
	inventory_data["id"] = inv_id
	inventory_data["date"] = Time.get_date_string_from_system()
	data.inventory.append(inventory_data)
	save_data()
	return true

func get_today_inventory() -> Dictionary:
	var today = Time.get_date_string_from_system()
	for inv in data.inventory:
		if inv.date == today:
			return inv
	return {}

# RM415 Forms
func save_rm415_form(form_data: Dictionary) -> bool:
	var form_id = data.rm415_forms.size() + 1
	form_data["id"] = form_id
	form_data["generated_at"] = Time.get_datetime_string_from_system()
	data.rm415_forms.append(form_data)
	save_data()
	return true

# Customers
func create_default_customers():
	if not data.customers.is_empty():
		return

	var default_customers = [
		{
			"id": 1,
			"name": "Lidl",
			"full_name": "Lidl RDC Mullingar",
			"contact": "",
			"notes": "Lidl stores delivery"
		},
		{
			"id": 2,
			"name": "Dublin",
			"full_name": "Dublin Orders",
			"contact": "",
			"notes": "Dublin area deliveries"
		},
		{
			"id": 3,
			"name": "Production",
			"full_name": "Production/Internal",
			"contact": "",
			"notes": "Internal production orders"
		}
	]

	data.customers = default_customers
	save_data()

func create_customer(customer_name: String, full_name: String, contact: String = "", notes: String = "") -> int:
	var customer_id = data.customers.size() + 1
	var customer = {
		"id": customer_id,
		"name": customer_name,
		"full_name": full_name,
		"contact": contact,
		"notes": notes
	}
	data.customers.append(customer)
	save_data()
	return customer_id

func get_all_customers() -> Array:
	return data.customers

func get_customer_by_id(customer_id: int) -> Dictionary:
	for customer in data.customers:
		if customer.id == customer_id:
			return customer
	return {}

func update_customer(customer_id: int, updates: Dictionary) -> bool:
	for i in range(data.customers.size()):
		if data.customers[i].id == customer_id:
			for key in updates:
				data.customers[i][key] = updates[key]
			save_data()
			return true
	return false

func delete_customer(customer_id: int) -> bool:
	for i in range(data.customers.size()):
		if data.customers[i].id == customer_id:
			data.customers.remove_at(i)
			save_data()
			return true
	return false

# Products
func create_default_products():
	if not data.products.is_empty():
		return

	var default_products = [
		# Lidl products
		{
			"id": 1,
			"name": "433g Cups",
			"customer_id": 1,
			"product_type": "cups",
			"target_weight": "433g",
			"punnet": "Standard punnet",
			"packaging_type": "crates",
			"punnets_per_crate": 12,
			"punnets_per_box": 1,
			"barcode": "2078 1675",
			"pn": "",
			"product_classification": "Lidl"
		},
		{
			"id": 2,
			"name": "300g Cups",
			"customer_id": 1,
			"product_type": "cups",
			"target_weight": "300g",
			"punnet": "Standard punnet",
			"packaging_type": "crates",
			"punnets_per_crate": 16,
			"punnets_per_box": 1,
			"barcode": "2054 0586",
			"pn": "",
			"product_classification": "Lidl"
		},
		{
			"id": 3,
			"name": "150g Buttons",
			"customer_id": 1,
			"product_type": "buttons",
			"target_weight": "150g",
			"punnet": "Standard punnet",
			"packaging_type": "crates",
			"punnets_per_crate": 16,
			"punnets_per_box": 1,
			"barcode": "2064 9562",
			"pn": "",
			"product_classification": "Lidl"
		},
		{
			"id": 4,
			"name": "250g Flats",
			"customer_id": 1,
			"product_type": "flats",
			"target_weight": "250g",
			"punnet": "Standard punnet",
			"packaging_type": "crates",
			"punnets_per_crate": 6,
			"punnets_per_box": 1,
			"barcode": "2016 6632",
			"pn": "",
			"product_classification": "Lidl"
		},
		{
			"id": 5,
			"name": "150g Sliced",
			"customer_id": 1,
			"product_type": "sliced",
			"target_weight": "150g",
			"punnet": "Standard punnet",
			"packaging_type": "crates",
			"punnets_per_crate": 8,
			"punnets_per_box": 1,
			"barcode": "4056 4890",
			"pn": "",
			"product_classification": "Lidl"
		},
		{
			"id": 6,
			"name": "250g Chestnut",
			"customer_id": 1,
			"product_type": "chestnut",
			"target_weight": "250g",
			"punnet": "Standard punnet",
			"packaging_type": "crates",
			"punnets_per_crate": 6,
			"punnets_per_box": 1,
			"barcode": "2016 6625",
			"pn": "",
			"product_classification": "Lidl"
		},
		{
			"id": 7,
			"name": "150g Wild Mix",
			"customer_id": 1,
			"product_type": "wild_mix",
			"target_weight": "150g",
			"punnet": "Standard punnet",
			"packaging_type": "crates",
			"punnets_per_crate": 16,
			"punnets_per_box": 1,
			"barcode": "2008 9283",
			"pn": "",
			"product_classification": "Lidl"
		},
		# Dublin products - chips (stacked trays)
		{
			"id": 8,
			"name": "2.27kg/5lb Cups",
			"customer_id": 2,
			"product_type": "cups",
			"target_weight": "2.27kg",
			"punnet": "5lb chip tray",
			"packaging_type": "chips",
			"punnets_per_crate": 8,
			"punnets_per_box": 1,
			"barcode": "",
			"pn": "",
			"product_classification": "Dublin"
		},
		{
			"id": 9,
			"name": "1.8kg/4lb Flats",
			"customer_id": 2,
			"product_type": "flats",
			"target_weight": "1.8kg",
			"punnet": "4lb chip tray",
			"packaging_type": "chips",
			"punnets_per_crate": 8,
			"punnets_per_box": 1,
			"barcode": "",
			"pn": "",
			"product_classification": "Dublin"
		}
	]

	data.products = default_products
	save_data()

func create_product(product_data: Dictionary) -> int:
	var product_id = data.products.size() + 1
	product_data["id"] = product_id
	data.products.append(product_data)
	save_data()
	return product_id

func get_all_products() -> Array:
	return data.products

func get_products_by_customer(customer_id: int) -> Array:
	var products = []
	for product in data.products:
		if product.customer_id == customer_id:
			products.append(product)
	return products

func get_product_by_id(product_id: int) -> Dictionary:
	for product in data.products:
		if product.id == product_id:
			return product
	return {}

func update_product(product_id: int, updates: Dictionary) -> bool:
	for i in range(data.products.size()):
		if data.products[i].id == product_id:
			for key in updates:
				data.products[i][key] = updates[key]
			save_data()
			return true
	return false

func delete_product(product_id: int) -> bool:
	for i in range(data.products.size()):
		if data.products[i].id == product_id:
			data.products.remove_at(i)
			save_data()
			return true
	return false

# Suppliers
func create_default_suppliers():
	if not data.suppliers.is_empty():
		return

	var default_suppliers = [
		{"id": 1, "name": "RM", "contact": "", "pn": "", "notes": ""},
		{"id": 2, "name": "McKenna", "contact": "", "pn": "1381", "notes": ""},
		{"id": 3, "name": "Reilly Mushrooms", "contact": "", "pn": "509", "notes": ""}
	]

	data.suppliers = default_suppliers
	save_data()

func create_supplier(supplier_name: String, contact: String = "", pn: String = "", notes: String = "") -> int:
	var supplier_id = data.suppliers.size() + 1
	var supplier = {
		"id": supplier_id,
		"name": supplier_name,
		"contact": contact,
		"pn": pn,
		"notes": notes
	}
	data.suppliers.append(supplier)
	save_data()
	return supplier_id

func get_all_suppliers() -> Array:
	return data.suppliers

func get_supplier_by_id(supplier_id: int) -> Dictionary:
	for supplier in data.suppliers:
		if supplier.id == supplier_id:
			return supplier
	return {}

func update_supplier(supplier_id: int, updates: Dictionary) -> bool:
	for i in range(data.suppliers.size()):
		if data.suppliers[i].id == supplier_id:
			for key in updates:
				data.suppliers[i][key] = updates[key]
			save_data()
			return true
	return false

func delete_supplier(supplier_id: int) -> bool:
	for i in range(data.suppliers.size()):
		if data.suppliers[i].id == supplier_id:
			data.suppliers.remove_at(i)
			save_data()
			return true
	return false

# Operators (manual, not linked to users)
func create_operator(operator_name: String) -> int:
	var operator_id = data.operators.size() + 1
	var operator = {
		"id": operator_id,
		"name": operator_name,
		"linked_user_id": null,  # Can be connected to a user account later
		"created_at": Time.get_datetime_string_from_system()
	}
	data.operators.append(operator)
	save_data()
	return operator_id

func get_all_operators() -> Array:
	return data.operators

func get_operator_by_id(operator_id: int) -> Dictionary:
	for operator in data.operators:
		if operator.id == operator_id:
			return operator
	return {}

func link_operator_to_user(operator_id: int, user_id: int) -> bool:
	for i in range(data.operators.size()):
		if data.operators[i].id == operator_id:
			data.operators[i].linked_user_id = user_id
			save_data()
			return true
	return false

func unlink_operator_from_user(operator_id: int) -> bool:
	for i in range(data.operators.size()):
		if data.operators[i].id == operator_id:
			data.operators[i].linked_user_id = null
			save_data()
			return true
	return false

func delete_operator(operator_id: int) -> bool:
	for i in range(data.operators.size()):
		if data.operators[i].id == operator_id:
			data.operators.remove_at(i)
			save_data()
			return true
	return false

# Product Types
func create_default_product_types():
	if not data.product_types.is_empty():
		return

	var default_types = [
		{
			"id": 1,
			"name": "Lidl Product",
			"customer_ids": [1]  # Lidl
		},
		{
			"id": 2,
			"name": "Dublin Product",
			"customer_ids": [2]  # Dublin
		},
		{
			"id": 3,
			"name": "Other Product",
			"customer_ids": [3]  # Production
		}
	]

	data.product_types = default_types
	save_data()

func create_product_type(type_name: String, customer_ids: Array) -> int:
	var type_id = data.product_types.size() + 1
	var product_type = {
		"id": type_id,
		"name": type_name,
		"customer_ids": customer_ids
	}
	data.product_types.append(product_type)
	save_data()
	return type_id

func get_all_product_types() -> Array:
	return data.product_types

func update_product_type(type_id: int, updates: Dictionary) -> bool:
	for i in range(data.product_types.size()):
		if data.product_types[i].id == type_id:
			for key in updates:
				data.product_types[i][key] = updates[key]
			save_data()
			return true
	return false

func delete_product_type(type_id: int) -> bool:
	for i in range(data.product_types.size()):
		if data.product_types[i].id == type_id:
			data.product_types.remove_at(i)
			save_data()
			return true
	return false

# Pause Reasons
func add_pause_reason(reason: String):
	if not reason in data.pause_reasons:
		data.pause_reasons.append(reason)
		save_data()

func get_pause_reasons() -> Array:
	return data.pause_reasons

func remove_pause_reason(reason: String):
	data.pause_reasons.erase(reason)
	save_data()
