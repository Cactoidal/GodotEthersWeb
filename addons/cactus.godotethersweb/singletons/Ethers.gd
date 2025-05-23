extends Control

# Current Ethers version: 6.14.1
# accessed at: window.ethers
var ethers_filepath = "res://addons/cactus.godotethersweb/js/ethers.umd.min.js"

# For handling the many async functions of web3 wallets
# accessed at: window.walletBridge
var wallet_bridge_filepath = "res://addons/cactus.godotethersweb/js/walletBridge.js"

var window = JavaScriptBridge.get_interface("window")

var has_wallet = false
var transaction_logs = []
var event_streams = []

func _ready():
	# Scripts are attached to the browser window on ready
	load_and_attach(ethers_filepath)
	load_and_attach(wallet_bridge_filepath)

	# Check if a webwallet is in the window
	if window.ethereum:
		has_wallet = true
	

### WEB3 WALLET

# Wallet must be connected for most function calls to work
func connect_wallet(callback="{}"):
	window.walletBridge.request_accounts(success_callback, error_callback, callback)

# Returns the wallet address, gas balance, and chainId, accessible
# at callback["result"][0], callback["result"][1], callback["result"][2]
func get_connected_wallet_info(callback="{}"):
	window.walletBridge.getWalletInfo(
		success_callback, 
		error_callback, 
		callback)

# Prompts wallet to add a specified chain and RPC
func add_chain(network, callback="{}"):
	var info = JSON.stringify(default_network_info[network])
	window.walletBridge.add_chain(info, success_callback, error_callback, callback)


# Manually getting the current chain and switching chains is often
# unnecessary, as walletBridge is programmed to automatically switch
# to whichever chain is specified during a function call
func current_chain(callback="{}"):
	window.walletBridge.current_chain(success_callback, error_callback, callback)

func switch_chain(chain_id, success, failure, callback):
	window.walletBridge.switch_chain(chain_id, success, failure, callback)



### BLOCKCHAIN INTERACTIONS AND SIGNING

# Prompts wallet to sign an ETH transfer.
func transfer(
	network,
	recipient, 
	amount,
	callback="{}"
	):
		var chainId = default_network_info[network]["chainId"]
		callback = _add_value_to_callback(callback, "network", network)
		
		window.walletBridge.startTransferETH(
			chainId,
			recipient, 
			amount, 
			success_callback, 
			error_callback,
			tx_callback,
			callback
			)


# Prompts wallet to sign a contract interaction.
func send_transaction(
	network,
	contract,
	ABI,
	method,
	parameters=[],
	value="0",
	callback="{}"
	):
		var chainId = default_network_info[network]["chainId"]
		callback = _add_value_to_callback(callback, "network", network)
		
		window.walletBridge.initiateContractCall(
			chainId,
			contract, 
			JSON.stringify(ABI), 
			method, 
			arr_to_obj(parameters), 
			value, 
			success_callback, 
			error_callback,
			tx_callback,
			callback
			)


# "result" in the callback arrives as an array.
# Access values with callback["result"][0], etc.
func read_from_contract(
	network,
	contract,
	ABI,
	method,
	parameters=[],
	callback="{}"
	):
		var chainId = default_network_info[network]["chainId"]
		callback = _add_value_to_callback(callback, "network", network)
		
		window.walletBridge.initiateContractRead(
			chainId,
			contract, 
			JSON.stringify(ABI), 
			method, 
			arr_to_obj(parameters), 
			success_callback, 
			error_callback, 
			callback
			)



# Message can be a string or a utf8 buffer
func sign_message(message, callback="{}"):
	window.walletBridge.signMessage(
		message,
		success_callback, 
		error_callback,
		callback 
	)


# EIP-712 signing
# Expects domain, types, and value as dictionaries
# To see what this looks like, check out example_format_typed() 
# in Examples.gd 
func sign_typed(
	domain, 
	types, 
	value, 
	callback="{}"
	):
	window.walletBridge.signTyped(
		JSON.stringify(domain),
		JSON.stringify(types),
		JSON.stringify(value),
		success_callback,
		error_callback,
		callback
		)


# Sets a persistent provider to the window, bound to the provided network,
# to be used by end_listen() whenever you want to stop the stream
#TODO
# Event listening needs to be generalized, the current JavaScript function
# is written specifically for the ERC20 "Transfer" event
func listen_for_event(
	network, 
	contract, 
	ABI, 
	event, 
	callback="{}"
	):
	var chainId = default_network_info[network]["chainId"]
	callback = _add_value_to_callback(callback, "network", network)
	
	window.walletBridge.listenForEvent(
		chainId,
		contract, 
		ABI, 
		event, 
		success_callback, 
		error_callback,
		event_callback, 
		callback
	)


