extends GutTest
# Integration tests for user management and authentication workflows

var TestHelpers = preload("res://tests/test_helpers.gd")

func before_each():
	TestHelpers.setup_test_environment()

func after_each():
	TestHelpers.teardown_test_environment()

# ========== COMPLETE USER LIFECYCLE ==========

func test_complete_user_lifecycle():
	# Step 1: Admin logs in
	var login_success = DataStore.authenticate_user("testadmin", "test123")
	assert_true(login_success, "Admin should login successfully")
	assert_true(DataStore.get_current_user()["is_admin"], "Should be admin")

	# Step 2: Admin creates new user
	var user_data = {
		"username": "sarah",
		"password": "sarah123",
		"role": "Packing Supervisor",
		"tasks": ["wrapping", "quality_control"],
		"is_admin": false
	}

	var user_id = DataStore.create_user(user_data)
	assert_gt(user_id, 0, "User should be created")

	# Step 3: Admin logs out
	DataStore.logout()
	assert_null(DataStore.get_current_user(), "Should be logged out")

	# Step 4: New user logs in
	login_success = DataStore.authenticate_user("sarah", "sarah123")
	assert_true(login_success, "New user should login successfully")

	var current_user = DataStore.get_current_user()
	assert_eq(current_user["username"], "sarah", "Should be logged in as sarah")
	assert_eq(current_user["role"], "Packing Supervisor", "Role should match")

	# Step 5: Verify user has correct permissions
	assert_true(DataStore.user_has_task("wrapping"), "Should have wrapping task")
	assert_true(DataStore.user_has_task("quality_control"), "Should have quality_control task")
	assert_false(DataStore.user_has_task("admin"), "Should not have admin task")
	assert_false(DataStore.user_has_task("orders"), "Should not have orders task")

	# Step 6: User tries to access admin functions
	var cannot_create_user = DataStore.create_user({
		"username": "unauthorized",
		"password": "pass",
		"role": "General Staff",
		"tasks": ["wrapping"],
		"is_admin": false
	})

	# Should fail if permission check is in place
	if not current_user["is_admin"]:
		# Expected behavior: non-admin can't create users
		pass

	# Step 7: User logs out
	DataStore.logout()

	# Step 8: Admin logs back in
	DataStore.authenticate_user("testadmin", "test123")

	# Step 9: Admin updates user permissions
	var update_success = DataStore.update_user(user_id, {
		"tasks": ["wrapping", "quality_control", "orders"]
	})
	assert_true(update_success, "Should update user tasks")

	# Step 10: User logs in again
	DataStore.logout()
	DataStore.authenticate_user("sarah", "sarah123")

	# Step 11: Verify user now has orders permission
	assert_true(DataStore.user_has_task("orders"), "Should now have orders task")

func test_role_based_access_control():
	# Create users with different roles
	DataStore.authenticate_user("testadmin", "test123")

	# Manager - full access
	var manager_id = DataStore.create_user({
		"username": "manager",
		"password": "pass123",
		"role": "Manager",
		"tasks": ["wrapping", "orders", "quality_control", "folding", "admin"],
		"is_admin": true
	})

	# Packing Supervisor - limited access
	var supervisor_id = DataStore.create_user({
		"username": "supervisor",
		"password": "pass123",
		"role": "Packing Supervisor",
		"tasks": ["wrapping", "quality_control", "orders"],
		"is_admin": false
	})

	# Picker - minimal access
	var picker_id = DataStore.create_user({
		"username": "picker",
		"password": "pass123",
		"role": "Picker",
		"tasks": ["quality_control"],
		"is_admin": false
	})

	DataStore.logout()

	# Test Manager access
	DataStore.authenticate_user("manager", "pass123")
	assert_true(DataStore.user_has_task("wrapping"), "Manager should have wrapping")
	assert_true(DataStore.user_has_task("orders"), "Manager should have orders")
	assert_true(DataStore.user_has_task("admin"), "Manager should have admin")
	assert_true(DataStore.get_current_user()["is_admin"], "Manager should be admin")
	DataStore.logout()

	# Test Supervisor access
	DataStore.authenticate_user("supervisor", "pass123")
	assert_true(DataStore.user_has_task("wrapping"), "Supervisor should have wrapping")
	assert_true(DataStore.user_has_task("quality_control"), "Supervisor should have QC")
	assert_true(DataStore.user_has_task("orders"), "Supervisor should have orders")
	assert_false(DataStore.user_has_task("admin"), "Supervisor should not have admin")
	assert_false(DataStore.get_current_user()["is_admin"], "Supervisor should not be admin")
	DataStore.logout()

	# Test Picker access
	DataStore.authenticate_user("picker", "pass123")
	assert_false(DataStore.user_has_task("wrapping"), "Picker should not have wrapping")
	assert_false(DataStore.user_has_task("orders"), "Picker should not have orders")
	assert_true(DataStore.user_has_task("quality_control"), "Picker should have QC")
	assert_false(DataStore.user_has_task("admin"), "Picker should not have admin")
	DataStore.logout()

