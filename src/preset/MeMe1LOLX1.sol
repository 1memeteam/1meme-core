// SPDX-License-Identifier: None
pragma solidity >=0.8.13;

// diy
import "./MeMe1LOL.sol";

contract MeMe1LOLX1 is MeMe1LOL {
    using SafeERC20 for IERC20;

    function _route() internal pure override returns (address) {
        return 0x89eA27957bb86FBFFC2e0ABfc5a5a64BB0343367;
    }

    function _createPair(address raisingToken) internal virtual override returns (address addr) {
        if (raisingToken == address(0)) {
            addr = IUniswapFactory(IUniswapRouter(_route()).factory()).createPair(IUniswapRouter(_route()).WETH(), address(this));
        } else {
            addr = IUniswapFactory(IUniswapRouter(_route()).factory()).createPair(raisingToken, address(this));
        }
    }

    function _addLiquidity(address raisingToken, uint256 value) internal override {
        uint256 balance = balanceOf(address(this));
        address route = _route();
        _approve(address(this), address(route), balance);
        if (raisingToken == address(0)) {
            IUniswapRouter(route).addLiquidityETH{value: value}(address(this), balance, 0, 0, address(0), block.timestamp + 1);
        } else {
            IERC20(raisingToken).safeApprove(address(route), value);
            IUniswapRouter(route).addLiquidity(address(this), raisingToken, balance, value, 0, 0, address(0), block.timestamp + 1);
        }
    }
}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouter {
    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable;

    function factory() external returns (address);
}
