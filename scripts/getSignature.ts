import * as dotenv from "dotenv";
import { ethers, network } from "hardhat";
import { readAddressList } from "./contractAddress";
import { getLatestBlockTimestamp } from "./utils";
dotenv.config();

async function main() {
  const privateKey = process.env.BNB_PRIVATE_KEY || "";

  const signer = new ethers.Wallet(privateKey, ethers.provider);

  console.log("signer is ", signer.address);

  const addressList = readAddressList();

  const userAddress = "0xaEd009c79E1D7978FD3B87EBe6d1f1FA3C542161";
  const factoryAddress = addressList[network.name].DeSurveyFactory;

  const level = 1;

  const chainId = await ethers.provider.getNetwork().then((res) => res.chainId);

  console.log("chainId is ", chainId);

  const domainStruct = {
    name: "DeSurveyNFTFactory",
    version: "1.0",
    chainId: chainId,
    verifyingContract: factoryAddress,
  };

  const MintRequest_Type = {
    MintRequest: [
      { name: "user", type: "address" },
      { name: "achievementId", type: "uint256" },
      { name: "validUntil", type: "uint256" },
    ],
  };

  const validUntil = (await getLatestBlockTimestamp(ethers.provider)) + 10000;

  const mintRequest = {
    user: userAddress,
    level: level,
    validUntil: validUntil,
  };

  const sig = await signer._signTypedData(
    domainStruct,
    MintRequest_Type,
    mintRequest
  );

  console.log(`Signature is ${sig}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
