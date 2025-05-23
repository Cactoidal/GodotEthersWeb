extends Control

@onready var ERC20 = Contract.ERC20

var connected_wallet
var listening = false

var test_recipient = "0xdef456def456def456def456def456def456def4"

func _ready():
	connect_buttons()

func connect_buttons():
	$ConnectWallet.connect("pressed", test_connect)
	$WalletInfo.connect("pressed", test_get_wallet_info)
	$ContractRead.connect("pressed", test_read)
	$ERC20Info.connect("pressed", test_get_erc20_info)
	$Sign.connect("pressed", test_sign)
	$SignTyped.connect("pressed", example_format_typed)
	$Transfer.connect("pressed", test_transfer)
	$SendLink.connect("pressed", test_write)
	$EventStart.connect("pressed", listen_test)
	$EventStop.connect("pressed", stop_listen_test)

	#$TestWrite.connect("pressed", test_add_erc20)
	#$TestWrite.connect("pressed", test_add_chain)
	
	EthersWeb.register_transaction_log(self, "test_tx_receipt")
	EthersWeb.register_event_stream(self, "test_event_log")


func test_connect():
	var callback = EthersWeb.create_callback(self, "get_account_list")
	EthersWeb.connect_wallet(callback)

func get_account_list(callback):
	if has_error(callback):
		return
		
	connected_wallet = callback["result"][0]
	print_log(connected_wallet + " Connected")
	


func test_get_wallet_info():
	var callback = EthersWeb.create_callback(self, "show_wallet_info")
	EthersWeb.get_connected_wallet_info(callback)

func show_wallet_info(callback):
	if has_error(callback):
		return
		
	var info =  callback["result"]
	
	var txt = "Address " + info["address"] + "\n"
	txt += "ChainID " + info["chainId"] + "\n"
	txt += "Gas Balance " + info["balance"]
	print_log(txt)



func test_read():
	var network = "Ethereum Sepolia"
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	var callback = EthersWeb.create_callback(self, "read_result")
	EthersWeb.read_from_contract(network, token_address, ERC20, "name", [], callback)

func read_result(callback):
	if has_error(callback):
		return
		
	var result = callback["result"]
	# Contract reads always come back as an array
	print_log(result[0])



func test_get_erc20_info():
	var network = "Ethereum Sepolia"
	var callback = EthersWeb.create_callback(self, "show_erc20_info")
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	
	EthersWeb.erc20_info(network, token_address, callback)

func show_erc20_info(callback):
	if has_error(callback):
		return
		
	var info = callback["result"]
	
	var txt = "Name: " + info["name"] + "\n"
	txt += "Symbol: " + info["symbol"] + "\n"
	txt += "Decimals: " + str(info["decimals"]) + "\n"
	txt += "Your Balance: " + str(info["balance"])
	print_log(txt)




func test_sign():
	var callback = EthersWeb.create_callback(self, "show_signature")
	
	var message = "Hello from Godot!"
	
	EthersWeb.sign_message(message, callback)


func example_format_typed():
	var domain := {
		"name": "GodotEthersWeb",
		"version": "1",
		"chainId": 1,
		"verifyingContract": "0xabc123abc123abc123abc123abc123abc123abcd"
	}

	var types := {
		"Person": [
			{ "name": "name", "type": "string" },
			{ "name": "wallet", "type": "address" }
		]
	}

	var value := {
		"name": "Alice",
		"wallet": "0xdef456def456def456def456def456def456def4"
	}

	var callback = EthersWeb.create_callback(self, "show_signature")
	EthersWeb.sign_typed(domain, types, value, callback)


func show_signature(callback):
	if has_error(callback):
		return
	
	print_log("Signature: " + callback["result"])



func test_transfer():
	var amount = "0"
	var network = "Ethereum Sepolia"
		
	var callback = EthersWeb.create_callback(self, "transaction_callback")
	EthersWeb.transfer(network, test_recipient, amount, callback)
	


func test_write():
	var network = "Ethereum Sepolia"
	var callback = EthersWeb.create_callback(self, "transaction_callback")
	
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	
	# This commented function does the same thing 
	#erc20_transfer(network, token_address, test_recipient, "0", callback)
	EthersWeb.send_transaction(network, token_address, ERC20, "transfer", [test_recipient, "0"], "0", callback)


func transaction_callback(callback):
	if has_error(callback):
		return
	
	print_log("Tx Hash: " + callback["result"]["hash"])


func listen_test():
	var network = "Ethereum Mainnet"
	var callback = EthersWeb.create_callback(self, "show_listen")
	
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	
	EthersWeb.listen_for_event(network, token_address, JSON.stringify(ERC20), "Transfer", callback)

func show_listen(callback):
	if has_error(callback):
		return
	$ListenNotice.visible = true


func stop_listen_test():
	var network = "Ethereum Mainnet"
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	var event = "Transfer"
	var callback = EthersWeb.create_callback(self, "stop_listen")
	EthersWeb.end_listen(network, token_address, JSON.stringify(ERC20), event, callback)


func stop_listen(callback):
	if has_error(callback):
		return
	$ListenNotice.visible = false




func test_add_chain():
	EthersWeb.add_chain("Avalanche Mainnet")

func test_add_erc20():
	var network = "Ethereum Sepolia"
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	EthersWeb.add_erc20(network, token_address, "LINK", 18)


func test_tx_receipt(tx_receipt):

	var hash = tx_receipt["hash"]
	var status = str(tx_receipt["status"])
	
	var txt = "Tx: " + hash + "\nStatus: " + status
	
	if status == "1":
		var blockNumber = str(tx_receipt["blockNumber"])
		txt += "\nIncluded in block " + blockNumber
	
	print_log(txt)
	


func test_event_log(event):
	print_log("Event: " + event["sender"] + " sent to\n" + event["value"])

func print_log(txt):
	$Log.text += txt + "\n___________________________________\n"
	$Log.scroll_vertical = $Log.get_v_scroll_bar().max_value

func has_error(callback):
	if "error_code" in callback.keys():
		var txt = "Error " + str(callback["error_code"]) + ": " + callback["error_message"]
		print_log(txt)
		return true
