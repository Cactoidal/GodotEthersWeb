extends Control


@onready var ERC20 = Contract.ERC20

func _ready():
	connect_buttons()

func connect_buttons():
	$ConnectWallet.connect("pressed", EthersWeb.connect_wallet)
	$TestSend.connect("pressed", test_transfer)
	#$TestRead.connect("pressed", test_get_wallet_info)
	#$TestRead.connect("pressed", test_read)
	$TestRead.connect("pressed", test_get_erc20_info)
	$TestWrite.connect("pressed", test_sign)
	#$TestWrite.connect("pressed", listen_test)
	#$TestRead.connect("pressed", stop_listen_test)
	#$TestWrite.connect("pressed", example_format_typed)
	#$TestWrite.connect("pressed", test_write)
	#$TestWrite.connect("pressed", test_add_erc20)
	#$TestWrite.connect("pressed", test_add_chain)
	
	EthersWeb.register_transaction_log(self, "test_tx_receipt")
	EthersWeb.register_event_stream(self, "test_event_log")


func test_tx_receipt(callback):
	print(callback)

func test_event_log(callback):
	print(callback)



var test_recipient = "0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba"

func test_add_chain():
	EthersWeb.add_chain("Avalanche Mainnet")

func test_transfer():
	#var recipient = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
	var amount = "0"
	var callback_args = {"test": "OOoOOooOOoo"}
	var network = "Sonic Mainnet"
	#var network = "Ethereum Sepolia"
		
	var callback = EthersWeb.create_callback(self, "transaction_callback", callback_args)
	EthersWeb.transfer(network, test_recipient, amount, callback)
	

func transaction_callback(callback):
	$Data.text = callback["test"]


func test_read():
	var network = "Ethereum Sepolia"
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	var callback = EthersWeb.create_callback(self, "read_result")
	EthersWeb.read_from_contract(network, token_address, ERC20, "name", [], callback)

func read_result(callback):
	var result = callback["result"]
	$Data.text = result[0]

	
func test_write():
	var network = "Ethereum Sepolia"
	var callback = EthersWeb.create_callback(self, "show_receipt")
	
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	
	#erc20_transfer(network, token_address, test_recipient, "0", callback)
	EthersWeb.send_transaction(network, token_address, ERC20, "transfer", ["0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045", "0"])

# Tx logging works, but I need to figure out
# a graceful way to handle callbacks
func show_receipt(callback):
	var _tx_thing = callback["result"]
	
	var tx_thing = JSON.parse_string(_tx_thing)
	
	if "hash" in tx_thing.keys():
		print(tx_thing["hash"])
	else:
		print(tx_thing["transactionHash"])

	
	
func test_get_wallet_info():
	var callback = EthersWeb.create_callback(self, "show_wallet_info")
	EthersWeb.get_connected_wallet_info(callback)

func show_wallet_info(callback):
	$Data.text = callback["result"][0]
	$Data2.text = callback["result"][1]
	print(callback["result"][2])


func test_get_erc20_info():
	var network = "Ethereum Sepolia"
	var callback = EthersWeb.create_callback(self, "show_erc20_info")
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	
	EthersWeb.erc20_info(network, token_address, callback)

func show_erc20_info(callback):
	$Data.text = callback["result"][0]
	$Data2.text = callback["result"][3]


func test_sign():
	var callback = EthersWeb.create_callback(self, "show_signature")
	
	var message = "hello"
	
	EthersWeb.sign_message(message, callback)


func show_signature(callback):
	$Data.text = callback["result"]


func test_add_erc20():
	var network = "Ethereum Sepolia"
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	EthersWeb.add_erc20(network, token_address, "LINK", 18)



func listen_test():
	var network = "Ethereum Mainnet"
	var callback = EthersWeb.create_callback(self, "show_event")
	
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	
	EthersWeb.listen_for_event(network, token_address, JSON.stringify(ERC20), "Transfer", callback)

func show_event(callback):
	pass


func stop_listen_test():
	var network = "Ethereum Mainnet"
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	var event = "Transfer"
	EthersWeb.end_listen(network, token_address, JSON.stringify(ERC20), event)


func example_format_typed():
	var domain := {
		"name": "MyDapp",
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
