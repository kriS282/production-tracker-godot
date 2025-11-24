# Production Manager - Automated Tests

This directory contains automated tests for the Production Manager application using the GUT (Godot Unit Test) framework.

## Test Structure

```
tests/
├── README.md (this file)
├── test_helpers.gd (test utilities and fixtures)
├── unit/ (unit tests for individual components)
│   ├── test_authentication.gd
│   ├── test_datastore.gd
│   ├── test_order_management.gd
│   └── test_quality_defects.gd
└── integration/ (end-to-end workflow tests)
    ├── test_order_workflow.gd
    └── test_user_management_workflow.gd
```

## Setup

### 1. Install GUT (Godot Unit Test)

**Option A: Install from Asset Library (Recommended)**
1. Open Godot Editor
2. Click "AssetLib" tab at the top
3. Search for "GUT"
4. Click on "Godot Unit Test (GUT)"
5. Click "Download" then "Install"
6. Enable the plugin in Project > Project Settings > Plugins

**Option B: Manual Installation**
1. Download GUT from: https://github.com/bitwes/Gut
2. Extract the `addons/gut` folder to your project's `addons/` directory
3. Enable the plugin in Project > Project Settings > Plugins

### 2. Configure GUT

1. In Godot, go to Project > Project Settings > Plugins
2. Make sure "Gut" is enabled
3. Create a test scene (optional) or run tests via command line

### 3. Run Tests

**Option A: From Godot Editor**
1. Open the GUT panel (bottom panel in editor)
2. Click "Run All" to run all tests
3. View results in the panel

**Option B: From Command Line**
```bash
# Run all tests
godot --path /path/to/project -s addons/gut/gut_cmdln.gd -gdir=res://tests/

# Run specific test file
godot --path /path/to/project -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_authentication.gd

# Run tests and exit
godot --path /path/to/project -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

**Option C: Using a Test Scene**
1. Create a new scene with a GutTestRunner node
2. Configure test directories
3. Run the scene (F6)

## Test Categories

### Unit Tests

Test individual components in isolation:

**test_authentication.gd**
- Password hashing
- User login/logout
- Session management
- Permission checking

**test_datastore.gd**
- User CRUD operations
- Data persistence
- Product configuration
- Batch code generation
- Defect reason management

**test_order_management.gd**
- Order creation/update/deletion
- Order status management
- Order filtering
- Order statistics

**test_quality_defects.gd**
- Defect creation/update/deletion
- Defect statistics
- Custom reason management
- Daily summaries

### Integration Tests

Test complete workflows end-to-end:

**test_order_workflow.gd**
- Complete order lifecycle (create → select → complete → generate form)
- Manual entry workflow
- Order with quality issues workflow
- Multiple orders on same day
- Cancelled orders
- Data persistence across app restarts

**test_user_management_workflow.gd**
- Complete user lifecycle (create → login → use → update → delete)
- Role-based access control
- Password changes
- Permission enforcement
- User data persistence

## Writing New Tests

### Basic Test Structure

```gdscript
extends GutTest
# Description of what this test file covers

var TestHelpers = preload("res://tests/test_helpers.gd")

func before_each():
	TestHelpers.setup_test_environment()

func after_each():
	TestHelpers.teardown_test_environment()

func test_your_feature():
	# Arrange
	var input = "test_data"

	# Act
	var result = DataStore.some_function(input)

	# Assert
	assert_true(result, "Should return true")
```

### Available Assertions

GUT provides many assertion methods:

```gdscript
assert_true(value, message)
assert_false(value, message)
assert_eq(value1, value2, message)
assert_ne(value1, value2, message)
assert_gt(value1, value2, message)  # greater than
assert_lt(value1, value2, message)  # less than
assert_null(value, message)
assert_not_null(value, message)
assert_has(container, value, message)
assert_does_not_have(container, value, message)
assert_string_contains(string, substring, message)
assert_string_starts_with(string, prefix, message)
assert_string_ends_with(string, suffix, message)
```

### Test Helpers

Use `TestHelpers` for common operations:

```gdscript
# Setup/teardown
TestHelpers.setup_test_environment()
TestHelpers.teardown_test_environment()

