extends Node

# Singleton for data management using JSON files
# Access via DataStore.method_name()

var data_path = "user://production_data.json"
var data = {
	"users": [],
	"orders": [],
	"wrapping_sessions": [],
	"inventory": [],
	"quality_defects": [],
	"rm415_forms": [],
	"current_user": null,
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
	}
}

func _ready():
	load_data()
	create_default_admin()

func load_data():
	if FileAccess.file_exists(data_path):
		var file = FileAccess.open(data_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				data = json.get_data()
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
