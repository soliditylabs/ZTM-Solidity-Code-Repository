import { ethers, network } from "hardhat";
import { expect } from "chai";

import { loadFixture, mine } from "@nomicfoundation/hardhat-network-helpers";

import { smock } from "@defi-wonderland/smock";
import { ERC20__factory } from "../typechain-types";

describe("ERC20", function () {
  async function deployAndMockERC20() {
    const [alice, bob] = await ethers.getSigners();

    const ERC20 = await smock.mock<ERC20__factory>("ERC20");
    const erc20Token = await ERC20.deploy("Name", "SYM", 18);

    await erc20Token.setVariable("balanceOf", {
      [alice.address]: 300,
    });
    await mine();

    return { alice, bob, erc20Token };
  }

  it("transfers tokens correctly", async function () {
    const { alice, bob, erc20Token } = await loadFixture(deployAndMockERC20);

    await expect(
      await erc20Token.transfer(bob.address, 100)
    ).to.changeTokenBalances(erc20Token, [alice, bob], [-100, 100]);

    await expect(
      await erc20Token.connect(bob).transfer(alice.address, 50)
    ).to.changeTokenBalances(erc20Token, [alice, bob], [50, -50]);
  });

  it("should revert if sender has insufficient balance", async function () {
    const { bob, erc20Token } = await loadFixture(deployAndMockERC20);
    await expect(erc20Token.transfer(bob.address, 400)).to.be.revertedWith(
      "ERC20: Insufficient sender balance"
    );
  });

  it("should emit Transfer event on transfers", async function () {
    const { alice, bob, erc20Token } = await loadFixture(deployAndMockERC20);
    await expect(erc20Token.transfer(bob.address, 200))
      .to.emit(erc20Token, "Transfer")
      .withArgs(alice.address, bob.address, 200);
  });
});
