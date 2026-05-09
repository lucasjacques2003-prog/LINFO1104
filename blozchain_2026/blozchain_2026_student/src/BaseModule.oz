functor
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain


define
    %% STUDENT START:
    fun {IntPow Base Exp}
        if Exp == 0 then 1
        else Base * {IntPow Base Exp-1}
        end
    end

    fun {HashTransaction Transaction}
        (Transaction.nonce + Transaction.sender + Transaction.receiver + Transaction.value) mod {IntPow 10 6}
    end

    fun {EffortTransaction Transaction}
        fun{EffortTransactionHelper Value Acc}
            if Value < 10 then {IntPow 2 Acc}
            else {IntPow 2 Acc} + {EffortTransactionHelper Value//10 Acc+1}
            end
        end
    in
        {EffortTransactionHelper Transaction.value 0}
    end

    fun {SumEffortListTransactions Transactions}
        fun {SumEffortListTransactionsHelper Transactions Acc}
            case Transactions of nil then Acc
            [] Ti|Rest then {SumEffortListTransactionsHelper Rest Acc+{EffortTransaction Ti}}
            end
        end
    in
        {SumEffortListTransactionsHelper Transactions 0}
    end
        
    fun{SumHashListTransactions Transactions}
        fun {SumHashListTransactionsHelper Transactions Acc}
            case Transactions of nil then Acc
            [] Ti|Rest then {SumHashListTransactionsHelper Rest Acc+{HashTransaction Ti}}
            end
        end
    in
        {SumHashListTransactionsHelper Transactions 0}
    end

    fun {HashBlock Block}
        (Block.number + Block.previousHash + {SumHashListTransactions Block.transactions}) mod {IntPow 10 6}
    end

    fun {ValidateTransaction Transaction State}
        if Transaction.nonce \= State.(Transaction.sender).nonce + 1 then false
        elseif Transaction.hash \= {HashTransaction Transaction} then false
        elseif Transaction.value > State.(Transaction.sender).balance then false
        elseif Transaction.value < 0 then false
        elseif Transaction.max_effort < 0 then false
        elseif Transaction.max_effort < {EffortTransaction Transaction} then false
        else true
        end
    end

    fun {ValidateBlock Block PreviousBlock}
        if Block.number \= PreviousBlock.number + 1 then false
        elseif Block.previousHash \= PreviousBlock.hash then false
        elseif Block.hash \= {HashBlock Block} then false
        elseif {SumEffortListTransactions Block.transactions} > 300 then false
        else true
        end
    end

    fun {GenesisToState Genesis}
        Addresses = {Arity Genesis}
    in
        {GenesisToStateHelper Genesis Addresses state}
    end

    fun {GenesisToStateHelper Genesis Addresses StateCurrent}
        case Addresses of nil then StateCurrent
        [] Address|Rest then
            NewUser = user(balance:(Genesis.Address) nonce:0)
            NewState = {AdjoinAt StateCurrent Address NewUser}
        in
            {GenesisToStateHelper Genesis Rest NewState}
        end
    end

    fun {ApplyTransaction Transaction State}
        NewSender = user(balance: State.(Transaction.sender).balance - Transaction.value nonce: State.(Transaction.sender).nonce +1)
        NewReceiver = if {HasFeature State Transaction.receiver} then
            user(balance: State.(Transaction.receiver).balance + Transaction.value nonce: State.(Transaction.receiver).nonce)
        else
            user(balance: Transaction.value nonce: 0)
        end
        NewState1 = {AdjoinAt State Transaction.sender NewSender}
        NewState2 = {AdjoinAt NewState1 Transaction.receiver NewReceiver}
    in
        NewState2
    end

    proc {AddTransactionToBlock Transaction Block State NewBlock NewState}
        NewTransaction = {AdjoinAt Transaction effort {EffortTransaction Transaction}}
    in
        if {ValidateTransaction NewTransaction State} andthen {SumEffortListTransactions Block.transactions} + NewTransaction.effort =< 300 then
            NewState = {ApplyTransaction NewTransaction State}
            NewBlock = {AdjoinAt Block transactions NewTransaction|Block.transactions}
        else
            NewState = State
            NewBlock = Block
        end
    end

    proc {AddTransactionsToBlock Transactions Block State NewBlock NewState}
        case Transactions of nil then
            NewState = State
            NewBlock = Block
        [] Ti|Rest then
            AccBlock AccState
        in
            {AddTransactionToBlock Ti Block State AccBlock AccState}
            {AddTransactionsToBlock Rest AccBlock AccState NewBlock NewState}
        end
    end

    fun {LastBlock Blockchain}
        case Blockchain of nil then block(number: ~1 previousHash: 0 transactions: nil hash: 0) %% Genesis block permettant la vérification de validité du premier bloc de la blockchain
        []Block|nil then Block
        []Block|Rest then {LastBlock Rest}
        end
    end

    fun {BuildBlock PreviousBlock}
        NewBlock = block(number: PreviousBlock.number + 1 previousHash: PreviousBlock.hash transactions: nil hash: 0)
    in
        NewBlock
    end

    fun {FinalizeBlock Block}
        ReversedTransactionsBlock = {AdjoinAt Block transactions {List.reverse Block.transactions}}
    in
        {AdjoinAt ReversedTransactionsBlock hash {HashBlock ReversedTransactionsBlock}}
    end

    fun {AddBlockToBlockchain Block Blockchain}
        case Blockchain of nil then
            Block|nil
        []B|nil then
            B|Block|nil
        []B|Rest then
            B|{AddBlockToBlockchain Block Rest}
        end
    end
    
    proc {ExecuteBlockchainHelper Transactions State CurrentBlock Blockchain FinalState FinalBlockchain}
        case Transactions of nil then
            FinalizedBlock = {FinalizeBlock CurrentBlock}
        in
            if {ValidateBlock FinalizedBlock {LastBlock Blockchain}} then
                FinalBlockchain = {AddBlockToBlockchain FinalizedBlock Blockchain}
            else
                FinalBlockchain = Blockchain
            end
            FinalState = State
        []Ti|Rest then
            if Ti.block_number == CurrentBlock.number then
                NewBlock NewState
            in
                {AddTransactionToBlock Ti CurrentBlock State NewBlock NewState}
                {ExecuteBlockchainHelper Rest NewState NewBlock Blockchain FinalState FinalBlockchain}
            else
                FinalizedBlock NewBlockchain NewBlock
            in 
                FinalizedBlock = {FinalizeBlock CurrentBlock}
                if {ValidateBlock FinalizedBlock {LastBlock Blockchain}} then
                    NewBlockchain = {AddBlockToBlockchain FinalizedBlock Blockchain}
                else
                    NewBlockchain = Blockchain
                end
                NewBlock = {BuildBlock {LastBlock NewBlockchain}}
                {ExecuteBlockchainHelper Transactions State NewBlock NewBlockchain FinalState FinalBlockchain}
            end
        end
    end
                    

                

    %% STUDENT END

    fun {Decode Blockchain} 
        %% STUDENT START:
        ""   % placeholder 
        %% STUDENT END
    end

    proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        %% STUDENT START:
        InitialState = {GenesisToState GenesisState}
        InitialBlockchain = nil
        InitialBlock = {BuildBlock {LastBlock InitialBlockchain}}
    in
        {ExecuteBlockchainHelper Transactions InitialState InitialBlock InitialBlockchain FinalState FinalBlockchain}
    end
        %% STUDENT END
end