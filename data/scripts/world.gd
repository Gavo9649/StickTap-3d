extends Node3D


var paused = true

signal pause
signal unpause

@export var player_scene: PackedScene

@onready var main_menu = $"Menu Canvas/MainMenu"
@onready var address_entry = $"Menu Canvas/MainMenu/MarginContainer/VBoxContainer/AddressEnter"

const Player = preload("res://data/player/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func pause_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#get_tree().paused = true #In case you want to pause the game
	pause.emit()

func unpause_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#get_tree().paused = false
	unpause.emit()

func _process(_delta):
	if Input.is_action_just_released("game_pause"):
		paused = !paused
		if paused:
			pause_game()
		else:
			unpause_game()


func _on_host_button_pressed():
	main_menu.hide()
	paused = !paused
	if paused:
		pause_game()
	else:
		unpause_game()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	
	add_player(multiplayer.get_unique_id())
	
	upnp_setup()
	

func _on_join_button_pressed():
	main_menu.hide()
	paused = !paused
	if paused:
		pause_game()
	else:
		unpause_game()
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	
	
func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	#
	#var randSpawn = randf_range(0, 360)
	#player.transform.origin.x = 5 * cos(deg_to_rad(randSpawn))
	#player.transform.origin.z = 5 * sin(deg_to_rad(randSpawn))
	
func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed. Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed. Error %s" % map_result)
	
	print("Success. Join Address: %s" % upnp.query_external_address())
