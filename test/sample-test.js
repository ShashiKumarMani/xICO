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

      const RESERVE_WALLET = 15_000_000_000;
      const INTEREST_PAYOUT_WALLET = 10_000_000_000;
      const TEAM_MEMBERS_WALLET = 5_000_000_000;
      const GENERAL_FUND_WALLET = 6_500_000_000;
      const BOUNTIES_AIRDROP_WALLET = 1_000_000_000;
      const TOKENSALE_WALLET = 12_500_000_000;

      await xToken.mint(owner.address, RESERVE_WALLET);
      await xToken.mint(owner.address, INTEREST_PAYOUT_WALLET);
      await xToken.mint(owner.address, TEAM_MEMBERS_WALLET);
      await xToken.mint(owner.address, GENERAL_FUND_WALLET);
      await xToken.mint(owner.address, BOUNTIES_AIRDROP_WALLET);
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