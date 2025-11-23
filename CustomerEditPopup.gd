extends Window

# Popup for adding/editing customers

var editing_customer = null

func _ready():
	%CancelBtn.pressed.connect(_on_cancel_pressed)
	%SaveBtn.pressed.connect(_on_save_pressed)

func populate_customer(customer: Dictionary):
	editing_customer = customer
	%NameInput.text = customer.name
	%FullNameInput.text = customer.full_name
	%ContactInput.text = customer.contact
	%NotesInput.text = customer.notes
	title = "Edit Customer"
	%SaveBtn.text = "Save Changes"

func clear_form():
	editing_customer = null
	%NameInput.text = ""
	%FullNameInput.text = ""
	%ContactInput.text = ""
	%NotesInput.text = ""
	title = "New Customer"
	%SaveBtn.text = "Create Customer"
	%ErrorLabel.hide()

func _on_cancel_pressed():
	hide()

func _on_save_pressed():
	var name = %NameInput.text.strip_edges()
	var full_name = %FullNameInput.text.strip_edges()
	var contact = %ContactInput.text.strip_edges()
	var notes = %NotesInput.text.strip_edges()

	if name == "":
		show_error("Customer name is required")
		return

	if full_name == "":
		show_error("Full name is required")
		return

	if editing_customer:
		# Update existing
		var updates = {
			"name": name,
			"full_name": full_name,
			"contact": contact,
			"notes": notes
		}
		DataStore.update_customer(editing_customer.id, updates)
	else:
		# Create new
		DataStore.create_customer(name, full_name, contact, notes)

	hide()
	get_parent().load_customers()

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
