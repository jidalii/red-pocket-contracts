
import { describe, expect, it, } from "vitest";
import { Cl, uintCV, listCV, principalCV } from '@stacks/transactions';
import { accountsApi } from "@stacks/blockchain-api-client";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

describe("example tests", () => {
  const amount = 3000n; // set a test amount
  const mode = 0n; // example mode (e.g., 1 for even distribution, 2 for random)
  const revealBlock = 100n; // an example reveal block height
  const claimDuration = 1n; // example claim duration
  // const address1 = "ST153CEHB9B8RGTT8NWGZX15H37KTH0S48WK0DC0H";
  it("ensures simnet is well initalised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("should create a red pocket with valid parameters", () => {
    const addresses = [
      "ST153CEHB9B8RGTT8NWGZX15H37KTH0S48WK0DC0H", // replace with actual test principals
      "ST153CEHB9B8RGTT8NWGZX15H37KTH0S48WK0DC0H",
      "ST153CEHB9B8RGTT8NWGZX15H37KTH0S48WK0DC0H"
    ];
    const addressesCV = listCV(addresses.map(address => principalCV(address)));

    // Call createRedPocket with uint parameters
    const { result } = simnet.callPublicFn(
      "red_pocket", 
      "createRedPocket", 
      [
        uintCV(amount),
        uintCV(mode),
        addressesCV,
        uintCV(revealBlock),
        uintCV(claimDuration),
      ], 
      address1
    );

    // Validate the result
    console.log(result)
    expect(result); // assuming a result of 0 indicates success
  });

  it("should claim a red pocket", () => {
    const addresses = [
      address1,
      "ST153CEHB9B8RGTT8NWGZX15H37KTH0S48WK0DC0H",
      "ST153CEHB9B8RGTT8NWGZX15H37KTH0S48WK0DC0H"
    ];
    const addressesCV = listCV(addresses.map(address => principalCV(address)));

    // First, create a red pocket
    const { result: createResult } = simnet.callPublicFn(
      "red_pocket", 
      "createRedPocket", 
      [
        uintCV(amount),
        uintCV(mode),
        addressesCV,
        uintCV(revealBlock),
        uintCV(claimDuration),
      ], 
      address1
    );

    console.log("Create Result:", createResult);
    // expect(createResult);

    // Then, attempt to claim the red pocket
    const { result: claimResult } = simnet.callPublicFn(
      "red_pocket", 
      "claimRedPocket", 
      [
        uintCV(0),
      ], 
      address1
    );

    console.log("Claim Result:", claimResult);
    console.log("Claim Result:", claimResult.type.toString());
    expect(claimResult).toBe(true); // Ensure the claim function succeeded
  });
});
