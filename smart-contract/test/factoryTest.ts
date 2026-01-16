import { expect } from "chai";
import hre from "hardhat";

const { ethers, networkHelpers } = await hre.network.connect();

describe ("coinForge Factory", ()=>{
    let creatorCoin;
    let cCoinAddress;
    let factory;
    let address;


    it("it should deploy coinForge factory contract", async function(){

        // console.log("this is ethers::::::::::::::::", ethers)
        // console.log("this is the hre ++++++++++++++++++++++++++",hre);

        const Factory = await ethers.deployContract("CoinForgeFactory");
        factory = Factory;

        console.log("this is the factory deployment",factory);

        address = Factory.target;
        console.log("this is contract address=>", address)
    })

    it("should deploy creatorCoin", async function(){

        const name = "coin-forge";
        const symbol= "CF";
        const reserveToken = "0x0000000000000000000000000000000000000001";
        const treasuryAddress = "0x0000000000000000000000000000000000000002"
        const initialRoyaltyPercentage = 5;
    

        const CreatorCoinContract = await ethers.deployContract("CreatorCoin", [
            name,
            symbol,
            reserveToken,
            treasuryAddress,
            initialRoyaltyPercentage
        ]);

        creatorCoin = CreatorCoinContract;

        console.log("this is the creator coin::::::::", creatorCoin);

        cCoinAddress = CreatorCoinContract.target

        console.log("this is creator coin Address::::::::", cCoinAddress);
    })
})