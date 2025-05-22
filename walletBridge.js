window.walletBridge = {

  // WEB3 WALLET DIRECT INTERACTIONS 

  handleChainChanged: async function() {
    console.log("chain changed")
  },

  handleAccountsChanged: async function() {
    console.log("account changed")
  },

  getBalance: async function(address, success, failure, callback) {
    var provider = new window.ethers.BrowserProvider(window.ethereum);
    
    try {
			const balance = await provider.getBalance(address);
			success(balance, callback)
		  } 

    catch (_error) { 
        console.error(_error); 
        failure(_error.code, _error.message, callback)
		  }
  },

  getWalletAddress: async function(success, failure, callback) {
    var provider = new window.ethers.BrowserProvider(window.ethereum);
    
    try {
      const signer = await provider.getSigner();
			const address = await signer.getAddress();
			success(address, callback)
		  } 

    catch (_error) { 
        console.error(_error); 
        failure(_error.code, _error.message, callback)
		  }
  },


  getWalletInfo: async function(success, failure, callback) {
    var provider = new window.ethers.BrowserProvider(window.ethereum);
    
    try {
      const signer = await provider.getSigner();
			const address = await signer.getAddress();
      const balance = await provider.getBalance(address);
      const chainId = await window.ethereum.request({method: "eth_chainId"})
			success([address, balance, chainId], callback)
		  } 

    catch (_error) { 
        console.error(_error); 
        failure(_error.code, _error.message, callback)
		  }


  },

	request_accounts: async function() {
	  window.account_list = await window.ethereum.request({ method: 'eth_requestAccounts' })
	  console.log(window.account_list)
  },

  getAccounts: async function() {
		try {
			const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
			window.lastAccounts = accounts;
		  } catch (e) {
			console.error("MetaMask error:", e);
			window.lastAccounts = null;
		  }
	},


	current_chain: async function() {
	  window.chainId = await window.ethereum.request({ method: 'eth_chainId' });
	  console.log(window.chainId)
	},

	switch_chain: async function(_chainId, success, failure, callback) {
	  
    try {
    await window.ethereum // Or window.ethereum if you don't support EIP-6963.
	.request({
	  method: "wallet_switchEthereumChain",
	  params: [{ chainId: _chainId }],
	  })
    success(_chainId, callback)
    }
    catch (_error) { 
		  console.error(_error); 
		  failure(_error.code, _error.message, callback)
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
		  failure(_error.code, _error.message, callback)
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
              symbol: symbol,                    // Token symbol (up to 5 chars)
              decimals: decimals,                     // Token decimals
              //image: 'https://example.com/token-icon.png', // (Optional) Token icon URL
            },
          },
        });
        success(callback)

      }
      catch (_error) { 
        console.error(_error); 
        failure(_error.code, _error.message, callback)
        }
  },



