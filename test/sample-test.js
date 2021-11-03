const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("xToken",  () => {
  let xToken;
  let owner;
  let account1;

  beforeEach(async () => {
    const XToken = await ethers.getContractFactory("XToken");
    xToken = await XToken.deploy("xToken", "EX", 50_000_000_000);
    await xToken.deployed();
    [owner, account1] = await ethers.getSigners();
  });

  describe("constructor", async () => {

    it("Token cap", async function () {
      const cap = ethers.BigNumber.from(50000000000);
      expect(await xToken.cap()).to.equal(cap);
    });

    it("Token owner", async () => {
      expect(await xToken.owner()).to.equal(owner.address);
    });
  });

  describe("Mint", async () => {

    it("Mint Tokens", async () => {
      
      xToken.mint(account1.address, 20_000_000_000);

      expect(await xToken.totalSupply()).to.equal(20_000_000_000);
    });

    it("Call mint from different account", async () => {
        await expect(
          xToken.connect(account1.address).mint(account1.address, 20_000_000_000)
        ).to.be.reverted;
    });

    it("Mint Initial Tokens", async() => {

      const [ , , account2, account3, account4, account5] = await ethers.getSigners();

      const RESERVE_WALLET = 15_000_000_000;
      const INTEREST_PAYOUT_WALLET = 10_000_000_000;
      const TEAM_MEMBERS_WALLET = 5_000_000_000;
      const GENERAL_FUND_WALLET = 6_500_000_000;
      const BOUNTIES_AIRDROP_WALLET = 1_000_000_000;
      const TOKENSALE_WALLET = 12_500_000_000;

      await xToken.mint(account1.address, RESERVE_WALLET);
      await xToken.mint(account2.address, INTEREST_PAYOUT_WALLET);
      await xToken.mint(account3.address, TEAM_MEMBERS_WALLET);
      await xToken.mint(account4.address, GENERAL_FUND_WALLET);
      await xToken.mint(account5.address, BOUNTIES_AIRDROP_WALLET);
      await xToken.mint(owner.address, TOKENSALE_WALLET);

      expect(await xToken.totalSupply()).to.equal(50_000_000_000);
    })

    it("Cap Exceeded", async ()=> {

      await xToken.mint(owner.address, 50_000_000_001);
      await expect(xToken.mint(owner.address, 50_000_000_000)).to.be.reverted;

    });
  });
});

describe("XTokenSale", () => {

  let xToken;
  let xTokenSale;
  let owner;
  let account1;
  const  priceFeed = "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e";

  beforeEach(async () => {
  
    const XToken = await ethers.getContractFactory("XToken");
    xToken = await XToken.deploy("xToken", "EX", 50_000_000_000);
    let res = await xToken.deployed();

    [owner, account1] = await ethers.getSigners();

    const date = new Date();
    let open = Math.floor(date.getTime() / 1000) + 60;
    let close = open + (30*24*60*60);

    const XTokenSale = await ethers.getContractFactory("XTokenSale");
    xTokenSale = await XTokenSale.deploy(1000, account1.address, xToken.address, 12_500_000_000, open, close, priceFeed);
    await xTokenSale.deployed();
  });

  describe("Constructor", async() => {
    it("Cap", async () => {
      expect(await xTokenSale.cap()).to.be.equal(12_500_000_000);
    });
  });

  describe("Open", () => {
    it("open false", async () => {
        expect(await xTokenSale.isOpen()).to.be.equal(false);
    });
  });

  describe("Oracle ", async() => {

    it("Get oracle price data", async () => {
      await xTokenSale.getOracleData();
      expect(await xTokenSale.ethToUsd()).to.not.equal(0);
      console.log(await xTokenSale.ethToUsd());
    });
  });

    describe("Send eth", async() => {

      it("Send eth to xTokenSale", async() => {

        expect(owner.sendTransaction({
          to: xTokenSale.address,
          value: ethers.utils.parseEther("1")
        })).to.be.reverted;
      });
    });
}); 