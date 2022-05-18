// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Passthehat.sol";

abstract contract ERC20Interface {
  function transfer(address recipient, uint amount) external virtual;

  function balanceOf(address account) external view virtual;

  function withdraw(address amount) external virtual;
}

contract TokenManager is Passthehat {
  mapping(uint => address) tokenList;

  ERC20Interface TokenContract;

  function setTokenContractAddress(address _address) external onlyOwner {
    TokenContract = ERC20Interface(_address);
  }
}
