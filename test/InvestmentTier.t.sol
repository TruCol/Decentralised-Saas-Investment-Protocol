// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Tier } from "../src/Tier.sol";
import { ITier } from "../src/Tier.sol";

import { TierInvestment } from "../src/TierInvestment.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract TierTest is PRBTest, StdCheats {
  Tier internal validTier;
  ITier internal some;
  address internal testAddress;
  Tier internal tierInterface;

  TierInvestment internal tierInvestment;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual {
    // Instantiate the attribute for the contract-under-test.
    tierInterface = new Tier(0, 10000, 10); // Set expected values
    testAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // Instantiate the object that is tested.
    // tierInvestment = new TierInvestment(testAddress, 43, mockTierInterface);
    tierInvestment = new TierInvestment(testAddress, 43, tierInterface);
  }

  /**
   * Test the TierInvestment object can be created with valid values, and that
   * its public parameters are available, and that its private parameters are
   * not available.
   *
   */
  function testAttributes() public {
    // Fail first: The test detects the invalid commented address below.
    // address expectedAddress = 0xF39fD6E51aad88F6f4ce6AB8827279cFFFb92268;
    // Actual expected address.
    address expectedAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    assert(tierInvestment.investor() == expectedAddress);
    assertEq(tierInvestment.newInvestmentAmount(), 43, "The maxVal was not as expected");
  }
}
