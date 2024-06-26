// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { Tier } from "../../../src/Tier.sol";
import { DecentralisedInvestmentManager } from "../../../src/DecentralisedInvestmentManager.sol";
import { ExposedDecentralisedInvestmentManager } from "test/unit/ExposedDecentralisedInvestmentManager.sol";
import { SaasPaymentProcessor } from "../../../src/SaasPaymentProcessor.sol";
import { Helper } from "../../../src/Helper.sol";
import { TierInvestment } from "../../../src/TierInvestment.sol";
import { WorkerGetReward } from "../../../src/WorkerGetReward.sol";
import { InitialiseDim } from "test/InitialiseDim.sol";

interface Interface {
  function setUp() external;

  function testRecoverRewardsWithNonprojectLead() external;

  function testRecoverMoreRewardThanContractContains() external;

  function testRecoverBeforeMinDurationHasPassed() external;

  function testRecoverBeforeMaxDurationHasPassed() external;

  function testRecoverRewardsWithProjectLead() external;
}

contract WorkerGetRewardTest is PRBTest, StdCheats, Interface {
  address internal _projectLead;
  address private _userWallet;
  Tier[] private _tiers;
  DecentralisedInvestmentManager private _dim;
  uint256 private _projectLeadFracNumerator;
  uint256 private _projectLeadFracDenominator;
  SaasPaymentProcessor private _saasPaymentProcessor;
  Helper private _helper;
  TierInvestment[] private _tierInvestments;
  ExposedDecentralisedInvestmentManager private _exposedDim;
  uint256 private _investmentAmount1;

  address[] private _withdrawers;
  uint256[] private _owedDai;

  WorkerGetReward private _workerGetReward;

  /// @dev A function invoked before each test case is run.
  function setUp() public virtual override {
    // Instantiate the attribute for the contract-under-test.
    _projectLead = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256[] memory ceilings = new uint256[](3);
    ceilings[0] = 4 ether;
    ceilings[1] = 15 ether;
    ceilings[2] = 30 ether;
    uint8[] memory multiples = new uint8[](3);
    multiples[0] = 10;
    multiples[1] = 5;
    multiples[2] = 2;
    InitialiseDim initDim = new InitialiseDim({
      ceilings: ceilings,
      multiples: multiples,
      raisePeriod: 12 weeks,
      investmentTarget: 3 ether,
      projectLead: _projectLead,
      projectLeadFracNumerator: 4,
      projectLeadFracDenominator: 10
    });
    _dim = initDim.getDim();

    _workerGetReward = _dim.getWorkerGetReward();
  }

  function testRecoverRewardsWithNonprojectLead() public virtual override {
    vm.expectRevert("Someone other than projectLead tried to recover rewards.");
    _workerGetReward.projectLeadRecoversRewards(1);
  }

  function testRecoverMoreRewardThanContractContains() public virtual override {
    // Ask 0 when contract has 0.
    vm.prank(_projectLead);
    vm.expectRevert("Tried to recover 0 wei.");
    _workerGetReward.projectLeadRecoversRewards(0);

    // Ask 1 when contract has 0.
    vm.prank(_projectLead);
    vm.expectRevert("Tried to recover more than the contract contains.");
    _workerGetReward.projectLeadRecoversRewards(1);

    // Ask 2 when contract has 1.
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 1 }(workerAddress, 8 weeks);
    vm.prank(_projectLead);
    vm.expectRevert("Tried to recover more than the contract contains.");
    _workerGetReward.projectLeadRecoversRewards(2);
  }

  function testRecoverBeforeMinDurationHasPassed() public virtual override {
    // Ask 2 when contract has 1.
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 3 }(workerAddress, 8 weeks);
    vm.prank(_projectLead);
    vm.expectRevert("ProjectLead tried to recover funds before workers got the chance.");
    _workerGetReward.projectLeadRecoversRewards(3);
    //
  }

  function testRecoverBeforeMaxDurationHasPassed() public virtual override {
    // Ask 2 when contract has 1.
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 3 }(workerAddress, 12 weeks);
    vm.prank(_projectLead);
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 12 weeks - 1);
    vm.expectRevert("ProjectLead tried to recover funds before workers got the chance.");
    _workerGetReward.projectLeadRecoversRewards(3);
  }

  function testRecoverRewardsWithProjectLead() public virtual override {
    // Ask 2 when contract has 1.
    address workerAddress = address(0);
    _workerGetReward.addWorkerReward{ value: 3 }(workerAddress, 12 weeks);
    vm.prank(_projectLead);
    // solhint-disable-next-line not-rely-on-time
    vm.warp(block.timestamp + 12 weeks + 1);
    // vm.expectRevert("ProjectLead tried to recover funds before workers got the chance.");
    _workerGetReward.projectLeadRecoversRewards(3);
  }
}
