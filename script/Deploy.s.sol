// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAuctionBlock} from "./interfaces/IAuctionBlock.sol";

import {TokenMock} from "../src/mocks/tokenMock.sol";

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

    uint256 public constant TIME_BUFFER = 0;
    uint256 public constant RESERVE_PRICE = 0;
    uint256 public constant MIN_BID_INCREMENT_PERCENTAGE = 0;
    uint256 public constant DURATION = 0;
    uint256 public constant FEE = 0;

    function run() public {
        uint256 _pk = isTest ? 42069 : vm.envUint("DEPLOYER_PRIVATE_KEY");
        VmSafe.Wallet memory _wallet = vm.createWallet(_pk);
        deployer = _wallet.addr;

        uint256 _ownerPk = isTest ? 69420 : vm.envUint("OWNER_PRIVATE_KEY");
        VmSafe.Wallet memory _ownerWallet = vm.createWallet(_ownerPk);
        owner = _ownerWallet.addr;

        uint256 _proceedsReceiverPk = isTest ? 6942069 : vm.envUint("PROCEEDS_RECEIVER_PRIVATE_KEY");
        VmSafe.Wallet memory _proceedsReceiverWallet = vm.createWallet(_proceedsReceiverPk);
        proceedsReceiver = _proceedsReceiverWallet.addr;

        uint256 _feeReceiverPk = isTest ? 6942069420 : vm.envUint("FEE_RECEIVER_PRIVATE_KEY");
        VmSafe.Wallet memory _feeReceiverWallet = vm.createWallet(_feeReceiverPk);
        feeReceiver = _feeReceiverWallet.addr;

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
