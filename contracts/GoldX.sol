// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ========== 匯入 OpenZeppelin ERC20 相關擴充套件 ==========
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";                     // 標準 ERC20
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";   // 支援燒毀（burn）功能
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";   // 支援暫停（pause）功能
import "@openzeppelin/contracts/access/Ownable.sol";                         // 擁有者權限管理

/**
 * @title GoldX (GOX)
 * @dev 這是一個用於 DEX 測試/模擬的 ERC20 代幣，支援「燒毀」、「可暫停」、「僅 owner 可增發」等功能。
 * 常用於交換、流動池等測試場景。
 */
contract GoldX is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    /**
     * @dev 建構子，初始化代幣名稱、符號、總供給，以及 owner
     * @param initialSupply   初始發行數量（會直接 mint 給 owner）
     * @param initialOwner    初始持有人（也是 owner）
     */
    constructor(uint256 initialSupply, address initialOwner) 
        ERC20("GoldX", "GOX")
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialSupply); // 部署時一次性 mint 給 owner
    }

    /**
     * @dev 只允許 owner 執行，可以額外 mint 新代幣給指定帳戶
     * @param to      新增代幣接收人
     * @param amount  新增發行數量
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev 只允許 owner 執行，暫停全體轉帳與燒毀等動作
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev 只允許 owner 執行，解除暫停，所有功能回復正常
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev 覆寫 OpenZeppelin 內部 _update（多重繼承時必須顯式宣告），確保暫停機制正確生效
     */
    function _update(address from, address to, uint256 value) 
        internal 
        override(ERC20, ERC20Pausable) 
    {
        super._update(from, to, value);
    }
}
