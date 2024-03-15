import { Ether } from "../../web3webdeploy/lib/etherUnits";
import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployVerifiedContributorClaimingSettings
  extends Omit<DeployInfo, "contract" | "args"> {
  token: Address;
}

export async function deployVerifiedContributorClaiming(
  deployer: Deployer,
  settings: DeployVerifiedContributorClaimingSettings
): Promise<Address> {
  const week = 7 * 24 * 60 * 60;

  return await deployer
    .deploy({
      id: "VerifiedContributorClaiming",
      contract: "OpenClaiming",
      args: [
        settings.token,
        Ether(10_000_000), // 1% of total supply
        1 * week,
        "0x8B4a225774EDdAF9C33f6b961Db832228c770b21",
      ],
      salt: "NODE",
      ...settings,
    })
    .then((deployment) => deployment.address);
}