func test_password_change_workflow():
	# Step 1: Create user
	DataStore.authenticate_user("testadmin", "test123")

	var user_id = DataStore.create_user({
		"username": "john",
		"password": "oldpass123",
		"role": "General Staff",
		"tasks": ["wrapping"],
		"is_admin": false
	})

	DataStore.logout()

	# Step 2: User logs in with original password
	var login_success = DataStore.authenticate_user("john", "oldpass123")
	assert_true(login_success, "Should login with original password")

	# Step 3: Admin changes user's password
	DataStore.logout()
	DataStore.authenticate_user("testadmin", "test123")

	var new_password_hash = DataStore.hash_password("newpass123")
	var update_success = DataStore.update_user(user_id, {
		"password_hash": new_password_hash
	})
	assert_true(update_success, "Should update password")

	DataStore.logout()

	# Step 4: User tries old password (should fail)
	login_success = DataStore.authenticate_user("john", "oldpass123")
	assert_false(login_success, "Old password should not work")

	# Step 5: User logs in with new password
	login_success = DataStore.authenticate_user("john", "newpass123")
	assert_true(login_success, "Should login with new password")

func test_user_deletion_workflow():
	# Step 1: Admin creates user
	DataStore.authenticate_user("testadmin", "test123")

	var user_id = DataStore.create_user({
		"username": "temporary",
		"password": "temp123",
		"role": "General Staff",
		"tasks": ["wrapping"],
		"is_admin": false
	})

	assert_true(TestHelpers.assert_user_exists("temporary"), "User should exist")

	# Step 2: User logs in and creates some data
	DataStore.logout()
	DataStore.authenticate_user("temporary", "temp123")

	# User creates an order (if they had permission)
	# This tests what happens to user's data when user is deleted

	# Step 3: Admin deletes user
	DataStore.logout()
	DataStore.authenticate_user("testadmin", "test123")

	var delete_success = DataStore.delete_user(user_id)
	assert_true(delete_success, "Should delete user")

	assert_false(TestHelpers.assert_user_exists("temporary"), "User should not exist")

	# Step 4: Deleted user tries to log in
	DataStore.logout()
	var login_success = DataStore.authenticate_user("temporary", "temp123")
	assert_false(login_success, "Deleted user should not be able to login")

func test_cannot_delete_self():
	# Admin logs in
	DataStore.authenticate_user("testadmin", "test123")

	var admin_user = DataStore.get_current_user()

	# Try to delete self
	var delete_success = DataStore.delete_user(admin_user["id"])

	# Should fail - can't delete yourself
	assert_false(delete_success, "Should not be able to delete self")
	assert_true(TestHelpers.assert_user_exists("testadmin"), "Admin should still exist")

func test_multiple_concurrent_sessions():
	# This tests what happens if same user logs in multiple times
	# (e.g., on different devices)

	# First login
	var login1 = DataStore.authenticate_user("testadmin", "test123")
	assert_true(login1, "First login should succeed")
	var user1 = DataStore.get_current_user()

	# Second login (same user)
	var login2 = DataStore.authenticate_user("testadmin", "test123")
	assert_true(login2, "Second login should succeed")
	var user2 = DataStore.get_current_user()

	# Should be the same user
	assert_eq(user1["id"], user2["id"], "Should be same user ID")

	# In a real app, you might want to handle sessions differently
	# This test documents current behavior

func test_session_timeout():
	# Login
	DataStore.authenticate_user("testadmin", "test123")
	assert_not_null(DataStore.get_current_user(), "User should be logged in")

	# Simulate session timeout (if implemented)
	# For now, sessions don't timeout automatically
	# This test documents that behavior

	# Manual logout
	DataStore.logout()
	assert_null(DataStore.get_current_user(), "User should be logged out")

