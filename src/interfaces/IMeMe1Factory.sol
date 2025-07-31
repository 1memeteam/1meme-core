// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "openzeppelin/access/IAccessControl.sol";

interface IMeMe1Factory is IAccessControl {
    /**
     * Token information struct, containing details of the token being deployed.
     */
    struct TokenInfo {
        /**
         * Token type.
         */
        string tokenType;
        /**
         * Bonding curve type.
         */
        string bondingCurveType;
        /**
         * Token name.
         */
        string name;
        /**
         * Token symbol.
         */
        string symbol;
        /**
         * Token metadata.
         */
        string metadata;
        /**
         * Address of the project administrator.
         */
        address projectAdmin;
        /**
         * Address of the project treasury.
         */
        address projectTreasury;
        /**
         * Project mint tax rate.
         */
        uint256 projectMintTax;
        /**
         * Project burn tax rate.
         */
        uint256 projectBurnTax;
        /**
         * Address of the raising token.
         */
        address raisingTokenAddr;
        /**
         * Data bytes.
         */
        bytes data;
        /**
         * Salt, determine token address
         */
        bytes32 salt;
    }

    /**
     * Deploy a new token with the specified `TokenInfo`.
     *
     * @param token The information of the token to be deployed
     * @param mintfirstAmount The first amount of the token to be minted.
     */
    function deployToken(TokenInfo calldata token, uint256 mintfirstAmount) external payable returns (address);

    /**
     * Add an implementation of a bonding curve type to the Bonding platform.
     *
     * @param impl the implementation address to be added.
     */
    function addBondingCurveImplement(address impl) external;

    /**
     * Updates the implementation of a Bonding token.
     *
     * @param tokenType the type of token
     * @param impl updates the implementation of the Bonding.
     */
    function updateBondingImplement(string calldata tokenType, address impl) external;

    /**
     * Retrieve the implementation of a specified token type from the Bonding platform.
     *
     * @param tokenType the type of token
     * @return impl the implementation address.
     */
    function getBondingImplement(string memory tokenType) external view returns (address impl);

    /**
     * Retrieve the implementation of a specified bonding curve type.
     *
     * @param bondingCurveType the type of bonding curve
     * @return impl the implementation address.
     */
    function getBondingCurveImplement(string calldata bondingCurveType) external view returns (address impl);

    /**
     * Set the platform's tax rate for minting and burning tokens.
     * @param platformMintTax the platform's tax rate for minting tokens.
     * @param platformBurnTax the platform's tax rate for burning tokens.
     */
    function setPlatformTaxRate(uint256 platformMintTax, uint256 platformBurnTax) external;

    /**
     * Retrieve the platform's tax rate for minting and burning tokens.
     * @return platformMintTax the platform's tax rate for minting tokens.
     * @return platformBurnTax the platform's tax rate for burning tokens.
     */
    function getTaxRateOfPlatform() external view returns (uint256 platformMintTax, uint256 platformBurnTax);

    /**
     * Get the number of tokens deployed on the Bonding platform.
     * @return len the number of tokens.
     */
    function getTokensLength() external view returns (uint256 len);

    /**
     * Get the address of a deployed token by its index.
     * @param index the index of the token.
     * @return addr the address of the deployed token.
     */
    function getToken(uint256 index) external view returns (address addr);

    /**
     * Get the address of the platform administrator.
     * @return the address of the platform administrator.
     */
    function getPlatformAdmin() external view returns (address);

    /**
     * Get the address of the platform treasury.
     * @return the address of the platform treasury.
     */
    function getPlatformTreasury() external view returns (address);

    function getTokenHooks(address token) external view returns (address[] memory hooks);

    /** Deploy a new token with the specified `TokenInfo` and hooks
     * @param token The information of the token to be deployed
     * @param mintfirstAmount The first amount of the token to be minted.
     * @param hooks the addresses of hooks
     * @param datas the parameters of hooks
     */
    function deployTokenWithHooks(TokenInfo calldata token, uint256 mintfirstAmount, address[] calldata hooks, bytes[] calldata datas) external payable returns (address);

    event LogTokenDeployed(address tokenImpl, address curveImpl, uint256 tokenId, address deployedAddr);

    event LogTokenTypeImplAdded(string tokenType, address impl);

    event LogBondingCurveTypeImplAdded(string tokenType, address impl);

    event LogPlatformAdminChanged(address newAccount);

    event LogPlatformTreasuryChanged(address newAccount);
    event LogRouteChanged(address newRoute);

    event LogPlatformTaxChanged();
    event LogHookRegistered(address token, address hook, bytes data);
}
