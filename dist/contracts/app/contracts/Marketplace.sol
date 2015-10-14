contract Keystore{

	event Key(address indexed addr, bytes data);

	function setKey(bytes data){
		Key(tx.origin, data);
	}

}

contract AliasReg {
	mapping(address=>bytes32[]) addrToAliasesMap;
	mapping(bytes32=>address) aliasToAddrMap;

	function claimAlias(bytes32 alias){
		if(aliasToAddrMap[alias] != address(0)) return;

		var aliases = addrToAliasesMap[msg.sender];
		
		aliases[aliases.length++]=alias;
		aliasToAddrMap[alias]=msg.sender;
	}

	function claimAliases(bytes32[] aliases){
		for(var i = 0; i < aliases.length; i++){
			claimAlias(aliases[i]);
		}
	}

/*
	function abandonAliasByIndex(uint index){
		var aliases = addrToAliasesMap[msg.sender];
		
		if(aliases.length<=index) return;

		var alias = aliases[index];

		aliases[index] = 0;
		aliasToAddrMap[alias] = address(0);
	}
*/

	function getAliases(address addr) constant returns(bytes32[]){
		return addrToAliasesMap[addr];
	}

	function getAddr(bytes32 alias) constant returns(address){
		return aliasToAddrMap[alias];
	}

}

contract semiautonomous{

	address operator;
	bool[] operations;

	function semiautonomous(){
		operator = msg.sender;
	}

	function getOperator() constant returns(address){
		return operator;
	}

	function getOperations() constant returns(bool[]){
		return operations;
	}

	function operate(address addr, string func, bytes32[] values) {
        var isSuccess = addr.call(func,values);
        operations[operations.length++] = isSuccess;
    }
}

contract Forum{
	
	address moderator;

	event Comment(address indexed author, bytes32 indexed parentId, bytes data);
	event Vote(bytes indexed comment, uint8 direction);
	event Moderation(bytes indexed comment, uint8 direction);

	function Forum(){
		moderator = msg.sender;
	}

	function addComment(bytes32 parentId, bytes data){
		Comment(msg.sender, parentId, data);
	}

	function addVote(bytes comment, uint8 direction){
		Vote(comment, direction);
	}

	function addModeration(bytes comment, uint8 direction){
		if(msg.sender != moderator) return;
		Moderation(comment, direction);
	}

	function test() constant returns(bool){
		return true;
	}
}

contract Market is semiautonomous{
	address admin;
	address forumAddr;
	event Meta(bytes meta);
	AliasReg aliasReg;

	function Market(bytes meta){
		admin = tx.origin;
		var forum = new Forum();
		forumAddr = address(forum);
		aliasReg = AliasReg(0xe42e7754c58b11f7cee145efeca4ec8c232eb9b1);
		Meta(meta);
	}

	function getAdmin() constant returns(address){
		return admin;
	}

	function getForumAddr() constant returns(address){
		return forumAddr;
	}
	
	function setMeta(bytes meta){
		if(tx.origin!=admin) return;
		Meta(meta);
	}

	function claimAliases(bytes32[] aliases){
		aliasReg.claimAliases(aliases);
	}

	function claimAlias(bytes32 alias){
		aliasReg.claimAlias(alias);
	}

}

contract Order{
	address buyer;
	address merchant;
	address admin;
	uint fee;
	uint disputeSeconds;
	uint status;
	uint received;
	uint timestamp;
	uint shippedAt;

	event Meta(bytes meta);
	event Message(address indexed sender, bytes text);
	event Update(address indexed sender, uint indexed status);

	uint constant initialized = 0;
	uint constant cancelled = 1;
	uint constant shipped = 2;
	uint constant finalized = 3;
	uint constant disputed = 4;
	uint constant resolved = 5;

	function Order(
		bytes _meta
		,address _merchant
		,address _admin
		,uint _fee
		,uint _disputeSeconds
	){
		buyer = tx.origin;
		merchant = _merchant;
		admin = _admin;
		fee = _fee;
		disputeSeconds = _disputeSeconds;
		timestamp = now;
		Meta(_meta);
	}

	function addMessage(bytes text){
		if(tx.origin != buyer && tx.origin != merchant && tx.origin != admin)
			return;

		Message(tx.origin, text);
	}

	function(){
		received += msg.value;
	}

	function getBuyer() constant returns(address){
		return buyer;
	}

	function getMerchant() constant returns(address){
		return merchant;
	}

	function getAdmin() constant returns(address){
		return admin;
	}

	function getFee() constant returns(uint){
		return fee;
	}

	function getStatus() constant returns(uint){
		return status;
	}

	function getReceived() constant returns(uint){
		return received;
	}

	function getTimestamp() constant returns(uint){
		return timestamp;
	}

	function addUpdate(uint _status) private{
		status = _status;
		Update(tx.origin,_status);
	}

	function cancel(){

		if(status != initialized)
			return;

		if(tx.origin != buyer && tx.origin != merchant)
			return;

		var isSent = buyer.send(this.balance);
		if(!isSent) return;

		addUpdate(cancelled);
	}

	function markAsShipped(){

		if(status !=  initialized)
			return;

		if(tx.origin != merchant)
			return;

		shippedAt = now;
		addUpdate(shipped);
	}

	function finalize(){

		if(status !=  shipped)
			return;

		if(tx.origin != buyer && tx.origin != merchant)
			return;

		if(tx.origin == merchant && now - shippedAt < disputeSeconds)
			return;

		var isSent = merchant.send(this.balance);
		if(!isSent) return;
		
		addUpdate(finalized);
	}

	function dispute(){
		if(tx.origin != buyer)
			return;

		if(status != shipped)
			return;

		if(now - shippedAt > disputeSeconds)
			return;

		if(admin==0)
			return;

		addUpdate(disputed);
	}

	function resolve(uint buyerAmount){
		if(status!=disputed)
			return;

		if(tx.origin != admin)
			return;

		if(buyerAmount>0)
			buyer.send(buyerAmount);

		var merchantAmount = this.balance-buyerAmount;

		if(merchantAmount>0)
			merchant.send(merchantAmount);

		addUpdate(resolved);
	}
}



contract Store is semiautonomous{
    address merchant;
    event Meta(bytes meta);

    function Store(bytes meta){
        merchant = tx.origin;
        Meta(meta);
    }
    
    function getMerchant() constant returns(address){
    	return merchant;
    }

    function setMeta(bytes meta){
		if(tx.origin!=merchant) return;
		Meta(meta);
	}
}