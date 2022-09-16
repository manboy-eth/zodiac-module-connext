// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.16;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "./interfaces/IExecutor.sol";
import {IXReceiver} from "./interfaces/IXReceiver.sol";

contract ConnextModule is Module, IXReceiver {
    event ModuleSetUp(
        address owner,
        address avatar,
        address target,
        address originAddress,
        uint32 origin,
        address executor
    );
    event OriginAddressSet(address originAddress);
    event OriginSet(uint32 origin);
    event ExecutorSet(address executor);

    error ExecutorOnly();
    error ModuleTransactionFailed();
    error OriginAddressOnly();
    error OriginOnly();

    address public executor;
    address public originAddress;

    uint32 public origin;

    constructor(
        address _owner,
        address _avatar,
        address _target,
        address _originAddress,
        uint32 _origin,
        address _executor
    ) {
        bytes memory initializeParams = abi.encode(_owner, _avatar, _target, _originAddress, _origin, _executor);
        setUp(initializeParams);
    }

    /// @dev Initialize function, will be triggered when a new proxy is deployed
    /// @param initializeParams Parameters of initialization encoded
    function setUp(bytes memory initializeParams) public override initializer {
        __Ownable_init();
        (
            address _owner,
            address _avatar,
            address _target,
            address _originAddress,
            uint32 _origin,
            address _executor
        ) = abi.decode(initializeParams, (address, address, address, address, uint32, address));

        setAvatar(_avatar);
        setTarget(_target);
        setOriginAddress(_originAddress);
        setOrigin(_origin);
        setExecutor(_executor);
        transferOwnership(_owner);

        emit ModuleSetUp(owner(), avatar, target, originAddress, origin, executor);
    }

    modifier onlyExecutor(address _originSender, uint32 _origin) {
        if (msg.sender != executor) revert ExecutorOnly();
        if (_originSender != originAddress) revert OriginAddressOnly();
        if (_origin != origin) revert OriginOnly();
        _;
    }

    function xReceive(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    ) 
        external onlyExecutor(_originSender, _origin)
        returns (bytes memory) {
            _execute(_callData);
        
    }

    function _execute(bytes calldata _message) internal {
        (address _to, uint256 _value, bytes memory _data, Enum.Operation _operation) = abi.decode(
            _message,
            (address, uint256, bytes, Enum.Operation)
        );
        if (!exec(_to, _value, _data, _operation)) revert ModuleTransactionFailed();
    }

    function setOriginAddress(address _originAddress) public onlyOwner {
        originAddress = _originAddress;
        emit OriginAddressSet(originAddress);
    }

    function setOrigin(uint32 _origin) public onlyOwner {
        origin = _origin;
        emit OriginSet(origin);
    }

    function setExecutor(address _executor) public onlyOwner {
        executor = _executor;
        emit ExecutorSet(executor);
    }
}
