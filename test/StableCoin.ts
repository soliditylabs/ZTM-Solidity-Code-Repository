import { expect } from "chai";
import { ethers } from "hardhat";
import { DepositorCoin } from "../typechain-types";
import { Stablecoin } from "../typechain-types/Stablecoin";

describe("Stablecoin", function () {
  let ethUsdPrice: number, feeRatePercentage: number;
  let Stablecoin: Stablecoin;

  this.beforeEach(async () => {
    feeRatePercentage = 0;
    ethUsdPrice = 4000;

    const OracleFactory = await ethers.getContractFactory("Oracle");
    const ethUsdOracle = await OracleFactory.deploy();
    await ethUsdOracle.setPrice(ethUsdPrice);

    const StablecoinFactory = await ethers.getContractFactory("Stablecoin");
    Stablecoin = await StablecoinFactory.deploy(
      "Stable Coin",
      "STC",
      ethUsdOracle.address,
      feeRatePercentage,
      10,
      0
    );
    await Stablecoin.deployed();
  });

  it("Should set fee rate percentage", async function () {
    expect(await Stablecoin.feeRatePercentage()).to.equal(feeRatePercentage);
  });

  it("Should allow minting", async function () {
    const ethAmount = 1;
    const expectedMintAmount = ethAmount * ethUsdPrice;

    await Stablecoin.mint({
      value: ethers.utils.parseEther(ethAmount.toString()),
    });
    expect(await Stablecoin.totalSupply()).to.equal(
      ethers.utils.parseEther(expectedMintAmount.toString())
    );
  });

  describe("With minted tokens", function () {
    let mintAmount: number;

    this.beforeEach(async () => {
      const ethAmount = 1;
      mintAmount = ethAmount * ethUsdPrice;

      await Stablecoin.mint({
        value: ethers.utils.parseEther(ethAmount.toString()),
      });
    });

    it("Should allow burning", async function () {
      const remainingStablecoinAmount = 100;
      await Stablecoin.burn(
        ethers.utils.parseEther(
          (mintAmount - remainingStablecoinAmount).toString()
        )
      );

      expect(await Stablecoin.totalSupply()).to.equal(
        ethers.utils.parseEther(remainingStablecoinAmount.toString())
      );
    });

    it("Should prevent depositing collateral buffer below minimum", async function () {
      const stablecoinCollateralBuffer = 0.05; // less than minimum

      await expect(
        Stablecoin.depositCollateralBuffer({
          value: ethers.utils.parseEther(stablecoinCollateralBuffer.toString()),
        })
      ).to.be.revertedWithCustomError(
        Stablecoin,
        "InitialCollateralRatioError"
      );
    });

    it("Should allow depositing collateral buffer", async function () {
      const stablecoinCollateralBuffer = 0.5;
      await Stablecoin.depositCollateralBuffer({
        value: ethers.utils.parseEther(stablecoinCollateralBuffer.toString()),
      });

      const DepositorCoinFactory = await ethers.getContractFactory(
        "DepositorCoin"
      );
      const DepositorCoin = await DepositorCoinFactory.attach(
        await Stablecoin.depositorCoin()
      );

      const newInitialSurplusInUsd = stablecoinCollateralBuffer * ethUsdPrice;
      expect(await DepositorCoin.totalSupply()).to.equal(
        ethers.utils.parseEther(newInitialSurplusInUsd.toString())
      );
    });

    describe("With deposited collateral buffer", function () {
      let stablecoinCollateralBuffer: number;
      let DepositorCoin: DepositorCoin;

      this.beforeEach(async () => {
        stablecoinCollateralBuffer = 0.5;
        await Stablecoin.depositCollateralBuffer({
          value: ethers.utils.parseEther(stablecoinCollateralBuffer.toString()),
        });

        const DepositorCoinFactory = await ethers.getContractFactory(
          "DepositorCoin"
        );
        DepositorCoin = await DepositorCoinFactory.attach(
          await Stablecoin.depositorCoin()
        );
      });

      it("Should allow withdrawing collateral buffer", async function () {
        const newDepositorTotalSupply =
          stablecoinCollateralBuffer * ethUsdPrice;
        const stablecoinCollateralBurnAmount = newDepositorTotalSupply * 0.2;

        await Stablecoin.withdrawCollateralBuffer(
          ethers.utils.parseEther(stablecoinCollateralBurnAmount.toString())
        );

        expect(await DepositorCoin.totalSupply()).to.equal(
          ethers.utils.parseEther(
            (
              newDepositorTotalSupply - stablecoinCollateralBurnAmount
            ).toString()
          )
        );
      });
    });
  });
});
