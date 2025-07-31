// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/MeMe1TokenFactory.sol";
import "src/bondingCurve/ExpMixedBondingSwap.sol";
import "src/bondingCurve/LinearMixedBondingSwap.sol";
import "src/preset/MeMe1ERC20Mixed.sol";
import "src/preset/MeMe1ERC20WithSupply.sol";
import "src/preset/MeMe1LOL.sol";
import "src/test/TestERC20.sol";

abstract contract BaseTest is Test {
    address deployer = address(0x11);
    address platformAdmin = address(0x21);
    address platformTreasury = address(0x22);
    address projectAdmin = address(0x31);
    address projectTreasury = address(0x32);
    address user1 = address(0x41);
    address user2 = address(0x42);
    address user3 = address(0x43);
    uint256 nonce = 0;
    MeMe1TokenFactory factory;
    MeMe1ERC20WithSupply currentToken;
    string bondingCurveType;
    TestERC20 fakeUSDT = new TestERC20();
    LinearMixedBondingSwap linear;
    ExpMixedBondingSwap exp;

    function setUp() public virtual {
        vm.startPrank(platformAdmin);
        vm.deal(platformAdmin, 100 ether);
        factory = new MeMe1TokenFactory(platformAdmin, platformTreasury);
        exp = new ExpMixedBondingSwap();
        linear = new LinearMixedBondingSwap();
        factory.addBondingCurveImplement(address(exp));
        factory.addBondingCurveImplement(address(linear));
        factory.setLaunchTokenFee(0);
        MeMe1ERC20Mixed erc20Impl = new MeMe1ERC20Mixed();
        MeMe1ERC20WithSupply erc20WithSupplyImpl = new MeMe1ERC20WithSupply();
        factory.updateBondingImplement("ERC20", address(erc20Impl));
        factory.updateBondingImplement("ERC20WithSupply", address(erc20WithSupplyImpl));
        vm.label(address(factory), "Factory Implement");
        vm.label(address(exp), string.concat(exp.BondingCurveType(), " Bonding Curve"));
        bondingCurveType = exp.BondingCurveType();
        vm.label(address(factory), "factory");
        vm.label(deployer, "deployer");
        vm.label(platformTreasury, "platformTreasury");
        vm.label(projectAdmin, "projectAdmin");
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.stopPrank();

        vm.deal(projectTreasury, 0);
        vm.deal(platformTreasury, 0);
        vm.deal(user1, type(uint256).max / 2);
        vm.deal(user2, type(uint256).max / 2);
        vm.deal(user3, type(uint256).max / 2);
        vm.deal(msg.sender, type(uint256).max / 2);
    }

    function deployNewERC20WithFirstMint(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice, uint256 firstMint) public returns (MeMe1ERC20Mixed) {
        deployNewERC20WithHooks(mintTax, burnTax, A, initPrice, firstMint, address(0), "");
    }

    function deployNewERC20(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice) public returns (MeMe1ERC20Mixed) {
        deployNewERC20WithFirstMint(mintTax, burnTax, A, initPrice, 0);
    }

    function deployNewERC20WithHooks(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice, uint256 firstMint, address hook, bytes memory hookdata) public returns (MeMe1ERC20Mixed) {
        uint256 a = initPrice;
        uint256 b = ((A * 1e18) / a) * 1e18;
        bytes memory data = abi.encode(a, b);
        IMeMe1Factory.TokenInfo memory info = IMeMe1Factory.TokenInfo({
            tokenType: "ERC20",
            bondingCurveType: bondingCurveType,
            name: "Bonding ERC20 Token",
            symbol: "BET",
            metadata: "",
            projectAdmin: projectAdmin,
            projectTreasury: projectTreasury,
            projectMintTax: mintTax,
            projectBurnTax: burnTax,
            raisingTokenAddr: address(fakeUSDT),
            data: data,
            salt: bytes32(nonce++)
        });
        address[] memory hooks = new address[](1);
        bytes[] memory datas = new bytes[](1);
        hooks[0] = hook;
        datas[0] = hookdata;
        fakeUSDT.mint(firstMint);
        fakeUSDT.approve(address(factory), 1e8 ether);
        currentToken = MeMe1ERC20WithSupply(factory.deployTokenWithHooks(info, firstMint, hooks, datas));
        return currentToken;
    }

    function deployERC20WithSupply(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice, uint256 supply) public returns (MeMe1ERC20Mixed) {
        uint256 a = initPrice;
        uint256 b = ((A * 1e18) / a) * 1e18;
        console.log(a, b);
        bytes memory data = abi.encode(a, b);
        bytes memory dataNew = abi.encode(supply, data);
        IMeMe1Factory.TokenInfo memory info = IMeMe1Factory.TokenInfo({
            tokenType: "ERC20WithSupply",
            bondingCurveType: bondingCurveType,
            name: "Bonding ERC20 Token",
            symbol: "BET",
            metadata: "",
            projectAdmin: projectAdmin,
            projectTreasury: projectTreasury,
            projectMintTax: mintTax,
            projectBurnTax: burnTax,
            raisingTokenAddr: address(fakeUSDT),
            data: dataNew,
            salt: bytes32(nonce++)
        });
        fakeUSDT.approve(address(factory), 1e8 ether);
        currentToken = MeMe1ERC20WithSupply(factory.deployToken(info, 0));
        return currentToken;
    }

    function deployLOL(address mm) public returns (MeMe1LOL) {
        IMeMe1Factory.TokenInfo memory info = IMeMe1Factory.TokenInfo({
            tokenType: "LOL",
            bondingCurveType: bondingCurveType,
            name: "Bonding ERC20 Token",
            symbol: "BET",
            metadata: "",
            projectAdmin: projectAdmin,
            projectTreasury: projectTreasury,
            projectMintTax: 0,
            projectBurnTax: 0,
            raisingTokenAddr: address(fakeUSDT),
            data: abi.encode(mm,1e9 ether,90, 50,uint256(0.0001666349480736 ether),uint256(200000000 ether)),
            salt: bytes32(nonce++)
        });
        return MeMe1LOL(factory.deployToken(info, 0));
    }
}
