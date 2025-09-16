const { ethers } = require("ethers");
const privateKey = process.env.PRIVATE_KEY;

const provider = new ethers.providers.WebSocketProvider(
    "wss://mainnet.infura.io/ws/v3/My_PROJECT_ID"
);//示例ID

const abi = [
    "event newPrice(uint256);",
    "function callback(uint256 id, string memory data) external"
]

const contractAddress = "0x1234567890123456789012345678901234567890";//示例地址

const contract = new ethers.Contract(contractAddress,abi,provider);

contract.on("newPrice",()=>{
    console.log("newPrice",price);
    //拿环形缓冲区中最老的元素，前60次不用拿
    sendCallBack(oldPrice);
})

async function sendCallBack(oldPrice){
    try{
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
