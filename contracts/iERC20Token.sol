// Abstract contract for the full ERC 20 Token standard
// https://github.com/ConsenSys/Tokens
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.13;


/// @title iERC20Token contract
contract iERC20Token {

    // FIELDS

    
    uint256 public totalSupply = 0;

    // NON-CONSTANT METHODS

    /// @dev send `_value` tokens to `_to` address/wallet from `msg.sender`.
    /// @param _to The address of the recipient.
    /// @param _value The amount of token to be transferred.
    /// @return Whether the transfer was successful or not.
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @dev send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @dev `msg.sender` approves `_spender` to spend `_value` tokens.
    /// @param _spender The address of the account able to transfer the tokens.
    /// @param _value The amount of tokens to be approved for transfer.
    /// @return Whether the approval was successful or not.
    function approve(address _spender, uint256 _value) returns (bool success);

    // CONSTANT METHODS

    /** @dev Checks the balance of an address without changing the state of the blockchain.
      * @param _owner The address to check.
      * @return balance An unsigned integer representing the token balance of the address.
      */
    function balanceOf(address _owner) constant returns (uint256 balance);

    /** @dev Checks for the balance of the tokens of that which the owner had approved another address owner to spend.
      * @param _owner The address of the token owner.
      * @param _spender The address of the allowed spender.
      * @return remaining An unsigned integer representing the remaining approved tokens.
      */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);


    // EVENTS

    // An event triggered when a transfer of tokens is made from a _from address to a _to address.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // An event triggered when an owner of tokens successfully approves another address to spend a specified amount of tokens.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
