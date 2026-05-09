functor
import % ligne ajoutée 
    System % ligne ajoutée
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain


define
    %% STUDENT START:
    % J'ai ajouté ça pour avoir la visualisation de tout 
    proc {PrintBlockchain Blockchain}
        case Blockchain of nil then skip
        [] Block|Rest then
            {System.show Block}
            {PrintBlockchain Rest}
        end
    end

    
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
            else {IntPow 2 Acc} + {EffortTransactionHelper (Value div 10) (Acc+1)}
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
            NewUser = user(balance:(Genesis.(Address)) nonce:0)
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
        fun {NumberToLetter N}
            case N of 10 then &a
            [] 11 then &b
            [] 12 then &c
            [] 13 then &d
            [] 14 then &e
            [] 15 then &f
            [] 16 then &g
            [] 17 then &h
            [] 18 then &i
            [] 19 then &j
            [] 20 then &k
            [] 21 then &l
            [] 22 then &m
            [] 23 then &n
            [] 24 then &o
            [] 25 then &p
            [] 26 then &q
            [] 27 then &r
            [] 28 then &s
            [] 29 then &t
            [] 30 then &u
            [] 31 then &v
            [] 32 then &w
            [] 33 then &x
            [] 34 then &y
            [] 35 then &z
            [] 36 then 32
            end
        end


        fun {HashToDigits Hash} % transformer un nombre entier en liste de chiffres.
            fun {Helper N Acc}
                if N == 0 then Acc
                else {Helper (N div 10) ((N mod 10)|Acc)}
                end
            end
        in
            if Hash == 0 then nil
            else {Helper Hash nil}
            end
        end


        fun {DigitsToLetters Digits} % Fonction qui convertit une liste de chiffres en lettres.
            case Digits of nil then nil
            [] _|nil then nil % s'il n'y a qu'un chiffre, on ignore parce que c'est par pair.
            [] D1|D2|Rest then 
                Pair = D1*10 + D2
                ModResult = Pair mod 37
                FinalNumber = if ModResult < 10 then 36 else ModResult end
            in
                {NumberToLetter FinalNumber} | {DigitsToLetters Rest}
            end
        end

        fun {ProcessBlocks Blocks} 
            case Blocks of nil then nil
            [] Block|Rest then
                {List.append
                    {DigitsToLetters {HashToDigits Block.hash}}{ProcessBlocks Rest}}
            end
        end
    in
        {ProcessBlocks Blockchain}
    end

    proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        %% STUDENT START:
        InitialState = {GenesisToState GenesisState}
        InitialBlockchain = nil
        InitialBlock = {BuildBlock {LastBlock InitialBlockchain}}
    in
        {ExecuteBlockchainHelper Transactions InitialState InitialBlock InitialBlockchain FinalState FinalBlockchain}
        {PrintBlockchain FinalBlockchain} % ligne ajoutée
    end
        %% STUDENT END
end