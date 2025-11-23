extends Window

# Popup for adding/editing suppliers

var editing_supplier = null

func _ready():
	%CancelBtn.pressed.connect(_on_cancel_pressed)
	%SaveBtn.pressed.connect(_on_save_pressed)

func populate_supplier(supplier: Dictionary):
	editing_supplier = supplier
	%NameInput.text = supplier.name
	%ContactInput.text = supplier.contact
	%PNInput.text = supplier.get("pn", "")
	%NotesInput.text = supplier.notes
	title = "Edit Supplier"
	%SaveBtn.text = "Save Changes"

func clear_form():
	editing_supplier = null
	%NameInput.text = ""
	%ContactInput.text = ""
	%PNInput.text = ""
	%NotesInput.text = ""
	title = "New Supplier"
	%SaveBtn.text = "Create Supplier"
	%ErrorLabel.hide()

func _on_cancel_pressed():
	hide()

func _on_save_pressed():
	var supplier_name = %NameInput.text.strip_edges()
	var contact = %ContactInput.text.strip_edges()
	var pn = %PNInput.text.strip_edges()
	var notes = %NotesInput.text.strip_edges()

	if supplier_name == "":
		show_error("Supplier name is required")
		return

	if editing_supplier:
		# Update existing
		var updates = {
			"name": supplier_name,
			"contact": contact,
			"pn": pn,
			"notes": notes
		}
		DataStore.update_supplier(editing_supplier.id, updates)
	else:
		# Create new
		DataStore.create_supplier(supplier_name, contact, pn, notes)

	hide()
	get_parent().load_suppliers()

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
