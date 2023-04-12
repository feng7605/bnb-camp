//主合约
pragma solidity ^0.8.0;

contract ProxyContract {
  address public currentVersion;
  address public owner;

  constructor(address _currentVersion) {
    currentVersion = _currentVersion;
    owner = msg.sender;
  }
 
  function upgrade(address newVersion) public {
    require(msg.sender == owner, "Only owner can call this function");
    currentVersion = newVersion;
  }
 
  fallback() external payable {
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), sload(currentVersion.slot), ptr, calldatasize(), 0, 0)
      returndatacopy(ptr, 0, returndatasize())
      switch result
      case 0 {revert(ptr, returndatasize())}
      default {return(ptr, returndatasize())}
    }
  }
}

//被代理的合约版本
pragma solidity ^0.8.0;
 
contract MyContract {
  uint256 public value;
 
  function setValue(uint256 newValue) public {
    value = newValue;
  }
 
  function getValue() public view returns (uint256) {
    return value;
  }
}
