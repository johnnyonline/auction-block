// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IOwnable2Step {
    function owner() external view returns (address);
    function pending_owner() external view returns (address);
    function transfer_ownership(address new_owner) external;
    function accept_ownership() external;
}
