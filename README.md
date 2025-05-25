# GodotEthersWeb
Ethers.js and Web3 Wallet Interaction for Godot 4.4+ HTML5 Builds

NOTE:
This addon will work only with Godot HTML5 projects running in a browser with a webwallet (such as Metamask).   For desktop projects, please refer to [GodotEthers](https://github.com/Cactoidal/GodotEthersV3).

Documentation coming soon!

___

### A Note on Security

This is experimental, alpha software, in a state of ongoing development, intended for usage on testnets.  

___

## Add GodotEthersWeb to your Godot 4.4 Project

* Download the GodotEthersWeb plugin ([cactus.godotethersweb](https://github.com/Cactoidal/GodotEthersWeb/tree/main/addons/cactus.godotethersweb)) and add it to your project's `addons` folder.

* Inside the editor, open Project Settings, click Plugins, and activate GodotEthersWeb.

* Restart the editor.

* Click "Project", then "Export..."  If you have not yet done so, download the export templates, and click "Add..." to add the Web export template.

* Click the "Resources" tab, and under "Filters to export non-resource files/folders" type: *.js

* Click "Export Project..." to create the HTML5 build.

* To quickly test, you can open Project > Project Settings > Run, set the Main Scene to "res://addons/cactus.godotethersweb/examples/Examples.tscn", and then click the Remote Deploy button in the upper right corner of the main editor window.

* OPTIONAL: If you want the .js files to be visible in the filesystem sidebar, click "Godot", open "Editor Settings", click "Advanced Settings", then go to Dock > Filesystem.  Under TextFile Extensions, add: js
___

## How to Use

 See [Examples.gd](https://github.com/Cactoidal/GodotEthersWeb/blob/main/addons/cactus.godotethersweb/examples/Examples.gd) for usage examples.

You'll want to connect `EthersWeb.connect_wallet()` to a button, prompting the user to connect.  The user must be connected for most functions to work.  Once the user has connected once, they won't need to connect again (unless they manually disconnect their wallet).  

You can call `EthersWeb.get_connected_wallet_info()` if you want to display the user address, gas balance, and current chain.

For blockchain operations, you can call `EthersWeb.transfer()`, `EthersWeb.send_transaction()`, and `EthersWeb.read_from_contract()`.  Basic ERC20 support has been built in, so you don't need to implement these functions yourself (see documentation).  You can also sign messages, sign typed data (ERC-712), and listen for events.

All blockchain interaction functions require you to specify the target chain, and they will automatically prompt the user to add the chain if their wallet does not have it.  

Make sure to add any chains you want to use to the `default_network_info` dictionary.
