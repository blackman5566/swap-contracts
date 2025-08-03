// contracts/USDT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ========== 匯入 OpenZeppelin 標準 ERC20 及其擴充功能 ==========
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";                     // 標準 ERC20 代幣
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";   // 可燒毀功能（burn）
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";   // 可暫停功能（pause）
import "@openzeppelin/contracts/access/Ownable.sol";                         // 擁有者權限

/**
 * @title USDT (Testnet Version)
 * @dev 這是一個**模擬穩定幣**的 ERC20 代幣，**專供本地/測試網部署**。
 * - 支援 owner 增發（mint）、燒毀（burn）、暫停（pause）等功能。
 * - 非真實 USDT，僅供 AMM/DEX 測試、流動池模擬用途。
 */
contract USDT is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    /**
     * @dev 建構子：初始化幣名、符號、初始供給及 owner 權限
     * @param initialSupply    初始鑄造數量（全部 mint 給 initialOwner）
     * @param initialOwner     初始持有人（同時成為 owner）
     */
    constructor(uint256 initialSupply, address initialOwner) 
        ERC20("USDT", "USDT")
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialSupply); // 發行全部初始供給給 owner
    }

    /**
     * @dev 只允許 owner 執行，額外 mint（增發）新代幣
     *      完全模擬中心化穩定幣的增發行為
     * @param to      接收新代幣的帳戶
     * @param amount  增發的數量
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev 只允許 owner 執行，啟動暫停（所有轉帳/燒毀都會被凍結）
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev 只允許 owner 執行，解除暫停，恢復所有功能
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev 覆寫 _update，支援 Pausable 機制（多重繼承 override 要明確寫出）
     *      用來保證合約暫停時，所有轉帳/burn 會被攔截
     */
    function _update(address from, address to, uint256 value) 
        internal 
        override(ERC20, ERC20Pausable) 
    {
        super._update(from, to, value);
    }
}
