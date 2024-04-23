import { Ether } from "../../web3webdeploy/lib/etherUnits";
import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployNodesWithdrawClaimingSettings
  extends Omit<DeployInfo, "contract" | "args"> {
  token: Address;
}

export async function deployNodesWithdrawClaiming(
  deployer: Deployer,
  settings: DeployNodesWithdrawClaimingSettings
): Promise<Address> {
  const week = 7 * 24 * 60 * 60;

  return await deployer
    .deploy({
      id: "NodesWithdrawClaiming",
      contract: "OpenClaiming",
      args: [
        settings.token,
        Ether(1_000_000), // 0.1% of total supply
        1 * week,
        "0x4EfafD64b32b87a221DA50a5A7E54E5cBce00b6E",
      ],
      salt: "NODE",
      ...settings,
    })
    .then((deployment) => deployment.address);
}
