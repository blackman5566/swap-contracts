// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
說明：

所有資產計帳都在內部 reserve，不直接查 ERC20.balanceOf（這是 AMM 標準做法）。

流動性必須外部先 transfer，PairAMM 不主動收錢。（Router 負責打錢過來再執行 addLiquidity/swap）

swap 沒有 LP token、沒手續費，完全學 Uniswap 最簡模式。

 * @title PairAMM
 * @dev 每一組 token 的 AMM 流動池。支援：加流動性、查詢儲備、單池 swap。
 * 本合約只做內部資產計帳與 swap 兌換，不發 LP Token、不收手續費。
 */
contract PairAMM {
    // 池子裡的兩種 Token（token0, token1），部署時就固定
    address public immutable token0;
    address public immutable token1;

    // 內部記帳的資金池（非直接讀取 ERC20 balance，這是流動性累計值）
    uint112 public reserve0;
    uint112 public reserve1;

    /**
     * @dev 部署時設置兩個 token 的位址，token0 < token1
     */
    constructor(address _token0, address _token1) {
        require(_token0 != _token1, "Tokens must be different");
        require(_token0 != address(0) && _token1 != address(0), "Zero address");
        token0 = _token0;
        token1 = _token1;
    }

    // ========== 加流動性 ==========
    /**
     * @notice 將兩種 token 按比例存入池內（要先把幣 transfer 進合約）
     * @dev 只負責內部記帳，不處理 transfer，外部如 Router 需先傳好
     */
    function addLiquidity(uint amount0, uint amount1) external {
        reserve0 += uint112(amount0);
        reserve1 += uint112(amount1);
    }

    // ========== 儲備查詢 ==========
    /**
     * @notice 依據指定的 from/to token 傳回各自儲備
     * @dev swap 前計算用
     */
    function getReservesFor(address fromToken, address toToken) external view returns (uint112, uint112) {
        if (fromToken == token0 && toToken == token1) return (reserve0, reserve1);
        if (fromToken == token1 && toToken == token0) return (reserve1, reserve0);
        revert("Wrong tokens");
    }

    /**
     * @notice 查詢目前池子的兩種 token 儲備
     */
    function getReserves() external view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    // ========== Swap 功能 ==========
    /**
     * @notice 單 hop swap。把 fromToken 換成另一種 token 給指定用戶（to）
     * @dev swap 之前要先把 fromToken 傳到池子，否則沒得換！
     */
    function swap(address fromToken, uint amountIn, address to) public returns (uint amountOut) {
        require(fromToken == token0 || fromToken == token1, "Invalid token");
        require(amountIn > 0, "AmountIn = 0");

        // 判斷是哪個方向
        bool isToken0In = fromToken == token0;
        uint112 reserveIn  = isToken0In ? reserve0 : reserve1;
        uint112 reserveOut = isToken0In ? reserve1 : reserve0;

        require(reserveIn + amountIn > 0 && reserveOut > 0, "No liquidity");

        // AMM 兌換公式（無手續費版）: y = (dx * y) / (x + dx)
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);

        // 把 output 幣轉給使用者
        address outToken = isToken0In ? token1 : token0;
        IERC20(outToken).transfer(to, amountOut);

        // 內部更新池子記帳
        if (isToken0In) {
            reserve0 += uint112(amountIn);
            reserve1 -= uint112(amountOut);
        } else {
            reserve1 += uint112(amountIn);
            reserve0 -= uint112(amountOut);
        }
    }

    /**
     * @notice Router 用，語意更明確的 swap 呼叫方式
     */
    function swapOutTo(address fromToken, uint amountIn, address to) external returns (uint amountOut) {
        return swap(fromToken, amountIn, to);
    }
}
