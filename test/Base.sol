// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../script/Deploy.s.sol";

import "forge-std/Test.sol";

abstract contract Base is Deploy, Test {
    string public constant IPFS_HASH = "ipfs_hash";
    address public constant alice = address(420);
    address public constant bob = address(420420);

    uint256 public constant MIN_FUZZ = 10_000;
    uint256 public constant MAX_FUZZ = 100_000 ether;
    uint256 public constant BID_ONLY = 2;
    // Nothing --> 1
    // BidOnly --> 2
    // WithdrawOnly --> 4
    // BidAndWithdraw --> 8

    function setUp() public virtual {
        // notify deplyment script that this is a test
        {
            isTest = true;
        }

        // create fork
        {
            vm.selectFork(vm.createFork(vm.envString("MAINNET_RPC_URL")));
        }

        // deploy and initialize contracts
        {
            run();
        }
    }

    function airdrop(address _token, address _to, uint256 _amount) public {
        deal({token: _token, to: _to, give: _amount});
    }
}