func end_listen(
	network, 
	contract, 
	ABI, 
	event, 
	callback="{}"
	):
	var chainId = default_network_info[network]["chainId"]
	callback = _add_value_to_callback(callback, "network", network)
	
	window.walletBridge.endEventListen(
		chainId,
		contract, 
		ABI, 
		event,
		success_callback, 
		error_callback, 
		callback
	)


# "Transaction logs" and "event streams" are defined by providing
# a callback node and a callback function.  Whenever a transaction receipt
# or event is received, they will be transmitted to any registered 
# nodes/functions.  To stop transmitting to a node, simply delete the node 
# you no longer want to use, or manually erase its entry in the array.

func register_transaction_log(callback_node, callback_function):
	transaction_logs.push_back([callback_node, callback_function])

func register_event_stream(callback_node, callback_function):
	event_streams.push_back([callback_node, callback_function])
	


# "result" in the callback arrives as a single
# value, NOT as an array
func get_connected_wallet_address(callback="{}"):
	window.walletBridge.getWalletAddress(
		success_callback, 
		error_callback, 
		callback
		)

# "result" in the callback arrives as a single
# value, NOT as an array
func get_gas_balance(address, callback="{}"):
	window.walletBridge.getBalance(
		address,
		success_callback, 
		error_callback, 
		callback
		)



### ERC20 BUILT-INS

# If no address is provided, it is presumed you want
# the balanceOf the connected wallet.
# Returns the token name, token symbol, token decimals,
# and the balance of the provided address.
func erc20_info(
	network, 
	token_contract, 
	callback="{}", 
	address=""
	):
	var chainId = default_network_info[network]["chainId"]
	callback = _add_value_to_callback(callback, "network", network)
	
	window.walletBridge.getERC20Info(
		chainId,
		token_contract, 
		JSON.stringify(Contract.ERC20), 
		success_callback, 
		error_callback, 
		callback, 
		address
		)


func erc20_transfer(
	network, 
	token_contract, 
	recipient, 
	amount, 
	callback="{}"
	):
	send_transaction(
		network,
		token_contract, 
		Contract.ERC20, 
		"transfer", 
		[recipient, amount],
		"0",
		callback
		)

func erc20_balance(
	network, 
	address, 
	token_contract, 
	callback="{}"
	):
	var chainId = default_network_info[network]["chainId"]
	callback = _add_value_to_callback(callback, "network", network)
	
	read_from_contract(
		chainId,
		token_contract, 
		Contract.ERC20, 
		"balanceOf", 
		[address], 
		callback
		)



# Prompts wallet to add a specified token
# It is probably good practice to link this function to
# a deliberate "Add Token" button, rather than triggering it
# without the user's input
func add_erc20(
	network, 
	address, 
	symbol, 
	decimals, 
	callback="{}"
	):
	var chainId = default_network_info[network]["chainId"]
	callback = _add_value_to_callback(callback, "network", network)
	
	window.walletBridge.add_erc20(
		chainId, 
		address, 
		symbol,
		decimals, 
		success_callback, 
		error_callback, 
		callback
		)



### CALLBACKS

var success_callback = JavaScriptBridge.create_callback(got_success_callback)
var tx_callback = JavaScriptBridge.create_callback(got_tx_callback)
var event_callback = JavaScriptBridge.create_callback(got_event_callback)
var error_callback = JavaScriptBridge.create_callback(got_error_callback)


func got_success_callback(args):
	
	var callback = JSON.parse_string(args[0])
	if args.size() > 1:
		callback["result"] = args[1]
	else:
		callback["result"] = "success"
	
	do_callback(callback)


func got_error_callback(args):
	var callback = JSON.parse_string(args[0])
	callback["error_code"] = str(args[1])
	callback["error_message"] = args[2]
	

	# If the wallet doesn't have the network,
	# prompt the user to add it
	if callback["error_code"] == "4902":
		if "network" in callback.keys():
			add_chain(callback["network"])
	
	else:
		do_callback(callback)


func got_tx_callback(args):
	var tx_receipt = args[0]
	transmit_transaction_object(tx_receipt)

func got_event_callback(event):
	transmit_event_object(event[0])


func transmit_transaction_object(transaction):
	for log in transaction_logs:
		var callback_node = log[0]
		var callback_function = log[1]
		
		if is_instance_valid(callback_node):
			callback_node.call(callback_function, transaction)
		else:
			transaction_logs.erase(log)


func transmit_event_object(event):
	for stream in event_streams:
		var callback_node = stream[0]
		var callback_function = stream[1]
		
		if is_instance_valid(callback_node):
			callback_node.call(callback_function, event)
		else:
			event.erase(stream)
	

func do_callback(callback):
	if "callback_function" in callback.keys():
		if "callback_node" in callback.keys():
			var callback_function = callback["callback_function"]
			var callback_node = deserialize_node_ref(callback["callback_node"])
		
			if callback_node:
				callback_node.call(callback_function, callback)
			

