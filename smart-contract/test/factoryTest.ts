import { expect } from "chai";
import hre from "hardhat";

const { ethers, networkHelpers } = await hre.network.connect();

describe ("coinForge Factory", ()=>{
    let factory;
    let address;


    it("it should deploy coinForge factory contract", async ()=>{

        // console.log("this is ethers::::::::::::::::", ethers)
        // console.log("this is the hre ++++++++++++++++++++++++++",hre);

        const Factory = await ethers.deployContract("CoinForgeFactory");
        factory = await Factory;

        console.log("this is the factory deployment",factory);

        address = Factory.target;
        console.log("this is contract address=>", address)
    })
})