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
	calldata,
	#ABI,
	#method,
	#parameters=[],
	value="0",
	callback="{}"
	):
		var chainId = default_network_info[network]["chainId"]
		callback = _add_value_to_callback(callback, "network", network)
	
		window.walletBridge.initiateContractCall(
			chainId,
			contract, 
			calldata["calldata"],
			#JSON.stringify(ABI), 
			#method, 
			#arr_to_obj(parameters), 
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
	calldata,
	callback="{}"
	):
		
		var chainId = default_network_info[network]["chainId"]
		callback = _add_value_to_callback(callback, "network", network)
		
		var outputs = calldata["outputs"]
		
		callback = _add_value_to_callback(callback, "output_types", outputs)
		
		window.walletBridge.initiateContractRead(
			chainId,
			contract, 
			calldata["calldata"],
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
	chainId,
	domain, 
	types, 
	value, 
	callback="{}"
	):
	window.walletBridge.signTyped(
		chainId,
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
	wss_node, 
	contract,
	topics,
	callback="{}"
	):
	var chainId = default_network_info[network]["chainId"]
	callback = _add_value_to_callback(callback, "network", network)
	
	window.walletBridge.listenForEvent(
		chainId,
		wss_node,
		contract, 
		arr_to_obj(topics),
		success_callback, 
		error_callback,
		event_callback, 
		callback
	)


