@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("EthersWeb", "res://addons/cactus.godotethersweb/singletons/Ethers.gd")
	add_autoload_singleton("Contract", "res://addons/cactus.godotethersweb/singletons/Contract.gd")
	add_autoload_singleton("Calldata", "res://addons/cactus.godotethersweb/singletons/Calldata.gd")

func _exit_tree():
	remove_autoload_singleton("EthersWeb")
	remove_autoload_singleton("Contract")
	remove_autoload_singleton("Calldata")
