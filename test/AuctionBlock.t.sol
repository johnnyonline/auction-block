// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./Base.sol";

contract AuctionBlockTest is Base {
    function setUp() public override {
        Base.setUp();
    }

    // ============================================================================================
    // Setup
    // ============================================================================================

    function testSetUp() public view {
        assertEq(auction.time_buffer(), TIME_BUFFER, "testSetUp: E0");
        assertEq(auction.reserve_price(), RESERVE_PRICE, "testSetUp: E1");
        assertEq(auction.min_bid_increment_percentage(), MIN_BID_INCREMENT_PERCENTAGE, "testSetUp: E2");
        assertEq(auction.duration(), DURATION, "testSetUp: E3");
        assertEq(auction.fee(), FEE, "testSetUp: E4");
        assertEq(auction.payment_token(), address(token), "testSetUp: E5");
        assertEq(auction.proceeds_receiver(), proceedsReceiver, "testSetUp: E6");
        assertEq(auction.fee_receiver(), feeReceiver, "testSetUp: E7");
        assertEq(auction.pending_owner(), owner, "testSetUp: E8");
        assertEq(auction.owner(), deployer, "testSetUp: E9");
    }

    // ============================================================================================
    // Create Auction
    // ============================================================================================

    function testCreateAuction() public returns (uint256 _auctionId) {
        vm.prank(deployer);
        _auctionId = auction.create_auction(IPFS_HASH);

        assertEq(auction.auction_list(_auctionId).auction_id, _auctionId, "testCreateAuction: E0");
        assertEq(auction.auction_list(_auctionId).amount, 0, "testCreateAuction: E1");
        assertEq(auction.auction_list(_auctionId).start_time, block.timestamp, "testCreateAuction: E2");
        assertEq(auction.auction_list(_auctionId).end_time, block.timestamp + DURATION, "testCreateAuction: E3");
        assertEq(auction.auction_list(_auctionId).bidder, address(0), "testCreateAuction: E4");
        assertEq(auction.auction_list(_auctionId).settled, false, "testCreateAuction: E5");
        assertEq(auction.auction_list(_auctionId).ipfs_hash, IPFS_HASH, "testCreateAuction: E6");
    }

    // ============================================================================================
    // Create Bid
    // ============================================================================================

    function testCreateBid(uint256 _amount) public {
        vm.assume(_amount > RESERVE_PRICE && _amount < MAX_FUZZ);

        uint256 _auctionId = testCreateAuction();

        airdrop(address(token), alice, _amount);

        vm.startPrank(alice);
        token.approve(address(auction), _amount);
        auction.create_bid(_auctionId, _amount);
        vm.stopPrank();

        assertEq(auction.auction_list(_auctionId).amount, _amount, "testCreateBid: E0");
        assertEq(auction.auction_list(_auctionId).end_time, block.timestamp + DURATION, "testCreateAuction: E1");
        assertEq(auction.auction_list(_auctionId).bidder, alice, "testCreateBid: E2");
        assertEq(auction.auction_list(_auctionId).settled, false, "testCreateBid: E3");
    }

    function testCreateBidOnBehalfOf(uint256 _amount) public {
        vm.assume(_amount > RESERVE_PRICE && _amount < MAX_FUZZ);

        uint256 _auctionId = testCreateAuction();

        vm.startPrank(bob);
        auction.set_approved_caller(alice, BID_ONLY);
        token.approve(address(auction), _amount);
        vm.stopPrank();

        airdrop(address(token), bob, _amount);

        vm.prank(alice);
        auction.create_bid(_auctionId, _amount, bob);

        assertEq(auction.auction_list(_auctionId).amount, _amount, "testCreateBidOnBehalfOf: E0");
        assertEq(auction.auction_list(_auctionId).end_time, block.timestamp + DURATION, "testCreateBidOnBehalfOf: E1");
        assertEq(auction.auction_list(_auctionId).bidder, bob, "testCreateBidOnBehalfOf: E2");
        assertEq(auction.auction_list(_auctionId).settled, false, "testCreateBidOnBehalfOf: E3");
    }
}
