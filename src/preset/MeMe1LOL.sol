// SPDX-License-Identifier: None
pragma solidity >=0.8.13;

// diy
import "./MeMe1ERC20WithSupply.sol";

abstract contract MeMe1LOL is MeMe1ERC20WithSupply {
    bytes32 public constant MEME_OPERATOR = keccak256("MEME_OPERATOR");

    uint256 public supplyCap;
    uint256 public launchTime;
    bool public idoEnded;
    address public pair;
    event IdoEnded();
    event IdoFull();

    function _route() internal virtual returns (address);

    function _createPair(address raisingToken) internal virtual returns (address);

    function _addLiquidity(address raisingToken, uint256 value) internal virtual;

    function initialize(address bondingCurveAddress, IMeMe1Factory.TokenInfo memory token, address factory) public virtual override {
        pair = _createPair(token.raisingTokenAddr);
        uint256 totalSupply = 1e8 ether;
        supplyCap = totalSupply * 80 / 100;
        uint256 _a = 0.0000944339 ether;
        uint256 _b = 34394486.48770362 ether;
        (uint256 startTime) = abi.decode(token.data,(uint256));
        token.data = abi.encode(totalSupply, abi.encode(_a, _b));
        token.projectMintTax = 0;
        token.projectBurnTax = 0;
        super.initialize(bondingCurveAddress, token, factory);
        launchTime = startTime;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(pair != to || idoEnded, "can not add liquidity before ido");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mintInternal(address account, uint256 amount) internal virtual override {
        if(block.timestamp>=launchTime) {}
        else if (_msgSender()==address(_factory)) {}
        else {
            require(false, "didn't launch");
        }
        require(!idoEnded, "ido ended");
        super._mintInternal(account, amount);
        if (circulatingSupply() < supplyCap - 100e18) {
        } else if (circulatingSupply() <= supplyCap + 100e18) {
            emit IdoFull();
        } else {
            require(false, "ido ended");
        }
    }

    function _burnInternal(address account, uint256 amount) internal virtual override {
        require(block.timestamp>launchTime, "didn't launch");
        require(!idoEnded && circulatingSupply() < supplyCap - 100e18, "ido ended");
        super._burnInternal(account, amount);
    }

    function finishIDO() public {
        require(_factory.hasRole(MEME_OPERATOR, _msgSender()),"permission deny");
        require(!idoEnded, "ido ended");
        if (circulatingSupply() >= supplyCap - 100e18) {
            address raisingToken = getRaisingToken();
            uint256 raisedAmount = _getBalance(raisingToken);
            uint256 finishFee = 1000 ether;
            _transferInternal(_factory.getPlatformTreasury(), finishFee);
            uint256 out = raisedAmount - finishFee;
            idoEnded = true;
            _addLiquidity(raisingToken, out);
            emit IdoEnded();
        }
    }

    function getLeftTokenNeed() public view returns(uint256 paidAmount) {
        (,  paidAmount,,) = estimateMintNeed(supplyCap - circulatingSupply());
    }

    function _getBalance(address token) private view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
    
    function setProjectTaxRate(uint256, uint256) override public {
        require(false, "meme can't set tax rate");
    }
}
