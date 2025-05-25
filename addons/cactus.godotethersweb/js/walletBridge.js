window.walletBridge = {
  
  // WEB3 WALLET 

  getBalance: async function(address, success, failure, callback) {
    var provider = new window.ethers.BrowserProvider(window.ethereum);
    
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
    var provider = new window.ethers.BrowserProvider(window.ethereum);
    
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
    var provider = new window.ethers.BrowserProvider(window.ethereum);
    
    try {
      const signer = await provider.getSigner();
      var _address = await signer.getAddress();
      var _chainId = await window.ethereum.request({method: "eth_chainId"});
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


	request_accounts: async function(success, failure, callback) {
    try {
	  account_list = await window.ethereum.request({ method: 'eth_requestAccounts' })
    success(callback, account_list)
    }
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		}
  },


	current_chain: async function(success, failure, callback) {
    try {
      chainId = await window.ethereum.request({ method: 'eth_chainId' });
      success(callback, chainId)
      }
    catch (_error) { 
        console.error(_error); 
        failure(callback, _error.code, _error.message)
      }
	},


	switch_chain: async function(_chainId, success, failure, callback) {
	  
    try {
    await window.ethereum // Or window.ethereum if you don't support EIP-6963.
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

      await window.ethereum 
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

        await window.ethereum.request({
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

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
        await window.ethereum.request({
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

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.ethereum);

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

  initiateContractRead: async function(_chainId, contract_address, abi, method, args, success, failure, callback) {
      
    try {

        await window.ethereum.request({
          method: "wallet_switchEthereumChain",
          params: [{ chainId: _chainId }],
          })
        
        var provider = new window.ethers.BrowserProvider(window.ethereum);
        const iface = new window.ethers.Interface(abi);
        const calldata = iface.encodeFunctionData(method, args);


        const result = await provider.call({
        to: contract_address,
        data: calldata,
        });

        decoded = iface.decodeFunctionResult(method, result)

        // BigInts must be converted into Strings so they can be
        // read into Godot
        converted = this.convertBigIntsToStrings(decoded)
   
        success(callback, converted); 
        } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }

  },





  // CONTRACT WRITE 

  initiateContractCall: async function(_chainId, contract_address, abi, method, args, valueEth, success, failure, receiptCallback, callback) {
	  console.log("what")
    try {

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.ethereum);

      var signer = await provider.getSigner();
      this.callContractFunction(signer, contract_address, abi, method, args, valueEth, success, failure, receiptCallback, callback) 
          } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }

  },

  callContractFunction: async function(signer, contract_address, abi, method, args, valueEth, success, failure, receiptCallback, callback) {

    try {
      const iface = new window.ethers.Interface(abi);
      const calldata = iface.encodeFunctionData(method, args);
      console.log(calldata);

      const tx = await signer.sendTransaction({
        to: contract_address,
        data: calldata,
        value: valueEth ? window.ethers.parseEther(valueEth) : 0
      });
      
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





  // SIGN MESSAGE

  signMessage: async function(message, success, failure, callback) {
    
    var provider = new window.ethers.BrowserProvider(window.ethereum);
	  
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

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })

      const domain = JSON.parse(domainJson);
      const types = JSON.parse(typesJson);
      const value = JSON.parse(valueJson);

      const provider = new window.ethers.BrowserProvider(window.ethereum);
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

  listenForEvent: async function(_chainId, wss_node, contract_address, ABI, event, success, failure, eventCallback, callback) {
	  
    try {

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      

      if (!window.provider) {
        window.provider = {}
      }
     
      if (!(_chainId in window.provider)) {
        window.provider[_chainId] = new window.ethers.WebSocketProvider(wss_node)
        //window.provider[_chainId] = new window.ethers.BrowserProvider(window.ethereum)
      }

      const iface = new window.ethers.Interface(ABI);
      const topic = iface.getEvent(event).topicHash;

      console.log(topic)

      const filter = {
        address: contract_address,
        topics: [topic]
      };
      
      window.provider[_chainId].on(filter, (log) => {
        const parsed = iface.parseLog(log);
        var deproxied = this.deProxify(parsed.args)
        var converted = this.convertBigIntsToStrings(deproxied)
        console.log(converted)
        eventCallback(converted)
      });
      success(callback);
     

    } 
    
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }
  },





  // END EVENT LISTENING

  endEventListen: async function(_chainId, contract_address, ABI, event, success, failure, callback) {
	  
    try {

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })

      const iface = new window.ethers.Interface(ABI);
      const fragment = iface.getEvent(event);
      const signature = fragment.format(); 
      const topic = window.ethers.id(signature);

      const filter = {
        address: contract_address,
        topics: [topic]
      };
      
      window.provider[_chainId].removeAllListeners(filter);
      success(callback, topic)
      }
    catch (_error) { 
		  console.error(_error); 
		  failure(callback, _error.code, _error.message)
		    }
  },






  // ERC20 INFO

  getERC20Info: async function (_chainId, contract_address, ABI, success, failure, callback, address) { 
  
    try {

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.ethereum);
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


    // Parsed event logs (produced by parseLog()) are proxies, which makes
    // cycling through their fields difficult.  We must access every field
    // to convert all BigInts into Strings, so they can be read into Godot.
    deProxify: function (args) {

      try {
      const result = {};
      for (const key in args) {
        result[key] = args[key];
      }
        return result;
    
      }
      catch(_error) {
        console.error(_error)
      }
    },

    
    // Not fully tested yet

    /**
 * Recursively converts all BigNumbers in an object (or array) to strings.
 * @param {*} input - The object, array, or value to process.
 * @returns {*} A new structure with BigNumbers converted to strings.
 */
    convertBigIntsToStrings: function(input) {

      if (typeof(input) == "bigint") {
        return input.toString();
      }

      if (Array.isArray(input)) {
        return input.map(walletBridge.convertBigIntsToStrings);
      }

      if (typeof input === 'object' && input !== null) {
        const result = {};
        for (const key in input) {
          if (Object.prototype.hasOwnProperty.call(input, key)) {
            result[key] = walletBridge.convertBigIntsToStrings(input[key]);
          }
        }
        return result;
      }

      return input; // return unchanged for primitives (string, number, null, etc.)
    }
    
  };


  // Listen for changes from wallet
  if (window.ethereum) {
    window.ethereum.on('accountsChanged', window.walletBridge.handleAccountsChanged);
    window.ethereum.on('chainChanged', window.walletBridge.handleChainChanged);
  };