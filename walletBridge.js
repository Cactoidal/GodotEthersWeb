window.walletBridge = {


  // WEB3 WALLET DIRECT INTERACTIONS 

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
			success([address, balance], callback)
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

	switch_chain: async function(_chainId) {
	  await window.ethereum // Or window.ethereum if you don't support EIP-6963.
	.request({
	  method: "wallet_switchEthereumChain",
	  params: [{ chainId: _chainId }],
	})
	},

  add_chain: async function() {

  },



// ETHERS INTERACTIONS


  // ETH TRANSFER START

  startTransferETH: async function(recipient, amount, success, failure, callback) {
    
    var provider = new window.ethers.BrowserProvider(window.ethereum);
	  
    try {
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

  initiateContractRead: async function(contract_address, abi, method, args, success, failure, callback) {
    
    var provider = new window.ethers.BrowserProvider(window.ethereum);
    const iface = new ethers.Interface(abi);
    const calldata = iface.encodeFunctionData(method, args);
	  
    try {
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


  initiateContractCall: async function(contract_address, abi, method, args, valueEth, success, failure, callback) {
    
    var provider = new window.ethers.BrowserProvider(window.ethereum);
	  
    try {
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
      const iface = new ethers.Interface(abi);
      const calldata = iface.encodeFunctionData(method, args);
      console.log(calldata);

      const tx = await signer.sendTransaction({
        to: contract_address,
        data: calldata,
        value: valueEth ? ethers.parseEther(valueEth) : 0
      });
      
      success(tx, callback); 
    } 
  
    catch (_error) { 
      console.error(_error); 
      failure(_error.code, _error.message, callback)
      }

},

  // CONTRACT WRITE END



  // ERC20 INFO START

  getERC20Info: async function (contract_address, ABI, success, failure, callback, address) { 
	  var provider = new window.ethers.BrowserProvider(window.ethereum);
	  var contract = new window.ethers.Contract(contract_address, ABI, provider)
	  
    console.log("hello")
    try {
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