// ETHERS INTERACTIONS


  // ETH TRANSFER START

  startTransferETH: async function(_chainId, recipient, amount, success, failure, callback) {
    
    try {

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.ethereum);

      var signer = await provider.getSigner();
      this.transferETH(signer, recipient, amount, success, failure, callback) 
        } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(_error.code, _error.message, callback)
		    }

  },

  transferETH: async function(signer, recipient, amount, success, failure, callback) {
	  
    try {
      tx = await signer.sendTransaction(
        {
        to: recipient,
        value: window.ethers.parseEther(amount)
        }
        );
        success(tx, callback); 
        } 
      
      catch (_error) { 
        console.error(_error); 
        failure(_error.code, _error.message, callback)
        }


  },


  // ETH TRANSFER END



  // CONTRACT READ START

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
        success(decoded, callback); 
        } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(_error.code, _error.message, callback)
		    }

  },


  // CONTRACT READ END




  // CONTRACT WRITE START
  

  initiateContractCall: async function(_chainId, contract_address, abi, method, args, valueEth, success, failure, callback) {
	  console.log("what")
    try {

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.ethereum);

      var signer = await provider.getSigner();
      this.callContractFunction(signer, contract_address, abi, method, args, valueEth, success, failure, callback) 
          } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(_error.code, _error.message, callback)
		    }

  },

  callContractFunction: async function(signer, contract_address, abi, method, args, valueEth, success, failure, callback) {

    try {
      const iface = new window.ethers.Interface(abi);
      const calldata = iface.encodeFunctionData(method, args);
      console.log(calldata);

      const tx = await signer.sendTransaction({
        to: contract_address,
        data: calldata,
        value: valueEth ? window.ethers.parseEther(valueEth) : 0
      });
      
      success(JSON.stringify(tx), callback); 
      
      try {
        const receipt = await tx.wait();
        success(JSON.stringify(receipt), callback)
      }
      catch (_error) { 
        console.error(_error); 
        failure(_error.code, _error.message, callback)
        }
      

    } 
  
    catch (_error) { 
      console.error(_error); 
      failure(_error.code, _error.message, callback)
      }

},

  // CONTRACT WRITE END



  // SIGN MESSAGE START

  signMessage: async function(message, success, failure, callback) {
    
    var provider = new window.ethers.BrowserProvider(window.ethereum);
	  
    try {
      var signer = await provider.getSigner();

      //const bytes = new TextEncoder().encode(message);

      var signature = await signer.signMessage(message);
      success(signature, callback)
      } 
		
    catch (_error) { 
		  console.error(_error); 
		  failure(_error.code, _error.message, callback)
		    }

  },


  // SIGN MESSAGE END



  // SIGN TYPED START

  signTyped: async function(domainJson, typesJson, valueJson, success, failure, callback) {
    try {
      const domain = JSON.parse(domainJson);
      const types = JSON.parse(typesJson);
      const value = JSON.parse(valueJson);

      const provider = new window.ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      const signature = await signer.signTypedData(domain, types, value);
      console.log("EIP-712 signature:", signature);
      success(signature, callback)
    } 
    
    catch (_error) { 
		  console.error(_error); 
		  failure(_error.code, _error.message, callback)
		    }
  },

   // SIGN TYPED END


  // LISTEN FOR EVENTS START

  listenForEvent: async function(_chainId, contract_address, ABI, event, success, failure, callback) {
	  
    try {

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.ethereum);
      var contract = new window.ethers.Contract(contract_address, ABI, provider)

      contract.on(event, (sender, value, event) => {
        success(sender, value, event)
      });

      //contract.on(event, (sender, value, event) => {
      //  console.log('MyEvent emitted: ', { sender, value });
      //  console.log('Full event data: ', event);
      //});

      //success(event, callback)
    } 
    
    catch (_error) { 
		  console.error(_error); 
		  failure(_error.code, _error.message, callback)
		    }
  },



  // LISTEN FOR EVENTS END


  // STOP LISTEN FOR EVENTS BEGIN

  endEventListen: async function(_chainId, contract_address, ABI, success, failure, callback) {
	  
    try {

      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: _chainId }],
        })
      
      var provider = new window.ethers.BrowserProvider(window.ethereum);
      var contract = new window.ethers.Contract(contract_address, ABI, provider)

      contract.removeAllListeners();
      success(callback)
      }
    catch (_error) { 
		  console.error(_error); 
		  failure(_error.code, _error.message, callback)
		    }
  },



  // STOP LISTEN FOR EVENTS END




  // ERC20 INFO START

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


      var name = await contract.name()

      var sym = await contract.symbol()

      var decimals = await contract.decimals()

      var balance = await contract.balanceOf(address)

      var balance_amount = window.ethers.formatUnits(balance, decimals)

      success([name, sym, decimals, balance_amount], callback)
  }
    catch (_error) { 
      console.error(_error); 
      failure(_error.code, _error.message, callback)
    }

	},

    // ERC20 INFO END


  };


  // Listening for changes from Wallet
  // Not particularly consistent
  if (window.ethereum) {
    window.ethereum.on('accountsChanged', window.walletBridge.handleAccountsChanged);
    window.ethereum.on('chainChanged', window.walletBridge.handleChainChanged);
  };