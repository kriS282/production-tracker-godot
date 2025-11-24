extends GutTest
# Unit tests for quality defect tracking system

var TestHelpers = preload("res://tests/test_helpers.gd")

func before_each():
	TestHelpers.setup_test_environment()
	# Login as user with quality_control task
	DataStore.authenticate_user("testadmin", "test123")

func after_each():
	TestHelpers.teardown_test_environment()

# ========== DEFECT CREATION TESTS ==========

func test_add_bad_product_defect():
	var defect_data = {
		"type": "bad_product",
		"reason": "Bruised",
		"quantity": 15,
		"notes": "Severe bruising on caps"
	}

	var defect_id = DataStore.add_defect(defect_data)

	assert_gt(defect_id, 0, "Defect ID should be positive")
	assert_true(TestHelpers.assert_defect_count(1), "Should have 1 defect")

	var defect = DataStore.data["quality_defects"][0]
	assert_eq(defect["type"], "bad_product", "Type should be bad_product")
	assert_eq(defect["reason"], "Bruised", "Reason should be Bruised")
	assert_eq(defect["quantity"], 15, "Quantity should be 15")

func test_add_bad_wrap_defect():
	var defect_data = {
		"type": "bad_wrap",
		"reason": "Torn Film",
		"quantity": 5,
		"notes": "Film tore during wrapping"
	}

	var defect_id = DataStore.add_defect(defect_data)

	assert_gt(defect_id, 0, "Defect ID should be positive")

	var defect = DataStore.data["quality_defects"][0]
	assert_eq(defect["type"], "bad_wrap", "Type should be bad_wrap")
	assert_eq(defect["reason"], "Torn Film", "Reason should be Torn Film")

func test_add_defect_missing_type():
	var defect_data = {
		"reason": "Bruised",
		"quantity": 15
	}

	var defect_id = DataStore.add_defect(defect_data)

	assert_eq(defect_id, -1, "Should return -1 for missing type")

func test_add_defect_missing_reason():
	var defect_data = {
		"type": "bad_product",
		"quantity": 15
	}

	var defect_id = DataStore.add_defect(defect_data)

	assert_eq(defect_id, -1, "Should return -1 for missing reason")

func test_add_defect_missing_quantity():
	var defect_data = {
		"type": "bad_product",
		"reason": "Bruised"
	}

	var defect_id = DataStore.add_defect(defect_data)

	assert_eq(defect_id, -1, "Should return -1 for missing quantity")

func test_add_defect_zero_quantity():
	var defect_data = {
		"type": "bad_product",
		"reason": "Bruised",
		"quantity": 0
	}

	var defect_id = DataStore.add_defect(defect_data)

	assert_eq(defect_id, -1, "Should return -1 for zero quantity")

func test_add_defect_negative_quantity():
	var defect_data = {
		"type": "bad_product",
		"reason": "Bruised",
		"quantity": -5
	}

	var defect_id = DataStore.add_defect(defect_data)

	assert_eq(defect_id, -1, "Should return -1 for negative quantity")

func test_add_defect_optional_notes():
	var defect_data = {
		"type": "bad_product",
		"reason": "Bruised",
		"quantity": 10
		# No notes
	}

	var defect_id = DataStore.add_defect(defect_data)

	assert_gt(defect_id, 0, "Defect should be created without notes")

	var defect = DataStore.data["quality_defects"][0]
	assert_eq(defect.get("notes", ""), "", "Notes should be empty if not provided")

func test_add_defect_records_user():
	var defect_data = {
		"type": "bad_product",
		"reason": "Bruised",
		"quantity": 10
	}

	var defect_id = DataStore.add_defect(defect_data)

	var defect = DataStore.data["quality_defects"][0]
	assert_eq(defect["recorded_by"], 1, "Should record user ID")
	assert_not_null(defect.get("recorded_at"), "Should record timestamp")

# ========== DEFECT RETRIEVAL TESTS ==========

func test_get_all_defects():
	TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	TestHelpers.create_test_defect("bad_wrap", "Torn Film", 5)

	var all_defects = DataStore.get_all_defects()

	assert_eq(all_defects.size(), 2, "Should return all defects")

func test_get_defects_by_type_bad_product():
	TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	TestHelpers.create_test_defect("bad_product", "Discolored", 8)
	TestHelpers.create_test_defect("bad_wrap", "Torn Film", 5)

	var bad_product_defects = DataStore.get_defects_by_type("bad_product")

	assert_eq(bad_product_defects.size(), 2, "Should return only bad_product defects")

