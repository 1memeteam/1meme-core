// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/proxy/Clones.sol";
import "./interfaces/IMeMe1Factory.sol";
import "./interfaces/IMeMe1Token.sol";
import "./interfaces/IBondingCurve.sol";
import "./interfaces/IHook.sol";

contract MeMe1TokenFactory is IMeMe1Factory, AccessControl {
    using SafeERC20 for IERC20;
    using Clones for address;
    bytes32 public constant PLATFORM_ADMIN_ROLE = keccak256("PLATFORM_ADMIN");

    mapping(string => address) private _implementsMap;
    mapping(uint256 => address) private tokens;
    mapping(address => string) private tokensType;
    mapping(address => uint256) private upgradeTimelock;
    mapping(address => bytes) private upgradeList;
    mapping(address => address[]) public tokenHooks;
    mapping(address => mapping(address => uint256)) public getPair;

    uint256 private tokensLength;

    mapping(string => address) private _BondingImplementMap;
    address private _platformAdmin;
    address private _platformTreasury;

    uint256 private constant MAX_PLATFORM_TAX_RATE = 100;
    uint256 private _platformMintTax;
    uint256 private _platformBurnTax;
    uint256 public launchTokenFee = 10 ether;
    address private _route;
    event Initialized(uint8);
    event LaunchTokenFeeChanged(uint256 fee);

    constructor(address platformAdmin, address platformTreasury) {
        _grantRole(PLATFORM_ADMIN_ROLE, platformAdmin);
        _platformAdmin = platformAdmin;
        _platformTreasury = platformTreasury;
        _platformMintTax = 50;
        _platformBurnTax = 50;
        emit Initialized(1);
    }

    /// @inheritdoc IMeMe1Factory
    function deployToken(TokenInfo calldata token, uint256 mintfirstAmount) public payable returns (address) {
        address tokenImpl = getBondingImplement(token.tokenType);
        address tokenAddr = tokenImpl.cloneDeterministic(token.salt);
        address curveImpl = getBondingCurveImplement(token.bondingCurveType);
        IMeMe1Token(tokenAddr).initialize(curveImpl, token, address(this));
        address raisingAddr = IMeMe1Token(tokenAddr).getRaisingToken();
        getPair[raisingAddr][tokenAddr] = 1; // mint
        getPair[tokenAddr][raisingAddr] = 2; // burn
        uint256 tokenId = tokensLength;
        tokens[tokensLength] = tokenAddr;
        tokensLength++;
        tokensType[tokenAddr] = token.tokenType;
        payable(_platformTreasury).transfer(launchTokenFee);
        if (mintfirstAmount > 0) {
            if (token.raisingTokenAddr != address(0)) {
                IERC20(token.raisingTokenAddr).safeTransferFrom(msg.sender, address(this), mintfirstAmount);
                uint256 amount = IERC20(token.raisingTokenAddr).balanceOf(address(this));
                IERC20(token.raisingTokenAddr).safeApprove(tokenAddr, amount);
                IMeMe1Token(tokenAddr).mint(msg.sender, amount, 0);
            } else {
                uint256 amount = address(this).balance;
                require(amount>=mintfirstAmount, "maybe loss fund");
                IMeMe1Token(tokenAddr).mint{value: amount}(msg.sender, amount, 0);
            }
        }
        emit LogTokenDeployed(tokenImpl, curveImpl, tokenId, tokenAddr);
        return tokenAddr;
    }

    /// @inheritdoc IMeMe1Factory
    function deployTokenWithHooks(TokenInfo calldata token, uint256 mintfirstAmount, address[] calldata hooks, bytes[] calldata datas) public payable returns (address) {
        address proxy = deployToken(token, mintfirstAmount);
        require(hooks.length == datas.length);
        addHooksForToken(proxy, hooks, datas);
        return proxy;
    }

    /// @inheritdoc IMeMe1Factory
    function setPlatformTaxRate(uint256 platformMintTax, uint256 platformBurnTax) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(MAX_PLATFORM_TAX_RATE >= platformMintTax && platformMintTax >= 0, "SetTax:Platform Mint Tax Rate must between 0% to 1%");
        require(MAX_PLATFORM_TAX_RATE >= platformBurnTax && platformBurnTax >= 0, "SetTax:Platform Burn Tax Rate must between 0% to 1%");
        _platformMintTax = platformMintTax;
        _platformBurnTax = platformBurnTax;
        emit LogPlatformTaxChanged();
    }

    /// @inheritdoc IMeMe1Factory
    function getTaxRateOfPlatform() public view returns (uint256 platformMintTax, uint256 platformBurnTax) {
        return (_platformMintTax, _platformBurnTax);
    }

    /// @inheritdoc IMeMe1Factory
    function addBondingCurveImplement(address impl) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(impl != address(0), "invalid implement");
        string memory bondingCurveType = IBondingCurve(impl).BondingCurveType();
        require(bytes(bondingCurveType).length != bytes("").length, "bonding curve type error");
        _implementsMap[bondingCurveType] = impl;
        emit LogBondingCurveTypeImplAdded(bondingCurveType, impl);
    }

    /// @inheritdoc IMeMe1Factory
    function getBondingCurveImplement(string calldata bondingCurveType) public view returns (address impl) {
        impl = _implementsMap[bondingCurveType];
        require(impl != address(0), "no such implement");
    }

    /// @inheritdoc IMeMe1Factory
    function updateBondingImplement(string calldata tokenType, address impl) public onlyRole(PLATFORM_ADMIN_ROLE) {
        _BondingImplementMap[tokenType] = impl;
        require(_BondingImplementMap[tokenType] != address(0), "init already error");
        emit LogTokenTypeImplAdded(tokenType, impl);
    }

    /// @inheritdoc IMeMe1Factory
    function getBondingImplement(string memory tokenType) public view returns (address impl) {
        impl = _BondingImplementMap[tokenType];
        require(impl != address(0), "no such implement");
    }

    /// @inheritdoc IMeMe1Factory
    function getTokensLength() public view returns (uint256 len) {
        len = tokensLength;
    }

    /// @inheritdoc IMeMe1Factory
    function getToken(uint256 index) public view returns (address addr) {
        addr = tokens[index];
        require(addr != address(0), "no such token");
    }

    function getRoute() public view returns (address) {
        return _route;
    }

    /// @inheritdoc IMeMe1Factory
    function getPlatformAdmin() public view returns (address) {
        return _platformAdmin;
    }

    /// @inheritdoc IMeMe1Factory
    function getPlatformTreasury() public view returns (address) {
        return _platformTreasury;
    }

    function setRoute(address route) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(route != address(0), "Invalid Address");
        _route = route;
        emit LogRouteChanged(route);
    }

    function setLaunchTokenFee(uint256 fee) public onlyRole(PLATFORM_ADMIN_ROLE) {
        launchTokenFee = fee;
        emit LaunchTokenFeeChanged(fee);
    }

    function setPlatformAdmin(address newPlatformAdmin) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(newPlatformAdmin != address(0), "Invalid Address");
        _revokeRole(PLATFORM_ADMIN_ROLE, _platformAdmin);
        _grantRole(PLATFORM_ADMIN_ROLE, newPlatformAdmin);
        _platformAdmin = newPlatformAdmin;
        emit LogPlatformAdminChanged(newPlatformAdmin);
    }

    function addPlatformRole(bytes32 role, address account) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(role != PLATFORM_ADMIN_ROLE, "Invalid role");
        _setRoleAdmin(role, PLATFORM_ADMIN_ROLE);
        _grantRole(role, account);
    }

    function setPlatformTreasury(address newPlatformTreasury) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(newPlatformTreasury != address(0), "Invalid Address");
        _platformTreasury = newPlatformTreasury;
        emit LogPlatformTreasuryChanged(newPlatformTreasury);
    }

    function addHookForToken(address token, address hook, bytes calldata data) private {
        if (address(0) == hook) {
            return;
        }
        tokenHooks[token].push(hook);
        IHook(hook).registerHook(token, data);
        emit LogHookRegistered(token, hook, data);
    }

    function addHooksForToken(address token, address[] calldata hooks, bytes[] calldata datas) private {
        require(hooks.length == datas.length);
        for (uint256 i = 0; i < hooks.length; i++) {
            addHookForToken(token, hooks[i], datas[i]);
        }
    }

    /// @inheritdoc IMeMe1Factory
    function getTokenHooks(address token) external view override returns (address[] memory) {
        return tokenHooks[token];
    }

    receive() external payable {
        (bool success, ) = _platformTreasury.call{value: msg.value}("");
        require(success, "platform transfer failed");
    }

    fallback() external payable {}
}
