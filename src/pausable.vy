# @version 0.4.0

"""
@title Pausable
@license MIT
@author Leviathan
@notice pauseable.vy allows to implement an emergency stop mechanism that can be triggered by an authorized account
"""


import ownable_2step as ownable


# ============================================================================================
# Modules
# ============================================================================================


initializes: ownable
exports: (
    ownable.owner,
    ownable.pending_owner,
    ownable.transfer_ownership,
    ownable.accept_ownership,
)


# ============================================================================================
# Events
# ============================================================================================


event Paused:
    account: address


event Unpaused:
    account: address


# ============================================================================================
# Storage
# ============================================================================================


paused: public(bool)


# ============================================================================================
# Constructor
# ============================================================================================


@deploy
def __init__(owner: address):
    """
    @dev Initializes the contract with the owner
    @param owner The address of the owner
    """
    ownable.__init__(owner)


# ============================================================================================
# Owner functions
# ============================================================================================


@external
def pause():
    """
    @dev Pauses the contract
    """
    ownable._check_owner()
    _check_unpaused()
    self.paused = True
    log Paused(msg.sender)


@external
def unpause():
    """
    @dev Unpauses the contract
    """
    ownable._check_owner()
    _check_paused()
    self.paused = False
    log Unpaused(msg.sender)


# ============================================================================================
# Internal functions
# ============================================================================================


@internal
def _check_unpaused():
    """
    @dev Checks if the contract is unpaused
    """
    assert not self.paused, "paused"


@internal
def _check_paused():
    """
    @dev Checks if the contract is paused
    """
    assert self.paused, "!paused"