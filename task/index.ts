import { task } from "hardhat/config";
import { readAddressList } from "../scripts/contractAddress";
import { DeSurveyNFTFactory__factory } from "../typechain-types";

task("create", "Create new nft")
  .addParam("price")
  .addParam("limit")
  .setAction(async (taskArgs, hre) => {
    const { network } = hre;

    const [dev] = await hre.ethers.getSigners();

    const addressList = readAddressList();

    const factory = new DeSurveyNFTFactory__factory(dev).attach(
      addressList[network.name].DeSurveyNFTFactory
    );

    const tx = await factory.createDeSurveyNFT(
      hre.ethers.utils.parseUnits(taskArgs.price),
      taskArgs.limit
    );

    const receipt = await tx.wait();
    console.log("receipt: ", receipt);
  });
