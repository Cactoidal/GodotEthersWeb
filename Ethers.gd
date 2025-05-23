extends Control

# Current Ethers version: 6.14.1
# accessed at: window.ethers
var ethers_filepath = "res://js/ethers.umd.min.js"

# For handling the many async functions of web3 wallets
# accessed at: window.walletBridge
var wallet_bridge_filepath = "res://js/walletBridge.js"

var window = JavaScriptBridge.get_interface("window")

var has_wallet = false
var transaction_logs = []
var event_streams = []


func _ready():
	load_and_attach(ethers_filepath)
	load_and_attach(wallet_bridge_filepath)
	
	#TEST
	connect_buttons()

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
# For an example of how to format, see example_format_typed() at the
# bottom of this script
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
		event_callback, 
		error_callback, 
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
# logs/streams.  To stop transmitting, simply delete the node you no longer
# want to use.

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
		JSON.stringify(ERC20), 
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
		ERC20, 
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
		ERC20, 
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
	callback["error_code"] = args[1]
	callback["error_message"] = args[2]
	
	# If the wallet doesn't have the network,
	# prompt the user to add it
	if callback["error_code"] == 4902:
		if "network" in callback.keys():
			add_chain(callback["network"])
	
	else:
		do_callback(callback)


func got_tx_callback(args):
	#var callback = JSON.parse_string(args[1])
	var tx_receipt = args[0]
	transmit_transaction_object(tx_receipt)

func got_event_callback(args):
	#var callback = JSON.parse_string(args[1])
	var event = args[0]
	transmit_event_object(event)


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
# has already been made.  This system design should be revisited later 
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

# Dictionaries are easily transported by using JSON.stringify,
# and then JSON.parse in JavaScript or JSON.parse_string in Godot


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




### ERC20 ABI

var ERC20 = [
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "initialSupply",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "spender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "allowance",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "needed",
				"type": "uint256"
			}
		],
		"name": "ERC20InsufficientAllowance",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "sender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "balance",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "needed",
				"type": "uint256"
			}
		],
		"name": "ERC20InsufficientBalance",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "approver",
				"type": "address"
			}
		],
		"name": "ERC20InvalidApprover",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "receiver",
				"type": "address"
			}
		],
		"name": "ERC20InvalidReceiver",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "sender",
				"type": "address"
			}
		],
		"name": "ERC20InvalidSender",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "spender",
				"type": "address"
			}
		],
		"name": "ERC20InvalidSpender",
		"type": "error"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "spender",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "Approval",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "Transfer",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "spender",
				"type": "address"
			}
		],
		"name": "allowance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "spender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "approve",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "account",
				"type": "address"
			}
		],
		"name": "balanceOf",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "decimals",
		"outputs": [
			{
				"internalType": "uint8",
				"name": "",
				"type": "uint8"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "name",
		"outputs": [
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "symbol",
		"outputs": [
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "totalSupply",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "transfer",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "transferFrom",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]




### TEST


func connect_buttons():
	$ConnectWallet.connect("pressed", connect_wallet)
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
	
	register_transaction_log(self, "test_tx_receipt")
	register_event_stream(self, "test_event_log")


func test_tx_receipt(callback):
	print(callback)

func test_event_log(callback):
	print(callback)



var test_recipient = "0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba"

func test_add_chain():
	add_chain("Avalanche Mainnet")

func test_transfer():
	#var recipient = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
	var amount = "0"
	var callback_args = {"test": "OOoOOooOOoo"}
	var network = "Sonic Mainnet"
	#var network = "Ethereum Sepolia"
		
	var callback = create_callback(self, "transaction_callback", callback_args)
	transfer(network, test_recipient, amount, callback)
	

func transaction_callback(callback):
	$Data.text = callback["test"]


func test_read():
	var network = "Ethereum Sepolia"
	var token_address = default_network_info[network]["chainlinkToken"]
	var callback = create_callback(self, "read_result")
	read_from_contract(network, token_address, ERC20, "name", [], callback)

func read_result(callback):
	var result = callback["result"]
	$Data.text = result[0]

	
func test_write():
	var network = "Ethereum Sepolia"
	var callback = create_callback(self, "show_receipt")
	
	var token_address = default_network_info[network]["chainlinkToken"]
	
	#erc20_transfer(network, token_address, test_recipient, "0", callback)
	send_transaction(network, token_address, ERC20, "transfer", ["0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045", "0"])

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
	var callback = create_callback(self, "show_wallet_info")
	get_connected_wallet_info(callback)

func show_wallet_info(callback):
	$Data.text = callback["result"][0]
	$Data2.text = callback["result"][1]
	print(callback["result"][2])


func test_get_erc20_info():
	var network = "Ethereum Sepolia"
	var callback = create_callback(self, "show_erc20_info")
	var token_address = default_network_info[network]["chainlinkToken"]
	
	erc20_info(network, token_address, callback)

func show_erc20_info(callback):
	$Data.text = callback["result"][0]
	$Data2.text = callback["result"][3]


func test_sign():
	var callback = create_callback(self, "show_signature")
	
	var message = "hello"
	
	sign_message(message, callback)


func show_signature(callback):
	$Data.text = callback["result"]


func test_add_erc20():
	var network = "Ethereum Sepolia"
	var token_address = default_network_info[network]["chainlinkToken"]
	add_erc20(network, token_address, "LINK", 18)



func listen_test():
	var network = "Ethereum Mainnet"
	var callback = create_callback(self, "show_event")
	
	var token_address = default_network_info[network]["chainlinkToken"]
	
	listen_for_event(network, token_address, JSON.stringify(ERC20), "Transfer", callback)

func show_event(callback):
	pass


func stop_listen_test():
	var network = "Ethereum Mainnet"
	var token_address = default_network_info[network]["chainlinkToken"]
	var event = "Transfer"
	end_listen(network, token_address, JSON.stringify(ERC20), event)


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

	var callback = create_callback(self, "show_signature")
	sign_typed(domain, types, value, callback)
