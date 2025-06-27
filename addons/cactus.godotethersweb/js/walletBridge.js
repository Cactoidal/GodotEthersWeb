window.walletBridge = {

// CONNECTOR
// See the "Connector.tscn" scene in the addons examples folder.
// When the scene is instantiated, it sets up a listener in this function,
// then pings any wallets in the window.  The names of detected wallets are then
// fed back to Godot to populate a set of buttons.  Clicking a button will
// call the connectWallet function, setting the selectedProvider, and then
// EthersWeb will request the wallet's list of connected accounts.
  detectWallets: function(callback) {
    window.walletDetectionHandler = function handleAnnounce(event) {
      window.walletBridge.walletDetected(event, callback);
      }
    window.addEventListener('eip6963:announceProvider', window.walletDetectionHandler)
  
    window.dispatchEvent(new Event('eip6963:requestProvider'));
  },


  walletDetected: function(event, callback) {
    const { detail } = event;
    const { info, provider } = detail;

    console.log('Discovered wallet:', info.name);
    console.log(provider)

    window[info.name] = provider
    
    callback(info.name)
  },

  
  connectWallet: async function(walletName) {
    window.selectedProvider = window[walletName]
    window.selectedProvider.on('accountsChanged', window.walletBridge.handleAccountsChanged);
    window.selectedProvider.on('chainChanged', window.walletBridge.handleChainChanged);
    window.removeEventListener('eip6963:announceProvider', window.walletDetectionHandler)
  },
  


  // WEB3 WALLET
  getBalance: async function(address, success, failure, callback) {
    var provider = new window.ethers.BrowserProvider(window.selectedProvider);
    
    try {
			const balance = await provider.getBalance(address);
			success(callback, balance)
		  } 

    catch (_error) { 
        console.error(_error); 
        failure(callback, _error.code, _error.message)
		  }
  },

  getWalletAddress: async function(success, failure, callback) {
    var provider = new window.ethers.BrowserProvider(window.selectedProvider);
    
    try {
      const signer = await provider.getSigner();
			const address = await signer.getAddress();
			success(callback, address)
		  } 

    catch (_error) { 
        console.error(_error); 
        failure(callback, _error.code, _error.message)
		  }
  },


  getWalletInfo: async function(success, failure, callback) {
    var provider = new window.ethers.BrowserProvider(window.selectedProvider);
    
    try {
      const signer = await provider.getSigner();
      var _address = await signer.getAddress();
      var _chainId = await window.selectedProvider.request({method: "eth_chainId"});
      var _balance = await provider.getBalance(_address);
      
      const info = {
        address: _address,
        chainId: _chainId,
    
        balance: window.ethers.formatUnits(_balance)
      }
      console.log(info)
			success(callback, info)
		  } 

    catch (_error) { 
        console.error(_error); 
        failure(callback, _error.code, _error.message)
		  }


  },

  getCurrentBlockTimestamp: async function(success, failure, callback) {
    try {
      // Ask MetaMask for the latest block
      const latestBlock = await window.selectedProvider.request({
        method: 'eth_getBlockByNumber',
        params: ['latest', false], // false = don't return full transaction objects
      });
  
      // Convert hex timestamp to decimal
      timestamp = parseInt(latestBlock.timestamp, 16);
  
      console.log("Latest block timestamp:", timestamp);
  
      success(callback, timestamp);

    } catch (error) {
      console.error("Error fetching block timestamp:", error);
      failure(callback, _error.code, _error.message)
    }
  },

  
  poll_accounts: async function(success, failure, callback) {
    try {
      account_list = await window.selectedProvider.request({ method: 'eth_accounts' })
      success(callback, account_list[0])
      }
      catch (_error) { 
        console.error(_error); 
        failure(callback, _error.code, _error.message)
      }
  },


	request_accounts: async function(success, failure, callback) {
    // Simple fallback, if Connector.tscn is not used 
    // (see CONNECTOR above for more info)
    if (!window.selectedProvider) {
      window.selectedProvider = window.selectedProvider
    }

    try {
	  account_list = await window.selectedProvider.request({ method: 'eth_requestAccounts' })
    success(callback, account_list)
    }
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		}
  },


	current_chain: async function(success, failure, callback) {
    try {
      chainId = await window.selectedProvider.request({ method: 'eth_chainId' });
      success(callback, chainId)
      }
    catch (_error) { 
        console.error(_error); 
        failure(callback, _error.code, _error.message)
      }
	},


	switch_chain: async function(_chainId, success, failure, callback) {
	  
    try {
    await window.selectedProvider 
	.request({
	  method: "wallet_switchEthereumChain",
	  params: [{ chainId: _chainId }],
	  })
    success(callback, _chainId)
    }
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		}

	},



  add_chain: async function(network_info, success, failure, callback) {
  
    try {
      const network = JSON.parse(network_info)

      await window.selectedProvider 
        .request({
          method: "wallet_addEthereumChain",
          params: [
            {
              chainId: network.chainId,
              chainName: network.chainName,
              rpcUrls: network.rpcUrls,
              nativeCurrency: network.nativeCurrency,
              blockExplorerUrls: network.blockExplorerUrls
            },
          ],
        })

        await window.selectedProvider.request({
          method: "wallet_switchEthereumChain",
          params: [{ chainId: network.chainId }],
          })
        success(callback)
    }
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		}
  },



  add_erc20: async function(_chainId, token_address, symbol, decimals, success, failure, callback) {
    
    try {

      await window.selectedProvider.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
        await window.selectedProvider.request({
          method: 'wallet_watchAsset',
          params: {
            type: 'ERC20',
            options: {
              address: token_address, // Token contract address
              symbol: symbol,         // Token symbol (up to 5 chars)
              decimals: decimals,     // Token decimals
              //image: 'https://example.com/token-icon.png', // (Optional) Token icon URL
            },
          },
        });
        success(callback)

      }
      catch (_error) { 
        console.error(_error); 
        failure(callback, _error.code, _error.message)
        }
  },



