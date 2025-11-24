extends Node
# Test Helper Utilities
# Provides common functions for setting up and tearing down tests

const TEST_DATA_FILE = "user://test_production_data.json"

# Clean up test data before each test
static func setup_test_environment():
	# Use a separate test data file
	if FileAccess.file_exists(TEST_DATA_FILE):
		DirAccess.remove_absolute(TEST_DATA_FILE)

	# Reset DataStore to initial state
	DataStore.data = {
		"users": [],
		"orders": [],
		"wrapping_sessions": [],
		"inventory": [],
		"quality_defects": [],
		"rm415_forms": [],
		"current_user": null,
		"defect_reasons": {
			"bad_product": ["Bruised", "Discolored", "Too Small", "Too Large", "Damaged", "Foreign Object"],
			"bad_wrap": ["Torn Film", "Loose Wrap", "Poor Seal", "Wrinkled", "Incorrect Weight", "Missing Label"]
		}
	}

	# Add default admin user for tests
	var admin_password_hash = DataStore.hash_password("test123")
	DataStore.data["users"].append({
		"id": 1,
		"username": "testadmin",
		"password_hash": admin_password_hash,
		"role": "Manager",
		"tasks": ["wrapping", "orders", "admin", "quality_control", "folding"],
		"is_admin": true
	})

# Clean up after tests
static func teardown_test_environment():
	if FileAccess.file_exists(TEST_DATA_FILE):
		DirAccess.remove_absolute(TEST_DATA_FILE)
	DataStore.data["current_user"] = null

# Create a test user with specific permissions
static func create_test_user(username: String, role: String, tasks: Array, is_admin: bool = false) -> Dictionary:
	var password_hash = DataStore.hash_password("password123")
	var user_id = DataStore.data["users"].size() + 1

	var user = {
		"id": user_id,
		"username": username,
		"password_hash": password_hash,
		"role": role,
		"tasks": tasks,
		"is_admin": is_admin
	}

	DataStore.data["users"].append(user)
	return user

# Create a test order
static func create_test_order(product: String = "300g Cups", quantity: String = "160x16") -> Dictionary:
	var order = {
		"id": DataStore.data["orders"].size() + 1,
		"product": product,
		"quantity": quantity,
		"customer": "Test Customer",
		"delivery_date": "2025-11-25",
		"harvest_date": "2025-11-23",
		"supplier": "RM",
		"batch_code": "L4705",
		"status": "pending",
		"created_by": 1,
		"created_at": Time.get_datetime_string_from_system()
	}

	DataStore.data["orders"].append(order)
	return order

# Create a test wrapping session
static func create_test_session(order_id: int = 1, crates_wrapped: int = 0) -> Dictionary:
	var session = {
		"id": DataStore.data["wrapping_sessions"].size() + 1,
		"order_id": order_id,
		"operator_id": 1,
		"crates_wrapped": crates_wrapped,
		"started_at": Time.get_datetime_string_from_system(),
		"ended_at": null,
		"status": "active"
	}

	DataStore.data["wrapping_sessions"].append(session)
	return session

# Create a test defect
static func create_test_defect(defect_type: String = "bad_product", reason: String = "Bruised", quantity: int = 5) -> Dictionary:
	var defect = {
		"id": DataStore.data["quality_defects"].size() + 1,
		"type": defect_type,
		"reason": reason,
		"quantity": quantity,
		"notes": "Test defect",
		"recorded_by": 1,
		"recorded_at": Time.get_datetime_string_from_system()
	}

	DataStore.data["quality_defects"].append(defect)
	return defect

# Assert helpers
static func assert_user_exists(username: String) -> bool:
	for user in DataStore.data["users"]:
		if user["username"] == username:
			return true
	return false

static func assert_order_exists(order_id: int) -> bool:
	for order in DataStore.data["orders"]:
		if order["id"] == order_id:
			return true
	return false

static func assert_order_status(order_id: int, expected_status: String) -> bool:
	for order in DataStore.data["orders"]:
		if order["id"] == order_id:
			return order["status"] == expected_status
	return false

static func assert_defect_count(expected_count: int) -> bool:
	return DataStore.data["quality_defects"].size() == expected_count

# Get helpers
static func get_user_by_username(username: String) -> Dictionary:
	for user in DataStore.data["users"]:
		if user["username"] == username:
			return user
	return {}

static func get_order_by_id(order_id: int) -> Dictionary:
	for order in DataStore.data["orders"]:
		if order["id"] == order_id:
			return order
	return {}

static func get_pending_orders_count() -> int:
	var count = 0
	for order in DataStore.data["orders"]:
		if order["status"] == "pending":
			count += 1
	return count

static func get_completed_orders_count() -> int:
	var count = 0
	for order in DataStore.data["orders"]:
		if order["status"] == "completed":
			count += 1
	return count
