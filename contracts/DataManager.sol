pragma solidity ^0.4.17;


import "./iERC20Token.sol";
import "./CurrencyToken.sol";
import "./withAccessManager.sol";

/// @title DataManager contract
contract DataManager is withAccessManager {
    // FIELDS
    uint256 public version = 2;
    // currency symbol => currency erc20 contract address
    mapping(bytes32 => address) public currencyAddresses;
    // currency address => currency symbol
    mapping(address => bytes32) public currencySymbols;
    // clientId => depositAddress
    mapping(bytes32 => address) public depositAddresses;
    // depositAddress => clientId
    mapping(address => bytes32) public depositClientIds;
    // blockchainActionId => boolean 
    mapping(bytes32 => bool) public actionStatus;
    // blockchainActionData
    struct actionData {
        bytes32 currency;
        uint amount;
        bytes32 accountId;
        address to;
        uint pptFee;
    }
    // blockchainActionId => actionData
    mapping(bytes32 => actionData) public blockchainActionIdData;
    
    //actionId => invoiceId
    mapping(bytes32 => bytes32) public actionIdToInvoiceId;
    // invoice provider company data
    struct providerCompany {
        //bool isEnabled;
        bytes32 companyNumber;
        bytes32 companyName;
        bytes2 countryCode;
    }
    // companyCode => companyNumber => providerId
    mapping(bytes2 => mapping(bytes32 => bytes32)) public providerData;
    // providedId => providerCompany
    mapping(bytes32 => providerCompany) public providerCompanyData;
    // crowdsale invoiceDetails
    struct _invoiceDetails {
        bytes2 invoiceCountryCode;
        bytes32 invoiceCompanyNumber;
        bytes32 invoiceCompanyName;
        bytes32 invoiceNumber;
    }
    // crowdsale invoiceData
    struct invoiceData {
        bytes32 providerUserId;
        bytes32 invoiceCompanyName;
    }

    // country code => company number => invoice number => invoice data
    mapping(bytes2 => mapping(bytes32 => mapping(bytes32 => invoiceData))) public invoices;

    // NON-CONSTANT METHODS

    /** @dev Constructor that sets the server when contract is deployed.
      * @param _accessManager The address to set as the access manager.
      */
    function DataManager(address _accessManager) public withAccessManager(_accessManager) { }

    /** @dev Adds a new deposit smart contract address linked to a client id
      * @param _depositAddress the deposit smart contract address
      * @param _clientId the client id
      * @return success true/false denoting successful function call
      */
    function setDepositAddress(address _depositAddress, bytes32 _clientId) public onlyServerOrOnlyPopulous returns (bool success) {
        if (depositAddresses[_clientId] != 0x0 && depositClientIds[_depositAddress] != 0x0){
            return false;
        } else {
            depositAddresses[_clientId] = _depositAddress;
            depositClientIds[_depositAddress] = _clientId;
            return true;
        }
    }

    /** @dev Adds a new currency sumbol and smart contract address  
      * @param _currencyAddress the currency smart contract address
      * @param _currencySymbol the currency symbol
      * @return success true/false denoting successful function call
      */
    function setCurrency(address _currencyAddress, bytes32 _currencySymbol) public onlyServerOrOnlyPopulous returns (bool success) {
        if (currencySymbols[_currencyAddress] != 0x0 && currencyAddresses[_currencySymbol] != 0x0){
            return false;
        } else {
            currencySymbols[_currencyAddress] = _currencySymbol;
            currencyAddresses[_currencySymbol] = _currencyAddress;
            assert(currencyAddresses[_currencySymbol] != 0x0 && currencySymbols[_currencyAddress] != 0x0);
            return true;
        }
    }

    /** @dev Updates a currency sumbol and smart contract address  
      * @param _currencyAddress the currency smart contract address
      * @param _currencySymbol the currency symbol
      * @return success true/false denoting successful function call
      */
    function _setCurrency(address _currencyAddress, bytes32 _currencySymbol) public onlyPopulous returns (bool success) {
        currencySymbols[_currencyAddress] = _currencySymbol;
        currencyAddresses[_currencySymbol] = _currencyAddress;
        assert(currencyAddresses[_currencySymbol] != 0x0 && currencySymbols[_currencyAddress] != 0x0);
        return true;
    }

    /** @dev set blockchain action data in struct 
      * @param _blockchainActionId the blockchain action id
      * @param currency the token currency symbol
      * @param accountId the clientId
      * @param to the blockchain address or smart contract address used in the transaction
      * @param amount the amount of tokens in the transaction
      * @return success true/false denoting successful function call
      */
    function setBlockchainActionData(
        bytes32 _blockchainActionId, bytes32 currency, 
        uint amount, bytes32 accountId, address to, uint pptFee) 
        public
        onlyServerOrOnlyPopulous 
        returns (bool success)
    {
        require(actionStatus[_blockchainActionId] == true);
        blockchainActionIdData[_blockchainActionId].currency = currency;
        blockchainActionIdData[_blockchainActionId].amount = amount;
        blockchainActionIdData[_blockchainActionId].accountId = accountId;
        blockchainActionIdData[_blockchainActionId].to = to;
        blockchainActionIdData[_blockchainActionId].pptFee = pptFee;
        return true;
    }

    /** @dev upgrade deposit address 
      * @param _blockchainActionId the blockchain action id
      * @param _clientId the client id
      * @param _depositContract the deposit contract address for the client
      * @return success true/false denoting successful function call
      */
    function upgradeDepositAddress(bytes32 _blockchainActionId, bytes32 _clientId, address _depositContract) public
      onlyServerOrOnlyPopulous
      returns (bool success)
    {
        require(actionStatus[_blockchainActionId] == false);
        // check that client does not already have a stored deposit address
        require(depositAddresses[_clientId] == 0x0 && depositAddresses[_clientId] != _depositContract);
        // DepositContract(_clientId).clientId() == _clientId
        // store the deposit address for the client Id
        //DepositContract(_clientId, address(AM));
        depositAddresses[_clientId] = _depositContract;
        // check that deposit address has been stored for client Id
        assert(depositAddresses[_clientId] != 0x0);
        // set blockchain action data
        actionStatus[_blockchainActionId] = true;
        blockchainActionIdData[_blockchainActionId].accountId = _clientId;
        blockchainActionIdData[_blockchainActionId].to = depositAddresses[_clientId];
        return true;
    }
  

    /** @dev Updates a deposit address for client id
      * @param _blockchainActionId the blockchain action id
      * @param _clientId the client id
      * @param _depositContract the deposit contract address for the client
      * @return success true/false denoting successful function call
      */
    function _setDepositAddress(bytes32 _blockchainActionId, bytes32 _clientId, address _depositContract) public
      onlyPopulous
      returns (bool success)
    {
        require(actionStatus[_blockchainActionId] == false);
        depositAddresses[_clientId] = _depositContract;
        // check that deposit address has been stored for client Id
        assert(depositAddresses[_clientId] != 0x0);
        // set blockchain action data
        actionStatus[_blockchainActionId] = true;
        blockchainActionIdData[_blockchainActionId].accountId = _clientId;
        blockchainActionIdData[_blockchainActionId].to = depositAddresses[_clientId];
        return true;
    }

    /** @dev Set action status for blockchain action  
      * @param _blockchainActionId the action id
      * @return success true or false if function call is successful
      */
    function setActionStatus(bytes32 _blockchainActionId) public onlyServerOrOnlyPopulous returns (bool success) {
        require(actionStatus[_blockchainActionId] == false);
        actionStatus[_blockchainActionId] = true;
        return true;
    }

    /** @dev Add a new invoice to the platform  
      * @param _providerUserId the providers user id
      * @param _invoiceCountryCode the country code of the provider
      * @param _invoiceCompanyNumber the providers company number
      * @param _invoiceCompanyName the providers company name
      * @param _invoiceNumber the invoice number
      * @return success true or false if function call is successful
      */
    function setInvoice(
        bytes32 _providerUserId, bytes2 _invoiceCountryCode, 
        bytes32 _invoiceCompanyNumber, bytes32 _invoiceCompanyName, bytes32 _invoiceNumber) 
        public 
        onlyServerOrOnlyPopulous 
        returns (bool success) 
    {   
        bytes32 providerUserId; 
        bytes32 companyName;
        (providerUserId, companyName) = getInvoice(_invoiceCountryCode, _invoiceCompanyNumber, _invoiceNumber);
        require(providerUserId == 0x0);
        // country code => company number => invoice number => invoice data
        invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].providerUserId = _providerUserId;
        invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].invoiceCompanyName = _invoiceCompanyName;
        
        assert(
            invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].providerUserId != 0x0 && 
            invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].invoiceCompanyName != 0x0
        );
        return true;
    }
    
    /** @dev Add a new invoice provider to the platform  
      * @param _blockchainActionId the blockchain action id
      * @param _userId the user id of the provider
      * @param _companyNumber the providers company number
      * @param _companyName the providers company name
      * @param _countryCode the providers country code
      * @return success true or false if function call is successful
      */
    function setProvider(
        bytes32 _blockchainActionId, bytes32 _userId, bytes32 _companyNumber, 
        bytes32 _companyName, bytes2 _countryCode) 
        public 
        onlyServerOrOnlyPopulous
        returns (bool success)
    {   
        require(actionStatus[_blockchainActionId] == false);
        require(
            providerCompanyData[_userId].companyNumber == 0x0 && 
            providerCompanyData[_userId].countryCode == 0x0 &&
            providerCompanyData[_userId].companyName == 0x0);
        providerCompanyData[_userId].countryCode = _countryCode;
        providerCompanyData[_userId].companyName = _companyName;
        providerCompanyData[_userId].companyNumber = _companyNumber;

        providerData[_countryCode][_companyNumber] = _userId;
        
        actionStatus[_blockchainActionId] = true;
        setBlockchainActionData(_blockchainActionId, 0x0, 0, _userId, 0x0, 0);
        return true;
    }


    /** @dev Update an added invoice provider to the platform  
      * @param _blockchainActionId the blockchain action id
      * @param _userId the user id of the provider
      * @param _companyNumber the providers company number
      * @param _companyName the providers company name
      * @param _countryCode the providers country code
      * @return success true or false if function call is successful
      */
    function _setProvider(
        bytes32 _blockchainActionId, bytes32 _userId, bytes32 _companyNumber, 
        bytes32 _companyName, bytes2 _countryCode) 
        public 
        onlyPopulous
        returns (bool success)
    {   
        require(actionStatus[_blockchainActionId] == false);
        providerCompanyData[_userId].countryCode = _countryCode;
        providerCompanyData[_userId].companyName = _companyName;
        providerCompanyData[_userId].companyNumber = _companyNumber;

        providerData[_countryCode][_companyNumber] = _userId;
        
        actionStatus[_blockchainActionId] = true;
        setBlockchainActionData(_blockchainActionId, 0x0, 0, _userId, 0x0, 0);
        return true;
    }

    // CONSTANT METHODS

    /** @dev Gets a deposit address with the client id 
      * @return clientDepositAddress The client's deposit address
      */
    function getDepositAddress(bytes32 _clientId) public view returns (address clientDepositAddress){
        return depositAddresses[_clientId];
    }

    /** @dev Gets a client id linked to a deposit address 
      * @return depositClientId The client id
      */
    function getClientIdWithDepositAddress(address _depositContract) public view returns (bytes32 depositClientId){
        return depositClientIds[_depositContract];
    }

    /** @dev Gets a currency smart contract address 
      * @return currencyAddress The currency address
      */
    function getCurrency(bytes32 _currencySymbol) public view returns (address currencyAddress) {
        return currencyAddresses[_currencySymbol];
    }
   
    /** @dev Gets a currency symbol given it's smart contract address 
      * @return currencySymbol The currency symbol
      */
    function getCurrencySymbol(address _currencyAddress) public view returns (bytes32 currencySymbol) {
        return currencySymbols[_currencyAddress];
    }

    function getCurrencyDetails(address _currencyAddress) public view returns (bytes32 _symbol, bytes32 _name, uint8 _decimals) {
        return (CurrencyToken(_currencyAddress).symbol(), CurrencyToken(_currencyAddress).name(), CurrencyToken(_currencyAddress).decimals());
    } 

    /** @dev Get the blockchain action Id Data for a blockchain Action id
      * @param _blockchainActionId the blockchain action id
      * @return bytes32 currency
      * @return uint amount
      * @return bytes32 accountId
      * @return address to
      */
    function getBlockchainActionIdData(bytes32 _blockchainActionId) public view 
    returns (bytes32 _currency, uint _amount, bytes32 _accountId, address _to) 
    {
        require(actionStatus[_blockchainActionId] == true);

        return (blockchainActionIdData[_blockchainActionId].currency, 
        blockchainActionIdData[_blockchainActionId].amount,
        blockchainActionIdData[_blockchainActionId].accountId,
        blockchainActionIdData[_blockchainActionId].to);
    }

    /** @dev Get the bool status of a blockchain Action id
      * @param _blockchainActionId the blockchain action id
      * @return bool actionStatus
      */
    function getActionStatus(bytes32 _blockchainActionId) public view returns (bool _blockchainActionStatus) {
        return actionStatus[_blockchainActionId];
    }

    /** @dev Gets the details of an invoice with the country code, company number and invocie number.
      * @param _invoiceCountryCode The country code.
      * @param _invoiceCompanyNumber The company number.
      * @param _invoiceNumber The invoice number
      * @return providerUserId The invoice provider user Id
      * @return invoiceCompanyName the invoice company name
      */
    function getInvoice(bytes2 _invoiceCountryCode, bytes32 _invoiceCompanyNumber, bytes32 _invoiceNumber) 
        public 
        view 
        returns (bytes32 providerUserId, bytes32 invoiceCompanyName) 
    {   
        bytes32 _providerUserId = invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].providerUserId;
        bytes32 _invoiceCompanyName = invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].invoiceCompanyName;
        //require(_providerUserId != 0x0 && _invoiceCompanyName != 0x0);
        return (_providerUserId, _invoiceCompanyName);
    }

    /** @dev Gets the details of an invoice provider with the country code and company number.
      * @param _providerCountryCode The country code.
      * @param _providerCompanyNumber The company number.
      * @return isEnabled The boolean value true/false indicating whether invoice provider is enabled or not
      * @return providerId The invoice provider user Id
      * @return companyName the invoice company name
      */
    function getProviderByCountryCodeCompanyNumber(bytes2 _providerCountryCode, bytes32 _providerCompanyNumber) 
        public 
        view 
        returns (bytes32 providerId, bytes32 companyName) 
    {
        bytes32 providerUserId = providerData[_providerCountryCode][_providerCompanyNumber];

        return (providerUserId, 
        providerCompanyData[providerUserId].companyName);
        //providerCompanyData[providerUserId].isEnabled);
    }

    /** @dev Gets the details of an invoice provider with the providers user Id.
      * @param _providerUserId The provider user Id.
      * @return countryCode The invoice provider country code
      * @return companyName the invoice company name
      */
    function getProviderByUserId(bytes32 _providerUserId) public view 
        returns (bytes2 countryCode, bytes32 companyName, bytes32 companyNumber) 
    {
        return (providerCompanyData[_providerUserId].countryCode,
        providerCompanyData[_providerUserId].companyName,
        providerCompanyData[_providerUserId].companyNumber);
    }
    
    
    /**
    function getProviderStatus(bytes32 _userId) public view returns (bool isEnabled) {
        return providerCompanyData[_userId].isEnabled;
    } */

    /** @dev Gets the version number for the current contract instance
      * @return _version The version number
      */
    function getVersion() public view returns (uint256 _version) {
        return version;
    }


}