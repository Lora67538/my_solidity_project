// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract WETH is ERC20{
    constructor() ERC20("Wrapped Ether", "WETH") {}
    event Deposit(address indexed account, uint amount);
    event Withdraw(address indexed account, uint amount);

    fallback() external payable {
        Deposit();
    }

    function Deposit() external {
        _mint(msg.sender,msg.value);
        emit Deposit(msg.sender, amount);
    }
    function burn(address from, uint256 _amount) external {
        _burn(from, amount);
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

}