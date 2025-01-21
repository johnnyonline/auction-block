# @version 0.4.0

"""
@title Auction Block
@license MIT
@author Leviathan
@notice auction_block.vy facilitates creating, bidding on, and settling auctions
"""


from ethereum.ercs import IERC20

# import ownable_2step as ownable
# import pausable
# import ownable_2step
# from . import ownable_2step
from . import ownable_2step as ownable
initializes: ownable

from . import pausable
initializes: pausable[ownable_2step := ownable]
# initializes: o2[ownable := ow]




# ============================================================================================
# Modules
# ============================================================================================


# initializes: ownable
# # exports: (
# #     ownable.owner,
# #     ownable.pending_owner,
# #     ownable.transfer_ownership,
# #     ownable.accept_ownership,
# # )


# initializes: pausable[ownable := ownable]
# exports: (
#     pausable.paused,
#     pausable.pause,
#     pausable.unpause,
# )
# exports: (
#     # from `ownable`
#     ownable.transfer_ownership,
#     ownable.accept_ownership,
#     ownable.owner,
#     # from `pausable`
#     pausable.paused,
#     pausable.pause,
#     pausable.unpause,
# )


# ============================================================================================
# Structs
# ============================================================================================


struct Auction:
    auction_id: uint256
    amount: uint256
    start_time: uint256
    end_time: uint256
    bidder: address
    settled: bool
    ipfs_hash: String[46]


flag ApprovalStatus:
    Nothing # Default value, indicating no approval
    BidOnly # Approved for bid only
    WithdrawOnly # Approved for withdraw only
    BidAndWithdraw # Approved for both bid and withdraw

# ============================================================================================
# Events
# ============================================================================================


event AuctionBid:
    auction_id: indexed(uint256)
    bidder: indexed(address)
    caller: indexed(address)
    value: uint256
    extended: bool


event AuctionExtended:
    auction_id: indexed(uint256)
    end_time: uint256


event AuctionTimeBufferUpdated:
    time_buffer: uint256


event AuctionReservePriceUpdated:
    reserve_price: uint256


event AuctionMinBidIncrementPercentageUpdated:
    min_bid_increment_percentage: uint256


event AuctionDurationUpdated:
    duration: uint256


event AuctionCreated:
    auction_id: indexed(uint256)
    start_time: uint256
    end_time: uint256
    ipfs_hash: String[46]


event AuctionSettled:
    auction_id: indexed(uint256)
    winner: address
    amount: uint256


event Withdraw:
    auction_id: indexed(uint256)
    on_behalf_of: indexed(address)
    caller: indexed(address)
    amount: uint256


event ApprovedCallerSet:
    account: address
    caller: address
    status: ApprovalStatus


event ProceedsReceiverUpdated:
    proceeds_receiver: address


event FeeReceiverUpdated:
    fee_receiver: address


event FeeUpdated:
    fee: uint256


# ============================================================================================
# Constants
# ============================================================================================


PRECISION: constant(uint256) = 100
MAX_WITHDRAWALS: constant(uint256) = 100
MIN_DURATION: constant(uint256) = 3600 # 1 hour
MAX_DURATION: constant(uint256) = 259200 # 3 days
MIN_BID_INCREMENT_PERCENTAGE_: constant(uint256) = 2 # 2%
MAX_BID_INCREMENT_PERCENTAGE: constant(uint256) = 15 # 15%
MAX_FEE: constant(uint256) = 10 # 10%


# ============================================================================================
# Storage
# ============================================================================================


# Auction
time_buffer: public(uint256)
reserve_price: public(uint256)
min_bid_increment_percentage: public(uint256)
duration: public(uint256)
auction_id: public(uint256)

auction_pending_returns: public(HashMap[uint256, HashMap[address, uint256]])
auction_list: public(HashMap[uint256, Auction])

# User settings
approved_caller: public(HashMap[address, HashMap[address, ApprovalStatus]])

# Payment token
payment_token: public(IERC20)

