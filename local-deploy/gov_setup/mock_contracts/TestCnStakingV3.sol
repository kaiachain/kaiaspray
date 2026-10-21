// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @notice Local-only CnStakingV3 fixture for the permissionless migration rehearsal.
/// @dev PublicDelegationV1 talks to this contract through the production V3 ABI.
///      The withdrawal state machine and KAIA transfers match the production path;
///      only the seven-day lock is constructor-configurable so the local network can
///      complete redeem -> claim without waiting a week.
contract TestCnStakingV3 {
    enum WithdrawalStakingState {
        Unknown,
        Transferred,
        Canceled
    }

    struct WithdrawalRequest {
        address to;
        uint256 value;
        uint256 withdrawableFrom;
        WithdrawalStakingState state;
    }

    string public constant CONTRACT_TYPE = "CnStakingContract";
    uint256 public constant VERSION = 3;

    address public immutable owner;
    address public immutable nodeId;
    uint256 public immutable STAKE_LOCKUP;

    address public publicDelegation;
    address public rewardAddress;
    bool public isInitialized;
    bool public constant isRedelegationEnabled = false;
    uint256 public staking;
    uint256 public unstaking;
    uint256 public withdrawalRequestCount;

    mapping(uint256 => WithdrawalRequest) private withdrawalRequestMap;

    event DeployCnStakingV3(
        string contractType,
        address nodeId,
        address rewardAddress,
        uint256[] unlockTime,
        uint256[] unlockAmount
    );
    event SetPublicDelegation(address indexed from, address publicDelegation, address rewardAddress);
    event DelegateKaia(address indexed from, uint256 value);
    event ApproveStakingWithdrawal(
        uint256 indexed approvedWithdrawalId,
        address indexed to,
        uint256 value,
        uint256 withdrawableFrom
    );
    event CancelApprovedStakingWithdrawal(uint256 indexed approvedWithdrawalId, address indexed to, uint256 value);
    event WithdrawApprovedStaking(uint256 indexed approvedWithdrawalId, address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyPublicDelegation() {
        require(msg.sender == publicDelegation, "not PublicDelegation");
        _;
    }

    constructor(address _owner, address _nodeId, uint256 _stakeLockup) {
        require(_owner != address(0) && _nodeId != address(0), "zero address");
        require(_stakeLockup > 0, "zero lockup");
        owner = _owner;
        nodeId = _nodeId;
        STAKE_LOCKUP = _stakeLockup;

        uint256[] memory empty;
        emit DeployCnStakingV3(CONTRACT_TYPE, _nodeId, address(0), empty, empty);
    }

    /// @dev Represents the already-completed V3/PDV1 setup at migration start.
    function setPublicDelegation(address pd) external onlyOwner {
        require(pd != address(0), "zero PublicDelegation");
        require(publicDelegation == address(0), "PublicDelegation already set");
        publicDelegation = pd;
        rewardAddress = pd;
        isInitialized = true;
        emit SetPublicDelegation(msg.sender, pd, pd);
    }

    function delegate() external payable onlyPublicDelegation {
        _delegate();
    }

    receive() external payable onlyPublicDelegation {
        _delegate();
    }

    function _delegate() private {
        staking += msg.value;
        emit DelegateKaia(msg.sender, msg.value);
    }

    function approveStakingWithdrawal(
        address to,
        uint256 value
    ) external onlyPublicDelegation returns (uint256 id) {
        require(to != address(0) && value > 0 && unstaking + value <= staking, "invalid withdrawal");

        id = withdrawalRequestCount++;
        uint256 withdrawableFrom = block.timestamp + STAKE_LOCKUP;
        withdrawalRequestMap[id] = WithdrawalRequest({
            to: to,
            value: value,
            withdrawableFrom: withdrawableFrom,
            state: WithdrawalStakingState.Unknown
        });
        unstaking += value;

        emit ApproveStakingWithdrawal(id, to, value, withdrawableFrom);
    }

    function cancelApprovedStakingWithdrawal(uint256 id) external onlyPublicDelegation {
        WithdrawalRequest storage request = withdrawalRequestMap[id];
        require(request.to != address(0) && request.state == WithdrawalStakingState.Unknown, "invalid request");
        request.state = WithdrawalStakingState.Canceled;
        unstaking -= request.value;
        emit CancelApprovedStakingWithdrawal(id, request.to, request.value);
    }

    function withdrawApprovedStaking(uint256 id) external onlyPublicDelegation {
        WithdrawalRequest storage request = withdrawalRequestMap[id];
        require(request.to != address(0) && request.state == WithdrawalStakingState.Unknown, "invalid request");
        require(request.value <= staking, "value not withdrawable");
        require(block.timestamp >= request.withdrawableFrom, "not withdrawable yet");

        if (block.timestamp >= request.withdrawableFrom + STAKE_LOCKUP) {
            request.state = WithdrawalStakingState.Canceled;
            unstaking -= request.value;
            emit CancelApprovedStakingWithdrawal(id, request.to, request.value);
            return;
        }

        request.state = WithdrawalStakingState.Transferred;
        unstaking -= request.value;
        staking -= request.value;
        (bool success,) = payable(request.to).call{value: request.value}("");
        require(success, "transfer failed");

        emit WithdrawApprovedStaking(id, request.to, request.value);
    }

    function getApprovedStakingWithdrawalInfo(
        uint256 id
    ) external view returns (address to, uint256 value, uint256 withdrawableFrom, WithdrawalStakingState state) {
        WithdrawalRequest storage request = withdrawalRequestMap[id];
        return (request.to, request.value, request.withdrawableFrom, request.state);
    }
}