# Create test data
var user = TestHelpers.create_test_user("username", "Role", ["tasks"])
var order = TestHelpers.create_test_order("300g Cups", "160x16")
var session = TestHelpers.create_test_session(order_id)
var defect = TestHelpers.create_test_defect("bad_product", "Bruised", 10)

# Assertions
TestHelpers.assert_user_exists("username")
TestHelpers.assert_order_exists(order_id)
TestHelpers.assert_order_status(order_id, "completed")
TestHelpers.assert_defect_count(5)

# Getters
var user = TestHelpers.get_user_by_username("username")
var order = TestHelpers.get_order_by_id(order_id)
var pending_count = TestHelpers.get_pending_orders_count()
```

## Test Coverage

### Critical Paths (Must Have 100% Coverage)

- [ ] User authentication
- [ ] Order creation and completion
- [ ] Wrapping session management
- [ ] Quality defect recording
- [ ] Data persistence
- [ ] Permission checking

### Important Features (Should Have High Coverage)

- [ ] User management
- [ ] Order filtering and search
- [ ] Defect statistics
- [ ] Batch code generation
- [ ] Role-based access control

### Nice to Have

- [ ] Edge cases and error handling
- [ ] Performance tests
- [ ] UI integration tests
- [ ] Report generation

## Current Test Coverage

Run tests to see coverage report:

```bash
godot --path /path/to/project -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/tests.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.3
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

## Troubleshooting

### Tests Not Running

1. **GUT not installed**: Follow installation steps above
2. **Plugin not enabled**: Check Project > Project Settings > Plugins
3. **Wrong Godot version**: GUT requires Godot 4.3+
4. **Path issues**: Ensure test files are in `res://tests/` directory

### Tests Failing

1. **Check test output**: Read assertion messages carefully
2. **Check DataStore methods**: Ensure all methods referenced in tests exist
3. **Check test data**: Verify test_helpers is setting up data correctly
4. **Run tests individually**: Isolate which test is failing

### Performance Issues

1. **Too much test data**: Use `before_each`/`after_each` to clean up
2. **Heavy operations**: Mock expensive operations
3. **File I/O**: Use in-memory test data when possible

## Best Practices

### 1. Test Independence
- Each test should be independent
- Use `before_each` to set up fresh state
- Use `after_each` to clean up
- Don't rely on test execution order

### 2. Clear Test Names
```gdscript
# Good
func test_create_order_with_valid_data()
func test_create_order_missing_product_fails()

# Bad
func test_order()
func test_create()
```

### 3. Arrange-Act-Assert Pattern
```gdscript
func test_example():
	# Arrange - set up test data
	var user = TestHelpers.create_test_user(...)

	# Act - perform the action
	var result = DataStore.some_function(user["id"])

	# Assert - verify the result
	assert_true(result, "Should succeed")
```

### 4. One Assertion Per Test (when possible)
```gdscript
# Good - focused test
func test_order_created_with_pending_status():
	var order_id = DataStore.create_order(...)
	var order = DataStore.get_order_by_id(order_id)
	assert_eq(order["status"], "pending")

# Acceptable - related assertions
func test_order_creation():
	var order_id = DataStore.create_order(...)
	assert_gt(order_id, 0, "Should return valid ID")
	assert_true(TestHelpers.assert_order_exists(order_id), "Order should exist")
```

### 5. Test Error Cases
```gdscript
func test_create_order_with_missing_data():
	var order_id = DataStore.create_order({})
	assert_eq(order_id, -1, "Should fail with empty data")

func test_create_order_with_invalid_product():
	var order_id = DataStore.create_order({"product": ""})
	assert_eq(order_id, -1, "Should fail with empty product")
```

## Resources

- **GUT Documentation**: https://github.com/bitwes/Gut/wiki
- **Godot Testing Guide**: https://docs.godotengine.org/en/stable/tutorials/scripting/unit_testing.html
- **Migration Plan**: See `MIGRATION_PLAN.md` for testing strategy

## Contributing

When adding new features:

1. Write tests first (TDD approach)
2. Ensure all tests pass before committing
3. Update this README if adding new test categories
4. Maintain test coverage above 80% for critical paths

## Test Results

Last test run: [Date]
- Total tests: [Number]
- Passed: [Number]
- Failed: [Number]
- Coverage: [Percentage]%

---

**Happy Testing!** 🎉