func end_listen(
	network, 
	contract, 
	topics,
	callback="{}"
	):
	var chainId = default_network_info[network]["chainId"]
	callback = _add_value_to_callback(callback, "network", network)
	
	window.walletBridge.endEventListen(
		chainId,
		contract, 
		arr_to_obj(topics),
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


func erc20_balance(
	network, 
	address, 
	token_contract, 
	callback="{}"
	):
	callback = _add_value_to_callback(callback, "network", network)
	var data = get_calldata(Contract.ERC20, "balanceOf", [address]) 
	
	read_from_contract(
		network,
		token_contract, 
		data,
		callback
		)


func erc20_approve(
	network, 
	token_contract, 
	spender_address, 
	amount, 
	callback="{}"
	):
		
	if amount in ["MAX", "MAXIMUM"]:
		amount = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

	
	var data = get_calldata(Contract.ERC20, "approve", [spender_address, amount])
	
	send_transaction(
		network,
		token_contract, 
		data,
		"0",
		callback
		)


func erc20_transfer(
	network, 
	token_contract, 
	recipient, 
	amount, 
	callback="{}"
	):
	var data = get_calldata(Contract.ERC20, "transfer", [recipient, amount])
	
	send_transaction(
		network,
		token_contract, 
		data,
		"0",
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


## ENCODING


func get_calldata(abi, function_name, function_args=[]):
	
	var calldata = {
		"calldata": Calldata.get_function_calldata(abi, function_name, function_args)
	}

	calldata["outputs"] = get_outputs(abi, function_name)
	
	return(calldata)


func get_outputs(abi, function_name):
	var function = Calldata.get_function(abi, function_name)
	var outputs = Calldata.get_function_outputs(function)
	return outputs
	



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
	# Decode read result.  Only read_from_contract() adds output_types 
	# into the callback object
	if "output_types" in callback.keys():
		var output_types = callback["output_types"]
		var calldata = callback["result"]
	
		var decoded = Calldata.abi_decode(output_types, calldata)

		callback["result"] = decoded
		
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

# Dictionaries can be transported by using JSON.stringify in Godot,
# and then JSON.parse in JavaScript.


func convert_to_bignum(number, token_decimals=18):
	number = str(number)
	
	if number.begins_with("."):
		number = "0" + number
		
	var zero_filler = int(token_decimals)
	var decimal_index = number.find(".")
	
	var bignum = number
	if decimal_index != -1:
		var segment = number.right(-(decimal_index+1) )
		zero_filler -= segment.length()
		bignum = bignum.erase(decimal_index,1)

	for zero in range(zero_filler):
		bignum += "0"
	
	var zero_parse_index = 0
	if bignum.begins_with("0"):
		for digit in bignum:
			if digit == "0":
				zero_parse_index += 1
			else:
				break
	if zero_parse_index > 0:
		bignum = bignum.right(-zero_parse_index)

	if bignum == "":
		bignum = "0"

	return bignum


func convert_to_smallnum(bignum, token_decimals=18):
	var size = bignum.length()
	var smallnum = ""
	if size <= int(token_decimals):
		smallnum = "0."
		var fill_length = int(token_decimals) - size
		for zero in range(fill_length):
			smallnum += "0"
		smallnum += String(bignum)
	elif size > 18:
		smallnum = bignum
		var decimal_index = size - 18
		smallnum = smallnum.insert(decimal_index, ".")
	
	var index = 0
	var zero_parse_index = 0
	var prune = false
	for digit in smallnum:
		if digit == "0":
			if !prune:
				zero_parse_index = index
				prune = true
		else:
			prune = false
		index += 1
	if prune:
		smallnum = smallnum.left(zero_parse_index).trim_suffix(".")
	
	return smallnum



func big_int_math(number1, operation, number2):
	var output
	if operation in ["ADD", "SUBTRACT", "DIVIDE", "MULTIPLY"]:
		output = window.walletBridge.bigintArithmetic(number1, number2, operation)
	if operation in ["GREATER THAN", "LESS THAN", "GREATER THAN OR EQUAL", "LESS THAN OR EQUAL", "EQUAL"]:
		output = window.walletBridge.bigintCompare(number1, number2, operation)
	return output






### NETWORK INFO

var default_network_info = {
	
	###		MAINNETS		###
	
	"Ethereum Mainnet": 
		{
		"chainId": "0x1",
		"chainName": 'Ethereum Mainnet',
		"rpcUrls": ["https://eth.llamarpc.com"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://etherscan.io/",
		"chainlinkToken": "0x514910771AF9Ca656af840dff83E8264EcF986CA",
		"ccipRouter": "0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D",
		"chainSelector": "5009297550715157269",
		},
	
	"Avalanche Mainnet":
		{
		"chainId": '0xa86a',
		"chainName": 'Avalanche C-Chain',
		"rpcUrls": ['https://api.avax.network/ext/bc/C/rpc'],
		"nativeCurrency": { "name": 'AVAX', "symbol": 'AVAX', "decimals": 18 },
		"blockExplorerUrls": ['https://snowtrace.io'],
		"chainlinkToken": "0x5947BB275c521040051D82396192181b413227A3",
		"ccipRouter": "0xF4c7E640EdA248ef95972845a62bdC74237805dB",
		"chainSelector": "6433500567565415381",
		},
	
	"Sonic Mainnet": 
		{
		"chainId": "0x92",
		"chainName": 'Sonic Mainnet',
		"rpcUrls": ["https://rpc.soniclabs.com"],
		"nativeCurrency": { "name": 'S', "symbol": 'S', "decimals": 18 },
		"blockExplorerUrls": ['https://sonicscan.org'],
		"chainlinkToken": "0x71052BAe71C25C78E37fD12E5ff1101A71d9018F",
		"ccipRouter": "0xB4e1Ff7882474BB93042be9AD5E1fA387949B860",
		"chainSelector": "1673871237479749969",
		},
		
	"Arbitrum Mainnet": 
		{
		"chainId": "0xa4b1",
		"chainName": 'Arbitrum One',
		"rpcUrls": ["https://arb-pokt.nodies.app"],
		"nativeCurrency": { "name": 'ETH', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": ['https://arbiscan.io'],
		"chainlinkToken": "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4",
		"ccipRouter": "0x141fa059441E0ca23ce184B6A78bafD2A517DdE8",
		"chainSelector": "4949039107694359620",
		},
	
	"Optimism Mainnet": 
		{
		"chainId": "0xa",
		"chainName": 'OP Mainnet',
		"rpcUrls": ["https://rpc.soniclabs.com"],
		"nativeCurrency": { "name": 'ETH', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": ['https://optimistic.etherscan.io'],
		"chainlinkToken": "0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6",
		"ccipRouter": "0x3206695CaE29952f4b0c22a169725a865bc8Ce0f",
		"chainSelector": "3734403246176062136",
		},
	
	"Base Mainnet": 
		{
		"chainId": "0x2105",
		"chainName": 'Base',
		"rpcUrls": ["https://base-rpc.publicnode.com"],
		"nativeCurrency": { "name": 'ETH', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": ['https://basescan.org'],
		"chainlinkToken": "0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196",
		"ccipRouter": "0x881e3A65B4d4a04dD529061dd0071cf975F58bCD",
		"chainSelector": "15971525489660198786",
		},
	
	"Soneium Mainnet": 
		{
		"chainId": "0x74c",
		"chainName": 'Soneium',
		"rpcUrls": ["https://soneium.drpc.org"],
		"nativeCurrency": { "name": 'ETH', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": ['https://soneium.blockscout.com'],
		"chainlinkToken": "0x32D8F819C8080ae44375F8d383Ffd39FC642f3Ec",
		"ccipRouter": "0x8C8B88d827Fe14Df2bc6392947d513C86afD6977",
		"chainSelector": "12505351618335765396",
		},
		
	
	###		TESTNETS		###
	
	"Ethereum Sepolia": 
		{
		"chainId": "0xaa36a7",
		"chainName": 'Ethereum Sepolia',
		"rpcUrls": ["https://ethereum-sepolia-rpc.publicnode.com", "https://rpc2.sepolia.org"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://sepolia.etherscan.io/",
		"chainlinkToken": "0x779877A7B0D9E8603169DdbD7836e478b4624789",
		"ccipRouter": "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59",
		"chainSelector": "16015286601757825753",
		},
		
	"Arbitrum Sepolia": 
		{
		"chainId": "0x66eee",
		"chainName": 'Arbitrum Sepolia',
		"rpcUrls": ["https://sepolia-rollup.arbitrum.io/rpc"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://sepolia.arbiscan.io/",
		"chainlinkToken": "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E",
		"ccipRouter": "0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165",
		"chainSelector": "3478487238524512106",
		},
		
	"Optimism Sepolia": {
		"chainId": "0xaa37dc",
		"chainName": "OP Sepolia",
		"rpcUrls": ["https://sepolia.optimism.io"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://sepolia-optimism.etherscan.io/",
		"chainlinkToken": "0xE4aB69C077896252FAFBD49EFD26B5D171A32410",
		"ccipRouter": "0x114A20A10b43D4115e5aeef7345a1A71d2a60C57",
		"chainSelector": "5224473277236331295",
	},
	
	"Base Sepolia": {
		"chainId": "0x14a34",
		"chainName": "Base Sepolia",
		"rpcUrls": ["https://sepolia.base.org", "https://base-sepolia-rpc.publicnode.com"],
		"nativeCurrency": { "name": 'Ether', "symbol": 'ETH', "decimals": 18 },
		"blockExplorerUrls": "https://sepolia.basescan.org/",
		"chainlinkToken": "0xE4aB69C077896252FAFBD49EFD26B5D171A32410",
		"ccipRouter": "0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93",
		"chainSelector": "10344971235874465080",
	},
	
	"Avalanche Fuji": {
		"chainId": "0xa869",
		"chainName": "Avalanche Fuji",
		"rpcUrls": ["https://avalanche-fuji-c-chain-rpc.publicnode.com"],
		"nativeCurrency": { "name": 'AVAX', "symbol": 'AVAX', "decimals": 18 },
		"scan": "https://testnet.snowtrace.io/",
		"chainlinkToken": "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
		"ccipRouter": "0xF694E193200268f9a4868e4Aa017A0118C9a8177",
		"chainSelector": "14767482510784806043",
	},
	
	"Sonic Blaze": {
		"chainId": "0xdede",
		"chainName": "Sonic Blaze",
		"rpcUrls": ["https://sonic-testnet.drpc.org"],
		"nativeCurrency": { "name": 'S', "symbol": 'S', "decimals": 18 },
		"scan": "https://testnet.sonicscan.org",
		"chainlinkToken": "0xd8C1eEE32341240A62eC8BC9988320bcC13c8580",
		"ccipRouter": "0x2fBd4659774D468Db5ca5bacE37869905d8EfA34",
		"chainSelector": "3676871237479449268",
	},
	
	"Soneium Minato": {
		"chainId": "0x79a",
		"chainName": "Soneium Minato",
		"rpcUrls": ["https://soneium-minato.drpc.org"],
		"nativeCurrency": { "name": 'ETH', "symbol": 'ETH', "decimals": 18 },
		"scan": "https://soneium-minato.blockscout.com",
		"chainlinkToken": "0x7ea13478Ea3961A0e8b538cb05a9DF0477c79Cd2",
		"ccipRouter": "0x443a1bce545d56E2c3f20ED32eA588395FFce0f4",
		"chainSelector": "686603546605904534",
	}
}


var chain_selector_map = {
	"5009297550715157269": "Ethereum Mainnet",
	"6433500567565415381": "Avalanche Mainnet",
	"1673871237479749969": "Sonic Mainnet",
	"4949039107694359620": "Arbitrum Mainnet",
	"3734403246176062136": "Optimism Mainnet",
	"15971525489660198786": "Base Mainnet",
	"12505351618335765396": "Soneium Mainnet",
	
	"16015286601757825753": "Ethereum Sepolia",
	"14767482510784806043": "Avalanche Fuji",
	"3676871237479449268": "Sonic Blaze",
	"3478487238524512106": "Arbitrum Sepolia",
	"5224473277236331295": "Optimism Sepolia",
	"10344971235874465080": "Base Sepolia",
	"686603546605904534": "Soneium Minato"
}



### CCIP Sending

# You must first approve the router's spend,
# and naturally you should validate 
# user inputs before attempting.
func ccip_send(recipient_address, from_network, to_network, token, amount, _callback="{}"):

	# When encoding, structs are declared as arrays 
	# containing their expected types.
	var EVMTokenAmount = [
		token,
		amount
	]
	
	var EVMExtraArgsV2 = [
		"200000", # Destination gas limit
		false
	]
	
	# EVM2Any messages expect some of their parameters to 
	# be ABI encoded and sent as bytes.
	var v2_args_tag = "0x181dcf10"
	var encoded_args = Calldata.abi_encode( [{"type": "tuple", "components":[{"type": "uint256"}, {"type": "bool"}]}], [EVMExtraArgsV2] )
	var extra_args = v2_args_tag + encoded_args
	
	
	var EVM2AnyMessage = [
		Calldata.abi_encode( [{"type": "address"}], [recipient_address] ), # ABI-encoded recipient address
		Calldata.abi_encode( [{"type": "string"}], ["eeee"] ), # Data payload, as bytes
		[EVMTokenAmount], # EVMTokenAmounts
		"0x0000000000000000000000000000000000000000", # Fee address (address(0) = native token)
		extra_args # Extra args
	]
	
	var chain_selector = default_network_info[to_network]["chainSelector"]
	
	var router = default_network_info[from_network]["ccipRouter"]
	
	var tx_calldata = get_calldata(Contract.CCIP_ROUTER, "ccipSend", [chain_selector, EVM2AnyMessage])
	var read_calldata = get_calldata(Contract.CCIP_ROUTER, "getFee", [chain_selector, EVM2AnyMessage])
	
	# Preserve the original callback key:value pairs, if there were any
	var callback = JSON.parse_string(_callback)
	var new_callback = {}
	for key in callback.keys():
		new_callback["original_" + key] = callback[key]
	
	new_callback["tx_calldata"] = tx_calldata
	new_callback["network"] = from_network
	new_callback["callback_function"] = "got_ccip_fee"
	# When manually building a callback object, don't forget to 
	# serialize the node reference
	new_callback["callback_node"] = serialize_node_ref(self)
	
	
	#var callback = create_callback(self, "got_ccip_fee", {"tx_calldata": tx_calldata, "network": from_network})
	
	read_from_contract(
		from_network,
		router,
		read_calldata,
		# Manually turn the callback back into a string
		str(new_callback)
	)


func got_ccip_fee(callback):	

	var network = callback["network"]
	var router = default_network_info[network]["ccipRouter"]
	var data = callback["tx_calldata"]
	
	var _fee = callback["result"][0]

	var fee = convert_to_smallnum(_fee)
	
	# Increase fee slightly to reduce chance of revert
	fee = str (float(fee) * 1.05)
	
	# Restore the original callback
	# (Remember to turn it back into a string!)
	for key in callback.keys():
		if key.begins_with("original_"):
			var restored_key = key.substr(9)
			callback[restored_key] = callback[key]
	
	# While not strictly necessary to remove this (it was added
	# by the previous read call), doing so will prevent the error
	# from appearing in the log :^)
	callback.erase("output_types")

	send_transaction(network, router, data, fee, str(callback))





## CCIP Monitoring

# Get outgoing lane
func get_onramp(sender_network, destination_network, callback="{}"):
	var router = default_network_info[sender_network]["ccipRouter"]
	var destination_selector = default_network_info[destination_network]["chainSelector"]
	
	var data = get_calldata(Contract.CCIP_ROUTER, "getOnRamp", [destination_selector])

	read_from_contract(sender_network, router, data, callback)


# Get incoming lanes
func get_offramps(destination_network, callback="{}"):
	var router = default_network_info[destination_network]["ccipRouter"]

	var data = get_calldata(Contract.CCIP_ROUTER, "getOffRamps", [])
	
	read_from_contract(destination_network, router, data, callback)
