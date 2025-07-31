// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "utils/BaseTest.sol";
import "../../src/bondingCurve/LinearMixedBondingSwap.sol";
import "../../src/preset/MeMe1LOLX1.sol";

contract PresetTest is BaseTest {
    uint256 bscFork;
    uint256 baseFork;

    function setUp() public override {
        super.setUp();
        bscFork = vm.createFork("https://rpc.xone.org");
        vm.selectFork(bscFork);
        address lolImpl = address(new MeMe1LOLX1());
        fakeUSDT = new TestERC20();
        vm.prank(platformAdmin);
        factory.addPlatformRole(keccak256("MEME_OPERATOR"), deployer);
        vm.prank(platformAdmin);
        factory.updateBondingImplement("LOL", address(lolImpl));
    }

    function testLOL() public {
        address mm = address(1011);
        MeMe1LOL lol = deployLOL(mm);
        uint leftNeed = lol.getLeftTokenNeed();
        uint paidAmount = leftNeed - 1 ether;
        vm.startPrank(user1);
        fakeUSDT.approve(address(lol), type(uint256).max);
        fakeUSDT.mint(paidAmount * 2);
        lol.mint(address(this), paidAmount, 0);
        address pair = lol.pair();
        console.log(lol.circulatingSupply());
        require(!lol.idoEnded(), "ido not end");
        vm.expectRevert();
        lol.transfer(pair, 1);
        vm.expectRevert();
        lol.mint(address(this), 10 ether, 0);
        lol.mint(address(this), 1 ether, 0);
        vm.startPrank(deployer);
        lol.finishIDO();
        require(lol.idoEnded(), "ido end");
        require(IERC20(pair).balanceOf(address(0x0))>0, "lp mint to dead");
        require(fakeUSDT.balanceOf(address(lol)) == 0 , "usdt left");
        require(lol.balanceOf(address(lol)) == 0 , "token left");
    }
}