# Callbacks are dictionaries converted into a string to make them easily
# transportable through JavaScript.  They are eventually converted back 
# into dictionaries using JSON.parse_string()
func create_callback(callback_node, callback_function, callback_args={}):
	var callback = {
		"callback_node": serialize_node_ref(callback_node),
		"callback_function": callback_function,
	}
	
	for key in callback_args.keys():
		callback[key] = callback_args[key]
	
	return str(callback)


# Quick workaround for adding information to a callback that
# has already been made.  This system design could be revisited later 
func _add_value_to_callback(callback, key, value):
	var parsed = JSON.parse_string(callback)
	parsed[key] = value
	return str(parsed)



### UTILITY

# When exporting, .js libraries (UMD version) are bundled into the .PCK file
# using the export filter.  While the application is running, the libraries
# are read from the .PCK file, and attached to the browser window 
# with JavaScriptBridge.eval().  Once attached, they can be called
# from any other gdscript function.

# Loads JavaScript libraries from the .PCK file and attaches 
# them to the browser window
func load_and_attach(path):
	var attaching_script = load_script_from_file(path)
	JavaScriptBridge.eval(attaching_script, true)


func load_script_from_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		return file.get_as_text()
	return ""



# For some reason NodePaths introduce a character unrecognizable to
# JSON.parse_string.  As a workaround, they get serialized into base64.
func serialize_node_ref(n):
	var path = n.get_path()
	var base64 = Marshalls.raw_to_base64( str(path).to_utf8_buffer() )
	return base64

func deserialize_node_ref(base64):
	var bytes = Marshalls.base64_to_raw(base64)
	var path = NodePath(bytes.get_string_from_utf8())
	
	return get_node_or_null(path)



# Convert from GDScript Array to JavaScript Array
func arr_to_obj(arr: Array) -> JavaScriptObject:
	var val = JavaScriptBridge.create_object('Array', len(arr))
	for i in range(len(arr)):
		val[i] = arr[i]
	return val

# Dictionaries are transported by using JSON.stringify in Godot,
# and then JSON.parse in JavaScript.


### NETWORK INFO

var default_network_info = {
	
	"Ethereum Mainnet": 
		{
		"chainId": "0x1",
		"chainName": 'Ethereum Mainnet',
		"rpcUrls": ["https://eth.llamarpc.com"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://etherscan.io/",
		"chainlinkToken": "0x514910771AF9Ca656af840dff83E8264EcF986CA"
		},
	
	"Avalanche Mainnet":
		{
		"chainId": '0xa86a',
		"chainName": 'Avalanche C-Chain',
		"rpcUrls": ['https://api.avax.network/ext/bc/C/rpc'],
		"nativeCurrency": { "name": 'AVAX', "symbol": 'AVAX', "decimals": 18 },
		"blockExplorerUrls": ['https://snowtrace.io'],
		},
	
	"Sonic Mainnet": 
		{
		"chainId": "0x92",
		"chainName": 'Sonic Mainnet',
		"rpcUrls": ["https://rpc.soniclabs.com"],
		"nativeCurrency": { "name": 'S', "symbol": 'S', "decimals": 18 },
		"blockExplorerUrls": ['https://sonicscan.org'],
		},
	
	"Ethereum Sepolia": 
		{
		"chainId": "0xaa36a7",
		"chainName": 'Ethereum Sepolia',
		"rpcUrls": ["https://ethereum-sepolia-rpc.publicnode.com", "https://rpc2.sepolia.org"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://sepolia.etherscan.io/",
		"chainlinkToken": "0x779877A7B0D9E8603169DdbD7836e478b4624789"
		},
		
	"Arbitrum Sepolia": 
		{
		"chainId": "0x66eee",
		"chainName": 'Arbitrum Sepolia',
		"rpcUrls": ["https://sepolia-rollup.arbitrum.io/rpc"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://sepolia.arbiscan.io/"
		},
		
	"Optimism Sepolia": {
		"chainId": "0xaa37dc",
		"chainName": "Optimism Sepolia",
		"rpcUrls": ["https://sepolia.optimism.io"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://sepolia-optimism.etherscan.io/"
	},
	
	"Base Sepolia": {
		"chainId": "0x14a34",
		"chainName": "Base Sepolia",
		"rpcUrls": ["https://sepolia.base.org", "https://base-sepolia-rpc.publicnode.com"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://sepolia.basescan.org/"
	},
	
	"Avalanche Fuji": {
		"chainId": "0xa869",
		"chainName": "Avalanche Fuji",
		"rpcUrls": ["https://avalanche-fuji-c-chain-rpc.publicnode.com"],
		"nativeCurrency": { "name": 'AVAX', "symbol": 'AVAX', "decimals": 18 },
		"scan": "https://testnet.snowtrace.io/"
	}
}
