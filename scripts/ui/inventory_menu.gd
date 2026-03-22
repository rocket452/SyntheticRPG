extends CanvasLayer
class_name InventoryMenu

signal sword_selected(sword_id: String)
signal shield_selected(shield_id: String)
signal ring_selected(ring_id: String)
signal store_purchase_requested(item_id: String)
signal party_member_toggled(member_id: String, enabled: bool)
signal controlled_character_selected(control_id: String)
signal menu_closed

var sword_entries: Array[Dictionary] = []
var equipped_sword_id: String = ""
var shield_entries: Array[Dictionary] = []
var equipped_shield_id: String = ""
var ring_entries: Array[Dictionary] = []
var equipped_ring_id: String = ""
var boot_entries: Array[Dictionary] = []
var gold_total: int = 0
var store_entries: Array[Dictionary] = []
var party_entries: Array[Dictionary] = []
var control_entries: Array[Dictionary] = []
var controlled_character_id: String = ""
var shield_slot_title: String = "Shields"
var shield_slot_empty_text: String = "No shields found."
var shield_slot_default_icon: String = "SHD"

var _content_root: VBoxContainer = null
var _gold_label: Label = null
var _control_list_root: VBoxContainer = null
var _party_list_root: VBoxContainer = null
var _party_capacity_label: Label = null
var _button_by_sword_id: Dictionary = {}
var _button_by_shield_id: Dictionary = {}
var _button_by_ring_id: Dictionary = {}
var _button_by_store_item_id: Dictionary = {}
var _toggle_by_party_member_id: Dictionary = {}
var _button_by_control_id: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 30
	_build_ui()
	_rebuild_gear_lists()


func configure(
	entries: Array[Dictionary],
	equipped_id: String,
	shield_entry_list: Array[Dictionary] = [],
	equipped_shield: String = "",
	ring_entry_list: Array[Dictionary] = [],
	equipped_ring: String = "",
	gold_amount: int = 0,
	store_entry_list: Array[Dictionary] = [],
	party_entry_list: Array[Dictionary] = [],
	boot_entry_list: Array[Dictionary] = [],
	control_entry_list: Array[Dictionary] = [],
	control_character_id: String = "",
	shield_slot_title_text: String = "Shields",
	shield_slot_empty_label_text: String = "No shields found.",
	shield_slot_icon_text: String = "SHD"
) -> void:
	sword_entries = []
	for entry in entries:
		if entry is Dictionary:
			sword_entries.append((entry as Dictionary).duplicate(true))
	equipped_sword_id = equipped_id
	shield_entries = []
	for shield_entry in shield_entry_list:
		if shield_entry is Dictionary:
			shield_entries.append((shield_entry as Dictionary).duplicate(true))
	equipped_shield_id = equipped_shield
	ring_entries = []
	for ring_entry in ring_entry_list:
		if ring_entry is Dictionary:
			ring_entries.append((ring_entry as Dictionary).duplicate(true))
	equipped_ring_id = equipped_ring
	boot_entries = []
	for boot_entry in boot_entry_list:
		if boot_entry is Dictionary:
			boot_entries.append((boot_entry as Dictionary).duplicate(true))
	gold_total = maxi(0, gold_amount)
	store_entries = []
	for store_entry in store_entry_list:
		if store_entry is Dictionary:
			store_entries.append((store_entry as Dictionary).duplicate(true))
	party_entries = []
	for party_entry in party_entry_list:
		if party_entry is Dictionary:
			party_entries.append((party_entry as Dictionary).duplicate(true))
	control_entries = []
	for control_entry in control_entry_list:
		if control_entry is Dictionary:
			control_entries.append((control_entry as Dictionary).duplicate(true))
	controlled_character_id = control_character_id
	shield_slot_title = shield_slot_title_text if not shield_slot_title_text.strip_edges().is_empty() else "Shields"
	shield_slot_empty_text = shield_slot_empty_label_text if not shield_slot_empty_label_text.strip_edges().is_empty() else "No shields found."
	shield_slot_default_icon = shield_slot_icon_text if not shield_slot_icon_text.strip_edges().is_empty() else "SHD"
	if is_inside_tree():
		_rebuild_gear_lists()


