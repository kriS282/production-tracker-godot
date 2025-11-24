extends GutTest
# Integration tests for complete order workflow
# Tests the full lifecycle: Create order -> Select order -> Complete wrapping -> Generate form

var TestHelpers = preload("res://tests/test_helpers.gd")

func before_each():
	TestHelpers.setup_test_environment()

func after_each():
	TestHelpers.teardown_test_environment()

# ========== COMPLETE ORDER WORKFLOW ==========

func test_complete_order_workflow():
	# Step 1: Manager logs in
	var login_success = DataStore.authenticate_user("testadmin", "test123")
	assert_true(login_success, "Manager should login successfully")
	assert_true(DataStore.user_has_task("orders"), "Manager should have orders task")

	# Step 2: Manager creates order
	var order_data = {
		"product": "300g Cups",
		"quantity": "160x16",
		"customer": "Lidl RDC Mullingar",
		"delivery_date": "2025-11-25",
		"harvest_date": "2025-11-23",
		"supplier": "RM"
	}

	var order_id = DataStore.create_order(order_data)
	assert_gt(order_id, 0, "Order should be created")

	# Step 3: Verify order appears in pending list
	var pending_orders = DataStore.get_pending_orders()
	assert_eq(pending_orders.size(), 1, "Should have 1 pending order")
	assert_eq(pending_orders[0]["id"], order_id, "Should be the created order")

	# Step 4: Manager logs out
	DataStore.logout()
	assert_null(DataStore.get_current_user(), "Should be logged out")

	# Step 5: Worker logs in
	TestHelpers.create_test_user("worker", "Packing Supervisor", ["wrapping", "quality_control"])
	login_success = DataStore.authenticate_user("worker", "password123")
	assert_true(login_success, "Worker should login successfully")

	# Step 6: Worker opens wrapping tracker and selects order
	pending_orders = DataStore.get_pending_orders()
	assert_eq(pending_orders.size(), 1, "Worker should see 1 pending order")

	var selected_order = pending_orders[0]

	# Step 7: Worker starts wrapping session
	var session_data = {
		"order_id": selected_order["id"],
		"operator_id": DataStore.get_current_user()["id"]
	}

	var session_id = DataStore.create_wrapping_session(session_data)
	assert_gt(session_id, 0, "Wrapping session should be created")

	# Step 8: Worker wraps crates
	var crates_wrapped = 150
	var update_success = DataStore.update_wrapping_session(session_id, {"crates_wrapped": crates_wrapped})
	assert_true(update_success, "Should update crates wrapped")

	# Step 9: Worker ends session
	var end_success = DataStore.end_wrapping_session(session_id)
	assert_true(end_success, "Should end session successfully")

	# Step 10: Order status should be updated to completed
	var order = DataStore.get_order_by_id(order_id)
	assert_eq(order["status"], "completed", "Order should be marked completed")

	# Step 11: Verify order no longer appears in pending list
	pending_orders = DataStore.get_pending_orders()
	assert_eq(pending_orders.size(), 0, "Should have 0 pending orders")

	# Step 12: Verify order appears in completed list
	var completed_orders = DataStore.get_completed_orders()
	assert_eq(completed_orders.size(), 1, "Should have 1 completed order")

func test_manual_entry_workflow():
	# Step 1: Worker logs in
	TestHelpers.create_test_user("worker", "Packing Supervisor", ["wrapping"])
	var login_success = DataStore.authenticate_user("worker", "password123")
	assert_true(login_success, "Worker should login successfully")

	# Step 2: Worker does manual entry (no order selection)
	var session_data = {
		"product": "433g Cups",
		"quantity": "200x12",
		"supplier": "McKenna",
		"harvest_date": "2025-11-23",
		"delivery_date": "2025-11-25",
		"operator_id": DataStore.get_current_user()["id"]
	}

	var session_id = DataStore.create_wrapping_session(session_data)
	assert_gt(session_id, 0, "Manual session should be created")

	# Step 3: Verify batch code was auto-generated
	var session = DataStore.get_wrapping_session_by_id(session_id)
	assert_not_null(session.get("batch_code"), "Batch code should be generated")
	assert_string_starts_with(session["batch_code"], "L", "Batch code should start with L")

	# Step 4: Worker wraps crates
	var update_success = DataStore.update_wrapping_session(session_id, {"crates_wrapped": 100})
	assert_true(update_success, "Should update crates wrapped")

	# Step 5: Worker ends session
	var end_success = DataStore.end_wrapping_session(session_id)
	assert_true(end_success, "Should end manual session")

	# Step 6: Verify session is saved
	session = DataStore.get_wrapping_session_by_id(session_id)
	assert_eq(session["crates_wrapped"], 100, "Crates should be saved")
	assert_not_null(session.get("ended_at"), "End time should be recorded")

