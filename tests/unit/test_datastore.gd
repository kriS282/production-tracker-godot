extends GutTest
# Unit tests for DataStore core functionality

var TestHelpers = preload("res://tests/test_helpers.gd")

func before_each():
	TestHelpers.setup_test_environment()

func after_each():
	TestHelpers.teardown_test_environment()

# ========== USER MANAGEMENT TESTS ==========

func test_create_user():
	var user_data = {
		"username": "newuser",
		"password": "password123",
		"role": "General Staff",
		"tasks": ["wrapping"],
		"is_admin": false
	}

	var user_id = DataStore.create_user(user_data)

	assert_gt(user_id, 0, "User ID should be positive")
	assert_true(TestHelpers.assert_user_exists("newuser"), "User should exist after creation")

func test_create_user_duplicate_username():
	var user_data = {
		"username": "testadmin",
		"password": "password123",
		"role": "General Staff",
		"tasks": ["wrapping"],
		"is_admin": false
	}

	var user_id = DataStore.create_user(user_data)

	assert_eq(user_id, -1, "Should return -1 for duplicate username")

func test_create_user_empty_username():
	var user_data = {
		"username": "",
		"password": "password123",
		"role": "General Staff",
		"tasks": ["wrapping"],
		"is_admin": false
	}

	var user_id = DataStore.create_user(user_data)

	assert_eq(user_id, -1, "Should return -1 for empty username")

func test_create_user_empty_password():
	var user_data = {
		"username": "newuser",
		"password": "",
		"role": "General Staff",
		"tasks": ["wrapping"],
		"is_admin": false
	}

	var user_id = DataStore.create_user(user_data)

	assert_eq(user_id, -1, "Should return -1 for empty password")

func test_update_user():
	var user = TestHelpers.create_test_user("user1", "General Staff", ["wrapping"])

	var updated_data = {
		"username": "user1_updated",
		"role": "Packing Supervisor",
		"tasks": ["wrapping", "quality_control"]
	}

	var result = DataStore.update_user(user["id"], updated_data)

	assert_true(result, "Update should succeed")
	var updated_user = TestHelpers.get_user_by_username("user1_updated")
	assert_eq(updated_user["role"], "Packing Supervisor", "Role should be updated")
	assert_has(updated_user["tasks"], "quality_control", "Tasks should be updated")

func test_update_user_nonexistent():
	var updated_data = {
		"username": "updated",
		"role": "Manager"
	}

	var result = DataStore.update_user(999, updated_data)

	assert_false(result, "Update should fail for non-existent user")

func test_delete_user():
	var user = TestHelpers.create_test_user("user_to_delete", "General Staff", ["wrapping"])

	var result = DataStore.delete_user(user["id"])

	assert_true(result, "Delete should succeed")
	assert_false(TestHelpers.assert_user_exists("user_to_delete"), "User should not exist after deletion")

func test_delete_user_nonexistent():
	var result = DataStore.delete_user(999)

	assert_false(result, "Delete should fail for non-existent user")

func test_get_all_users():
	TestHelpers.create_test_user("user1", "General Staff", ["wrapping"])
	TestHelpers.create_test_user("user2", "Manager", ["wrapping", "orders"])

	var users = DataStore.get_all_users()

	# Should have testadmin + 2 new users = 3 total
	assert_eq(users.size(), 3, "Should return all users")

# ========== DATA PERSISTENCE TESTS ==========

func test_save_and_load_data():
	# Create some test data
	TestHelpers.create_test_user("user1", "General Staff", ["wrapping"])
	TestHelpers.create_test_order("300g Cups", "160x16")

	# Save data
	DataStore.save_data()

	# Clear in-memory data
	DataStore.data["users"] = []
	DataStore.data["orders"] = []

	# Load data
	DataStore.load_data()

	# Verify data persisted
	assert_true(TestHelpers.assert_user_exists("user1"), "User should persist")
	assert_eq(DataStore.data["orders"].size(), 1, "Orders should persist")

func test_data_structure_integrity():
	# Ensure all required keys exist
	assert_has(DataStore.data, "users", "Should have users key")
	assert_has(DataStore.data, "orders", "Should have orders key")
	assert_has(DataStore.data, "wrapping_sessions", "Should have wrapping_sessions key")
	assert_has(DataStore.data, "inventory", "Should have inventory key")
	assert_has(DataStore.data, "quality_defects", "Should have quality_defects key")
	assert_has(DataStore.data, "rm415_forms", "Should have rm415_forms key")
	assert_has(DataStore.data, "current_user", "Should have current_user key")
	assert_has(DataStore.data, "defect_reasons", "Should have defect_reasons key")

