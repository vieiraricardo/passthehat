// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Passthehat is Ownable {
  using SafeMath for uint;

  uint32 public constant MAX_FEE = 5000;
  uint32 public FEE = 3000;
  // add a dev wallet to receive fees and implement to receive fee when the funding owner makes a withdrawal

  modifier isFundingReached() {
    uint id = crowdFundingId[msg.sender];

    CrowdfundingRegistration memory _registry = registry[id];

    require(msg.sender == _registry.owner);

    require(_registry.goal < _registry.amountRaised, "Funding not reached.");
    _;
  }

  event NewFunding(uint _id, address _owner, uint _goal, uint32 _expiresIn, uint32 _createdAt); // atualizar aqui
  event NewDonate(address _from, address _to, uint _value, uint amountRaised);

  struct CrowdfundingRegistration {
    address owner;
    uint goal;
    uint amountRaised;
    uint32 expiresIn;
    uint32 createdAt;
    // start time
    // minimum value for donation
    // create another fiel to know if funding is flexible, case not be flexible check the expiration time and disable funding to receive donations
    bool isActive;
  }

  CrowdfundingRegistration[] public registry;

  mapping(uint => address) crowdFundingOwner;
  mapping(address => uint) crowdFundingId;

  function newRegistry(CrowdfundingRegistration memory _registry) private {
    require(_registry.owner != address(0));

    registry.push(_registry);

    uint id = registry.length - 1;

    crowdFundingOwner[id] = msg.sender;

    crowdFundingId[msg.sender] = id;

    emit NewFunding(id, _registry.owner, _registry.goal, _registry.expiresIn, _registry.createdAt);
  }

  // function to inscrease expiration time

  function createFunding(uint32 _expiresIn, uint _goal) public {
    newRegistry(
      CrowdfundingRegistration(
        msg.sender,
        _goal,
        0,
        uint32(_expiresIn),
        uint32(block.timestamp),
        true
      )
    );
  }

  function getFunding(address _fundingAddress)
    public
    view
    returns (CrowdfundingRegistration memory)
  {
    uint id = crowdFundingId[_fundingAddress];

    CrowdfundingRegistration memory funding = registry[id];

    return funding;
  }

  function donate(address _fundingAddress) public payable {
    uint id = crowdFundingId[_fundingAddress];

    CrowdfundingRegistration storage funding = registry[id];

    require(
      funding.isActive == true,
      "This funding has already reached its goal and no longer accepts donations."
    );

    funding.amountRaised = funding.amountRaised.add(msg.value);

    emit NewDonate(msg.sender, _fundingAddress, msg.value, funding.amountRaised);
  }

  function withdraw() public isFundingReached {
    uint id = crowdFundingId[msg.sender];

    CrowdfundingRegistration storage funding = registry[id];

    require(msg.sender == funding.owner);

    uint withdrawFee = ((FEE / 10000) * funding.amountRaised) / 100;

    payable(msg.sender).transfer(funding.amountRaised - withdrawFee);

    funding.isActive = false;
  }

  function setFee(uint16 _fee) public onlyOwner {
    require((_fee * 100) <= MAX_FEE, "Fee greater than the maximum allowed.");

    FEE = _fee * 100;
  }

  function getFee() public view returns (uint32) {
    return FEE;
  }
}
// contrato para manipulação de tokens aceitos como fundos
// dois tipos de financiamento, Personal fundraising, Projects