func test_get_defects_by_type_bad_wrap():
	TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	TestHelpers.create_test_defect("bad_wrap", "Torn Film", 5)
	TestHelpers.create_test_defect("bad_wrap", "Loose Wrap", 3)

	var bad_wrap_defects = DataStore.get_defects_by_type("bad_wrap")

	assert_eq(bad_wrap_defects.size(), 2, "Should return only bad_wrap defects")

func test_get_defects_today():
	TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	TestHelpers.create_test_defect("bad_wrap", "Torn Film", 5)

	var today_defects = DataStore.get_defects_today()

	assert_eq(today_defects.size(), 2, "Should return today's defects")

func test_get_defect_by_id():
	var defect = TestHelpers.create_test_defect("bad_product", "Bruised", 15)

	var found_defect = DataStore.get_defect_by_id(defect["id"])

	assert_not_null(found_defect, "Should find defect by ID")
	assert_eq(found_defect["reason"], "Bruised", "Should return correct defect")

func test_get_defect_by_id_nonexistent():
	var found_defect = DataStore.get_defect_by_id(999)

	assert_null(found_defect, "Should return null for non-existent defect")

# ========== DEFECT STATISTICS TESTS ==========

func test_get_daily_defect_summary():
	TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	TestHelpers.create_test_defect("bad_product", "Discolored", 8)
	TestHelpers.create_test_defect("bad_wrap", "Torn Film", 5)
	TestHelpers.create_test_defect("bad_wrap", "Loose Wrap", 3)

	var summary = DataStore.get_daily_defect_summary()

	assert_eq(summary["bad_product"], 23, "Bad product total should be 23")
	assert_eq(summary["bad_wrap"], 8, "Bad wrap total should be 8")
	assert_eq(summary["total"], 31, "Total defects should be 31")

func test_get_defect_count_by_reason():
	TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	TestHelpers.create_test_defect("bad_product", "Bruised", 10)
	TestHelpers.create_test_defect("bad_product", "Discolored", 8)

	var counts = DataStore.get_defect_count_by_reason()

	assert_eq(counts["Bruised"], 25, "Bruised count should be 25")
	assert_eq(counts["Discolored"], 8, "Discolored count should be 8")

func test_empty_defect_summary():
	var summary = DataStore.get_daily_defect_summary()

	assert_eq(summary["bad_product"], 0, "Bad product should be 0")
	assert_eq(summary["bad_wrap"], 0, "Bad wrap should be 0")
	assert_eq(summary["total"], 0, "Total should be 0")

# ========== DEFECT REASON MANAGEMENT TESTS ==========

func test_get_bad_product_reasons():
	var reasons = DataStore.get_defect_reasons("bad_product")

	assert_gt(reasons.size(), 0, "Should have default bad_product reasons")
	assert_has(reasons, "Bruised", "Should include Bruised")
	assert_has(reasons, "Discolored", "Should include Discolored")

func test_get_bad_wrap_reasons():
	var reasons = DataStore.get_defect_reasons("bad_wrap")

	assert_gt(reasons.size(), 0, "Should have default bad_wrap reasons")
	assert_has(reasons, "Torn Film", "Should include Torn Film")
	assert_has(reasons, "Loose Wrap", "Should include Loose Wrap")

func test_add_custom_bad_product_reason():
	var initial_count = DataStore.get_defect_reasons("bad_product").size()

	DataStore.add_defect_reason("bad_product", "Moldy")

	var reasons = DataStore.get_defect_reasons("bad_product")
	assert_eq(reasons.size(), initial_count + 1, "Should add new reason")
	assert_has(reasons, "Moldy", "Should include custom reason")

func test_add_custom_bad_wrap_reason():
	var initial_count = DataStore.get_defect_reasons("bad_wrap").size()

	DataStore.add_defect_reason("bad_wrap", "Crooked Label")

	var reasons = DataStore.get_defect_reasons("bad_wrap")
	assert_eq(reasons.size(), initial_count + 1, "Should add new reason")
	assert_has(reasons, "Crooked Label", "Should include custom reason")

func test_add_duplicate_custom_reason():
	var initial_count = DataStore.get_defect_reasons("bad_product").size()

	DataStore.add_defect_reason("bad_product", "Bruised")  # Already exists

	var reasons = DataStore.get_defect_reasons("bad_product")
	assert_eq(reasons.size(), initial_count, "Should not add duplicate")

func test_remove_custom_reason():
	# Add a custom reason
	DataStore.add_defect_reason("bad_product", "Moldy")

	# Remove it
	var result = DataStore.remove_defect_reason("bad_product", "Moldy")

	assert_true(result, "Should remove custom reason")
	var reasons = DataStore.get_defect_reasons("bad_product")
	assert_does_not_have(reasons, "Moldy", "Should not include removed reason")

