extends SceneTree
# Test runner script for command-line execution
# Run with: godot --headless --script tests/run_tests.gd

func _init():
	# Create GUT instance
	var gut = load("res://addons/gut/gut.gd").new()

	# Configure GUT
	gut.add_directory("res://tests/unit")
	gut.add_directory("res://tests/integration")
	gut.set_log_level(gut.LOG_LEVEL_ALL_ASSERTS)
	gut.set_yield_between_tests(true)
	gut.set_exit_on_success(true)

	# Add to scene
	var root = Window.new()
	root.add_child(gut)
	self.root = root

	# Run tests
	gut.test_scripts()

	# Print summary
	print("\n========== TEST SUMMARY ==========")
	print("Tests run: ", gut.get_test_count())
	print("Passed: ", gut.get_pass_count())
	print("Failed: ", gut.get_fail_count())
	print("==================================\n")

	# Exit with proper code
	if gut.get_fail_count() > 0:
		quit(1)
	else:
		quit(0)
