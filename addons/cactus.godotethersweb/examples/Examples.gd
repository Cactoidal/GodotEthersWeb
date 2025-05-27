extends Control

@onready var ERC20 = Contract.ERC20

var connected_wallet
var listening = false

var test_recipient = "0xdef456def456def456def456def456def456def4"

func _ready():
	connect_buttons()

func connect_buttons():
	$ConnectWallet.connect("pressed", connect_wallet)
	$WalletInfo.connect("pressed", get_wallet_info)
	
	$ContractRead.connect("pressed", read_from_contract)
	$ERC20Info.connect("pressed", get_erc20_info)
	
	$Sign.connect("pressed", sign_message)
	$SignTyped.connect("pressed", example_format_typed)
	
	$MintBnM.connect("pressed", mint_sepolia_bnm)
	$ApproveRouter.connect("pressed", approve_router)
	$CCIPSend.connect("pressed", example_ccip_send)
	
	$EventStart.connect("pressed", event_listen)
	$EventStop.connect("pressed", stop_event_listen)
	
	# CCIP Listen
	
	
	
	#$Transfer.connect("pressed", test_transfer)
	#$AddERC20.connect("pressed", add_erc20)
	#$AddChain.connect("pressed", add_chain)
	#$ContractRead.connect("pressed", get_onramp)
	#$ContractRead.connect("pressed", get_offramps)
	#$BigIntMath.connect("pressed", big_int_math)
	
	EthersWeb.register_transaction_log(self, "receive_tx_receipt")
	EthersWeb.register_event_stream(self, "receive_event_log")


func connect_wallet():
	var callback = EthersWeb.create_callback(self, "got_account_list")
	EthersWeb.connect_wallet(callback)

func got_account_list(callback):
	if has_error(callback):
		return
		
	connected_wallet = callback["result"][0]
	print_log(connected_wallet + " Connected")
	


func get_wallet_info():
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



func read_from_contract():
	var network = "Ethereum Sepolia"
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	
	# You can send key:value pairs in your callback, to be used
	# in the callback function
	var callback = EthersWeb.create_callback(self, "got_name", {"token_address": token_address, "network": network})
	var data = EthersWeb.get_calldata(ERC20, "name", [])
	
	EthersWeb.read_from_contract(network, token_address, data, callback)
	

func got_name(callback):
	if has_error(callback):
		return
		
	# Contract reads always come back as an array
	var token_name = callback["result"][0]
	
	# Using callback values
	var network = callback["network"]
	var token_address = callback["token_address"]
	
	print_log("ERC20 Token " + token_address + " on " + network + " is named " + token_name)


func get_erc20_info():
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




func sign_message():
	var callback = EthersWeb.create_callback(self, "show_signature")
	
	var message = "Hello from Godot!"
	
	EthersWeb.sign_message(message, callback)


