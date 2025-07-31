// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;
import "../interfaces/IMeMe1Token.sol";

abstract contract MeMe1Metadata is IMeMe1Token {
    string private _meta;

    function _setMetadata(string memory uri) internal {
        _meta = uri;
        emit LogMetadataChanged();
    }

    function getMetadata() public view virtual returns (string memory) {
        return _meta;
    }

    event LogMetadataChanged();
}
