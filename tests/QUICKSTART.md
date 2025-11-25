# Quick Start Guide - Running Tests

## ✅ Setup Complete!

GUT (Godot Unit Test) is now installed and configured in your project.

## 🚀 How to Run Tests

### Option 1: From Godot Editor (Easiest)

1. **Open your project in Godot Editor**
2. **Look for the "Gut" panel** at the bottom of the editor (next to Output, Debugger, etc.)
3. **Click "Run All"** to run all tests
4. **View results** in the panel with detailed output

**OR**

1. Open the test runner scene: `res://tests/TestRunner.tscn`
2. Press **F6** to run the scene
3. Watch tests execute in the output panel

### Option 2: From Command Line

If you have Godot in your PATH:

```bash
# Run all tests (headless mode)
godot --headless --script tests/run_tests.gd

# Run all tests using GUT's command line runner
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit

# Run specific test file
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_authentication.gd -gexit

# Run with detailed output
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -glog=2 -gexit
```

### Option 3: Using the Test Runner Scene

1. In Godot, navigate to `res://tests/TestRunner.tscn`
2. Double-click to open it
3. Press **F6** (or click Run Current Scene)
4. Tests will run automatically

## 📊 Test Structure

Your test suite includes:

### Unit Tests (`tests/unit/`)
- ✅ **test_authentication.gd** - User login, passwords, sessions
- ✅ **test_datastore.gd** - Data operations and persistence
- ✅ **test_order_management.gd** - Order CRUD operations
- ✅ **test_quality_defects.gd** - Defect tracking

### Integration Tests (`tests/integration/`)
- ✅ **test_order_workflow.gd** - Complete order lifecycle
- ✅ **test_user_management_workflow.gd** - User management flows

### Test Helpers
- ✅ **test_helpers.gd** - Common utilities and fixtures

## 🎯 Quick Test Commands

```bash
# Run only unit tests
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

# Run only integration tests
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit

# Run a single test
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_authentication.gd -gexit
```

## 📝 Writing Your First Test

Create a new file in `tests/unit/` or `tests/integration/`:

```gdscript
extends GutTest
# Test description

var TestHelpers = preload("res://tests/test_helpers.gd")

func before_each():
	TestHelpers.setup_test_environment()

func after_each():
	TestHelpers.teardown_test_environment()

func test_something_works():
	# Arrange
	var input = "test"

	# Act
	var result = DataStore.some_function(input)

	# Assert
	assert_true(result, "Should work correctly")
```

## 🔍 Common Assertions

```gdscript
assert_true(value, "message")
assert_false(value, "message")
assert_eq(actual, expected, "message")
assert_ne(actual, not_expected, "message")
assert_gt(value1, value2, "greater than")
assert_lt(value1, value2, "less than")
assert_null(value, "message")
assert_not_null(value, "message")
```

## 🐛 Troubleshooting

### GUT panel not showing in editor?
- Restart Godot editor
- Check Project → Project Settings → Plugins
- Ensure "Gut" is enabled

### Tests not running?
- Make sure your test files extend `GutTest`
- Test functions must start with `test_`
- Check output console for error messages

### Import errors?
- Verify `DataStore` autoload is configured in project.godot
- Check that all test files are in `res://tests/` directory

## 📚 More Information

For detailed testing guide, see: `tests/README.md`

For GUT documentation: https://github.com/bitwes/Gut/wiki

---

**Happy Testing!** 🎉
