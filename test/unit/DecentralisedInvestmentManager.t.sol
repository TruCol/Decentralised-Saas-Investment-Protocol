// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import { Tier } from "../../src/Tier.sol";
// Used to run the tests
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

// Import the main contract that is being tested.
import { DecentralisedInvestmentManager } from "../../src/DecentralisedInvestmentManager.sol";
import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";

interface Interface {
  function setUp() external;

  function testProjectLeadFracNumerator() external;

  function testEmptyTiers() external;

  function testReturnFunds() external;

  function testTierGap() external;

  function testZeroSAASPayment() external;

  function testReachedCeiling() external;

  function testIncreaseCurrentMultipleInstantly() external;

  function testWithdraw() external;

  function testAllocateDoesNotAcceptZeroAmountAllocation() external;

  function testDifferenceInSAASPayoutAndCumulativeReturnThrowsError() external;

  function testPerformSaasRevenueAllocation() external;
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract DecentralisedInvestmentManagerTest is PRBTest, StdCheats, Interface {
  address internal _projectLeadAddress;
  address payable private _investorWallet;
  address private _userWallet;
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;

  /// @dev A function invoked before each test case is run.
  function setUp() public override {
    // Instantiate the attribute for the contract-under-test.
    _projectLeadAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    _projectLeadFracNumerator = 4;
    _projectLeadFracDenominator = 10;

    // Specify the investment tiers in ether.
    uint256 firstTierCeiling = 4 ether;
    uint256 secondTierCeiling = 15 ether;
    uint256 thirdTierCeiling = 30 ether;
    Tier tier0 = new Tier(0, firstTierCeiling, 10);
    _tiers.push(tier0);
    Tier tier1 = new Tier(firstTierCeiling, secondTierCeiling, 5);
    _tiers.push(tier1);
    Tier tier2 = new Tier(secondTierCeiling, thirdTierCeiling, 2);
    _tiers.push(tier2);

    // assertEq(address(_projectLeadAddress).balance, 43);
    _dim = new DecentralisedInvestmentManager(
      _tiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress
    );

    // Assert the _cumReceivedInvestments is 0 after Initialisation.
    assertEq(_dim.getCumReceivedInvestments(), 0);

    _investorWallet = payable(address(uint160(uint256(keccak256(bytes("1"))))));
    deal(_investorWallet, 3 ether);
    _userWallet = address(uint160(uint256(keccak256(bytes("2")))));
    deal(_userWallet, 100 ether);
  }

  /// @dev Test to simulate a larger balance using `deal`.
  function testProjectLeadFracNumerator() public override {
    assertEq(_dim.getProjectLeadFracNumerator(), _projectLeadFracNumerator);
  }

  function testEmptyTiers() public override {
    // Test empty tiers are not allowed.
    Tier[] memory emptyTiers;
    vm.expectRevert(bytes("You must provide at least one tier."));
    new DecentralisedInvestmentManager(
      emptyTiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress
    );
  }

  function testReturnFunds() public override {
    vm.expectRevert(bytes("Temaining funds should be returned if the investment ceiling is reached."));
    _dim.receiveInvestment{ value: 5555 ether }();

    vm.expectRevert(bytes("The amount invested was not larger than 0."));
    _dim.receiveInvestment{ value: 0 ether }();
  }

  function testTierGap() public override {
    // storage Tier[] gappedTiers;`
    Tier[] memory gappedTiers = new Tier[](3); // Assuming maximum of 2 tiers

    Tier tier0 = new Tier(0, 5, 10);
    Tier tier1 = new Tier(6, 15, 5);
    Tier tier2 = new Tier(20, 25, 6);

    gappedTiers[0] = tier0;
    gappedTiers[1] = tier1;
    gappedTiers[2] = tier2;

    vm.expectRevert(
      bytes("Error, the ceiling of the previous investment tier is not equal to the floor of the next investment tier.")
    );
    _dim = new DecentralisedInvestmentManager(
      gappedTiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress
    );
  }

  function testZeroSAASPayment() public override {
    vm.expectRevert(bytes("The SAAS payment was not larger than 0."));
    // vm.prank(address(_userWallet));
    // Directly call the function on the deployed contract.
    _dim.receiveSaasPayment{ value: 0 }();
  }

  function testReachedCeiling() public override {
    _dim.receiveInvestment{ value: 30 ether }();
    vm.expectRevert(bytes("The investor ceiling is not reached."));
    _dim.receiveInvestment{ value: 22 ether }();
  }

  function testIncreaseCurrentMultipleInstantly() public override {
    _dim.receiveInvestment{ value: 20 ether }();
    vm.prank(address(0));
    vm.expectRevert(
      bytes("Increasing the current investment tier multiple attempted by someone other than project lead.")
    );
    _dim.increaseCurrentMultipleInstantly(1);

    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("The new multiple was not larger than the old multiple."));
    _dim.increaseCurrentMultipleInstantly(1);
  }

  function testWithdraw() public override {
    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("Insufficient contract balance"));
    _dim.withdraw(500 ether);

    _dim.receiveInvestment{ value: 20 ether }();

    vm.expectRevert(bytes("Withdraw attempted by someone other than project lead."));
    _dim.withdraw(1);
  }

  function testAllocateDoesNotAcceptZeroAmountAllocation() public override {
    ExposedDecentralisedInvestmentManager exposed_dim = new ExposedDecentralisedInvestmentManager(
      _tiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress
    );
    vm.prank(_projectLeadAddress);
    vm.expectRevert(bytes("The amount invested was not larger than 0."));
    exposed_dim.allocateInvestment(0, address(0));
  }

  function testDifferenceInSAASPayoutAndCumulativeReturnThrowsError() public override {
    ExposedDecentralisedInvestmentManager exposed_dim = new ExposedDecentralisedInvestmentManager(
      _tiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress
    );

    uint256 saasRevenueForInvestors = 2;
    uint256 cumRemainingInvestorReturn0;

    vm.expectRevert(
      bytes(
        string.concat(
          "The cumulativePayout (\n",
          Strings.toString(cumRemainingInvestorReturn0),
          ") is not equal to the saasRevenueForInvestors (\n",
          Strings.toString(saasRevenueForInvestors),
          ")."
        )
      )
    );

    exposed_dim.distributeSaasPaymentFractionToInvestors(saasRevenueForInvestors, cumRemainingInvestorReturn0);

    // Verify you can also do 0, 0 without error.
    exposed_dim.distributeSaasPaymentFractionToInvestors(0, 0);
  }

  function testPerformSaasRevenueAllocation() public override {
    ExposedDecentralisedInvestmentManager exposed_dim = new ExposedDecentralisedInvestmentManager(
      _tiers,
      _projectLeadFracNumerator,
      _projectLeadFracDenominator,
      _projectLeadAddress
    );

    uint256 amountAboveContractBalance = 1;
    address receivingWallet = address(0);

    vm.expectRevert(bytes("Error: Insufficient contract balance."));
    exposed_dim.performSaasRevenueAllocation(amountAboveContractBalance, receivingWallet);

    vm.expectRevert(bytes("The SAAS revenue allocation amount was not larger than 0."));
    exposed_dim.performSaasRevenueAllocation(0, receivingWallet);
  }
}