# Proceeds
proceeds_receiver: public(address)
fee_receiver: public(address)
fee: public(uint256)


# ============================================================================================
# Constructor
# ============================================================================================


@deploy
def __init__(
    time_buffer: uint256,
    reserve_price: uint256,
    min_bid_increment_percentage: uint256,
    duration: uint256,
    payment_token: address,
    proceeds_receiver: address,
    fee_receiver: address,
    fee: uint256,
):
    assert (min_bid_increment_percentage >= MIN_BID_INCREMENT_PERCENTAGE_ and min_bid_increment_percentage <= MAX_BID_INCREMENT_PERCENTAGE), "!min_bid_increment_percentage"
    assert duration >= MIN_DURATION and duration <= MAX_DURATION, "!duration"
    assert payment_token != empty(address), "!payment_token"
    assert proceeds_receiver != empty(address), "!proceeds_receiver"
    assert fee_receiver != empty(address), "!fee_receiver"
    assert fee <= MAX_FEE, "!fee"

    ownable.__init__()
    pausable.__init__()

    self.time_buffer = time_buffer
    self.reserve_price = reserve_price
    self.min_bid_increment_percentage = min_bid_increment_percentage
    self.duration = duration
    self.payment_token = IERC20(payment_token)
    self.proceeds_receiver = proceeds_receiver
    self.fee_receiver = fee_receiver
    self.fee = fee


# ============================================================================================
# View functions
# ============================================================================================


@external
@view
def minimum_total_bid(auction_id: uint256) -> uint256:
    """
    @notice Returns the minimum bid one must place for a given auction
    @return Minimum bid in the payment token
    """
    return self._minimum_total_bid(auction_id)


@external
@view
def minimum_additional_bid_for_user(
    auction_id: uint256, user: address
) -> uint256:
    """
    @notice Returns the minimum additional amount a user must add to become top bidder for an auction
    @return Required amount to bid in the payment token
    """
    return self._minimum_additional_bid(auction_id, user)


# ============================================================================================
# Mutated functions
# ============================================================================================


@external
@nonreentrant
def create_auction(_ipfs_hash: String[46] = "") -> uint256:
    """
    @dev Create a new auction
    @param _ipfs_hash The IPFS hash of the auction metadata
    @return New auction id
      Throws if the auction house is paused or if the caller is not the owner
    """
    pausable._check_unpaused()
    ownable._check_owner()
    return self._create_auction(_ipfs_hash)


@external
@nonreentrant
def settle_auction(auction_id: uint256):
    """
    @dev Settle an auction.
      Throws if the auction house is paused.
    """
    pausable._check_unpaused()
    self._settle_auction(auction_id)


@external
@nonreentrant
def create_bid(
    auction_id: uint256,
    bid_amount: uint256,
    on_behalf_of: address = msg.sender,
):
    """
    @dev Create a bid using an ERC20 token, optionally on behalf of another address
    @param auction_id The ID of the auction to bid on
    @param bid_amount The amount to bid
    @param on_behalf_of Optional address to bid on behalf of. Defaults to sender
    """
    self._check_caller(on_behalf_of, msg.sender, ApprovalStatus.BidOnly)
    self._create_bid(auction_id, bid_amount, on_behalf_of)


@external
@nonreentrant
def withdraw(auction_id: uint256, on_behalf_of: address = msg.sender):
    """
    @dev Withdraw ERC20 tokens after losing auction
    """
    self._check_caller(on_behalf_of, msg.sender, ApprovalStatus.WithdrawOnly)
    pending: uint256 = self.auction_pending_returns[auction_id][msg.sender]
    assert pending > 0, "!pending"
    self.auction_pending_returns[auction_id][msg.sender] = 0
    assert extcall self.payment_token.transfer(msg.sender, pending, default_return_value=True), "!transfer"
    log Withdraw(auction_id, on_behalf_of, msg.sender, pending)


