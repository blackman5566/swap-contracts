import "dotenv/config";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "ethers";

const ethereumSepoliaConfig: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/your_alchemy_key", // 或 alchemy
      accounts: [process.env.PRIVATE_KEY!], // 你的錢包私鑰
      chainId: 11155111
    }
  }
};



export default ethereumSepoliaConfig;