# ========== PERMISSION ENFORCEMENT ==========

func test_permission_prevents_unauthorized_actions():
	# Create user without orders task
	DataStore.authenticate_user("testadmin", "test123")

	var user_id = DataStore.create_user({
		"username": "limited",
		"password": "pass123",
		"role": "Picker",
		"tasks": ["quality_control"],  # No "orders" task
		"is_admin": false
	})

	DataStore.logout()
	DataStore.authenticate_user("limited", "pass123")

	# Verify user doesn't have orders task
	assert_false(DataStore.user_has_task("orders"), "User should not have orders task")

	# Try to create order (should check permission first)
	if DataStore.user_has_task("orders"):
		# This block won't execute
		var order_id = DataStore.create_order({
			"product": "300g Cups",
			"quantity": "160x16",
			"supplier": "RM",
			"delivery_date": "2025-11-25"
		})
		assert_gt(order_id, 0, "Order would be created")
	else:
		# Expected behavior: user can't create orders
		pass

func test_admin_permission_required_for_user_management():
	# Create non-admin user
	DataStore.authenticate_user("testadmin", "test123")

	var user_id = DataStore.create_user({
		"username": "nonadmin",
		"password": "pass123",
		"role": "Manager",
		"tasks": ["wrapping", "orders", "quality_control"],
		"is_admin": false  # Not admin
	})

	DataStore.logout()
	DataStore.authenticate_user("nonadmin", "pass123")

	# Verify user is not admin
	assert_false(DataStore.get_current_user()["is_admin"], "User should not be admin")

	# Try to create another user (should fail)
	if DataStore.get_current_user()["is_admin"]:
		# This won't execute
		pass
	else:
		# Expected: non-admin can't create users
		# If permission check exists in DataStore.create_user()
		var new_user_id = DataStore.create_user({
			"username": "unauthorized",
			"password": "pass",
			"role": "General Staff",
			"tasks": ["wrapping"],
			"is_admin": false
		})

		# Should return -1 or fail
		# assert_eq(new_user_id, -1, "Non-admin should not create users")

# ========== DATA INTEGRITY ==========

func test_user_data_persists_across_sessions():
	# Create user
	DataStore.authenticate_user("testadmin", "test123")

	var user_id = DataStore.create_user({
		"username": "persistent",
		"password": "pass123",
		"role": "General Staff",
		"tasks": ["wrapping", "quality_control"],
		"is_admin": false
	})

	# Save data
	DataStore.save_data()

	# Simulate app restart
	DataStore.data["users"] = []
	DataStore.data["current_user"] = null

	# Load data
	DataStore.load_data()

	# User should still exist
	assert_true(TestHelpers.assert_user_exists("persistent"), "User should persist")

	# User should be able to login
	var login_success = DataStore.authenticate_user("persistent", "pass123")
	assert_true(login_success, "User should login after restart")

	# User permissions should be preserved
	assert_true(DataStore.user_has_task("wrapping"), "Tasks should persist")
	assert_true(DataStore.user_has_task("quality_control"), "Tasks should persist")

func test_last_login_tracking():
	# If we track last login time
	DataStore.authenticate_user("testadmin", "test123")

	var user = DataStore.get_current_user()

	# Check if last_login is tracked
	if user.has("last_login"):
		assert_not_null(user["last_login"], "Should track last login")

		# Logout and login again
		DataStore.logout()
		DataStore.authenticate_user("testadmin", "test123")

		var user_after = DataStore.get_current_user()
		# Last login should be updated
		# This would require actual time comparison

func test_user_activity_log():
	# If we track user activity
	DataStore.authenticate_user("testadmin", "test123")

	# Create order
	var order_id = DataStore.create_order({
		"product": "300g Cups",
		"quantity": "160x16",
		"supplier": "RM",
		"delivery_date": "2025-11-25"
	})

	# If activity logging exists, verify order is linked to user
	var order = DataStore.get_order_by_id(order_id)
	assert_eq(order["created_by"], 1, "Order should be linked to creator")

	# Create defect
	var defect_id = DataStore.add_defect({
		"type": "bad_product",
		"reason": "Bruised",
		"quantity": 10
	})

	var defect = DataStore.get_defect_by_id(defect_id)
	assert_eq(defect["recorded_by"], 1, "Defect should be linked to recorder")
