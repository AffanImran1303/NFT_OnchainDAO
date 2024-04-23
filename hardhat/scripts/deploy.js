const hre=require("hardhat");

async function sleep(ms){
    return new Promise((resolve)=>setTimeout(resolve,ms));
}

async function main(){
    //Deploy NFT contract
    const nftContract=await
    hre.ethers.deployContract("CryptoDevsNFT");
    await nftContract.waitForDeployment();
    console.log("CryptoDevsNFT Deployed to:",nftContract.target);

    //Deploy the FakeNFTMarktetplace Contract
    const FakeNFTMarktetplacecontract=await
    hre.ethers.deployContract("FakeNFTmarketplace");
    await FakeNFTMarktetplacecontract.waitForDeployment();
    console.log("FakeNFTMarketplace Deployed to:",FakeNFTMarktetplacecontract.target);

    //Deploying the DAO Contract
    const amount = hre.ethers.parseEther("0.00001");
    const daoContract=await
    hre.ethers.deployContract("CryptoDevsDAO",[FakeNFTMarktetplacecontract.target,nftContract.target,],{value:amount,});
    await daoContract.waitForDeployment();
    console.log("CryptoDevsDAO Deployed to:",daoContract.target);

    //Sleep for 30sec to let EtherScan catchup with deployments
    await sleep(30*1000);
    await hre.run("verify:verify",{
        address:nftContract.target,
        constructorArguments:[],
    });
    await hre.run("verify:verify",{
        address:FakeNFTMarktetplacecontract.target,
        constructorArguments:[],
    });
    await hre.run("verify:verify",{
        address:daoContract.target,
        constructorArguments:[
            FakeNFTMarktetplacecontract.target,
            nftContract.target,
        ],
    });
}

main().catch((error)=>{
    console.log(error);
    process.exitCode=1;
});