// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

interface IHook {
    function hookName() external pure returns (string memory);

    function parameterEncoder() external pure returns (string memory);

    function getParameters(address token) external view returns (bytes memory);

    function registerHook(address token, bytes calldata data) external;

    function beforeTransferHook(address from, address to, uint256 amount) external;

    function afterTransferHook(address from, address to, uint256 amount) external;

    function beforeMintHook(address to, uint256 tokenAmount, uint256 lockAmount) external;

    function afterMintHook(address to, uint256 tokenAmount, uint256 lockAmount) external;

    function beforeBurnHook(address from, uint256 tokenAmount, uint256 returnAmount) external;

    function afterBurnHook(address from, uint256 tokenAmount, uint256 returnAmount) external;
}
