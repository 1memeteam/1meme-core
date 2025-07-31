// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "utils/BaseTest.sol";

contract FeeTest is BaseTest {
    function testFee() public {
        (uint256 mintTax, uint256 burnTax) = (200, 300);
        deployNewERC20(mintTax, burnTax, 1000, 0.001 ether);
        vm.deal(user1, 1000000 ether);
        vm.startPrank(user1);
        fakeUSDT.mint(1e8 ether);
        fakeUSDT.approve(address(currentToken), 1e8 ether);

        currentToken.mint(user1, 1 ether, 0);
        uint256 projectTreasuryBalance = fakeUSDT.balanceOf(projectTreasury);
        vm.startPrank(platformAdmin);
        uint256 platformTreasuryBalance = fakeUSDT.balanceOf(platformTreasury);
        console.log("mint tax", mintTax);
        console.log("project fee", projectTreasuryBalance);
        console.log("platform fee", platformTreasuryBalance);
        (uint256 mintTaxPlatform, uint256 burnTaxPlatform) = factory.getTaxRateOfPlatform();
        require((1 ether * mintTax) / 10000 == projectTreasuryBalance, "invalid project fee");
        require((1 ether * mintTaxPlatform) / 10000 == platformTreasuryBalance, "ivalid project fee");
        uint256 erc20Balance = currentToken.balanceOf(user1);
        uint256 tokenBalanceBefore = fakeUSDT.balanceOf(address(currentToken));
        console.log(erc20Balance, currentToken.totalSupply());
        vm.startPrank(projectTreasury);
        fakeUSDT.transfer(address(1), fakeUSDT.balanceOf(projectTreasury));
        vm.startPrank(platformTreasury);
        fakeUSDT.transfer(address(1), fakeUSDT.balanceOf(platformTreasury));
        vm.startPrank(user1);
        currentToken.burn(user1, erc20Balance, 0);
        vm.startPrank(platformAdmin);
        uint256 tokenBalanceAfter = fakeUSDT.balanceOf(address(currentToken));
        projectTreasuryBalance = fakeUSDT.balanceOf(projectTreasury);
        platformTreasuryBalance = fakeUSDT.balanceOf(platformTreasury);

        console.log("burn tax", burnTax);
        console.log("project fee", projectTreasuryBalance);
        console.log("platform fee", platformTreasuryBalance);

        require(((tokenBalanceBefore - tokenBalanceAfter) * burnTax) / 10000 == projectTreasuryBalance, "invalid project fee");
        require(((tokenBalanceBefore - tokenBalanceAfter) * burnTaxPlatform) / 10000 == platformTreasuryBalance, "ivalid project fee");
    }
}
