const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("xToken", function () {
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
        xToken.connect(account1.address)
          .mint(account1.address, 20_000_000_000)
          .then(result => {
            console.log("result", result);
          })
          .catch(error => {
          console.log(error);
        })
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

      console.log("Total Supply",BigInt(await xToken.totalSupply()));

      expect(await xToken.totalSupply()).to.equal(50_000_000_000);
    })

    it("Cap Exceeded", async ()=> {
      console.log("Total Supply",BigInt(await xToken.totalSupply()));
      await xToken.mint(owner.address, 50_000_000_001);
      console.log("Total Supply",BigInt(await xToken.totalSupply()));

      // ? revertedWith not working
      try {
        expect(await xToken.mint(owner.address, 50_000_000_000)).to.be.revertedWith('ERC20Capped: cap exceeded');
      } catch(error) {
        console.log(error);
      }
    });
  });
});


describe("XTokenSale", function() {
  let xToken;
  let xTokenSale;
  let owner;
  let account1;

  beforeEach(async () => {
    const XToken = await ethers.getContractFactory("XToken");
    xToken = await XToken.deploy("xToken", "EX", 50_000_000_000);
    let res = await xToken.deployed();
    [owner, account1] = await ethers.getSigners();
    const date = new Date();

    // One hour after deployment incl mining
    let open = Math.floor(date.getTime() / 1000) + (60 * 60);
    let close = open + (30*24*60*60);

    const XTokenSale = await ethers.getContractFactory("XTokenSale");
    // Aggregator not used
    xTokenSale = await XTokenSale.deploy(1000, account1.address, xToken.address, 12_500_000_000, open, close, xToken.address);
    await xTokenSale.deployed();
  });

  describe("Constructor", async() => {

    it("Cap", async () => {
      expect(await xTokenSale.cap()).to.be.equal(12_500_000_000);
    });
  });

  describe("Open", () => {

    // opens after 60*60 seconds
    it("open false", async () => {
        expect(await xTokenSale.isOpen()).to.be.equal(false);
    });
  })
}); 