// ETHERS INTERACTIONS


  // ETH TRANSFER

  startTransferETH: async function(_chainId, recipient, amount, success, failure, receiptCallback, callback) {
    
    try {

      await window.selectedProvider.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.selectedProvider);

      var signer = await provider.getSigner();
      this.transferETH(signer, recipient, amount, success, failure, receiptCallback, callback) 
        } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }

  },

  transferETH: async function(signer, recipient, amount, success, failure, receiptCallback, callback) {
	  
    try {
      tx = await signer.sendTransaction(
        {
        to: recipient,
        value: window.ethers.parseEther(amount)
        }
        );
        console.log(tx)
        success(callback, tx); 

        try {
          const receipt = await tx.wait();
          console.log(receipt)
          receiptCallback(receipt)
        }
        catch (_error) { 
          console.error(_error); 
          //receiptCallback(_error.code, _error.message)
          }
        
        }
      
      catch (_error) { 
        console.error(_error); 
        failure(callback, _error.code, _error.message)
        }


  },





  // CONTRACT READ 

  initiateContractRead: async function(_chainId, contract_address, calldata, success, failure, callback) {
    
    try {

        await window.selectedProvider.request({
          method: "wallet_switchEthereumChain",
          params: [{ chainId: _chainId }],
          })

        var provider = new window.ethers.BrowserProvider(window.selectedProvider);

        const result = await provider.call({
        to: contract_address,
        data: calldata,
        });

        success(callback, result.toString()); 
        } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }

  },





  // CONTRACT WRITE 

  initiateContractCall: async function(_chainId, contract_address, calldata, valueEth, gasLimitOverride, success, failure, receiptCallback, callback) {
    
    try {

      await window.selectedProvider.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.selectedProvider);

      var signer = await provider.getSigner();
      this.callContractFunction(signer, contract_address, calldata, valueEth, gasLimitOverride, success, failure, receiptCallback, callback) 
          } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }

  },

  callContractFunction: async function(signer, contract_address, calldata, valueEth, gasLimitOverride, success, failure, receiptCallback, callback) {

    try {
      console.log(calldata)

      var tx;
      if (gasLimitOverride) {
          tx = await signer.sendTransaction({
          to: contract_address,
          data: calldata,
          gasLimit: gasLimitOverride,
          value: valueEth ? window.ethers.parseEther(valueEth) : 0
        })
      }

      else {
          tx = await signer.sendTransaction({
          to: contract_address,
          data: calldata,
          value: valueEth ? window.ethers.parseEther(valueEth) : 0
      })
      }
      console.log(tx)
      success(callback, tx); 
      
      try {
        const receipt = await tx.wait();
        console.log(receipt)
        receiptCallback(receipt, callback)
      }
      catch (_error) { 
        console.error(_error); 
        //receiptCallback(_error.code, _error.message)
        }
    
    } 
  
    catch (_error) { 
      console.error(_error); 
      failure(callback, _error.code, _error.message)
      }

},





  // SIGN MESSAGE

  signMessage: async function(message, success, failure, callback) {
    
    var provider = new window.ethers.BrowserProvider(window.selectedProvider);
	  
    try {
      var signer = await provider.getSigner();

      var signature = await signer.signMessage(message);
      success(callback, signature)
      } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }

  },





  // SIGN TYPED 

  signTyped: async function(_chainId, domainJson, typesJson, valueJson, success, failure, callback) {
    try {

      await window.selectedProvider.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })

      const domain = JSON.parse(domainJson);
      const types = JSON.parse(typesJson);
      const value = JSON.parse(valueJson);

      const provider = new window.ethers.BrowserProvider(window.selectedProvider);
      const signer = await provider.getSigner();

      const signature = await signer.signTypedData(domain, types, value);
      console.log("EIP-712 signature:", signature);
      success(callback, signature)
    } 
    
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }
  },





  // LISTEN FOR EVENTS 

  listenForEvent: async function(_chainId, wss_node, contract_address, _topics, success, failure, eventCallback, callback) {
	  
    try {

      await window.selectedProvider.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      

      if (!window.provider) {
        window.provider = {}
      }
     
      if (!(_chainId in window.provider)) {
        window.provider[_chainId] = new window.ethers.WebSocketProvider(wss_node)
        //window.provider[_chainId] = new window.ethers.BrowserProvider(window.selectedProvider)
      }



      const filter = {
        address: contract_address,
        topics: _topics
      };
      
      window.provider[_chainId].on(filter, (log) => {
        console.log(log)
        eventCallback(JSON.stringify(log))
  
      });
      success(callback);
     

    } 
    
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }
  },





  // END EVENT LISTENING

  endEventListen: async function(_chainId, contract_address, _topics, success, failure, callback) {
	  
    try {

      await window.selectedProvider.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })

      const filter = {
        address: contract_address,
        topics: _topics
      };
      
      window.provider[_chainId].removeAllListeners(filter);
      success(callback, contract_address)
      }
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }
  },






  // ERC20 INFO

  getERC20Info: async function (_chainId, contract_address, ABI, success, failure, callback, address) { 
  
    try {

      await window.selectedProvider.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.selectedProvider);
      var contract = new window.ethers.Contract(contract_address, ABI, provider)

      if (address === "") {
        var signer = await provider.getSigner();
        address = await signer.getAddress();
      }


      var _name = await contract.name()

      var _symbol = await contract.symbol()

      var _decimals = await contract.decimals()

      var _balance = await contract.balanceOf(address)

      var _balance_amount = window.ethers.formatUnits(_balance, _decimals)

      
      const info = {
        name: _name,
        symbol: _symbol,
        decimals: _decimals,
        balance: _balance_amount
      }

      success(callback, info)
  }
    catch (_error) { 
      console.error(_error); 
      failure(callback, _error.code, _error.message)
    }

	},



    // Triggered when user manually changes connected chain
    // (but not when changing back)
    handleChainChanged: async function() {
      console.log("chain changed")
    },
  
    // Triggered when user manually changes connected account
    // (but not when changing back)
    handleAccountsChanged: async function() {
      console.log("account changed")
    },




  // BIG INT MATH
  // These are not async, so they can be called and returned directly
  // back into Godot without a callback function

  bigintArithmetic: function(_number1, _number2, operation) {

    try {
      var number1 = BigInt(_number1);
      var number2 = BigInt(_number2);

      var output 

      if (operation == "ADD") {
        output = (number1 + number2);
      }

      else if (operation == "SUBTRACT") {
        if (number1 >= number2) {
          output = (number1 - number2);
        }
      }

      else if (operation == "DIVIDE") {
        if (number1 >= number2) {
          output = (number1 / number2);
        }
      }

      else if (operation == "MULTIPLY") {
          output = (number1 * number2);
      }

      else if (operation == "MODULO") {
        output = number1 % number2;
      }
      console.log(output)
      return output.toString()
    }

    catch (_error) { 
      console.error(_error); 
      return output
    }

  },

  bigintCompare: function(_number1, _number2, operation) { 
    var number1 = BigInt(_number1);
    var number2 = BigInt(_number2);

    var output 

    try {
      if (operation == "GREATER THAN") {
          if (number1 > number2) {
              output = true;
          }
          else {
              output = false;
          }
      }
      else if (operation == "LESS THAN") {
          if (number1 < number2) {
              output = true;
          }
          else {
              output = false;
          }
      }
      else if (operation == "GREATER THAN OR EQUAL") {
          if (number1 >= number2) {
              output = true;
          }
          else {
              output = false;
          }
      }
      else if (operation == "LESS THAN OR EQUAL") {
          if (number1 <= number2) {
              output = true;
          }
          else {
              output = false;
          }
      }
      else if (operation == "EQUAL") { 
          if (number1 == number2) {
              output = true;
          }
          else {
              output = false;
          }
      }
      console.log(output)
      return output
    }

    catch (_error) { 
      console.error(_error); 
      return output
    }


},

abiEncode: function(types, values) {

  var encoder = window.ethers.AbiCoder.defaultAbiCoder()

  var calldata = encoder.encode(types, values)
  
  return calldata
},

abiDecode: function(types, calldata) {

  var decoder = window.ethers.AbiCoder.defaultAbiCoder()

  var values = decoder.decode(types, calldata)
  
  return values.toString()
},



getFunctionSelector: function(selectorString) {
  var selectorBytes = window.ethers.toUtf8Bytes(selectorString)
  var selectorHash = window.ethers.keccak256(selectorBytes)
  return selectorHash
},




};


 