window.walletBridge = {


  // WEB3 WALLET DIRECT INTERACTIONS 
	getProvider: async function() {
		window.provider = new window.ethers.BrowserProvider(window.ethereum);
		window.signer = await window.provider.getSigner();
		console.log(window.signer)
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

	getSignerWrapper: async function  (signal, success, failure) { 
	  window.provider = new window.ethers.BrowserProvider(window.ethereum);
	  try {
		window.signer = await window.provider.getSigner();
		console.log(window.signer); 
		success(signal, window.signer); } 
		
		catch (_error) { 
		  console.error(_error); 
		  err_dict = { 'code': _error.code, 'message': _error.message }; 
		  failure(signal, err_dict); 
		}
	},

	sendTransaction: async function (recipient, amount) {
	  const tx = await window.signer.sendTransaction({
		to: recipient,
		value: window.ethers.parseEther(amount)
	  });

	},

	sendTransaction2: async function (recipient, amount, success, failure) {
	  window.provider = new window.ethers.BrowserProvider(window.ethereum);
	  window.signer = await window.provider.getSigner();
	  const tx = await window.signer.sendTransaction({
		to: recipient,
		value: window.ethers.parseEther(amount)
	  });

	},


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




	// Contract READ - probably 3 parts - starts here

  //initiateContractRead: async function  (contract_address, ABI, success, failure, signal) { 
  doContractRead: async function  (contract_address, ABI, success) { 
	  var provider = new window.ethers.BrowserProvider(window.ethereum);
	  var contract = new window.ethers.Contract(contract_address, ABI, provider)
	  
	  var sym = await contract.symbol()
	  console.log(sym)

	  var decimals = await contract.decimals()
	  console.log(decimals)

	  //The USDC contract has some LINK for some reason
	  var balance = await contract.balanceOf("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
	  console.log(balance)

	  var balance_amount = window.ethers.formatUnits(balance, decimals)
	  console.log(balance_amount)

	  success(sym, decimals, balance, balance_amount)

	},



	// Contract READ - concludes here









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


  };
