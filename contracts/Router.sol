// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Factory.sol";
import "./PairAMM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
說明：

用戶不直接跟 PairAMM/Factory 互動，只跟 Router。Router 自動找到池子，幫你送錢加流動性或 swap。

支援多跳路徑（A→B→C），每一段都自動拆解出金額與最終結果。

滑點保護、步驟說明、路徑解包等全自動處理。

 * @title Router
 * @dev 所有用戶都透過 Router 跟 DEX 互動：
 * - 增加流動性（addLiquidity）
 * - 兌換（單跳/多跳 swap）
 * Router 會自動幫你找到對應的 PairAMM，再把錢/指令送進去。
 */
contract Router {
    // Factory 合約，用於查找/創建對應的流動池
    Factory public factory;

    /**
     * @dev 設定工廠地址（部署時傳入）
     */
    constructor(address _factory) {
        factory = Factory(_factory);
    }

    // ========== 加流動性 ==========
    /**
     * @notice 增加 tokenA, tokenB 的流動性（一次性雙幣打入 pool）
     * @dev 實際流程：用戶 approve => Router 收錢 => 轉給 PairAMM => 更新儲備
     */
    function addLiquidity(address tokenA, address tokenB, uint amountA, uint amountB) external {
        address pair = factory.getPair(tokenA, tokenB);
        require(pair != address(0), "Pair not exist");

        // 1. 從用戶收兩種 token
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // 2. Router 把 token 轉給 PairAMM
        IERC20(tokenA).transfer(pair, amountA);
        IERC20(tokenB).transfer(pair, amountB);

        // 3. 通知 PairAMM 記帳
        PairAMM(pair).addLiquidity(amountA, amountB);
    }

    // ========== Swap（支援多跳路徑） ==========
    /**
     * @notice 支援單跳或多跳 swap（路徑 path 可以有多幣），自動分段找 pair 執行兌換
     * @param amountIn     用戶想輸入的幣數量
     * @param amountOutMin 最低可接受兌換結果（滑點防護）
     * @param path         交換路徑 [A, B, C, ...]
     * @param to           兌換結果給哪個帳戶
     * @return amounts     每個 step 的金額列表
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint[] memory amounts) {
        require(path.length >= 2, "Path too short");

        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        // [1] 先計算每一步的兌換結果（不實際 transfer，只是計算）
        for (uint i = 0; i < path.length - 1; i++) {
            address fromToken = path[i];
            address toToken = path[i + 1];
            address pair = factory.getPair(fromToken, toToken);
            require(pair != address(0), "Pair not exist");

            (uint112 reserveIn, uint112 reserveOut) = PairAMM(pair).getReservesFor(fromToken, toToken);
            require(reserveIn > 0 && reserveOut > 0, "No liquidity");

            // AMM 公式（無手續費）：(dx * y) / (x + dx)
            uint amountInWithFee = amounts[i];
            uint amountOut = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);

            amounts[i + 1] = amountOut;
        }

        // [2] 檢查最終滑點是否合格
        require(amounts[path.length - 1] >= amountOutMin, "Too much slippage");

        // [3] 實際執行每一步 swap：transfer & 呼叫 pair
        for (uint i = 0; i < path.length - 1; i++) {
            address fromToken = path[i];
            address toToken = path[i + 1];
            address pair = factory.getPair(fromToken, toToken);

            // 中間步驟收幣的是 Router，最後一步才給用戶
            address recipient = (i < path.length - 2) ? address(this) : to;

            // 第一步：從用戶轉給 Pair（需要 approve）
            if (i == 0) {
                IERC20(fromToken).transferFrom(msg.sender, pair, amounts[i]);
            } else {
                IERC20(fromToken).transfer(pair, amounts[i]);
            }

            // 呼叫 Pair swap
            PairAMM(pair).swapOutTo(fromToken, amounts[i], recipient);
        }
    }
}
