// SPDX-License-Identifier: MIT

/// @title Pass the Hat: Crowdfunding projects made easy with blockchain.
/// @author Ricardo Vieira

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Passthehat is Ownable {
  using SafeMath for uint;

  uint32 public constant MAX_FEE = 5000;
  uint32 public FEE = 3000;
  address public adminWallet;

  event TimeLimitIncreased(address _fundingAddress, uint32 _newTime);
  event NewDonate(address _from, address _to, uint _value, uint balance);
  event NewFunding(
    uint _id,
    address _owner,
    uint _goal,
    uint minAmount,
    uint32 _startsIn,
    uint32 _expiresIn,
    uint32 _createdAt,
    bool isFlexibleTimeLimit
  );

  struct CrowdfundingRegistration {
    address owner;
    uint goal;
    uint minAmount;
    uint balance;
    uint32 startsIn;
    uint32 expiresIn;
    uint32 createdAt;
    bool isActive;
    bool isFlexibleTimeLimit;
    bool isTimeLimitIncreased;
  }

  mapping(address => CrowdfundingRegistration[]) registry;

  modifier isGoalReached(uint _fundingId) {
    CrowdfundingRegistration[] memory fundings = registry[msg.sender];

    CrowdfundingRegistration memory funding = fundings[_fundingId];

    require(msg.sender == funding.owner);

    require(funding.goal < funding.balance, "Funding not reached.");
    _;
  }

  modifier isOwnerOfFunding(uint _fundingId) {
    CrowdfundingRegistration[] memory fundings = registry[msg.sender];

    CrowdfundingRegistration memory funding = fundings[_fundingId];

    require(msg.sender == funding.owner);
    _;
  }

  function newRegistry(CrowdfundingRegistration memory _registry) private {
    require(_registry.owner != address(0));

    CrowdfundingRegistration[] storage fundings = registry[msg.sender];
    fundings.push(_registry);

    uint id = fundings.length - 1;

    emit NewFunding(
      id,
      _registry.owner,
      _registry.goal,
      _registry.minAmount,
      _registry.startsIn,
      _registry.expiresIn,
      _registry.createdAt,
      _registry.isFlexibleTimeLimit
    );
  }

  function createFunding(
    uint _goal,
    uint _minAmount,
    uint32 _startsIn,
    uint32 _expiresIn,
    bool _isFlexibleTimeLimit
  ) public {
    uint32 createdAt = uint32(block.timestamp);
    uint32 max_allowed = createdAt + 60 days;

    if (_startsIn == 0) {
      newRegistry(
        CrowdfundingRegistration(
          msg.sender,
          _goal,
          _minAmount,
          0,
          createdAt,
          _expiresIn,
          createdAt,
          true,
          _isFlexibleTimeLimit,
          false
        )
      );

      return;
    }

    if ((_startsIn > createdAt && _startsIn <= max_allowed)) {
      newRegistry(
        CrowdfundingRegistration(
          msg.sender,
          _goal,
          _minAmount,
          0,
          _startsIn,
          _expiresIn,
          createdAt,
          true,
          _isFlexibleTimeLimit,
          false
        )
      );
    } else {
      revert("You must pass a start date in epoch time format with a maximum of 60 days from now");
    }
  }

  function increaseFundraisingTime(uint32 _days, uint _fundingId)
    public
    isOwnerOfFunding(_fundingId)
  {
    require(_days >= 0 && _days <= 30, "The number of days need to be less than or equal to 30");

    uint32 extendedTime = _days * 24 * 60 * 60;

    CrowdfundingRegistration[] storage fundings = registry[msg.sender];

    CrowdfundingRegistration storage funding = fundings[_fundingId];

    require(
      funding.isTimeLimitIncreased == false,
      "You cannot increase the time limit more than once"
    );

    require(funding.isFlexibleTimeLimit == false, "This Funding has a flexible time limit.");

    funding.expiresIn = (funding.expiresIn + extendedTime);

    funding.isTimeLimitIncreased = true;

    emit TimeLimitIncreased(msg.sender, funding.expiresIn + extendedTime);
  }

  function getFunding(address _fundingAddress, uint _fundingId)
    public
    view
    returns (CrowdfundingRegistration memory)
  {
    CrowdfundingRegistration[] memory fundings = registry[_fundingAddress];

    CrowdfundingRegistration memory funding = fundings[_fundingId];

    require(
      funding.owner == _fundingAddress,
      "Funding does not exist or is not owned by the address provided"
    );

    return funding;
  }

  function donate(address _fundingAddress, uint _fundingId) public payable {
    CrowdfundingRegistration[] storage fundings = registry[_fundingAddress];
    CrowdfundingRegistration storage funding = fundings[_fundingId];

    require(
      funding.isActive == true,
      "This funding has already reached its goal and no longer accepts donations."
    );

    require(msg.value >= 0);

    require(
      msg.value >= funding.minAmount,
      "This funding has a minimum amount allowed for donations."
    );

    funding.balance = funding.balance.add(msg.value);

    emit NewDonate(msg.sender, _fundingAddress, msg.value, funding.balance);
  }

  function withdraw(uint _fundingId) public isGoalReached(_fundingId) {
    CrowdfundingRegistration[] storage fundings = registry[msg.sender];
    CrowdfundingRegistration storage funding = fundings[_fundingId];

    uint withdrawalFee = funding.balance.mul(FEE / 100).div(10000);

    payable(msg.sender).transfer(funding.balance.sub(withdrawalFee));
    payable(adminWallet).transfer(withdrawalFee);

    funding.isActive = false;
  }

  function balanceOf(address _fundingAddress, uint _fundingId) public view returns (uint) {
    CrowdfundingRegistration[] memory fundings = registry[_fundingAddress];

    CrowdfundingRegistration memory funding = fundings[_fundingId];

    if (funding.owner == _fundingAddress) {
      return funding.balance;
    } else {
      return 0;
    }
  }

  function setFee(uint16 _fee) public onlyOwner {
    require((_fee * 100) <= MAX_FEE, "Fee is greater than the maximum allowed.");

    FEE = _fee * 100;
  }
}