func test_order_with_quality_issues_workflow():
	# Step 1: Login as worker
	TestHelpers.create_test_user("worker", "Packing Supervisor", ["wrapping", "quality_control"])
	DataStore.authenticate_user("worker", "password123")

	# Step 2: Create and select order
	var order = TestHelpers.create_test_order("300g Cups", "160x16")

	# Step 3: Start wrapping session
	var session_id = DataStore.create_wrapping_session({
		"order_id": order["id"],
		"operator_id": DataStore.get_current_user()["id"]
	})

	# Step 4: Worker notices quality issues
	var defect1 = DataStore.add_defect({
		"type": "bad_product",
		"reason": "Bruised",
		"quantity": 15,
		"notes": "Severe bruising"
	})
	assert_gt(defect1, 0, "Should record bad product defect")

	var defect2 = DataStore.add_defect({
		"type": "bad_wrap",
		"reason": "Torn Film",
		"quantity": 3,
		"notes": "Film torn during wrapping"
	})
	assert_gt(defect2, 0, "Should record bad wrap defect")

	# Step 5: Worker completes wrapping
	DataStore.update_wrapping_session(session_id, {"crates_wrapped": 150})
	DataStore.end_wrapping_session(session_id)

	# Step 6: Verify defects are recorded
	var defects = DataStore.get_defects_today()
	assert_eq(defects.size(), 2, "Should have 2 defects recorded")

	# Step 7: Verify daily summary
	var summary = DataStore.get_daily_defect_summary()
	assert_eq(summary["bad_product"], 15, "Should have 15 bad products")
	assert_eq(summary["bad_wrap"], 3, "Should have 3 bad wraps")

func test_multiple_orders_same_day():
	# Step 1: Manager creates multiple orders
	DataStore.authenticate_user("testadmin", "test123")

	var order1_id = DataStore.create_order({
		"product": "300g Cups",
		"quantity": "160x16",
		"supplier": "RM",
		"delivery_date": "2025-11-25"
	})

	var order2_id = DataStore.create_order({
		"product": "433g Cups",
		"quantity": "200x12",
		"supplier": "McKenna",
		"delivery_date": "2025-11-25"
	})

	var order3_id = DataStore.create_order({
		"product": "150g Buttons",
		"quantity": "160x16",
		"supplier": "RM",
		"delivery_date": "2025-11-26"
	})

	# Step 2: Verify all orders are pending
	var pending_orders = DataStore.get_pending_orders()
	assert_eq(pending_orders.size(), 3, "Should have 3 pending orders")

	# Step 3: Worker completes first order
	TestHelpers.create_test_user("worker", "Packing Supervisor", ["wrapping"])
	DataStore.logout()
	DataStore.authenticate_user("worker", "password123")

	var session1_id = DataStore.create_wrapping_session({
		"order_id": order1_id,
		"operator_id": DataStore.get_current_user()["id"]
	})
	DataStore.update_wrapping_session(session1_id, {"crates_wrapped": 150})
	DataStore.end_wrapping_session(session1_id)

	# Step 4: Verify order1 is completed, others are pending
	pending_orders = DataStore.get_pending_orders()
	assert_eq(pending_orders.size(), 2, "Should have 2 pending orders")

	var completed_orders = DataStore.get_completed_orders()
	assert_eq(completed_orders.size(), 1, "Should have 1 completed order")
	assert_eq(completed_orders[0]["id"], order1_id, "Should be order1")

	# Step 5: Worker completes second order
	var session2_id = DataStore.create_wrapping_session({
		"order_id": order2_id,
		"operator_id": DataStore.get_current_user()["id"]
	})
	DataStore.update_wrapping_session(session2_id, {"crates_wrapped": 200})
	DataStore.end_wrapping_session(session2_id)

	# Step 6: Verify order2 is completed, order3 is pending
	pending_orders = DataStore.get_pending_orders()
	assert_eq(pending_orders.size(), 1, "Should have 1 pending order")
	assert_eq(pending_orders[0]["id"], order3_id, "Should be order3")

	completed_orders = DataStore.get_completed_orders()
	assert_eq(completed_orders.size(), 2, "Should have 2 completed orders")