func set_equipped_sword(sword_id: String) -> void:
	equipped_sword_id = sword_id
	_rebuild_gear_lists()


func set_equipped_shield(shield_id: String) -> void:
	equipped_shield_id = shield_id
	_rebuild_gear_lists()


func set_equipped_ring(ring_id: String) -> void:
	equipped_ring_id = ring_id
	_rebuild_gear_lists()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle") or event.is_action_pressed("ui_cancel"):
		menu_closed.emit()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.02, 0.04, 0.84)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1020.0, 640.0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var root_row := HBoxContainer.new()
	root_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_row.add_theme_constant_override("separation", 14)
	margin.add_child(root_row)

	var inventory_column := VBoxContainer.new()
	inventory_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_column.add_theme_constant_override("separation", 10)
	root_row.add_child(inventory_column)

	var divider := VSeparator.new()
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_row.add_child(divider)

	var party_column := VBoxContainer.new()
	party_column.custom_minimum_size = Vector2(300.0, 0.0)
	party_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	party_column.add_theme_constant_override("separation", 8)
	root_row.add_child(party_column)

	var title := Label.new()
	title.text = "Inventory - Gear"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	inventory_column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Click to equip gear or buy items from the store."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_column.add_child(subtitle)

	_gold_label = Label.new()
	_gold_label.text = "Gold: %d" % maxi(0, gold_total)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.modulate = Color(1.0, 0.88, 0.44, 0.98)
	_gold_label.add_theme_font_size_override("font_size", 18)
	inventory_column.add_child(_gold_label)

	var header_separator := HSeparator.new()
	inventory_column.add_child(header_separator)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_column.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_content_root = content

	var sword_list := VBoxContainer.new()
	sword_list.name = "SwordList"
	sword_list.add_theme_constant_override("separation", 8)
	content.add_child(sword_list)

	var shield_separator := HSeparator.new()
	content.add_child(shield_separator)

	var shield_list := VBoxContainer.new()
	shield_list.name = "ShieldList"
	shield_list.add_theme_constant_override("separation", 8)
	content.add_child(shield_list)

	var ring_separator := HSeparator.new()
	content.add_child(ring_separator)

	var ring_list := VBoxContainer.new()
	ring_list.name = "RingList"
	ring_list.add_theme_constant_override("separation", 8)
	content.add_child(ring_list)

	var boot_separator := HSeparator.new()
	content.add_child(boot_separator)

	var boot_list := VBoxContainer.new()
	boot_list.name = "BootList"
	boot_list.add_theme_constant_override("separation", 8)
	content.add_child(boot_list)

	var store_separator := HSeparator.new()
	content.add_child(store_separator)

	var store_list := VBoxContainer.new()
	store_list.name = "StoreList"
	store_list.add_theme_constant_override("separation", 8)
	content.add_child(store_list)

	var party_title := Label.new()
	party_title.text = "Party Selection"
	party_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	party_title.add_theme_font_size_override("font_size", 22)
	party_column.add_child(party_title)

	var party_subtitle := Label.new()
	party_subtitle.text = "Choose companions for your current group."
	party_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	party_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	party_column.add_child(party_subtitle)

	var control_title := Label.new()
	control_title.text = "Controlled Character"
	control_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	control_title.modulate = Color(0.88, 0.94, 0.98, 0.95)
	party_column.add_child(control_title)

	var control_list := VBoxContainer.new()
	control_list.name = "ControlList"
	control_list.add_theme_constant_override("separation", 8)
	party_column.add_child(control_list)
	_control_list_root = control_list

	var control_separator := HSeparator.new()
	party_column.add_child(control_separator)

	_party_capacity_label = Label.new()
	_party_capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_party_capacity_label.modulate = Color(0.94, 0.96, 0.86, 0.95)
	party_column.add_child(_party_capacity_label)

	var party_separator := HSeparator.new()
	party_column.add_child(party_separator)

	var party_list := VBoxContainer.new()
	party_list.name = "PartyList"
	party_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	party_list.add_theme_constant_override("separation", 8)
	party_column.add_child(party_list)
	_party_list_root = party_list

	var party_hint := Label.new()
	party_hint.text = "Player is always included. Changes apply immediately in normal encounters."
	party_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	party_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	party_hint.modulate = Color(0.82, 0.9, 1.0, 0.88)
	party_column.add_child(party_hint)

	var hint := Label.new()
	hint.text = "Press Tab or Esc to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.86, 0.9, 1.0, 0.92)
	inventory_column.add_child(hint)