func example_format_typed():
	var network = "Ethereum Sepolia"
	var chainId = EthersWeb.default_network_info[network]["chainId"]
	
	var domain := {
		"name": "GodotEthersWeb",
		"version": "1",
		"chainId": chainId,
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
	
	EthersWeb.sign_typed(chainId, domain, types, value, callback)


func show_signature(callback):
	if has_error(callback):
		return
	
	print_log("Signature: " + callback["result"])



func test_transfer():
	
	# Note that numbers are always passed as strings.  To convert from
	# decimal to BigNumber format, use EthersWeb.convert_to_bignum()
	var amount = EthersWeb.convert_to_bignum("0", 18)
	var network = "Ethereum Sepolia"
		
	var callback = EthersWeb.create_callback(self, "transaction_callback")
	EthersWeb.transfer(network, test_recipient, amount, callback)
	


func approve_router():
	var amount = EthersWeb.convert_to_bignum("0", 18)
	
	var network = "Ethereum Sepolia"
	var callback = EthersWeb.create_callback(self, "transaction_callback")
	
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	
	var router = EthersWeb.default_network_info[network]["ccipRouter"]
	var bnm_contract = "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05"
	
	EthersWeb.erc20_approve(network, bnm_contract, router, "MAX", callback)



func transaction_callback(callback):
	if has_error(callback):
		return
	
	print_log("Tx Hash: " + callback["result"]["hash"])



func receive_tx_receipt(tx_receipt):

	var hash = tx_receipt["hash"]
	var status = str(tx_receipt["status"])
	
	var txt = "Tx: " + hash + "\nStatus: " + status
	
	if status == "1":
		var blockNumber = str(tx_receipt["blockNumber"])
		txt += "\nIncluded in block " + blockNumber
	
	print_log(txt)


func event_listen():
	var network = "Ethereum Mainnet"
	var wss_node = "wss://ethereum-rpc.publicnode.com"
	var callback = EthersWeb.create_callback(self, "show_listen")
	
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	
	EthersWeb.listen_for_event(network, wss_node, token_address, JSON.stringify(ERC20), "Transfer", callback)


func show_listen(callback):
	if has_error(callback):
		return
	$ListenNotice.visible = true


func stop_event_listen():
	var network = "Ethereum Mainnet"
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	var event = "Transfer"
	var callback = EthersWeb.create_callback(self, "stopped_listen")
	EthersWeb.end_listen(network, token_address, JSON.stringify(ERC20), event, callback)


func stopped_listen(callback):
	if has_error(callback):
		return
	$ListenNotice.visible = false


func receive_event_log(_args):
	var args = JSON.parse_string(_args)
	
	# Manually decoding event
	var _from = args.topics[1]
	var from = Calldata.abi_decode([{"type": "address"}], _from)[0]
	
	var _to = args.topics[2]
	var to = Calldata.abi_decode([{"type": "address"}], _to)[0]
	
	var _value = args.data
	var value = Calldata.abi_decode([{"type": "uint256"}], _value)[0]

	# You can convert the BigNumber into a decimal value if you wish
	var smallnum = EthersWeb.convert_to_smallnum(value)

	var txt = from + " sent " + str(smallnum) + " LINK to " + to
	print_log(txt)
	


func print_log(txt):
	$Log.text += txt + "\n___________________________________\n"
	$Log.scroll_vertical = $Log.get_v_scroll_bar().max_value

func has_error(callback):
	if "error_code" in callback.keys():
		var txt = "Error " + str(callback["error_code"]) + ": " + callback["error_message"]
		print_log(txt)
		return true


func add_chain():
	EthersWeb.add_chain("Avalanche Mainnet")

func add_erc20():
	var network = "Ethereum Sepolia"
	var token_address = EthersWeb.default_network_info[network]["chainlinkToken"]
	EthersWeb.add_erc20(network, token_address, "LINK", 18)

func big_int_math():
	var num1 = "2000000000000000000000000000000000"
	var num2 = "4000500000000000001000000002000001"
	var result = EthersWeb.big_int_math(num1, "ADD", num2)
	#var result = EthersWeb.big_int_math(num1, "MULTIPLY", num2)
	#var result = EthersWeb.big_int_math(num2, "DIVIDE", num1)
	
	#var result = EthersWeb.big_int_math(num2, "GREATER THAN", num1)
	#var result = EthersWeb.big_int_math(num2, "LESS THAN", num1)
	print_log(str(result))



### CCIP

func mint_sepolia_bnm():
	if !connected_wallet:
		print_log("Please connect your wallet")
		return
	
	var data = EthersWeb.get_calldata(Contract.BnM, "drip", [connected_wallet])
	var bnm_contract = "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05"
	
	EthersWeb.send_transaction(
		"Ethereum Sepolia",
		bnm_contract,
		data
	)
	


func example_ccip_send():
	if !connected_wallet:
		print_log("Please connect your wallet")
		return
	
	var from_network = "Ethereum Sepolia"
	var to_network = "Avalanche Fuji"
	var amount = "0.01"
	
	var callback_args = {
		"from_network": from_network,
		"to_network": to_network,
		"token_name": "BnM Token",
		"token_amount": amount
	}
	var callback = EthersWeb.create_callback(self, "sent_ccip_message", callback_args)
	
	# Ethereum Sepolia
	var bnm_contract = "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05"
	
	EthersWeb.ccip_send(
		connected_wallet,
		from_network,
		to_network,
		bnm_contract,
		EthersWeb.convert_to_bignum(amount),
		callback
		)


func sent_ccip_message(callback):
	var from_network = callback["from_network"]
	var to_network = callback["to_network"]
	var token_name = callback["token_name"]
	var token_amount =  callback["token_amount"]
	
	var txt = "Sending " + token_amount + " " + token_name +  " from " + from_network + " to "  + to_network
	print_log(txt)







# Find the onRamp targeting the destination network
func get_onramp():
	var sender_network = "Ethereum Sepolia"
	var destination_network = "Avalanche Fuji"
	var callback = EthersWeb.create_callback(self, "got_onramp", {"destination": destination_network})
	EthersWeb.get_onramp(sender_network, destination_network, callback)

func got_onramp(callback):
	var txt = "OnRamp for " + callback["destination"] +":\n" + callback["result"][0]
	print_log(txt)
	

# Monitor offRamps for incoming messages
func get_offramps():
	var destination_network = "Ethereum Sepolia"
	var callback = EthersWeb.create_callback(self, "got_offramps", {"destination": destination_network})
	EthersWeb.get_offramps(destination_network, callback)

func got_offramps(callback):
	print(callback)
