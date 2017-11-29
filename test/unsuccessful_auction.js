var
Populous = artifacts.require("Populous"),
CurrencyToken = artifacts.require("CurrencyToken"),
PopulousToken = artifacts.require("PopulousToken"),
DepositContractsManager = artifacts.require("DepositContractsManager"),
Crowdsale = artifacts.require("Crowdsale");

contract('Populous / Tokens > ', function(accounts) {
var
    config = require('../include/test/config.js'),
    commonTests = require('../include/test/common.js'),
    P, DCM, depositAddress, crowdsale;

describe("Init currency token > ", function() {
    it("should init currency GBP Pokens", function(done) {
        Populous.deployed().then(function(instance) {
            P = instance;
            console.log('Populous', P.address);
            // creating a new currency GBP for which to mint and use tokens
            return commonTests.createCurrency(P, "GBP Pokens", 3, "GBP");
        }).then(function() {
            done();
        });
    });

    it("should mint GBP tokens: " + (config.INVESTOR1_ACC_BALANCE), function(done) {
        assert(global.currencies.GBP, "Currency required.");
        // amount of USD tokens to mint = balance of accountIDs 'A' + 'B' + 'C'
        // amount of USD tokens to mint = 470 + 450 + 600 = 1,520
        var mintAmount = config.INVESTOR1_ACC_BALANCE;
        // mint mintAmount of USD tokens and allocate to LEDGER_ACC/"Populous"
        P.mintTokens('GBP', mintAmount).then(function(result) {
            console.log('mint tokens gas cost', result.receipt.gasUsed);
            return P.getLedgerEntry.call("GBP", config.LEDGER_ACC);
        }).then(function(amount) {
            assert.equal(amount.toNumber(), mintAmount, "Failed minting USD tokens");
            done();
        });
    });
    
    it("should transfer GBP tokens to config.INVESTOR1_ACC", function(done) {
        assert(global.currencies.GBP, "Currency required.");
        // transfer 190 GBP tokens from 'Populous' to 'A'
        P.transfer("GBP", config.LEDGER_ACC, config.INVESTOR1_ACC, 190).then(function(result) {
            console.log('transfer pokens gas cost', result.receipt.gasUsed);
            return P.getLedgerEntry.call("GBP", config.INVESTOR1_ACC);
        }).then(function(value) {
            assert.equal(value.toNumber(), 190, "Failed transfer 1");
            done();
        });
    });
    

    it("should init PPT", function(done) {
        PopulousToken.new().then(function(instance) {
            assert(instance);
            // creating a new instance of the populous token contract
            // PPT which is linked to ERC23Token.sol
            global.PPT = instance;
            console.log('PPT', global.PPT.address);

            done();
        });
    });
});

describe("Deposit Tokens > ", function() {
    it("should create deposit contract for client", function(done) {
        assert(global.PPT, "PPT required.");

        P.DCM.call().then(function(address) {
            DCM = DepositContractsManager.at(address);
            // create deposit contract for accountID 'A'
            return P.createDepositContract(config.INVESTOR1_ACC);
        }).then(function(result) {
            console.log('create deposit contract gas cost', result.receipt.gasUsed);
            // getting the address of the deposit contract for accountID 'A'
            return DCM.getDepositAddress.call(config.INVESTOR1_ACC);
        }).then(function(address) {
            assert(address);
            depositAddress = address;
            done();
        });
    });

    it("should get PPT from faucet", function(done) {
        assert(global.PPT, "PPT required.");

        var faucetAmount = 200;
        // getting PPT from faucet which increases the total amount in supply
        // and adds to the balance of the message sender accounts[0]
        global.PPT.faucet(faucetAmount).then(function() {
            return global.PPT.balanceOf(accounts[0]);
        }).then(function(amount) {
            // check that accounts[0] has the amount of PPT tokens -- 200
            // gotten from the faucet
            assert.equal(amount.toNumber(), faucetAmount, "Failed getting tokens from faucet");
            done();
        });
    });

    it("should transfer PPT to deposit address", function(done) {
        assert(global.PPT, "PPT required.");

        var faucetAmount = 200;
        // transferring 200 PPT tokens to depositAddress from accounts[0]
        // deositAddress is the address of the deposit contract for accountID 'A'
        global.PPT.transferToAddress(depositAddress, faucetAmount).catch(console.log).then(function(result) {
            console.log('transfer to address gas cost', result.receipt.gasUsed);
            // checking the balance of depositAddress is 200
            return global.PPT.balanceOf(depositAddress);
        }).then(function(amount) {
            assert.equal(amount.toNumber(), faucetAmount, "Failed getting tokens from faucet");
            done();
        });
    });

    it("should deposit PPT", function(done) {
        assert(global.PPT, "PPT required.");
        // deposit the 200 PPT from 'A' and get 190 GBP Pokens
        var
            depositAmount = 200,
            receiveCurrency = 'GBP',
            receiveAmount = 190;
        // the deposit amount is refunded later
        // When the actor deposits funds into the platform, an equivalent amount of tokens is deposited into his account
        // client gets receive amount in the particular currency ledger from 'Populous'
        P.deposit(config.INVESTOR1_ACC, global.PPT.address, receiveCurrency, depositAmount, receiveAmount).then(function() {
            return DCM.getActiveDepositList.call(config.INVESTOR1_ACC, global.PPT.address, "GBP");
        }).then(function(deposit) {
            // getActiveDepositList returns three uints
            // the last two are amount deposited and amount received
            assert.equal(deposit[1].toNumber(), depositAmount, 'Failed depositing PPT');
            assert.equal(deposit[2].toNumber(), receiveAmount, 'Failed depositing PPT');
            done();
        });
    });

    

    it("should create crowdsale", function(done) {
        assert(global.currencies.GBP, "Currency required.");
        // borrowerId is accountID 'B' and is funded when fundBeneficiary is called
        // the 100 (_invoiceAmount) is sent to invoice funders / winning group
        // the 90 (_fundingGoal) is sent to borrower from funding group
        // at the end of crowdsale
        P.createCrowdsale(
                "GBP",
                "B",
                "#8888",
                "#8888",
                200,
                190,
                1, 'ipfs')
            .then(function(createCS) {
                assert(createCS.logs.length, "Failed creating crowdsale");

                crowdsale = createCS.logs[0].args.crowdsale;
                console.log('Crowdsale', crowdsale);
                console.log('create crowdsale gas cost', createCS.receipt.gasUsed);
                done();
            });
    });

    it("should fail bid to group 1 from config.INVESTOR1_ACC with 0", function(done) {
        assert(crowdsale, "Crowdsale required.");

        var
            CS = Crowdsale.at(crowdsale);
                       
            var isCaught = false;
            // creation of this group should fail since investor1 has already created
            // and is part of a bidding group for this crowdsale.
            commonTests.bid(P, crowdsale, 0, config.INVESTOR1_ACC, "AA007", 0)
            .catch(function () {isCaught = true;}
            ).then(function () {
                if (isCaught === false) {
                    throw new Error('Not allowed group bid passed !!!');
                }
                done();
            });      
    });

    


    it("should check auction status", function(done){
        assert(crowdsale, "Crowdsale required.");

        // Check status
        // there are 6 states in total
        // Pending, Open, Closed, WaitingForInvoicePayment, PaymentReceived, Completed
        // Crowdsale.at(crowdsale).checkDeadline().then(function(){
        // Crowdsale.at(crowdsale).closeAuction().then(function(){
        P.closeAuction(crowdsale).then(function(){
            return Crowdsale.at(crowdsale).status.call();
        }).then(function(status) {
            assert.equal(status.toNumber(), 2, "Failed auction status to closed");
            done();
        });
    });



    it("should fail fund winner group", function(done) {
        assert(crowdsale, "Crowdsale required.");

        var isCaught = false;
        // Set payment received for funded invoice 
        // this sets paidAmount in crowdsale as well to the same amount
        // investor1 group will receive invoice amount of 200 and
        // investor1 the only one in the group will receive all
        // 200 + 190 = 390 balance
        P.invoicePaymentReceived(crowdsale, 200)
            .catch(function () {isCaught = true;}
        ).then(function () {
            if (isCaught === false) {
                throw new Error('Not allowed group funding passed !!!');
            }
            done();
        });
    });



    
    it("should release deposit PPT", function(done) {
        assert(global.PPT, "PPT required.");

        var
            depositAmount = 200,
            receiver = accounts[1],
            releaseCurrency = 'GBP',
            depositIndex = 0;
        // release investor1 PPT token deposit of 200 to receiver address
        // and update total as groupDeposit - investorDeposit
        // and update received as groupReceived - investorReceived 
        // and transfer balance to investor1
        // 390 - 190 = 200 gbp balance for investor1
        // gbp (received) is destroyed and ppt (deposited) is sent back
        // timelock
        P.releaseDeposit(config.INVESTOR1_ACC, global.PPT.address, releaseCurrency, receiver, depositIndex).then(function(result) {
            console.log('release deposit gas cost', result.receipt.gasUsed);
            // getActiveDepositList returns 1 = deposited and 2 = received
            return DCM.getActiveDepositList.call(config.INVESTOR1_ACC, global.PPT.address, "GBP");
        }).then(function(deposit) {
            // check that amount deposited and received are both = 0
            // and no longer 1 = 200, 2 = 190
            // remove 190 from investor1 received and transfer it to account[1]
            // o.transfer(tokenContract, receiver, deposits[clientId][tokenContract][receiveCurrency].list[depositIndex].deposited)
            // transfer received balance to investor1
            // _transfer(releaseCurrency, clientId, LEDGER_SYSTEM_ACCOUNT, received);
            
            assert.equal(deposit[1].toNumber(), 0, "Failed releasing deposit");
            assert.equal(deposit[2].toNumber(), 0, "Failed releasing deposit");
            // check reveiver has received the 200 token deposit
            return global.PPT.balanceOf(receiver);
        }).then(function(amount) {
            // check reveiver has been credited with 200 PPT token
            assert.equal(amount.toNumber(), depositAmount, "Failed releasing deposit");
            // get investor1 account balance in GBP tokens after 190 GBP pokens are destroyed
            return P.getLedgerEntry.call("GBP", config.INVESTOR1_ACC);
        }).then(function(value) {
            // investor1 should have 380 - 190 = 190 GBP Pokens left in GBP ledger
            // as 10 GBP Poken not received as interest from successful crowdsale

            assert.equal(value.toNumber(), 190, "Failed funding winner group");
            done();
        })
    });
});
});