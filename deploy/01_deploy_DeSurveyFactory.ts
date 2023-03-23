import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction, ProxyOptions } from "hardhat-deploy/types";

import {
  readAddressList,
  readImpList,
  storeAddressList,
  storeImpList,
} from "../scripts/contractAddress";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, network } = hre;
  const { deploy } = deployments;

  network.name = network.name == "hardhat" ? "localhost" : network.name;

  const { deployer } = await getNamedAccounts();

  console.log("\n-----------------------------------------------------------");
  console.log("-----  Network:  ", network.name);
  console.log("-----  Deployer: ", deployer);
  console.log("-----------------------------------------------------------\n");

  const balance = await hre.ethers.provider.getBalance(deployer);
  console.log("Deployer balance: ", balance.toString());

  // Read address list from local file
  const addressList = readAddressList();
  const impList = readImpList();

  const proxyOptions: ProxyOptions = {
    proxyContract: "OpenZeppelinTransparentProxy",
    viaAdminContract: {
      name: "ProxyAdmin",
      artifact: "ProxyAdmin",
    },
    execute: {
      init: {
        methodName: "initialize",
        args: [],
      },
    },
  };

  // Proxy Admin contract artifact
  const deSurveyFactory = await deploy("DeSurveyNFTFactory", {
    contract: "DeSurveyNFTFactory",
    from: deployer,
    proxy: proxyOptions,
    args: [],
    log: true,
  });
  addressList[network.name].DeSurveyNFTFactory = deSurveyFactory.address;

  impList[network.name].DeSurveyNFTFactory = deSurveyFactory.implementation;

  console.log("\ndeployed to address: ", deSurveyFactory.address);

  // Store the address list after deployment
  storeAddressList(addressList);
  storeImpList(impList);
};

func.tags = ["DeSurveyFactory"];
export default func;
