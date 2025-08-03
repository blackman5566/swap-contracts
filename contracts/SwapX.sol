// contracts/SwapX.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ========== 匯入 OpenZeppelin ERC20 與多種擴充功能 ==========
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";                     // 基礎 ERC20
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";   // 支援燒毀
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";   // 支援暫停
import "@openzeppelin/contracts/access/Ownable.sol";                         // 擁有者權限

/**
 * @title SwapX (SWX)
 * @dev 這是一個用於 DEX Swap 測試、作為主交易資產的 ERC20 代幣，
 * 支援「燒毀」、「暫停」、「僅 owner 可增發」等功能。
 */
contract SwapX is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    /**
     * @dev 建構子，初始化幣名、符號、初始供給、以及 owner 權限。
     * @param initialSupply    初始總供給（會直接 mint 給 initialOwner）
     * @param initialOwner     初始持有人（同時成為 owner）
     */
    constructor(uint256 initialSupply, address initialOwner) 
        ERC20("SwapX", "SWX")
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialSupply); // 初始發行全部給 owner
    }

    /**
     * @dev 只有 owner 可以調用，用來額外增發新代幣到指定地址。
     * @param to      收到新幣的帳戶
     * @param amount  增發的數量
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev 只有 owner 可以調用，啟動「暫停」狀態（防止全部交易，緊急使用）。
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev 只有 owner 可以調用，結束暫停狀態，所有交易恢復正常。
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev 覆寫 OpenZeppelin 的 _update（多重繼承必須顯式 override），
     * 以支援暫停機制（合約暫停時禁止轉帳）。
     */
    function _update(address from, address to, uint256 value) 
        internal 
        override(ERC20, ERC20Pausable) 
    {
        super._update(from, to, value);
    }
}
