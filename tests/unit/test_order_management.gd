extends GutTest
# Unit tests for order management system

var TestHelpers = preload("res://tests/test_helpers.gd")

func before_each():
	TestHelpers.setup_test_environment()
	# Login as admin for order operations
	DataStore.authenticate_user("testadmin", "test123")

func after_each():
	TestHelpers.teardown_test_environment()

# ========== ORDER CREATION TESTS ==========

func test_create_order():
	var order_data = {
		"product": "300g Cups",
		"quantity": "160x16",
		"customer": "Lidl RDC Mullingar",
		"delivery_date": "2025-11-25",
		"harvest_date": "2025-11-23",
		"supplier": "RM",
		"batch_code": "L4705"
	}

	var order_id = DataStore.create_order(order_data)

	assert_gt(order_id, 0, "Order ID should be positive")
	assert_true(TestHelpers.assert_order_exists(order_id), "Order should exist after creation")

	var order = TestHelpers.get_order_by_id(order_id)
	assert_eq(order["product"], "300g Cups", "Product should match")
	assert_eq(order["status"], "pending", "New order should have pending status")

func test_create_order_missing_product():
	var order_data = {
		"product": "",
		"quantity": "160x16",
		"customer": "Lidl RDC Mullingar",
		"delivery_date": "2025-11-25",
		"supplier": "RM"
	}

	var order_id = DataStore.create_order(order_data)

	assert_eq(order_id, -1, "Should return -1 for missing product")

func test_create_order_missing_quantity():
	var order_data = {
		"product": "300g Cups",
		"quantity": "",
		"customer": "Lidl RDC Mullingar",
		"delivery_date": "2025-11-25",
		"supplier": "RM"
	}

	var order_id = DataStore.create_order(order_data)

	assert_eq(order_id, -1, "Should return -1 for missing quantity")

func test_create_order_auto_batch_code():
	var order_data = {
		"product": "300g Cups",
		"quantity": "160x16",
		"customer": "Lidl RDC Mullingar",
		"delivery_date": "2025-11-25",
		"harvest_date": "2025-11-23",
		"supplier": "RM"
		# No batch_code provided
	}

	var order_id = DataStore.create_order(order_data)

	assert_gt(order_id, 0, "Order should be created")
	var order = TestHelpers.get_order_by_id(order_id)
	assert_ne(order["batch_code"], "", "Batch code should be auto-generated")
	assert_string_starts_with(order["batch_code"], "L", "Batch code should start with L")

func test_create_order_default_customer():
	var order_data = {
		"product": "300g Cups",
		"quantity": "160x16",
		"delivery_date": "2025-11-25",
		"supplier": "RM"
		# No customer provided
	}

	var order_id = DataStore.create_order(order_data)

	assert_gt(order_id, 0, "Order should be created")
	var order = TestHelpers.get_order_by_id(order_id)
	assert_eq(order["customer"], "Lidl RDC Mullingar", "Should use default customer")

func test_create_order_records_creator():
	var order_data = {
		"product": "300g Cups",
		"quantity": "160x16",
		"customer": "Lidl RDC Mullingar",
		"delivery_date": "2025-11-25",
		"supplier": "RM"
	}

	var order_id = DataStore.create_order(order_data)

	var order = TestHelpers.get_order_by_id(order_id)
	assert_eq(order["created_by"], 1, "Should record creator ID")
	assert_not_null(order.get("created_at"), "Should record creation timestamp")

# ========== ORDER RETRIEVAL TESTS ==========

func test_get_pending_orders():
	# Create some orders
	TestHelpers.create_test_order("300g Cups", "160x16")
	TestHelpers.create_test_order("433g Cups", "200x12")

	var pending_orders = DataStore.get_pending_orders()

	assert_eq(pending_orders.size(), 2, "Should return all pending orders")

func test_get_pending_orders_excludes_completed():
	# Create orders
	var order1 = TestHelpers.create_test_order("300g Cups", "160x16")
	var order2 = TestHelpers.create_test_order("433g Cups", "200x12")

	# Complete one order
	DataStore.update_order_status(order1["id"], "completed")

	var pending_orders = DataStore.get_pending_orders()

	assert_eq(pending_orders.size(), 1, "Should only return pending orders")
	assert_eq(pending_orders[0]["id"], order2["id"], "Should return the pending order")

func test_get_completed_orders():
	# Create orders
	var order1 = TestHelpers.create_test_order("300g Cups", "160x16")
	var order2 = TestHelpers.create_test_order("433g Cups", "200x12")

	# Complete one order
	DataStore.update_order_status(order1["id"], "completed")

	var completed_orders = DataStore.get_completed_orders()

	assert_eq(completed_orders.size(), 1, "Should return completed orders")
	assert_eq(completed_orders[0]["id"], order1["id"], "Should return the completed order")

func test_get_all_orders():
	# Create orders
	TestHelpers.create_test_order("300g Cups", "160x16")
	TestHelpers.create_test_order("433g Cups", "200x12")

	var all_orders = DataStore.get_all_orders()

	assert_eq(all_orders.size(), 2, "Should return all orders")

func test_get_order_by_id():
	var created_order = TestHelpers.create_test_order("300g Cups", "160x16")

	var order = DataStore.get_order_by_id(created_order["id"])

	assert_not_null(order, "Should find order by ID")
	assert_eq(order["product"], "300g Cups", "Should return correct order")

func test_get_order_by_id_nonexistent():
	var order = DataStore.get_order_by_id(999)

	assert_null(order, "Should return null for non-existent order")

# ========== ORDER STATUS TESTS ==========

