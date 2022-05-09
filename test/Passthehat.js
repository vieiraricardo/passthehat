const { expect } = require("chai");

describe("Transactions", () => {
  let owner, addr1, addr2, contract;

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();
    const Passthehat = await ethers.getContractFactory("Passthehat");
    contract = await Passthehat.deploy();
  });

  it("should create new crowndfunding registry", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        (Date.now() / 1000) | 0,
        ethers.utils.parseEther("0.0454")
      );

    const { goal } = await contract.connect(addr1).getFunding(owner.address);

    expect(ethers.utils.parseEther("0.0454")).to.be.equal(goal);
  });

  it("should donate a value", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        (Date.now() / 1000) | 0,
        ethers.utils.parseEther("0.0454")
      );

    await contract.connect(addr2).donate(addr1.address, {
      value: ethers.utils.parseEther("0.2"),
    });

    const { amountRaised } = await contract
      .connect(addr1)
      .getFunding(owner.address);

    expect(amountRaised).be.equal(ethers.utils.parseEther("0.2"));
  });

  it("should withdraw", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        (Date.now() / 1000) | 0,
        ethers.utils.parseEther("0.0454")
      );

    await contract.connect(addr2).donate(addr1.address, {
      value: ethers.utils.parseEther("0.5"),
    });

    await contract.connect(addr1).withdraw();

    const { isActive } = await contract
      .connect(addr1)
      .getFunding(owner.address);

    expect(isActive).to.be.false;
  });

  it("should revert when trying to withdraw funding that didn't reach the goal.", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        (Date.now() / 1000) | 0,
        ethers.utils.parseEther("0.0454")
      );

    await expect(contract.connect(addr1).withdraw()).to.be.revertedWith(
      "Funding not reached."
    );
  });

  it("should revert when trying to donate to inactive funding", async () => {
    await contract
      .connect(addr1)
      .createFunding(
        (Date.now() / 1000) | 0,
        ethers.utils.parseEther("0.0454")
      );

    await contract.connect(addr2).donate(addr1.address, {
      value: ethers.utils.parseEther("0.8"),
    });

    await contract.connect(addr1).withdraw();

    await expect(
      contract.connect(addr2).donate(addr1.address, {
        value: ethers.utils.parseEther("0.10"),
      })
    ).to.be.revertedWith(
      "This funding has already reached its goal and no longer accepts donations."
    );
  });

  it("should return fee value", async () => {
    const fee = await contract.getFee();

    expect(fee).to.be.equal(3000);
  });

  it("should set a new fee", async () => {
    // Set fee in basis point
    // if you want 0.35% you should pass 35 * 100 = "3500" bc 3500 / 10000 = "0.35"

    await contract.setFee(35);

    const fee = await contract.getFee();

    expect(fee).to.be.equal(3500);
  });

  it("should revert when trying to set fee greater than 5000", async () => {
    await expect(contract.setFee(51)).to.be.revertedWith(
      "Fee greater than the maximum allowed."
    );
  });
});
