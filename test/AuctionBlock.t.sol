// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./Base.sol";

contract AuctionBlockTest is Base {
    function setUp() public override {
        Base.setUp();
    }

    function testSetUp() public view {
        assertEq(auction.time_buffer(), TIME_BUFFER, "testSetUp: E0");
    }
}