func test_update_order_status_to_completed():
	var order = TestHelpers.create_test_order("300g Cups", "160x16")

	var result = DataStore.update_order_status(order["id"], "completed")

	assert_true(result, "Status update should succeed")
	assert_true(TestHelpers.assert_order_status(order["id"], "completed"), "Order should be completed")

func test_update_order_status_to_cancelled():
	var order = TestHelpers.create_test_order("300g Cups", "160x16")

	var result = DataStore.update_order_status(order["id"], "cancelled")

	assert_true(result, "Status update should succeed")
	assert_true(TestHelpers.assert_order_status(order["id"], "cancelled"), "Order should be cancelled")

func test_update_order_status_nonexistent_order():
	var result = DataStore.update_order_status(999, "completed")

	assert_false(result, "Status update should fail for non-existent order")

func test_update_order_status_invalid_status():
	var order = TestHelpers.create_test_order("300g Cups", "160x16")

	# Try to set invalid status
	var result = DataStore.update_order_status(order["id"], "invalid_status")

	# Should either fail or ignore invalid status
	assert_false(result, "Should fail for invalid status")

# ========== ORDER UPDATE TESTS ==========

func test_update_order_details():
	var order = TestHelpers.create_test_order("300g Cups", "160x16")

	var updated_data = {
		"quantity": "200x16",
		"delivery_date": "2025-11-26"
	}

	var result = DataStore.update_order(order["id"], updated_data)

	assert_true(result, "Order update should succeed")
	var updated_order = TestHelpers.get_order_by_id(order["id"])
	assert_eq(updated_order["quantity"], "200x16", "Quantity should be updated")
	assert_eq(updated_order["delivery_date"], "2025-11-26", "Delivery date should be updated")

func test_update_order_nonexistent():
	var updated_data = {
		"quantity": "200x16"
	}

	var result = DataStore.update_order(999, updated_data)

	assert_false(result, "Update should fail for non-existent order")

# ========== ORDER DELETION TESTS ==========

func test_delete_order():
	var order = TestHelpers.create_test_order("300g Cups", "160x16")

	var result = DataStore.delete_order(order["id"])

	assert_true(result, "Delete should succeed")
	assert_false(TestHelpers.assert_order_exists(order["id"]), "Order should not exist after deletion")

func test_delete_order_nonexistent():
	var result = DataStore.delete_order(999)

	assert_false(result, "Delete should fail for non-existent order")

func test_delete_completed_order():
	var order = TestHelpers.create_test_order("300g Cups", "160x16")
	DataStore.update_order_status(order["id"], "completed")

	var result = DataStore.delete_order(order["id"])

	# Decide if completed orders should be deletable
	# For now, assuming they should be
	assert_true(result, "Should be able to delete completed orders")

# ========== ORDER FILTERING TESTS ==========

func test_filter_orders_by_product():
	TestHelpers.create_test_order("300g Cups", "160x16")
	TestHelpers.create_test_order("300g Cups", "200x16")
	TestHelpers.create_test_order("433g Cups", "160x12")

	var filtered = DataStore.filter_orders_by_product("300g Cups")

	assert_eq(filtered.size(), 2, "Should return orders with matching product")

func test_filter_orders_by_supplier():
	var order1 = TestHelpers.create_test_order("300g Cups", "160x16")
	order1["supplier"] = "RM"
	var order2 = TestHelpers.create_test_order("433g Cups", "160x12")
	order2["supplier"] = "McKenna"

	var filtered = DataStore.filter_orders_by_supplier("RM")

	assert_eq(filtered.size(), 1, "Should return orders with matching supplier")

func test_filter_orders_by_date_range():
	var order1 = TestHelpers.create_test_order("300g Cups", "160x16")
	order1["delivery_date"] = "2025-11-20"
	var order2 = TestHelpers.create_test_order("433g Cups", "160x12")
	order2["delivery_date"] = "2025-11-25"
	var order3 = TestHelpers.create_test_order("150g Buttons", "160x16")
	order3["delivery_date"] = "2025-11-30"

	var filtered = DataStore.filter_orders_by_date_range("2025-11-23", "2025-11-27")

	assert_eq(filtered.size(), 1, "Should return orders within date range")
	assert_eq(filtered[0]["delivery_date"], "2025-11-25", "Should be the order in range")

# ========== BATCH CODE TESTS ==========

func test_batch_code_format():
	var order = TestHelpers.create_test_order("300g Cups", "160x16")

	# Batch code should be in format LWWdd (L + week + day)
	assert_string_starts_with(order["batch_code"], "L", "Batch code should start with L")
	assert_eq(order["batch_code"].length(), 5, "Batch code should be 5 characters")

func test_unique_batch_codes():
	var order1 = TestHelpers.create_test_order("300g Cups", "160x16")
	var order2 = TestHelpers.create_test_order("433g Cups", "200x12")

	# If created on the same day, batch codes might be the same
	# This depends on your batch code generation strategy
	# If they should be unique, add a counter or use different dates

# ========== ORDER STATISTICS TESTS ==========

func test_get_order_statistics():
	# Create orders with different statuses
	var order1 = TestHelpers.create_test_order("300g Cups", "160x16")
	var order2 = TestHelpers.create_test_order("433g Cups", "200x12")
	var order3 = TestHelpers.create_test_order("150g Buttons", "160x16")

	DataStore.update_order_status(order1["id"], "completed")
	DataStore.update_order_status(order2["id"], "completed")
	# order3 stays pending

	var stats = DataStore.get_order_statistics()

	assert_eq(stats["total"], 3, "Total should be 3")
	assert_eq(stats["pending"], 1, "Pending should be 1")
	assert_eq(stats["completed"], 2, "Completed should be 2")
