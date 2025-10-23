import { CircularBuffer } from "./circularBuffer.js";

require('dotenv').config();

const circularBuffer = new CircularBuffer();
const { ethers } = require("ethers");
const privateKey = process.env.PRIVATE_KEY;
const provider = new ethers.providers.WebSocketProvider(
    "ws://localhost:8545"
);//ID for test
const abi = [
    "event newPrice(uint256);",
    "function callback(uint256 id, string memory data) external"
]
const eventSignature = "newPrice(uint256)";
const eventTopic = ethers.utils.id(eventSignature);

provider.on({topics:[eventTopic]},(log)=>{
    const contract = new ethers.Contract(log.address,abi,provider);
    const event = contract.interface.parseLog(log);
    oldprice = circularBuffer.enqueue(event.args.price);//update buffer
    if(circularBuffer.bufferFull){
        sendCallBack(oldPrice,log.address);
    }
})

async function sendCallBack(oldPrice,contractAddress){
    try{
        const contract = new ethers.Contract(contractAddress,abi,provider);
        const wallet = new ethers.Wallet(privateKey,provider);
        const contractWithSigner = contract.connect(wallet);
        const tx = await contractWithSigner.callback(oldPrice);
        console.log('交易已发送：${tx.hash}');
        const receipt = await tx.wait();
        console.log('交易已确认，区块：${receipt.transactionHash}');

        return receipt;

    }catch (error) {
        console.error("交易失败",error);
        throw error;
    }
}
