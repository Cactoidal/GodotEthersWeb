extends Control

var window = EthersWeb.window

var ui_callback = "{}"
var wallet_callback = JavaScriptBridge.create_callback(wallet_detected)
var button_y_displace = 0

var connector_button = preload("res://addons/cactus.godotethersweb/examples/ConnectorButton.tscn")


func _ready():
	window.walletBridge.detectWallets(wallet_callback)


func wallet_detected(callback):
	if callback:
		create_button(callback[0])


func create_button(button_name):
	var new_button = connector_button.instantiate()
	new_button.text = button_name
	$Backdrop/Buttons.add_child(new_button)
	new_button.position.y += button_y_displace
	button_y_displace += 40
	
	new_button.connect("pressed", connect_wallet.bind(button_name))


func connect_wallet(button_name):
	window.walletBridge.connectWallet(button_name)
	EthersWeb.connect_wallet(ui_callback)
	queue_free()
