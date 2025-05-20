extends Control

# When exporting, .js libraries (UMD version) are bundled into the .PCK file
# using the export filter.  While the application is running, the libraries
# are read from the .PCK file, and attached to the browser window 
# with JavascriptBridge.eval().  Once attached, they can be called
# from any other gdscript function.

# Current Ethers version: 6.14.1
var ethers_filepath = "res://js/ethers.umd.min.js"

# For handling the many async functions of web3 wallets
var wallet_bridge_filepath = "res://js/walletBridge.js"

var window = JavaScriptBridge.get_interface("window")

var got_write_callback = JavaScriptBridge.create_callback(write_callback)
var got_read_callback = JavaScriptBridge.create_callback(read_callback)
var got_error_callback = JavaScriptBridge.create_callback(error_callback)


func _ready():
	load_and_attach(ethers_filepath)
	load_and_attach(wallet_bridge_filepath)
	connect_buttons()


func connect_buttons():
	$ConnectWallet.connect("pressed", connect_wallet)
	$TestSend.connect("pressed", test_transfer)
	$TestRead.connect("pressed", test_read)
	$TestWrite.connect("pressed", test_write)

	
### TEST

func test_transfer():
	var recipient = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
	var amount = "0"
	var callback_args = {"test": "OOoOOooOOoo"}
		
	var callback = create_callback(self, "transaction_callback", callback_args)
	transfer(recipient, amount, callback)
	

func transaction_callback(callback):
	$Data.text = callback["test"]


func test_read():
	var callback = create_callback(self, "read_result")
	read_from_contract(CHAINLINK_TOKEN_ADDRESS, ERC20, "name", [], callback)

func read_result(callback):
	var result = callback["read_result"]
	$Data.text = result[0]

	
func test_write():
	send_transaction(CHAINLINK_TOKEN_ADDRESS, ERC20, "transfer", ["0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045", "0"])




### CORE FUNCTIONS

# Prompts wallet to sign an ETH transfer.
func transfer(
	recipient, 
	amount,
	callback="{}"
	):
		window.walletBridge.startTransferETH(
			recipient, 
			amount, 
			got_write_callback, 
			got_error_callback, 
			callback
			)


# Prompts wallet to sign a contract interaction.
func send_transaction(
	contract,
	ABI,
	method,
	parameters=[],
	value="0",
	callback="{}"
	):
		window.walletBridge.initiateContractCall(
			contract, 
			JSON.stringify(ABI), 
			method, 
			arr_to_js(parameters), 
			value, 
			got_write_callback, 
			got_error_callback, 
			callback
			)

# "read_result" in the callback arrives as an array
func read_from_contract(
	contract,
	ABI,
	method,
	parameters=[],
	callback="{}"
	):
		window.walletBridge.initiateContractRead(
			contract, 
			JSON.stringify(ABI), 
			method, 
			arr_to_js(parameters), 
			got_read_callback, 
			got_error_callback, 
			callback
			)


func get_balance():
	pass


func sign_message():
	pass


func sign_structured():
	pass


func sign_userOps():
	pass
	

### WEB3 WALLET

func check_if_metamask():
	$Data2.text = str(JavaScriptBridge.eval("window.ethereum.isMetaMask", true))

func connect_wallet():
	window.walletBridge.request_accounts()

func current_chain():
	window.walletBridge.current_chain()

func switch_chain(chain_id):
	window.walletBridge.switch_chain(chain_id)

	
	
### ERC20 BUILT-INS

func erc20_balanceOf():
	pass

func add_erc20():
	pass



### ABI ENCODE / DECODE

func test_encode():
	var args = '[ "uint", "string" ], [ 1234, "Hello World" ]'
	$Data2.text = window.ethers.AbiCoder.defaultAbiCoder().encode(%s) % args
	

func abi_encode():
	pass

func abi_decode():
	pass




### CALLBACKS


func write_callback(args):
	var callback = JSON.parse_string(args[1])
	callback["tx_hash"] = args[0]
	do_callback(callback)

func read_callback(args):
	var callback = JSON.parse_string(args[1])
	callback["read_result"] = args[0]
	do_callback(callback)

func error_callback(args):
	var callback = JSON.parse_string(args[2])
	callback["error_code"] = args[0]
	callback["error_message"] = args[1]
	do_callback(callback)
	

func do_callback(callback):
	if "callback_function" in callback.keys():
		if "callback_node" in callback.keys():
			var callback_function = callback["callback_function"]
			var callback_node = deserialize_node_ref(callback["callback_node"])
		
			if callback_node:
				callback_node.call(callback_function, callback)
			
	




### UTILITY

func load_and_attach(path):
	var attaching_script = load_script_from_file(path)
	JavaScriptBridge.eval(attaching_script, true)


func load_script_from_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		return file.get_as_text()
	return ""



func create_callback(callback_node, callback_function, callback_args={}):
	var callback = {
		"callback_node": serialize_node_ref(callback_node),
		"callback_function": callback_function,
	}
	
	for key in callback_args.keys():
		callback[key] = callback_args[key]
	
	return str(callback)


func serialize_node_ref(n):
	var path = n.get_path()
	var base64 = Marshalls.raw_to_base64( str(path).to_utf8_buffer() )
	return base64

func deserialize_node_ref(base64):
	var bytes = Marshalls.base64_to_raw(base64)
	var path = NodePath(bytes.get_string_from_utf8())
	
	return get_node_or_null(path)



# Convert from GDScript Array to JavaScript Array
func arr_to_js(arr: Array) -> JavaScriptObject:
	var val = JavaScriptBridge.create_object('Array', len(arr))
	for i in range(len(arr)):
		val[i] = arr[i]
	return val

# Convert from GDScript Dictionary to JavaScript Dictionary
func dict_to_js(dict: Dictionary) -> JavaScriptObject:
	var val = JavaScriptBridge.create_object('Object')
	for key in dict:
		val[key] = dict[key]
	return val





### NETWORK INFO

var default_network_info = {
	
	"Ethereum Sepolia": 
		{
		"chain_id": "0xaa36a7",
		"rpcs": ["https://ethereum-sepolia-rpc.publicnode.com", "https://rpc2.sepolia.org"],
		"rpc_cycle": 0,
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia.etherscan.io/"
		},
		
	"Arbitrum Sepolia": 
		{
		"chain_id": "0x66eee",
		"rpcs": ["https://sepolia-rollup.arbitrum.io/rpc"],
		"rpc_cycle": 0,
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia.arbiscan.io/"
		},
		
	"Optimism Sepolia": {
		"chain_id": "0xaa37dc",
		"rpcs": ["https://sepolia.optimism.io"],
		"rpc_cycle": 0,
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia-optimism.etherscan.io/"
	},
	
	"Base Sepolia": {
		"chain_id": "0x14a34",
		"rpcs": ["https://sepolia.base.org", "https://base-sepolia-rpc.publicnode.com"],
		"rpc_cycle": 0,
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia.basescan.org/"
	},
	
	"Avalanche Fuji": {
		"chain_id": "0xa869",
		"rpcs": ["https://avalanche-fuji-c-chain-rpc.publicnode.com"],
		"rpc_cycle": 0,
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://testnet.snowtrace.io/"
	}
}




### ERC20 ABI

# Ethereum Mainnet
var CHAINLINK_TOKEN_ADDRESS = "0x514910771AF9Ca656af840dff83E8264EcF986CA"

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
