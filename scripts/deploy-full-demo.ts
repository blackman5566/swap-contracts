import { ethers } from "hardhat";

/**
 * DEX Demo 一鍵部署與流動池加池腳本（大池深測試場景）
 *
 * ✅ 腳本總流程：
 * 1. 部署多個 ERC20 測試代幣（模擬 SWX、GOX、EGC、USDT）
 * 2. 部署 Factory（負責建立 Pair 池）
 * 3. 部署 Router（負責管理 addLiquidity/swap 功能）
 * 4. 建立 SWX/USDT、GOX/USDT、EGC/USDT 各組流動池
 * 5. 預先注入大量流動性（模擬極深池，測試滑點不影響）
 *
 * ⚠️ 正式環境請拆分為不同部署腳本，並加入安全金流檢查機制。
 */

async function main() {
  // 1️⃣ 取得 deployer（部署帳號）
  const [deployer] = await ethers.getSigners();
  const deployerAddr = deployer.address.toLowerCase();
  const initialSupply = ethers.parseEther("10000000000"); // 每個測試幣初始 100 億顆

  // 2️⃣ 部署測試用 ERC20 代幣
  // 建立代幣名稱與符號設定（每個都會部署）
  const ERC20s: { [symbol: string]: any } = {}; // 儲存所有部署後的代幣實例
  const tokenConfigs = [
    { name: "SwapX", symbol: "SWX" },
    { name: "GoldX", symbol: "GOX" },
    { name: "EnergyCoin", symbol: "EGC" },
    { name: "USDT", symbol: "USDT" }
  ];

  // 🔁 對每個代幣設定執行部署流程
  for (const cfg of tokenConfigs) {
    // 部署對應的 ERC20 合約（建構參數：初始供應量 + 發行者地址）
    const token = await ethers.deployContract(cfg.name, [initialSupply, deployerAddr]);
    await token.waitForDeployment(); // 等待部署完成
    ERC20s[cfg.symbol] = token; // 將部署後的實例以 symbol 為 key 儲存
    console.log(`${cfg.name} (${cfg.symbol}) 已部署:`, token.target);
  }

  // 3️⃣ 部署 Factory（流動池工廠）
  // 專門負責建立 PairAMM 池子，並確保唯一性（用 CREATE2）
  const Factory = await ethers.deployContract("Factory", []);
  await Factory.waitForDeployment();
  console.log("Factory 已部署:", Factory.target);

  // 4️⃣ 部署 Router（流動池操作的中介）
  // Router 用來操作 addLiquidity/swap，負責資金移動與轉帳調度
  const Router = await ethers.deployContract("Router", [Factory.target]);
  await Router.waitForDeployment();
  console.log("Router 已部署:", Router.target);

  // 5️⃣ 池深配置（模擬高深度池，防止滑點）
  const tradeAmount = ethers.parseEther("10000"); // 模擬一筆常見交易量為 1 萬
  const POOL_DEPTH_MULTIPLIER = 1000; // 設定流動池為 1000 倍（即 1000 萬）

  // ⚖️ 設定代幣對 USDT 匯率（用來計算池中 USDT 數量）
  const pairs: { symbol: string; price: string }[] = [
    { symbol: "SWX", price: "0.001"  }, // 1 SWX = 0.001 USDT
    { symbol: "GOX", price: "0.01"   }, // 1 GOX = 0.01 USDT
    { symbol: "EGC", price: "1"      }, // 1 EGC = 1 USDT
  ];

  // 🔁 對每組 Pair 執行以下操作：建立池子、Approve、加流動性
  for (const pair of pairs) {
    // ✫️ 計算雙邊儲備
    const reserveIn = tradeAmount * BigInt(POOL_DEPTH_MULTIPLIER); // 例：1000 萬顆 SWX
    const reserveOut = (reserveIn * BigInt(Math.floor(Number(pair.price) * 1e6))) / BigInt(1e6); // 乘上匯率

    console.log(`Pair ${pair.symbol}/USDT 需注入流動性:`);
    console.log(` - ${pair.symbol}:`, ethers.formatEther(reserveIn));
    console.log(` - USDT:`, ethers.formatEther(reserveOut));

    // 🛠️ 創建 Pair Pool（流動池）
    const tx = await Factory.createPair(ERC20s[pair.symbol].target, ERC20s["USDT"].target);
    await tx.wait();
    const pairAddr = await Factory.getPair(ERC20s[pair.symbol].target, ERC20s["USDT"].target);
    console.log(`Pair ${pair.symbol}/USDT 已建立:`, pairAddr);

    // ✅ 對 Router 進行 approve（允許它轉帳代幣）
    const approveTokenTx = await ERC20s[pair.symbol].approve(Router.target, reserveIn);
    await approveTokenTx.wait();
    const approveUSDTTx = await ERC20s["USDT"].approve(Router.target, reserveOut);
    await approveUSDTTx.wait();

    // 💧 加入流動性（實際轉幣與記帳）
    const addLiquidityTx = await Router.addLiquidity(
      ERC20s[pair.symbol].target,
      ERC20s["USDT"].target,
      reserveIn,
      reserveOut
    );
    await addLiquidityTx.wait();
    console.log(`✅ 已注入流動性到 ${pair.symbol}/USDT`);
  }

  console.log("🎉 全部部署與流動性注入完成！");
}

// 主程式執行（自動 catch 錯誤）
main().catch((error) => {
  console.error("❌ 執行出錯：", error);
  process.exitCode = 1;
});