@external
@nonreentrant
def withdraw_multiple(auction_ids: DynArray[uint256, MAX_WITHDRAWALS], on_behalf_of: address = msg.sender):
    """
    @dev Withdraw ERC20 tokens from multiple auctions
    """
    self._check_caller(on_behalf_of, msg.sender, ApprovalStatus.WithdrawOnly)
    total_pending: uint256 = 0
    for auction_id: uint256 in auction_ids:
        pending: uint256 = self.auction_pending_returns[auction_id][on_behalf_of]
        if pending > 0:
            total_pending += pending
            self.auction_pending_returns[auction_id][on_behalf_of] = 0
            log Withdraw(auction_id, on_behalf_of, msg.sender, pending)

    assert total_pending > 0, "!pending"
    assert extcall self.payment_token.transfer(on_behalf_of, total_pending, default_return_value=True), "!transfer"


# ============================================================================================
# User settings
# ============================================================================================


@external
def set_approved_caller(caller: address, status: ApprovalStatus):
    """
    @dev Allow another address to bid or withdraw on behalf of. Useful for zaps and other functionality.
    @param caller Address of the caller to approve or unapprove.
    @param status Enum representing various approval status states.
    """
    self.approved_caller[msg.sender][caller] = status
    log ApprovedCallerSet(msg.sender, caller, status)


# ============================================================================================
# Owner functions
# ============================================================================================


@external
def set_time_buffer(time_buffer: uint256):
    ownable._check_owner()
    self.time_buffer = time_buffer
    log AuctionTimeBufferUpdated(time_buffer)


@external
def set_reserve_price(reserve_price: uint256):
    ownable._check_owner()
    self.reserve_price = reserve_price
    log AuctionReservePriceUpdated(reserve_price)


@external
def set_min_bid_increment_percentage(percentage: uint256):
    ownable._check_owner()
    assert (percentage >= MIN_BID_INCREMENT_PERCENTAGE_ and percentage <= MAX_BID_INCREMENT_PERCENTAGE), "!percentage"
    self.min_bid_increment_percentage = percentage
    log AuctionMinBidIncrementPercentageUpdated(percentage)


@external
def set_duration(duration: uint256):
    ownable._check_owner()
    assert duration >= MIN_DURATION and duration <= MAX_DURATION, "!duration"
    self.duration = duration
    log AuctionDurationUpdated(duration)


@external
def set_proceeds_receiver(proceeds_receiver: address):
    ownable._check_owner()
    assert proceeds_receiver != empty(address), "!proceeds_receiver"
    self.proceeds_receiver = proceeds_receiver
    log ProceedsReceiverUpdated(proceeds_receiver)


@external
def set_fee_receiver(fee_receiver: address):
    ownable._check_owner()
    assert fee_receiver != empty(address), "!fee_receiver"
    self.fee_receiver = fee_receiver
    log FeeReceiverUpdated(fee_receiver)


@external
def set_fee(fee: uint256):
    ownable._check_owner()
    assert fee <= MAX_FEE, "!fee"
    self.fee = fee
    log FeeUpdated(fee)


# ============================================================================================
# Internal functions
# ============================================================================================

@internal
def _create_auction(ipfs_hash: String[46]) -> uint256:
    _start_time: uint256 = block.timestamp
    _end_time: uint256 = _start_time + self.duration
    _auction_id: uint256 = self.auction_id + 1

    self.auction_id = _auction_id
    self.auction_list[_auction_id] = Auction(
        auction_id=_auction_id,
        amount=0,
        start_time=_start_time,
        end_time=_end_time,
        bidder=empty(address),
        settled=False,
        ipfs_hash=ipfs_hash,
    )

    log AuctionCreated(self.auction_id, _start_time, _end_time, ipfs_hash)

    return _auction_id


