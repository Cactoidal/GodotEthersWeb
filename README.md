# GodotEthersWeb
Ethers.js and Web3 Wallet Interaction for Godot 4.4+ HTML5 Builds

NOTE:
This addon will work only with Godot HTML5 projects running in a browser with a webwallet (such as Metamask).   For desktop projects, please refer to [GodotEthers](https://github.com/Cactoidal/GodotEthersV3).


TO DO:
FIX THESE

[About](https://github.com/Cactoidal/GodotEthersV3/blob/main/README.md#about) | [Docs](https://github.com/Cactoidal/GodotEthersV3/blob/main/DOCUMENTATION.md)

[Quickstart](https://github.com/Cactoidal/GodotEthersV3/blob/main/DOCUMENTATION.md#quickstart-1)

[Changelog](https://github.com/Cactoidal/GodotEthersV3/blob/main/CHANGELOG.md)

___

### A Note on Security

This is experimental, alpha software, in a state of ongoing development, intended for usage on testnets.  

___

## Add GodotEthersWeb to your Godot 4.4 Project

* Download the GodotEthersWeb plugin ([TO DO: FIX LINK HERE]()) and add it to your project's `addons` folder.

* Inside the editor, open Project Settings, click Plugins, and activate GodotEthersWeb.

* Restart the editor.
___

## How to Use

You'll want to connect `EthersWeb.connect_wallet()` to a button, prompting the user to connect.  The user must be connected for most functions to work.  Once the user has connected once, they won't need to connect again (unless they manually disconnect their wallet).  You can call `EthersWeb.get_connected_wallet_info()` if you want to display the user address, gas balance, and current chain.

For blockchain operations, you can call `EthersWeb.transfer()`, `EthersWeb.send_transaction()`, and `EthersWeb.read_from_contract()`.  Basic ERC20 support has been built in, so you don't need to implement these functions yourself (see documentation).  You can also sign messages, sign typed data (ERC-712), and listen for events.

All blockchain interaction functions require you to specify the target chain, and they will automatically prompt the user to add the chain if their wallet does not have it.  

Make sure to add any chains you want to use to the `default_network_info` dictionary.

---

TO DO:
FIX THE CODE BELOW

```gdscript

# Read from a contract

func get_hello(network, contract, ABI):
	
	var calldata = Ethers.get_calldata("READ", ABI, "helloWorld", [])
		
	Ethers.read_from_contract(
		network, 
		contract, 
		calldata, 
		self, 
		"hello_world",
		{}
		)



# Receive the callback from the contract read

func hello_world(callback):
	if callback["success"]:
		print(callback["result"])



# Create an encrypted keystore with an account name and password

func create_account(account, password):
	if !Ethers.account_exists(account):
		Ethers.create_account(account, password)
		password = Ethers.clear_memory()
		password.clear()



# An account must be logged in to send transactions

func login(account, password):
	Ethers.login(account, password)
	password = Ethers.clear_memory()
	password.clear()



# Send a transaction

func say_hello(account, network, contract, ABI):
	
	var calldata = Ethers.get_calldata("WRITE", ABI, "sayHello", ["hello"])

	Ethers.send_transaction(
			account, 
			network, 
			contract, 
			calldata, 
			self, 
			"get_receipt", 
			{}
			)



# Receive the callback from a successful transaction

func get_receipt(callback):
	if callback["success"]:
		print(callback["result"])

```
___

## About

TODO:
WRITE THIS AND FIX DOCS LINK

GodotEthersWeb uses ethers.js!

I wanted to create a gdscript interface similar to the one used in the desktop version, GodotEthers, and I think the existing code will be suitable for most use cases.

However, for complex tasks (like requesting multiple successive reads from a contract), you will probably be able to get the job done faster by simply writing in JavaScript.  To do this, it's easiest to write new functions into the walletBridge.js library found in the /js folder.  You can then access those functions in gdscript by calling window.walletBridge.yourFunction().

Note that in some cases you will need to convert between gdscript and JavaScript types.  Notably, Arrays must be converted into a JavaScriptObject (use `EthersWeb.arr_to_obj()` to accomplish this) and the current workaround for Dictionaries is to turn them into strings with str() on the Godot side, then use JSON.parse() on the JavaScript side so their fields can be accessed.

Likewise, when receiving a callback from JavaScript into Ethers, the returned parameters can be made accessible with JSON.parse_string().

You will notice that "success" and "failure" objects are passed into most functions.  These objects are callbacks created by Godot's JavaScriptBridge.create_callback() function.  You can use one of the existing callbacks or create your own.

These callbacks are distinct from the "callback" object created by `EthersWeb.create_callback()`, which are entirely optional, and which allow you to specify which Godot node and callback function will receive the callback from JavaScript.

While I'm accustomed to how this works, it sounds convoluted just writing it out, so I will revise this later


[Check out the Documentation](https://github.com/Cactoidal/GodotEthersV3/blob/main/DOCUMENTATION.md)
