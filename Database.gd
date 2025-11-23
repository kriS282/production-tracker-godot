extends Node

# Singleton for database management
# Access via Database.method_name()

var db: SQLite = null
var db_path = "user://production_tracker.db"

func _ready():
	db = SQLite.new()
	db.path = db_path
	db.open_db()
	create_tables()

func create_tables():
	# Users table
	var users_table = """
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT UNIQUE NOT NULL,
		password_hash TEXT NOT NULL,
		role TEXT NOT NULL,
		tasks TEXT,
		created_at TEXT DEFAULT CURRENT_TIMESTAMP,
		is_admin INTEGER DEFAULT 0
	);
	"""
	db.query(users_table)

	# Orders table
	var orders_table = """
	CREATE TABLE IF NOT EXISTS orders (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		product TEXT NOT NULL,
		quantity TEXT NOT NULL,
		customer TEXT DEFAULT 'Lidl RDC Mullingar',
		delivery_date TEXT NOT NULL,
		harvest_date TEXT,
		supplier TEXT,
		batch_code TEXT,
		status TEXT DEFAULT 'pending',
		created_by INTEGER,
		created_at TEXT DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (created_by) REFERENCES users(id)
	);
	"""
	db.query(orders_table)

	# Wrapping sessions table
	var sessions_table = """
	CREATE TABLE IF NOT EXISTS wrapping_sessions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		order_id INTEGER,
		user_id INTEGER,
		product TEXT NOT NULL,
		supplier TEXT NOT NULL,
		quantity_wrapped TEXT,
		crates_used INTEGER,
		harvest_date TEXT,
		delivery_date TEXT,
		batch_code TEXT,
		start_time TEXT,
		end_time TEXT,
		FOREIGN KEY (order_id) REFERENCES orders(id),
		FOREIGN KEY (user_id) REFERENCES users(id)
	);
	"""
	db.query(sessions_table)

	# Inventory table
	var inventory_table = """
	CREATE TABLE IF NOT EXISTS inventory (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		date TEXT NOT NULL,
		pallets_in INTEGER DEFAULT 0,
		crates_in INTEGER DEFAULT 0,
		leftovers INTEGER DEFAULT 0,
		class2_crates INTEGER DEFAULT 0,
		damaged_punnets INTEGER DEFAULT 0,
		harvest_date TEXT,
		user_id INTEGER,
		FOREIGN KEY (user_id) REFERENCES users(id)
	);
	"""
	db.query(inventory_table)

	# Quality defects table
	var defects_table = """
	CREATE TABLE IF NOT EXISTS quality_defects (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		session_id INTEGER,
		defect_type TEXT NOT NULL,
		defect_reason TEXT NOT NULL,
		quantity INTEGER DEFAULT 1,
		notes TEXT,
		recorded_at TEXT DEFAULT CURRENT_TIMESTAMP,
		user_id INTEGER,
		FOREIGN KEY (session_id) REFERENCES wrapping_sessions(id),
		FOREIGN KEY (user_id) REFERENCES users(id)
	);
	"""
	db.query(defects_table)

	# RM415 forms table
	var rm415_table = """
	CREATE TABLE IF NOT EXISTS rm415_forms (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		session_id INTEGER,
		product TEXT NOT NULL,
		supplier TEXT NOT NULL,
		batch_code TEXT NOT NULL,
		punnet_checks TEXT,
		box_checks TEXT,
		signature_data TEXT,
		generated_at TEXT DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (session_id) REFERENCES wrapping_sessions(id)
	);
	"""
	db.query(rm415_table)

	# Create default admin if no users exist
	create_default_admin()

func create_default_admin():
	var result = db.select_rows("users", "", ["id"])
	if result.is_empty():
		var admin_data = {
			"username": "admin",
			"password_hash": "admin".sha256_text(),  # CHANGE THIS IN PRODUCTION!
			"role": "Manager",
			"tasks": "wrapping,orders,admin",
			"is_admin": 1
		}
		db.insert_row("users", admin_data)
		print("Default admin created: username=admin, password=admin")

# User management
func create_user(username: String, password: String, role: String, tasks: String, is_admin: bool = false) -> bool:
	var user_data = {
		"username": username,
		"password_hash": password.sha256_text(),
		"role": role,
		"tasks": tasks,
		"is_admin": 1 if is_admin else 0
	}
	return db.insert_row("users", user_data)

func authenticate_user(username: String, password: String) -> Dictionary:
	var password_hash = password.sha256_text()
	var condition = "username = '%s' AND password_hash = '%s'" % [username, password_hash]
	var result = db.select_rows("users", condition, ["*"])

	if not result.is_empty():
		return result[0]
	return {}

func get_user_by_id(user_id: int) -> Dictionary:
	var condition = "id = %d" % user_id
	var result = db.select_rows("users", condition, ["*"])
	return result[0] if not result.is_empty() else {}

func get_all_users() -> Array:
	return db.select_rows("users", "", ["*"])

func update_user(user_id: int, data: Dictionary) -> bool:
	var condition = "id = %d" % user_id
	return db.update_rows("users", condition, data)

func delete_user(user_id: int) -> bool:
	return db.delete_rows("users", "id = %d" % user_id)

# Orders management
func create_order(order_data: Dictionary) -> int:
	db.insert_row("orders", order_data)
	# Get the last inserted row id
	var result = db.select_rows("orders", "", ["MAX(id) as id"])
	return result[0]["id"] if not result.is_empty() else -1

func get_pending_orders() -> Array:
	return db.select_rows("orders", "status = 'pending'", ["*"])

func get_all_orders() -> Array:
	return db.select_rows("orders", "", ["*"])

func update_order_status(order_id: int, status: String) -> bool:
	return db.update_rows("orders", "id = %d" % order_id, {"status": status})

# Wrapping sessions
func create_wrapping_session(session_data: Dictionary) -> int:
	db.insert_row("wrapping_sessions", session_data)
	var result = db.select_rows("wrapping_sessions", "", ["MAX(id) as id"])
	return result[0]["id"] if not result.is_empty() else -1

func get_user_sessions(user_id: int) -> Array:
	return db.select_rows("wrapping_sessions", "user_id = %d" % user_id, ["*"])

# Quality defects
func add_defect(defect_data: Dictionary) -> bool:
	return db.insert_row("quality_defects", defect_data)

func get_session_defects(session_id: int) -> Array:
	return db.select_rows("quality_defects", "session_id = %d" % session_id, ["*"])

# Inventory
func add_inventory(inventory_data: Dictionary) -> bool:
	return db.insert_row("inventory", inventory_data)

func get_today_inventory() -> Dictionary:
	var today = Time.get_date_string_from_system()
	var result = db.select_rows("inventory", "date = '%s'" % today, ["*"])
	return result[0] if not result.is_empty() else {}

# RM415 Forms
func save_rm415_form(form_data: Dictionary) -> bool:
	return db.insert_row("rm415_forms", form_data)
