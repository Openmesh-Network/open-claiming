import { Address, Deployer, DeployInfo } from "../web3webdeploy/types";
import {
  OpenTokenDeployment,
  deploy as openTokenDeploy,
} from "../lib/open-token/deploy/deploy";
import {
  deployVerifiedContributorClaiming,
  DeployVerifiedContributorClaimingSettings,
} from "./internal/VerifiedContributorClaiming";
import {
  deployNodesWithdrawClaiming,
  DeployNodesWithdrawClaimingSettings,
} from "./internal/NodesWithdrawClaiming";

export interface OpenClaimingDeploymentSettings {
  openTokenDeployment: OpenTokenDeployment;
  verifiedContributorClaiming: Omit<
    DeployVerifiedContributorClaimingSettings,
    "token"
  >;
  nodesWithdrawClaiming: Omit<DeployNodesWithdrawClaimingSettings, "token">;
  forceRedeploy?: boolean;
}

export interface OpenClaimingDeployment {
  ovcClaiming: Address;
  nodeClaiming: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: OpenClaimingDeploymentSettings
): Promise<OpenClaimingDeployment> {
  if (settings?.forceRedeploy !== undefined && !settings.forceRedeploy) {
    return await deployer.loadDeployment({ deploymentName: "latest.json" });
  }

  deployer.startContext("lib/open-token");
  const openTokenDeployment =
    settings?.openTokenDeployment ?? (await openTokenDeploy(deployer));
  deployer.finishContext();

  const ovcClaiming = await deployVerifiedContributorClaiming(deployer, {
    token: openTokenDeployment.openToken,
    ...(settings?.verifiedContributorClaiming ?? {}),
  });

  const nodeClaiming = await deployNodesWithdrawClaiming(deployer, {
    token: openTokenDeployment.openToken,
    ...(settings?.verifiedContributorClaiming ?? {}),
  });

  const deployment = {
    ovcClaiming: ovcClaiming.address,
    nodeClaiming: nodeClaiming.address,
  };
  await deployer.saveDeployment({
    deploymentName: "latest.json",
    deployment: deployment,
  });
  return deployment;
}
