// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../script/Deploy.s.sol";

import "forge-std/Test.sol";

abstract contract Base is Deploy, Test {
    address public constant alice = address(420);
    address public constant bob = address(420420);

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
