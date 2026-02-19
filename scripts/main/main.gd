extends Node2D

@onready var arena: Arena = $Arena
@onready var hud: HUD = $HUD


func _ready() -> void:
	InputConfig.ensure_actions()
	_connect_signals()
	arena.start_demo()


func _connect_signals() -> void:
	arena.player_health_changed.connect(hud.update_health)
	arena.player_xp_changed.connect(hud.update_xp)
	arena.cooldowns_changed.connect(hud.update_cooldowns)
	arena.objective_changed.connect(hud.update_objective)
	arena.item_collected.connect(hud.show_item_pickup)
	arena.player_died.connect(hud.show_defeat)
	arena.demo_won.connect(hud.show_victory)