func test_cannot_remove_default_reason():
	var result = DataStore.remove_defect_reason("bad_product", "Bruised")

	# Default reasons should not be removable
	assert_false(result, "Should not remove default reason")
	var reasons = DataStore.get_defect_reasons("bad_product")
	assert_has(reasons, "Bruised", "Default reason should still exist")

# ========== DEFECT UPDATE TESTS ==========

func test_update_defect():
	var defect = TestHelpers.create_test_defect("bad_product", "Bruised", 15)

	var updated_data = {
		"quantity": 20,
		"notes": "Updated notes"
	}

	var result = DataStore.update_defect(defect["id"], updated_data)

	assert_true(result, "Update should succeed")
	var updated_defect = DataStore.get_defect_by_id(defect["id"])
	assert_eq(updated_defect["quantity"], 20, "Quantity should be updated")
	assert_eq(updated_defect["notes"], "Updated notes", "Notes should be updated")

func test_update_defect_nonexistent():
	var updated_data = {
		"quantity": 20
	}

	var result = DataStore.update_defect(999, updated_data)

	assert_false(result, "Update should fail for non-existent defect")

# ========== DEFECT DELETION TESTS ==========

func test_delete_defect():
	var defect = TestHelpers.create_test_defect("bad_product", "Bruised", 15)

	var result = DataStore.delete_defect(defect["id"])

	assert_true(result, "Delete should succeed")
	assert_true(TestHelpers.assert_defect_count(0), "Should have 0 defects")

func test_delete_defect_nonexistent():
	var result = DataStore.delete_defect(999)

	assert_false(result, "Delete should fail for non-existent defect")

# ========== DEFECT FILTERING TESTS ==========

func test_filter_defects_by_date_range():
	# Create defects on different dates (would need to mock dates)
	var defect1 = TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	var defect2 = TestHelpers.create_test_defect("bad_wrap", "Torn Film", 5)

	# If we had date filtering
	# var filtered = DataStore.filter_defects_by_date_range("2025-11-20", "2025-11-25")
	# assert_eq(filtered.size(), 2, "Should return defects in date range")

func test_get_recent_defects():
	TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	TestHelpers.create_test_defect("bad_wrap", "Torn Film", 5)
	TestHelpers.create_test_defect("bad_product", "Discolored", 8)

	var recent = DataStore.get_recent_defects(2)

	assert_eq(recent.size(), 2, "Should return only 2 most recent defects")

# ========== DEFECT REPORTING TESTS ==========

func test_generate_defect_report():
	TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	TestHelpers.create_test_defect("bad_product", "Discolored", 8)
	TestHelpers.create_test_defect("bad_wrap", "Torn Film", 5)

	var report = DataStore.generate_defect_report()

	assert_has(report, "total_defects", "Report should have total_defects")
	assert_has(report, "by_type", "Report should have by_type breakdown")
	assert_has(report, "by_reason", "Report should have by_reason breakdown")
	assert_eq(report["total_defects"], 28, "Total should be 28")

# ========== PERMISSION TESTS ==========

func test_add_defect_without_permission():
	# Create user without quality_control task
	TestHelpers.create_test_user("limited", "Picker", ["wrapping"])
	DataStore.logout()
	DataStore.authenticate_user("limited", "password123")

	var defect_data = {
		"type": "bad_product",
		"reason": "Bruised",
		"quantity": 15
	}

	# Should check permission before adding
	if not DataStore.user_has_task("quality_control"):
		# If permission check is implemented
		pass

# ========== DATA PERSISTENCE TESTS ==========

func test_defects_persist_after_save_load():
	TestHelpers.create_test_defect("bad_product", "Bruised", 15)
	TestHelpers.create_test_defect("bad_wrap", "Torn Film", 5)

	# Save data
	DataStore.save_data()

	# Clear in-memory data
	DataStore.data["quality_defects"] = []

	# Load data
	DataStore.load_data()

	assert_eq(DataStore.data["quality_defects"].size(), 2, "Defects should persist")

func test_custom_reasons_persist():
	DataStore.add_defect_reason("bad_product", "Moldy")

	# Save data
	DataStore.save_data()

	# Clear in-memory data
	DataStore.data["defect_reasons"]["bad_product"] = []

	# Load data
	DataStore.load_data()

	var reasons = DataStore.get_defect_reasons("bad_product")
	assert_has(reasons, "Moldy", "Custom reasons should persist")
