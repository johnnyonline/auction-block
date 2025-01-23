// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAuctionBlock} from "./interfaces/IAuctionBlock.sol";

import {TokenMock} from "../src/mocks/TokenMock.sol";

import "forge-std/Script.sol";

// ---- Usage ----

// deploy:
// forge script script/Deploy.s.sol:Deploy --verify --slow --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

contract Deploy is Script {
    bool public isTest;
    address public deployer;
    address public owner;
    address public proceedsReceiver;
    address public feeReceiver;

    TokenMock public token;
    IAuctionBlock public auction;

    uint256 public constant TIME_BUFFER = 300; // 5 minutes
    uint256 public constant RESERVE_PRICE = 1 ether;
    uint256 public constant MIN_BID_INCREMENT_PERCENTAGE = 10; // 10%
    uint256 public constant DURATION = 1 hours;
    uint256 public constant FEE = 10; // 10%

    function run() public {
        uint256 _pk = isTest ? 42069 : vm.envUint("DEPLOYER_PRIVATE_KEY");
        VmSafe.Wallet memory _wallet = vm.createWallet(_pk);
        deployer = _wallet.addr;

        if (isTest) {
            owner = address(69420);
            proceedsReceiver = address(6942069);
            feeReceiver = address(6942069420);
        } else {
            owner = deployer;
            proceedsReceiver = deployer;
            feeReceiver = deployer;
        }

        vm.startBroadcast(_pk);

        // deploy mocks
        {
            token = new TokenMock();
        }

        // deploy contracts
        {
            auction = IAuctionBlock(
                deployCode(
                    "auction_block",
                    abi.encode(
                        TIME_BUFFER,
                        RESERVE_PRICE,
                        MIN_BID_INCREMENT_PERCENTAGE,
                        DURATION,
                        address(token), // payment_token
                        proceedsReceiver,
                        feeReceiver,
                        FEE
                    )
                )
            );
        }

        // transfer ownership
        {
            auction.transfer_ownership(owner);
        }

        vm.stopBroadcast();

        if (isTest) {
            vm.label({account: address(token), newLabel: "token"});
            vm.label({account: address(auction), newLabel: "auction"});
        } else {
            console.log("Deployer address: %s", deployer);
            console.log("Owner address: %s", owner);
            console.log("Proceeds receiver address: %s", proceedsReceiver);
            console.log("Fee receiver address: %s", feeReceiver);
            console.log("Token address: %s", address(token));
            console.log("Auction address: %s", address(auction));
        }
    }
}

// Chain 421614
// Deployer address: 0x318d0059efE546b5687FA6744aF4339391153981
// Owner address: 0x318d0059efE546b5687FA6744aF4339391153981
// Proceeds receiver address: 0x318d0059efE546b5687FA6744aF4339391153981
// Fee receiver address: 0x318d0059efE546b5687FA6744aF4339391153981
// Token address: 0x26307a19096f5fa9eDB46784f10d5CAaeeC90B08
// Auction address: 0x6B1E09821E5837F8082B97dE28aE389D7aaDabcb