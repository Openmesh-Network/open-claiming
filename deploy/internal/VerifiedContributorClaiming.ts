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
        Ether(1_000_000), // 0.1% of total supply
        1 * week,
        "0xf2Bb57E104Bc9A8B398A6b47E3579389798b273a",
      ],
      salt: "OVC",
      ...settings,
    })
    .then((deployment) => deployment.address);
}
