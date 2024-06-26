// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Helper } from "../../src/Helper.sol";

interface Interface {
  function setUp() external;

  function testPayout0() external;

  function testPayout1() external;

  function testPayout2() external;

  function testPayout3() external;

  function testPayout4() external;
}

contract ComputeRemainingInvestorPayoutTest is PRBTest, StdCheats, Interface {
  Helper private _helper;

  /// @dev A function invoked before each test case is run.
  function setUp() public override {
    // Initialise contract helper.
    _helper = new Helper();
  }

  /**
   * Test the computeRemainingInvestorPayout function returns 0 correctly.
   *
   */
  function testPayout0() public override {
    uint256 cumRemainingInvestorReturn = 0;
    uint256 investorFracNumerator = 4;
    uint256 investorFracDenominator = 10;
    uint256 paidAmount = 200;
    assertEq(
      _helper.computeRemainingInvestorPayout(
        cumRemainingInvestorReturn,
        investorFracNumerator,
        investorFracDenominator,
        paidAmount
      ),
      0,
      "Something other than zero was returned."
    );
  }

  function testPayout1() public override {
    uint256 cumRemainingInvestorReturn = 500;
    uint256 investorFracNumerator = 4;
    uint256 investorFracDenominator = 10;
    uint256 paidAmount = 200;
    assertEq(
      _helper.computeRemainingInvestorPayout(
        cumRemainingInvestorReturn,
        investorFracNumerator,
        investorFracDenominator,
        paidAmount
      ),
      // The investors could maximally receive 200*0.4= 80 from this payout,
      // even though they can receive up to 500 in total at later payments.
      80,
      "Investors did not get the expected payout allocation of 80 wei."
    );
  }

  function testPayout2() public override {
    uint256 cumRemainingInvestorReturn = 79;
    uint256 investorFracNumerator = 4;
    uint256 investorFracDenominator = 10;
    uint256 paidAmount = 200;
    assertEq(
      _helper.computeRemainingInvestorPayout(
        cumRemainingInvestorReturn,
        investorFracNumerator,
        investorFracDenominator,
        paidAmount
      ),
      // The investors could maximally receive 200*0.4= 80 from this payout,
      // even though they can receive up to 500 in total at later payments.
      79,
      "Investors did not get the expected payout allocation of 79 wei."
    );
  }

  function testPayout3() public override {
    uint256 cumRemainingInvestorReturn = 1;
    uint256 investorFracNumerator = 4;
    uint256 investorFracDenominator = 10;
    uint256 paidAmount = 200;
    assertEq(
      _helper.computeRemainingInvestorPayout(
        cumRemainingInvestorReturn,
        investorFracNumerator,
        investorFracDenominator,
        paidAmount
      ),
      // The investors could maximally receive 200*0.4= 80 from this payout,
      // even though they can receive up to 500 in total at later payments.
      1,
      "Investors did not get the expected payout allocation of 1 wei."
    );
  }

  function testPayout4() public override {
    uint256 cumRemainingInvestorReturn = 9900;
    uint256 investorFracNumerator = 3;
    uint256 investorFracDenominator = 7;
    uint256 paidAmount = 200;
    assertEq(
      _helper.computeRemainingInvestorPayout(
        cumRemainingInvestorReturn,
        investorFracNumerator,
        investorFracDenominator,
        paidAmount
      ),
      // The investors could maximally receive 200*3/7= 85.7... from this
      //payout, even though they can receive up to 500 in total at later
      // payments. This is rounded up to 86.
      86,
      "Investors did not get the expected payout allocation of 86 wei."
    );
  }
}
