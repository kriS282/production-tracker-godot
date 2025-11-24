extends GutTest
# Unit tests for authentication system

var TestHelpers = preload("res://tests/test_helpers.gd")

func before_each():
	TestHelpers.setup_test_environment()

func after_each():
	TestHelpers.teardown_test_environment()

# Test password hashing
func test_password_hashing():
	var password = "mypassword123"
	var hash1 = DataStore.hash_password(password)
	var hash2 = DataStore.hash_password(password)

	# Same password should produce same hash
	assert_eq(hash1, hash2, "Same password should produce same hash")

	# Hash should not be empty
	assert_ne(hash1, "", "Hash should not be empty")

	# Hash should not equal original password
	assert_ne(hash1, password, "Hash should not equal original password")

# Test successful authentication
func test_authenticate_valid_user():
	var result = DataStore.authenticate_user("testadmin", "test123")

	assert_true(result, "Authentication should succeed with valid credentials")
	assert_not_null(DataStore.get_current_user(), "Current user should be set after login")
	assert_eq(DataStore.get_current_user()["username"], "testadmin", "Current user should be testadmin")

# Test failed authentication - wrong password
func test_authenticate_wrong_password():
	var result = DataStore.authenticate_user("testadmin", "wrongpassword")

	assert_false(result, "Authentication should fail with wrong password")
	assert_null(DataStore.get_current_user(), "Current user should be null after failed login")

# Test failed authentication - non-existent user
func test_authenticate_nonexistent_user():
	var result = DataStore.authenticate_user("nonexistent", "password")

	assert_false(result, "Authentication should fail for non-existent user")
	assert_null(DataStore.get_current_user(), "Current user should be null after failed login")

# Test failed authentication - empty username
func test_authenticate_empty_username():
	var result = DataStore.authenticate_user("", "password")

	assert_false(result, "Authentication should fail with empty username")

# Test failed authentication - empty password
func test_authenticate_empty_password():
	var result = DataStore.authenticate_user("testadmin", "")

	assert_false(result, "Authentication should fail with empty password")

# Test logout
func test_logout():
	# First login
	DataStore.authenticate_user("testadmin", "test123")
	assert_not_null(DataStore.get_current_user(), "User should be logged in")

	# Then logout
	DataStore.logout()
	assert_null(DataStore.get_current_user(), "Current user should be null after logout")

# Test session persistence
func test_session_persistence():
	DataStore.authenticate_user("testadmin", "test123")
	var user_before = DataStore.get_current_user()

	# Save data
	DataStore.save_data()

	# Load data
	DataStore.load_data()

	# User should still be logged in
	var user_after = DataStore.get_current_user()
	assert_not_null(user_after, "User should persist after save/load")
	assert_eq(user_after["username"], user_before["username"], "Username should match after reload")

# Test permission checking
func test_user_has_task():
	DataStore.authenticate_user("testadmin", "test123")

	assert_true(DataStore.user_has_task("wrapping"), "Admin should have wrapping task")
	assert_true(DataStore.user_has_task("orders"), "Admin should have orders task")
	assert_true(DataStore.user_has_task("admin"), "Admin should have admin task")
	assert_false(DataStore.user_has_task("nonexistent"), "Should return false for non-existent task")

# Test permission checking without login
func test_user_has_task_not_logged_in():
	# No user logged in
	assert_false(DataStore.user_has_task("wrapping"), "Should return false when not logged in")

# Test permission checking for user without task
func test_user_without_specific_task():
	# Create user without wrapping task
	TestHelpers.create_test_user("limited", "Picker", ["quality_control"])

	DataStore.authenticate_user("limited", "password123")

	assert_false(DataStore.user_has_task("wrapping"), "Limited user should not have wrapping task")
	assert_true(DataStore.user_has_task("quality_control"), "Limited user should have quality_control task")

# Test is_admin check
func test_is_admin():
	DataStore.authenticate_user("testadmin", "test123")
	var current_user = DataStore.get_current_user()

	assert_true(current_user["is_admin"], "testadmin should be admin")

# Test is_admin for non-admin user
func test_is_not_admin():
	TestHelpers.create_test_user("worker", "General Staff", ["wrapping"], false)

	DataStore.authenticate_user("worker", "password123")
	var current_user = DataStore.get_current_user()

	assert_false(current_user["is_admin"], "worker should not be admin")

# Test multiple login attempts
func test_multiple_login_attempts():
	# First login
	assert_true(DataStore.authenticate_user("testadmin", "test123"), "First login should succeed")

	# Try to login as different user (should replace current user)
	TestHelpers.create_test_user("user2", "General Staff", ["wrapping"])
	assert_true(DataStore.authenticate_user("user2", "password123"), "Second login should succeed")

	var current_user = DataStore.get_current_user()
	assert_eq(current_user["username"], "user2", "Current user should be user2")

# Test case sensitivity in username
func test_username_case_sensitivity():
	# Try login with different case
	var result = DataStore.authenticate_user("TestAdmin", "test123")

	# This should fail (usernames are case-sensitive)
	assert_false(result, "Login should fail with wrong case in username")
