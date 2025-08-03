// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ========== 匯入 OpenZeppelin 的 ERC20 標準與延伸合約 ==========
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";                // 基本 ERC20 代幣
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";   // 可燒毀（Burnable）
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";   // 可暫停（Pausable）
import "@openzeppelin/contracts/access/Ownable.sol";                   // 擁有者控制權限

/**
 * @title EnergyCoin (EGC)
 * @dev 這是一個支援「燒毀」與「可暫停」功能的 ERC20 代幣，擁有者可以增發、暫停合約、解除暫停。
 * 常見於測試 DEX/流動池等場景。
 */
contract EnergyCoin is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    /**
     * @dev 部署時初始化：
     * - 指定初始供給（initialSupply）直接鑄造給初始擁有者（initialOwner）。
     * - 合約所有權給 initialOwner。
     * @param initialSupply  初始總發行數量
     * @param initialOwner   初始持有人，也是 Owner
     */
    constructor(uint256 initialSupply, address initialOwner) 
        ERC20("EnergyCoin", "EGC")
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialSupply); // 發行初始代幣給 owner
    }

    /**
     * @dev 僅限 owner 執行，額外增發新代幣
     * @param to     要發給哪個地址
     * @param amount 發行數量
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev 僅限 owner 執行，將合約設為暫停狀態（全體轉帳與 burn 都會被擋下）
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev 僅限 owner 執行，解除暫停，回復可正常轉帳
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev 內部轉帳邏輯覆寫，整合 ERC20 轉帳與 Pausable 邏輯，確保暫停時無法執行。
     * OpenZeppelin 的 Pausable 機制需呼叫父合約的 _update
     */
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
