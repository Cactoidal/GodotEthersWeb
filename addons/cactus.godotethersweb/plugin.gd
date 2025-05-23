@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("EthersWeb", "res://addons/cactus.godotethersweb/singletons/Ethers.gd")
	add_autoload_singleton("Contract", "res://addons/cactus.godotethersweb/singletons/Contract.gd")

func _exit_tree():
	remove_autoload_singleton("EthersWeb")
	remove_autoload_singleton("Contract")
