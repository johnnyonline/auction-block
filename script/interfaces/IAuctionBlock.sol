// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPausable} from "./IPausable.sol";
import {IOwnable2Step} from "./IOwnable2Step.sol";

interface IAuctionBlock is IPausable, IOwnable2Step {
    struct Auction {
        uint256 auction_id;
        uint256 amount;
        uint256 start_time;
        uint256 end_time;
        address bidder;
        bool settled;
        string ipfs_hash;
    }

    // Constants
    function PRECISION() external view returns (uint256);
    function MAX_WITHDRAWALS() external view returns (uint256);
    function MIN_DURATION() external view returns (uint256);
    function MAX_DURATION() external view returns (uint256);
    function MIN_BID_INCREMENT_PERCENTAGE_() external view returns (uint256);
    function MAX_BID_INCREMENT_PERCENTAGE() external view returns (uint256);
    function MAX_FEE() external view returns (uint256);

    // Storage

    // Auction
    function time_buffer() external view returns (uint256);
    function reserve_price() external view returns (uint256);
    function min_bid_increment_percentage() external view returns (uint256);
    function duration() external view returns (uint256);
    function auction_id() external view returns (uint256);

    function auction_pending_returns(uint256, address) external view returns (uint256);
    function auction_list(uint256) external view returns (Auction memory);

    // User settings
    function approved_caller(address, address) external view returns (uint256);

    // Payment token
    function payment_token() external view returns (address);

    // Proceeds
    function proceeds_receiver() external view returns (address);
    function fee_receiver() external view returns (address);
    function fee() external view returns (uint256);

    // View functions
    function minimum_total_bid(uint256) external view returns (uint256);
    function minimum_additional_bid_for_user(uint256, address) external view returns (uint256);

    // Mutated functions
    function create_auction(string memory _ipfs_hash) external returns (uint256);
    function settle_auction(uint256 auction_id) external;
    function create_bid(uint256 auction_id, uint256 bid_amount) external;
    function create_bid(uint256 auction_id, uint256 bid_amount, address on_behalf_of) external;
    function withdraw(uint256 auction_id, address on_behalf_of) external;
    function withdraw_multiple(uint256[] memory auction_ids, address on_behalf_of) external;

    // User settings
    function set_approved_caller(address caller, uint256 status) external;

    // Owner functions
    function set_time_buffer(uint256 time_buffer) external;
    function set_reserve_price(uint256 reserve_price) external;
    function set_min_bid_increment_percentage(uint256 percentage) external;
    function set_duration(uint256 duration) external;
    function set_proceeds_receiver(address proceeds_receiver) external;
    function set_fee_receiver(address fee_receiver) external;
    function set_fee(uint256 fee) external;
}
