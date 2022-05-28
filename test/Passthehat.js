const { expect } = require("chai");

describe("Transactions", () => {
  let owner, addr1, addr2, contract;

  beforeEach(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const Passthehat = await ethers.getContractFactory("Passthehat");
    contract = await Passthehat.deploy();
  });

  it("should create new crowdfunding registry", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        ethers.utils.parseEther("0.0454"),
        0,
        ((Date.now() / 1000) | 0) + 432000,
        (Date.now() / 1000) | 0,
        false
      );

    const { goal } = await contract.connect(addr1).getFunding(addr1.address, 0);

    expect(ethers.utils.parseEther("0.0454")).to.be.equal(goal);
  });

  it("should revert if the startIn parameter is greater than the maximum allowed for 60 days", async () => {
    await expect(
      contract
        .connect(addr1)
        .createFunding(
          ethers.utils.parseEther("0.0454"),
          0,
          ((Date.now() / 1000) | 0) + 5270400,
          (Date.now() / 1000) | 0,
          false
        )
    ).to.be.revertedWith(
      "You must pass a start date in epoch time format with a maximum of 60 days from now"
    );
  });

  it("should donate a value and return the balance of the funding", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        ethers.utils.parseEther("0.0454"),
        0,
        0,
        (Date.now() / 1000) | 0,
        false
      );

    await contract.connect(addr2).donate(addr1.address, 0, {
      value: ethers.utils.parseEther("0.2"),
    });

    const balance = await contract.connect(addr1).balanceOf(addr1.address, 0);

    expect(balance).be.equal(ethers.utils.parseEther("0.2"));
  });

  it("should withdraw", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        ethers.utils.parseEther("0.0454"),
        0,
        0,
        (Date.now() / 1000) | 0,
        false
      );

    await contract.connect(addr2).donate(addr1.address, 0, {
      value: ethers.utils.parseEther("3.4"),
    });

    await contract.connect(addr1).withdraw(0);

    const { isActive } = await contract
      .connect(addr1)
      .getFunding(addr1.address, 0);

    expect(isActive).to.be.false;
  });

  it("should revert when trying to withdraw funding that didn't reach the goal.", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        ethers.utils.parseEther("0.0454"),
        0,
        0,
        (Date.now() / 1000) | 0,
        false
      );

    await expect(contract.connect(addr1).withdraw(0)).to.be.revertedWith(
      "Funding not reached."
    );
  });

  it("should revert when trying to donate to inactive funding", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        ethers.utils.parseEther("0.0454"),
        0,
        0,
        (Date.now() / 1000) | 0,
        false
      );

    await contract.connect(addr2).donate(addr1.address, 0, {
      value: ethers.utils.parseEther("0.8"),
    });

    await contract.connect(addr1).withdraw(0);

    await expect(
      contract.connect(addr2).donate(addr1.address, 0, {
        value: ethers.utils.parseEther("0.10"),
      })
    ).to.be.revertedWith(
      "This funding has already reached its goal and no longer accepts donations."
    );
  });

  it("should set a new fee", async () => {
    // Set fee in basis point
    // if you want 0.35% you should pass 35 * 100 = "3500" bc 3500 / 10000 = "0.35"

    await contract.setFee(35);

    const fee = await contract.FEE.call();

    expect(fee).to.be.equal(3500);
  });

  it("should revert when trying to set fee greater than 5000", async () => {
    await expect(contract.setFee(51)).to.be.revertedWith(
      "Fee is greater than the maximum allowed."
    );
  });
});