func _rebuild_gear_lists() -> void:
	if _content_root == null \
		or not is_instance_valid(_content_root) \
		or _control_list_root == null \
		or not is_instance_valid(_control_list_root) \
		or _party_list_root == null \
		or not is_instance_valid(_party_list_root):
		return
	var sword_list := _content_root.get_node_or_null("SwordList") as VBoxContainer
	var shield_list := _content_root.get_node_or_null("ShieldList") as VBoxContainer
	var ring_list := _content_root.get_node_or_null("RingList") as VBoxContainer
	var boot_list := _content_root.get_node_or_null("BootList") as VBoxContainer
	var store_list := _content_root.get_node_or_null("StoreList") as VBoxContainer
	if sword_list == null or shield_list == null or ring_list == null or boot_list == null or store_list == null:
		return
	if _gold_label != null and is_instance_valid(_gold_label):
		_gold_label.text = "Gold: %d" % maxi(0, gold_total)
	for child in sword_list.get_children():
		child.queue_free()
	for child in shield_list.get_children():
		child.queue_free()
	for child in ring_list.get_children():
		child.queue_free()
	for child in boot_list.get_children():
		child.queue_free()
	for child in store_list.get_children():
		child.queue_free()
	for child in _control_list_root.get_children():
		child.queue_free()
	for child in _party_list_root.get_children():
		child.queue_free()
	_button_by_sword_id.clear()
	_button_by_shield_id.clear()
	_button_by_ring_id.clear()
	_button_by_store_item_id.clear()
	_toggle_by_party_member_id.clear()
	_button_by_control_id.clear()

	var sword_title := Label.new()
	sword_title.text = "Swords"
	sword_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sword_title.modulate = Color(0.88, 0.93, 1.0, 0.95)
	sword_list.add_child(sword_title)

	for entry in sword_entries:
		var sword_id := String(entry.get("id", ""))
		if sword_id.is_empty():
			continue
		var sword_name := String(entry.get("name", sword_id))
		var sword_icon := String(entry.get("icon", "SWD"))
		var sword_description := String(entry.get("description", ""))
		var equipped := sword_id == equipped_sword_id
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 52.0)
		button.toggle_mode = false
		button.text = "%s  %s%s\n%s" % [
			sword_icon,
			sword_name,
			"   [EQUIPPED]" if equipped else "",
			sword_description
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_sword_button_pressed.bind(sword_id))
		if equipped:
			button.modulate = Color(0.72, 1.0, 0.78, 1.0)
		sword_list.add_child(button)
		_button_by_sword_id[sword_id] = button

	var shield_title := Label.new()
	shield_title.text = shield_slot_title
	shield_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	shield_title.modulate = Color(0.88, 0.93, 1.0, 0.95)
	shield_list.add_child(shield_title)

	if shield_entries.is_empty():
		var empty_shield := Label.new()
		empty_shield.text = shield_slot_empty_text
		empty_shield.modulate = Color(0.72, 0.78, 0.88, 0.92)
		shield_list.add_child(empty_shield)
	else:
		for shield_entry in shield_entries:
			var shield_id := String(shield_entry.get("id", ""))
			if shield_id.is_empty():
				continue
			var shield_name := String(shield_entry.get("name", shield_id))
			var shield_icon := String(shield_entry.get("icon", shield_slot_default_icon))
			var shield_description := String(shield_entry.get("description", ""))
			var shield_equipped := shield_id == equipped_shield_id
			var shield_button := Button.new()
			shield_button.custom_minimum_size = Vector2(0.0, 52.0)
			shield_button.toggle_mode = false
			shield_button.text = "%s  %s%s\n%s" % [
				shield_icon,
				shield_name,
				"   [EQUIPPED]" if shield_equipped else "",
				shield_description
			]
			shield_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			shield_button.pressed.connect(_on_shield_button_pressed.bind(shield_id))
			if shield_equipped:
				shield_button.modulate = Color(0.64, 0.96, 1.0, 1.0)
			shield_list.add_child(shield_button)
			_button_by_shield_id[shield_id] = shield_button

	var ring_title := Label.new()
	ring_title.text = "Rings"
	ring_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ring_title.modulate = Color(0.96, 0.9, 1.0, 0.95)
	ring_list.add_child(ring_title)

	if ring_entries.is_empty():
		var empty_ring := Label.new()
		empty_ring.text = "No rings found."
		empty_ring.modulate = Color(0.72, 0.78, 0.88, 0.92)
		ring_list.add_child(empty_ring)
	else:
		for ring_entry in ring_entries:
			var ring_id := String(ring_entry.get("id", ""))
			if ring_id.is_empty():
				continue
			var ring_name := String(ring_entry.get("name", ring_id))
			var ring_icon := String(ring_entry.get("icon", "RNG"))
			var ring_description := String(ring_entry.get("description", ""))
			var ring_equipped := ring_id == equipped_ring_id
			var ring_button := Button.new()
			ring_button.custom_minimum_size = Vector2(0.0, 52.0)
			ring_button.toggle_mode = false
			ring_button.text = "%s  %s%s\n%s" % [
				ring_icon,
				ring_name,
				"   [EQUIPPED]" if ring_equipped else "",
				ring_description
			]
			ring_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			ring_button.pressed.connect(_on_ring_button_pressed.bind(ring_id))
			if ring_equipped:
				ring_button.modulate = Color(0.92, 0.78, 1.0, 1.0)
			ring_list.add_child(ring_button)
			_button_by_ring_id[ring_id] = ring_button

	var boot_title := Label.new()
	boot_title.text = "Boots"
	boot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	boot_title.modulate = Color(0.82, 0.98, 0.9, 0.95)
	boot_list.add_child(boot_title)

	if boot_entries.is_empty():
		var empty_boots := Label.new()
		empty_boots.text = "No boots equipped."
		empty_boots.modulate = Color(0.72, 0.78, 0.88, 0.92)
		boot_list.add_child(empty_boots)
	else:
		for boot_entry in boot_entries:
			var boot_id := String(boot_entry.get("id", ""))
			if boot_id.is_empty():
				continue
			var boot_name := String(boot_entry.get("name", boot_id))
			var boot_icon := String(boot_entry.get("icon", "BTS"))
			var boot_description := String(boot_entry.get("description", ""))
			var boot_equipped := bool(boot_entry.get("equipped", true))
			var boot_label := Label.new()
			boot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			boot_label.custom_minimum_size = Vector2(0.0, 44.0)
			boot_label.text = "%s  %s%s\n%s" % [
				boot_icon,
				boot_name,
				"   [EQUIPPED]" if boot_equipped else "",
				boot_description
			]
			boot_label.modulate = Color(0.8, 0.96, 0.86, 0.95) if boot_equipped else Color(0.74, 0.82, 0.9, 0.92)
			boot_list.add_child(boot_label)

	var store_title := Label.new()
	store_title.text = "Store"
	store_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	store_title.modulate = Color(1.0, 0.88, 0.52, 0.95)
	store_list.add_child(store_title)

	if store_entries.is_empty():
		var empty_store := Label.new()
		empty_store.text = "Store unavailable."
		empty_store.modulate = Color(0.72, 0.78, 0.88, 0.92)
		store_list.add_child(empty_store)
	else:
		for store_entry in store_entries:
			var item_id := String(store_entry.get("item_id", ""))
			if item_id.is_empty():
				continue
			var item_name := String(store_entry.get("name", item_id))
			var item_description := String(store_entry.get("description", ""))
			var item_price := maxi(0, int(store_entry.get("price", 0)))
			var owned := bool(store_entry.get("owned", false))
			var store_button := Button.new()
			store_button.custom_minimum_size = Vector2(0.0, 54.0)
			store_button.toggle_mode = false
			store_button.disabled = owned or item_price <= 0
			store_button.text = "%s  %s\n%s" % [
				"[OWNED]" if owned else ("[BUY %dG]" % item_price),
				item_name,
				item_description
			]
			store_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			store_button.pressed.connect(_on_store_button_pressed.bind(item_id))
			if owned:
				store_button.modulate = Color(0.74, 0.86, 0.98, 0.9)
			store_list.add_child(store_button)
			_button_by_store_item_id[item_id] = store_button

	if control_entries.is_empty():
		var no_control := Label.new()
		no_control.text = "No controllable characters available."
		no_control.modulate = Color(0.72, 0.78, 0.88, 0.92)
		_control_list_root.add_child(no_control)
	else:
		for control_entry in control_entries:
			var control_id := String(control_entry.get("id", ""))
			if control_id.is_empty():
				continue
			var control_name := String(control_entry.get("name", control_id))
			var control_description := String(control_entry.get("description", ""))
			var selected := bool(control_entry.get("selected", control_id == controlled_character_id))
			var available := bool(control_entry.get("available", true))
			var control_button := Button.new()
			control_button.custom_minimum_size = Vector2(0.0, 48.0)
			control_button.toggle_mode = false
			control_button.disabled = not available
			control_button.text = "%s%s\n%s" % [
				control_name,
				"   [CONTROLLED]" if selected else "",
				control_description
			]
			control_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			control_button.pressed.connect(_on_control_button_pressed.bind(control_id))
			if selected:
				control_button.modulate = Color(0.82, 0.96, 1.0, 1.0)
			_control_list_root.add_child(control_button)
			_button_by_control_id[control_id] = control_button

	var party_title := Label.new()
	party_title.text = "Companions"
	party_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	party_title.modulate = Color(0.88, 0.94, 0.98, 0.95)
	_party_list_root.add_child(party_title)

	var max_party_size := 3
	var max_companion_count := 2
	var enabled_companion_count := 0
	var active_party_size := 1
	if not party_entries.is_empty():
		var summary_entry := party_entries[0]
		max_party_size = maxi(1, int(summary_entry.get("max_party_size", max_party_size)))
		max_companion_count = maxi(0, int(summary_entry.get("max_companion_count", max_companion_count)))
		enabled_companion_count = maxi(0, int(summary_entry.get("enabled_companion_count", enabled_companion_count)))
		active_party_size = maxi(1, int(summary_entry.get("active_party_size", active_party_size)))
	if _party_capacity_label != null and is_instance_valid(_party_capacity_label):
		_party_capacity_label.text = "Party Size: %d/%d  (Player + %d/%d companions)" % [
			active_party_size,
			max_party_size,
			enabled_companion_count,
			max_companion_count
		]
		if active_party_size >= max_party_size:
			_party_capacity_label.modulate = Color(1.0, 0.86, 0.58, 0.98)
		else:
			_party_capacity_label.modulate = Color(0.84, 0.96, 0.86, 0.95)

	if party_entries.is_empty():
		var no_party := Label.new()
		no_party.text = "No companions available."
		no_party.modulate = Color(0.72, 0.78, 0.88, 0.92)
		_party_list_root.add_child(no_party)
	else:
		for party_entry in party_entries:
			var member_id := String(party_entry.get("id", ""))
			if member_id.is_empty():
				continue
			var member_name := String(party_entry.get("name", member_id))
			var member_description := String(party_entry.get("description", ""))
			var enabled := bool(party_entry.get("enabled", false))
			var active := bool(party_entry.get("active", false))
			var available := bool(party_entry.get("available", true))
			var blocked_by_party_limit := bool(party_entry.get("blocked_by_party_limit", false))

			var card := PanelContainer.new()
			_party_list_root.add_child(card)

			var card_style := StyleBoxFlat.new()
			card_style.set_corner_radius_all(5)
			card_style.set_border_width_all(2)
			if not available or blocked_by_party_limit:
				card_style.bg_color = Color(0.10, 0.11, 0.15, 0.82)
				card_style.border_color = Color(0.28, 0.32, 0.42, 0.55)
			elif enabled:
				card_style.bg_color = Color(0.10, 0.22, 0.14, 0.92)
				card_style.border_color = Color(0.38, 0.88, 0.52, 0.92)
			else:
				card_style.bg_color = Color(0.11, 0.14, 0.20, 0.88)
				card_style.border_color = Color(0.30, 0.38, 0.52, 0.72)
			card.add_theme_stylebox_override("panel", card_style)

			var card_margin := MarginContainer.new()
			card_margin.add_theme_constant_override("margin_left", 10)
			card_margin.add_theme_constant_override("margin_right", 10)
			card_margin.add_theme_constant_override("margin_top", 8)
			card_margin.add_theme_constant_override("margin_bottom", 8)
			card.add_child(card_margin)

			var card_content := VBoxContainer.new()
			card_content.add_theme_constant_override("separation", 4)
			card_margin.add_child(card_content)

			var toggle := CheckBox.new()
			toggle.text = "%s%s" % [member_name, "   [ACTIVE]" if active else ""]
			toggle.button_pressed = enabled
			toggle.disabled = (not available) or blocked_by_party_limit
			toggle.toggled.connect(_on_party_toggle_toggled.bind(member_id))
			toggle.add_theme_font_size_override("font_size", 14)
			toggle.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0, 1.0))
			toggle.add_theme_color_override("font_pressed_color", Color(0.48, 0.98, 0.62, 1.0))
			toggle.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.88, 1.0))
			toggle.add_theme_color_override("font_hover_pressed_color", Color(0.56, 1.0, 0.68, 1.0))
			toggle.add_theme_color_override("font_disabled_color", Color(0.46, 0.50, 0.60, 0.72))
			card_content.add_child(toggle)
			_toggle_by_party_member_id[member_id] = toggle

			var desc := Label.new()
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if not available:
				desc.modulate = Color(0.56, 0.60, 0.72, 0.82)
				desc.text = "%s\nUnavailable in this encounter." % member_description
			elif blocked_by_party_limit:
				desc.modulate = Color(0.84, 0.76, 0.52, 0.88)
				desc.text = "%s\nParty full: disable one companion to add this one." % member_description
			else:
				desc.modulate = Color(0.72, 0.80, 0.94, 0.88)
				desc.text = member_description
			card_content.add_child(desc)

	for child in sword_list.get_children():
		var candidate := child as Button
		if candidate == null:
			continue
		candidate.grab_focus()
		return
	for child in shield_list.get_children():
		var shield_candidate := child as Button
		if shield_candidate == null:
			continue
		shield_candidate.grab_focus()
		return
	for child in ring_list.get_children():
		var ring_candidate := child as Button
		if ring_candidate == null:
			continue
		ring_candidate.grab_focus()
		return
	for child in store_list.get_children():
		var store_candidate := child as Button
		if store_candidate == null:
			continue
		store_candidate.grab_focus()
		return
	for control_variant in _button_by_control_id.values():
		var control_candidate := control_variant as Button
		if control_candidate == null:
			continue
		control_candidate.grab_focus()
		return
	for toggle_variant in _toggle_by_party_member_id.values():
		var party_candidate := toggle_variant as CheckBox
		if party_candidate == null:
			continue
		party_candidate.grab_focus()
		return


func _on_control_button_pressed(control_id: String) -> void:
	controlled_character_selected.emit(control_id)


func _on_party_toggle_toggled(enabled: bool, member_id: String) -> void:
	party_member_toggled.emit(member_id, enabled)


func _on_sword_button_pressed(sword_id: String) -> void:
	sword_selected.emit(sword_id)


func _on_shield_button_pressed(shield_id: String) -> void:
	shield_selected.emit(shield_id)


func _on_ring_button_pressed(ring_id: String) -> void:
	ring_selected.emit(ring_id)


func _on_store_button_pressed(item_id: String) -> void:
	store_purchase_requested.emit(item_id)
