pragma solidity ^0.4.11;

import './SafeMath.sol';
import './GitTokenLib.sol';
import './Ownable.sol';

contract GitToken is Ownable {

  using SafeMath for uint;
  using GitTokenLib for GitTokenLib.Data;
  GitTokenLib.Data gittoken;

  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  event Contribution(address indexed contributor, string username, uint value, uint reservedValue, uint date, string rewardType);
  event ContributorVerified(address indexed contributor, string username, uint date);
  /*event ConfigUpdated();*/

  function GitToken(
    address _contributor,
    string _name,
    string _username,
    string _organization,
    string _symbol,
    uint _decimals
  ) {
    if (_contributor != 0x0) { owner[_contributor] = true; }
    gittoken.totalSupply = 0;
    gittoken.name = _name;
    gittoken.organization = _organization;
    gittoken.symbol = _symbol;
    gittoken.decimals = _decimals;
    // Set initial contributor username & address
    gittoken.contributorUsernames[msg.sender] = _username;
    gittoken.contributorUsernames[_contributor] = _username;
    gittoken.contributorAddresses[_username] = _contributor;

    if(!gittoken._initRewardValues(_decimals)) {
      throw;
    } else if(!gittoken._initReservedValues(_decimals)) {
      throw;
    }

  }

  function totalSupply() constant returns (uint) {
    return gittoken.totalSupply;
  }

  function decimals() constant returns (uint) {
    return gittoken.decimals;
  }

  function organization() constant returns (string) {
    return gittoken.organization;
  }

  function name() constant returns (string) {
    return gittoken.name;
  }

  function symbol() constant returns (string) {
    return gittoken.symbol;
  }
  /*
   * ERC20 Methods
   */
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
    if(!gittoken._transfer(_to, _value)) {
      throw;
    } else {
      Transfer(msg.sender, _to, _value);
    }
  }

  function balanceOf(address _contributor) constant returns (uint) {
    return gittoken.balances[_contributor];
  }

  function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
    if(!gittoken._transferFrom(_from, _to, _value)) {
      throw;
    } else {
      Transfer(_from, _to, _value);
    }
  }

  function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
    // Explicitly check if the approved address already has an allowance,
    // Ensure the approver must reset the approved value to 0 before changing to the desired amount.
    // see: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if(_value > 0 && gittoken.allowed[msg.sender][_spender] > 0) {
      throw;
    } else {
      gittoken.allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
    }
  }

  function allowance(address _owner, address _spender) constant returns (uint) {
    return gittoken.allowed[_owner][_spender];
  }


  /**
   * GitToken Setter (State Changing) Functions
   */
  function setRewardValue(
    uint256 _rewardValue,
    string _rewardType
  ) onlyOwner public returns (bool) {
    gittoken.rewardValues[_rewardType] = _rewardValue;
    return true;
  }

  function setReservedValue(
    uint256 _reservedValue,
    string _reservedType,
    string _reservedSubType
  ) onlyOwner public returns (bool) {
    gittoken.reservedValues[_reservedType][_reservedSubType] = _reservedValue;
    return true;
  }

  function verifyContributor(address _contributor, string _username) onlyOwner public returns (bool) {
    /*gittoken.usernameVerification[_username] = keccak256(_code);
    return true;*/
    if(!gittoken._verifyContributor(_contributor, _username)) {
      throw;
    } else {
      ContributorVerified(_contributor, _username, now);
      return true;
    }

  }

  function setContributor(string _username, bytes _code) public returns (bool) {
    if (!gittoken._setContributor(_username, _code)) {
      throw;
    } else {
      return true;
    }
  }

  function rewardContributor(
    string _username,
    string _rewardType,
    string _reservedType,
    uint _rewardBonus,
    string _deliveryID
  ) onlyOwner public returns (bool) {
    if(!gittoken._rewardContributor(_username, _rewardType, _reservedType, _rewardBonus, _deliveryID)) {
      throw;
    } else {
      address _contributor = gittoken.contributorAddresses[_username];
      uint _value = gittoken.rewardValues[_rewardType].add(_rewardBonus);
      uint _reservedValue = gittoken.reservedValues[_rewardType][_reservedType];
      Contribution(_contributor, _username, _value, _reservedValue, now, _rewardType);
      return true;
    }
  }


  /**
   * GitToken Getter Functions
   */

  function getRewardDetails(string _rewardType) constant returns (uint256) {
    return gittoken.rewardValues[_rewardType];
  }

  function getContributorAddress(string _username) constant returns (address) {
    return gittoken.contributorAddresses[_username];
  }

  function getContributorUsername(address _contributorAddress) constant returns (string) {
    return gittoken.contributorUsernames[_contributorAddress];
  }

  function getUnclaimedRewards(string _username) constant returns (uint) {
    return gittoken.unclaimedRewards[_username];
  }

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }


}
