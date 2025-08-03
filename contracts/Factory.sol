// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./PairAMM.sol";

/**
說明：

Factory 就像「池子工廠」，每組 token 池只會被創建一次（不可重複）。

用 CREATE2 部署 PairAMM，保證同組 token 的合約地址永遠一樣（前端可預測）。

用戶本身不直接跟 Factory 互動，而是由 Router 或管理者呼叫 createPair。

 * @title Factory
 * @dev 管理所有 Token Pair（流動池）的工廠合約
 * 主要負責「創建 pair（流動池）」與記錄所有已創建 pool 地址
 * 使用 CREATE2 保證每組 token pair 地址唯一且可預測
 */
contract Factory {
    // getPair[tokenA][tokenB] = pairAddress  方便查找某組 pair
    mapping(address => mapping(address => address)) public getPair;
    // 所有 pair pool 的地址
    address[] public allPairs;

    // 每次創建新 pair 時會發出此事件
    event PairCreated(address indexed token0, address indexed token1, address pair);

    /**
     * @notice 創建一個新的流動池 pair，只有第一次創建會生效（同組不能重複）
     * @dev token0, token1 用地址大小排序保證唯一
     */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Factory: IDENTICAL_ADDRESSES");
        // 按地址排序：小的當 token0，確保唯一與穩定
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Factory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Factory: PAIR_EXISTS");

        // 編碼 PairAMM 的 bytecode（含建構參數）
        bytes memory bytecode = abi.encodePacked(
            type(PairAMM).creationCode,
            abi.encode(token0, token1)
        );
        // 以 token0/token1 做 salt，CREATE2 可預測部署位址
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        // 部署新的 pair pool
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // 雙向記錄這組 pair（查詢方便）
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        // 統一記錄到 global list
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair);
    }

    /**
     * @notice 查詢目前總共有幾組 pair
     */
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
}
