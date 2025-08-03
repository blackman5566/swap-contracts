import { ethers } from "hardhat";

/**
 * 這個腳本用來**查詢部署者錢包的 nonce 狀態**，
 * 主要目的是協助判斷是否有未確認（pending）的交易導致 nonce 衝突，
 * 避免部署智能合約時發生卡住、無法發送新交易的狀況。
 */
async function main() {
  // 取得 Hardhat 設定的帳戶（一般預設第一個是 deployer）
  const [deployer] = await ethers.getSigners();

  // 拿到 deployer 的 provider（連線到鏈上的節點）
  const provider = deployer.provider!;

  // 取得 deployer 的地址，並轉為小寫（統一格式）
  const address = deployer.address.toLowerCase();

  // 取得「已確認」的最新交易 nonce（已上鍊）
  const latestNonce = await provider.getTransactionCount(address, "latest");

  // 取得包含 pending（未上鍊）交易在內的「下個可用 nonce」
  const pendingNonce = await provider.getTransactionCount(address, "pending");

  // 輸出目前 nonce 狀態（可協助判斷是否有卡住的 pending 交易）
  console.log("🧾 Nonce 狀態：");
  console.log("- latest:", latestNonce);     // 已確認的最新 nonce
  console.log("- pending:", pendingNonce);   // 下個可用 nonce，若大於 latest 則有 pending

  if (pendingNonce > latestNonce) {
    console.warn("⚠️ 警告：有 pending（未確認）交易，可能會阻擋後續部署。");
  } else {
    console.log("✅ Nonce 狀態乾淨，可以放心部署。");
  }
}

// 執行主程式，捕捉未預期的錯誤
main().catch((err) => {
  console.error("❌ 發生錯誤：", err);
  process.exitCode = 1;
});