func test_cancelled_order_workflow():
	# Step 1: Manager creates order
	DataStore.authenticate_user("testadmin", "test123")

	var order_id = DataStore.create_order({
		"product": "300g Cups",
		"quantity": "160x16",
		"supplier": "RM",
		"delivery_date": "2025-11-25"
	})

	# Step 2: Manager cancels order (e.g., customer changed mind)
	var cancel_success = DataStore.update_order_status(order_id, "cancelled")
	assert_true(cancel_success, "Should cancel order")

	# Step 3: Verify order doesn't appear in pending list
	var pending_orders = DataStore.get_pending_orders()
	assert_eq(pending_orders.size(), 0, "Should have 0 pending orders")

	# Step 4: Verify order has cancelled status
	var order = DataStore.get_order_by_id(order_id)
	assert_eq(order["status"], "cancelled", "Order should be cancelled")

# ========== DATA PERSISTENCE WORKFLOW ==========

func test_workflow_persists_across_app_restart():
	# Step 1: Create order
	DataStore.authenticate_user("testadmin", "test123")
	var order_id = DataStore.create_order({
		"product": "300g Cups",
		"quantity": "160x16",
		"supplier": "RM",
		"delivery_date": "2025-11-25"
	})

	# Step 2: Save data (simulate app close)
	DataStore.save_data()

	# Step 3: Clear in-memory data (simulate app restart)
	DataStore.data["orders"] = []
	DataStore.data["current_user"] = null

	# Step 4: Load data (simulate app open)
	DataStore.load_data()

	# Step 5: Login again
	DataStore.authenticate_user("testadmin", "test123")

	# Step 6: Verify order still exists
	var order = DataStore.get_order_by_id(order_id)
	assert_not_null(order, "Order should persist after restart")
	assert_eq(order["product"], "300g Cups", "Order data should be intact")

	# Step 7: Complete the order
	TestHelpers.create_test_user("worker", "Packing Supervisor", ["wrapping"])
	DataStore.logout()
	DataStore.authenticate_user("worker", "password123")

	var session_id = DataStore.create_wrapping_session({
		"order_id": order_id,
		"operator_id": DataStore.get_current_user()["id"]
	})
	DataStore.update_wrapping_session(session_id, {"crates_wrapped": 150})
	DataStore.end_wrapping_session(session_id)

	# Step 8: Save data again
	DataStore.save_data()

	# Step 9: Clear and reload
	DataStore.data["orders"] = []
	DataStore.data["wrapping_sessions"] = []
	DataStore.load_data()

	# Step 10: Verify order is completed
	order = DataStore.get_order_by_id(order_id)
	assert_eq(order["status"], "completed", "Order completion should persist")

	var sessions = DataStore.get_wrapping_sessions_by_order_id(order_id)
	assert_eq(sessions.size(), 1, "Session should persist")
	assert_eq(sessions[0]["crates_wrapped"], 150, "Session data should persist")

# ========== ERROR HANDLING WORKFLOW ==========

func test_order_workflow_with_invalid_data():
	# Step 1: Try to create order with missing required fields
	DataStore.authenticate_user("testadmin", "test123")

	var order_id = DataStore.create_order({
		"product": "",  # Missing product
		"quantity": "160x16",
		"supplier": "RM"
	})

	assert_eq(order_id, -1, "Should fail to create order with missing product")

	# Step 2: Create valid order
	order_id = DataStore.create_order({
		"product": "300g Cups",
		"quantity": "160x16",
		"supplier": "RM",
		"delivery_date": "2025-11-25"
	})

	assert_gt(order_id, 0, "Valid order should be created")

	# Step 3: Try to start session without being logged in
	DataStore.logout()

	var session_id = DataStore.create_wrapping_session({
		"order_id": order_id,
		"operator_id": 999  # Invalid user
	})

	# Should fail or handle gracefully
	assert_eq(session_id, -1, "Should fail to create session with invalid user")