@internal
def _settle_auction(auction_id: uint256):
    _auction: Auction = self.auction_list[auction_id]
    assert _auction.start_time != 0, "!auction"
    assert _auction.settled == False, "settled"
    assert block.timestamp > _auction.end_time, "!completed"

    self.auction_list[auction_id] = Auction(
        auction_id=_auction.auction_id,
        amount=_auction.amount,
        start_time=_auction.start_time,
        end_time=_auction.end_time,
        bidder=_auction.bidder,
        settled=True,
        ipfs_hash=_auction.ipfs_hash,
    )

    if _auction.amount > 0:
        fee: uint256 = self.fee
        owner_amount: uint256 = _auction.amount
        if fee > 0:
            fee_amount: uint256 = _auction.amount * fee // PRECISION
            owner_amount -= fee_amount
            assert extcall self.payment_token.transfer(self.fee_receiver, fee_amount, default_return_value=True), "!fee transfer"

        assert extcall self.payment_token.transfer(self.proceeds_receiver, owner_amount, default_return_value=True), "!owner transfer"

    log AuctionSettled(_auction.auction_id, _auction.bidder, _auction.amount)


@internal
def _create_bid(auction_id: uint256, total_bid: uint256, bidder: address):
    _auction: Auction = self.auction_list[auction_id]
    assert _auction.auction_id == auction_id, "!auctionId"
    assert block.timestamp < _auction.end_time, "expired"
    assert total_bid >= self.reserve_price, "!reservePrice"
    assert total_bid >= self._minimum_total_bid(auction_id), "!increment"

    tokens_needed: uint256 = total_bid
    pending_amount: uint256 = self.auction_pending_returns[auction_id][bidder]
    if pending_amount > 0:
        if pending_amount >= total_bid:
            # Use entire bid amount from pending returns
            self.auction_pending_returns[auction_id][bidder] = pending_amount - total_bid
            tokens_needed = 0
        else:
            # Use all pending returns and require additional tokens
            self.auction_pending_returns[auction_id][bidder] = 0
            tokens_needed = total_bid - pending_amount

    if tokens_needed > 0:
        assert extcall self.payment_token.transferFrom(bidder, self, tokens_needed, default_return_value=True), "!transfer"

    last_bidder: address = _auction.bidder
    if last_bidder != empty(address):
        # Store pending return for the auction it came from
        self.auction_pending_returns[auction_id][last_bidder] += _auction.amount

    extended: bool = _auction.end_time - block.timestamp < self.time_buffer
    self.auction_list[auction_id] = Auction(
        auction_id=_auction.auction_id,
        amount=total_bid,
        start_time=_auction.start_time,
        end_time=_auction.end_time
        if not extended
        else block.timestamp + self.time_buffer,
        bidder=bidder,
        settled=_auction.settled,
        ipfs_hash=_auction.ipfs_hash,
    )

    log AuctionBid(_auction.auction_id, bidder, msg.sender, total_bid, extended)

    if extended:
        log AuctionExtended(_auction.auction_id, _auction.end_time)


@internal
@view
def _minimum_total_bid(auction_id: uint256) -> uint256:
    _auction: Auction = self.auction_list[auction_id]
    assert _auction.start_time != 0, "!auctionId"
    assert not _auction.settled, "settled"
    if _auction.amount == 0:
        return self.reserve_price

    _min_pct: uint256 = self.min_bid_increment_percentage
    return _auction.amount + ((_auction.amount * _min_pct) // PRECISION)


@internal
@view
def _minimum_additional_bid(
    auction_id: uint256, bidder: address = empty(address)
) -> uint256:
    _total_min: uint256 = self._minimum_total_bid(auction_id)
    if bidder == empty(address):
        return _total_min

    pending: uint256 = self.auction_pending_returns[auction_id][bidder]
    if pending >= _total_min:
        return 0
    return _total_min - pending


@internal
@view
def _check_caller(_account: address, _caller: address, _req_status: ApprovalStatus):
    if _account != _caller:
        _status: ApprovalStatus = self.approved_caller[_account][_caller]
        if _status == ApprovalStatus.BidAndWithdraw:
            return

        assert (_status == _req_status), "!caller"