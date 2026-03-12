extends CanvasLayer
class_name InventoryMenu

signal sword_selected(sword_id: String)
signal shield_selected(shield_id: String)
signal ring_selected(ring_id: String)
signal store_purchase_requested(item_id: String)
signal menu_closed

var sword_entries: Array[Dictionary] = []
var equipped_sword_id: String = ""
var shield_entries: Array[Dictionary] = []
var equipped_shield_id: String = ""
var ring_entries: Array[Dictionary] = []
var equipped_ring_id: String = ""
var gold_total: int = 0
var store_entries: Array[Dictionary] = []

var _content_root: VBoxContainer = null
var _button_by_sword_id: Dictionary = {}
var _button_by_shield_id: Dictionary = {}
var _button_by_ring_id: Dictionary = {}
var _button_by_store_item_id: Dictionary = {}


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
	store_entry_list: Array[Dictionary] = []
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
	gold_total = maxi(0, gold_amount)
	store_entries = []
	for store_entry in store_entry_list:
		if store_entry is Dictionary:
			store_entries.append((store_entry as Dictionary).duplicate(true))
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
	panel.custom_minimum_size = Vector2(700.0, 640.0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_content_root = content

	var title := Label.new()
	title.text = "Inventory - Gear"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Click to equip gear or buy items from the store."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(subtitle)

	var gold_label := Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "Gold: %d" % maxi(0, gold_total)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.modulate = Color(1.0, 0.88, 0.44, 0.98)
	gold_label.add_theme_font_size_override("font_size", 18)
	content.add_child(gold_label)

	var separator := HSeparator.new()
	content.add_child(separator)

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

	var store_separator := HSeparator.new()
	content.add_child(store_separator)

	var store_list := VBoxContainer.new()
	store_list.name = "StoreList"
	store_list.add_theme_constant_override("separation", 8)
	content.add_child(store_list)

	var hint := Label.new()
	hint.text = "Press Tab or Esc to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.86, 0.9, 1.0, 0.92)
	content.add_child(hint)


func _rebuild_gear_lists() -> void:
	if _content_root == null or not is_instance_valid(_content_root):
		return
	var sword_list := _content_root.get_node_or_null("SwordList") as VBoxContainer
	var shield_list := _content_root.get_node_or_null("ShieldList") as VBoxContainer
	var ring_list := _content_root.get_node_or_null("RingList") as VBoxContainer
	var store_list := _content_root.get_node_or_null("StoreList") as VBoxContainer
	var gold_label := _content_root.get_node_or_null("GoldLabel") as Label
	if sword_list == null or shield_list == null or ring_list == null or store_list == null:
		return
	if gold_label != null:
		gold_label.text = "Gold: %d" % maxi(0, gold_total)
	for child in sword_list.get_children():
		child.queue_free()
	for child in shield_list.get_children():
		child.queue_free()
	for child in ring_list.get_children():
		child.queue_free()
	for child in store_list.get_children():
		child.queue_free()
	_button_by_sword_id.clear()
	_button_by_shield_id.clear()
	_button_by_ring_id.clear()
	_button_by_store_item_id.clear()

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
	shield_title.text = "Shields"
	shield_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	shield_title.modulate = Color(0.88, 0.93, 1.0, 0.95)
	shield_list.add_child(shield_title)

	if shield_entries.is_empty():
		var empty_shield := Label.new()
		empty_shield.text = "No shields found."
		empty_shield.modulate = Color(0.72, 0.78, 0.88, 0.92)
		shield_list.add_child(empty_shield)
	else:
		for shield_entry in shield_entries:
			var shield_id := String(shield_entry.get("id", ""))
			if shield_id.is_empty():
				continue
			var shield_name := String(shield_entry.get("name", shield_id))
			var shield_icon := String(shield_entry.get("icon", "SHD"))
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


func _on_sword_button_pressed(sword_id: String) -> void:
	sword_selected.emit(sword_id)


func _on_shield_button_pressed(shield_id: String) -> void:
	shield_selected.emit(shield_id)


func _on_ring_button_pressed(ring_id: String) -> void:
	ring_selected.emit(ring_id)


func _on_store_button_pressed(item_id: String) -> void:
	store_purchase_requested.emit(item_id)