# ========== PRODUCT CONFIGURATION TESTS ==========

func test_products_exist():
	assert_gt(DataStore.PRODUCTS.size(), 0, "Should have products configured")

func test_product_structure():
	# Check that 300g Cups exists and has correct structure
	assert_has(DataStore.PRODUCTS, "300g Cups", "Should have 300g Cups")

	var product = DataStore.PRODUCTS["300g Cups"]
	assert_has(product, "boxes_per_crate", "Product should have boxes_per_crate")
	assert_has(product, "weight", "Product should have weight")

func test_suppliers_exist():
	assert_gt(DataStore.SUPPLIERS.size(), 0, "Should have suppliers configured")
	assert_has(DataStore.SUPPLIERS, "RM", "Should have RM supplier")

# ========== BATCH CODE GENERATION TESTS ==========

func test_generate_batch_code():
	# Test with a specific date
	var test_date = "2025-11-24"  # Week 47, day 0 (Sunday)

	var batch_code = DataStore.generate_batch_code(test_date)

	# Format should be LWWdd (e.g., L4700)
	assert_string_starts_with(batch_code, "L", "Batch code should start with L")
	assert_eq(batch_code.length(), 5, "Batch code should be 5 characters")

func test_generate_batch_code_current_date():
	var batch_code = DataStore.generate_batch_code()

	assert_string_starts_with(batch_code, "L", "Batch code should start with L")
	assert_eq(batch_code.length(), 5, "Batch code should be 5 characters")

# ========== HELPER METHOD TESTS ==========

func test_get_user_by_id():
	var user = TestHelpers.create_test_user("findme", "General Staff", ["wrapping"])

	var found_user = DataStore.get_user_by_id(user["id"])

	assert_not_null(found_user, "Should find user by ID")
	assert_eq(found_user["username"], "findme", "Should return correct user")

func test_get_user_by_id_nonexistent():
	var found_user = DataStore.get_user_by_id(999)

	assert_null(found_user, "Should return null for non-existent ID")

func test_get_user_by_username():
	TestHelpers.create_test_user("findme", "General Staff", ["wrapping"])

	var found_user = DataStore.get_user_by_username("findme")

	assert_not_null(found_user, "Should find user by username")
	assert_eq(found_user["username"], "findme", "Should return correct user")

func test_get_user_by_username_nonexistent():
	var found_user = DataStore.get_user_by_username("nonexistent")

	assert_null(found_user, "Should return null for non-existent username")

# ========== DEFECT REASON TESTS ==========

func test_default_defect_reasons_exist():
	assert_has(DataStore.data["defect_reasons"], "bad_product", "Should have bad_product reasons")
	assert_has(DataStore.data["defect_reasons"], "bad_wrap", "Should have bad_wrap reasons")

	assert_gt(DataStore.data["defect_reasons"]["bad_product"].size(), 0, "Should have default bad_product reasons")
	assert_gt(DataStore.data["defect_reasons"]["bad_wrap"].size(), 0, "Should have default bad_wrap reasons")

func test_add_custom_defect_reason():
	var initial_count = DataStore.data["defect_reasons"]["bad_product"].size()

	DataStore.add_defect_reason("bad_product", "Custom Reason")

	assert_eq(DataStore.data["defect_reasons"]["bad_product"].size(), initial_count + 1, "Should add custom reason")
	assert_has(DataStore.data["defect_reasons"]["bad_product"], "Custom Reason", "Should contain custom reason")

func test_add_duplicate_defect_reason():
	var initial_count = DataStore.data["defect_reasons"]["bad_product"].size()

	# Add same reason twice
	DataStore.add_defect_reason("bad_product", "Bruised")
	DataStore.add_defect_reason("bad_product", "Bruised")

	# Should not add duplicates
	assert_eq(DataStore.data["defect_reasons"]["bad_product"].size(), initial_count, "Should not add duplicate reason")

# ========== VALIDATION TESTS ==========

func test_validate_email_format():
	# If DataStore has email validation
	if DataStore.has_method("validate_email"):
		assert_true(DataStore.validate_email("test@example.com"), "Valid email should pass")
		assert_false(DataStore.validate_email("invalid-email"), "Invalid email should fail")

func test_validate_date_format():
	# If DataStore has date validation
	if DataStore.has_method("validate_date"):
		assert_true(DataStore.validate_date("2025-11-24"), "Valid date should pass")
		assert_false(DataStore.validate_date("2025/11/24"), "Invalid date format should fail")
		assert_false(DataStore.validate_date("not-a-date"), "Invalid date should fail")
