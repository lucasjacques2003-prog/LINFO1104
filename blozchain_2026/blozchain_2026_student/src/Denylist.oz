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

    fun {HashTransaction Transaction} % Calcule le hash d'une transaction
        (Transaction.nonce + Transaction.sender + Transaction.receiver + Transaction.value) mod {IntPow 10 6}
    end

    fun {EffortTransaction Transaction} % Calcule l'effort d'une transaction
        fun{EffortTransactionHelper Value Acc}
            if Value < 10 then {IntPow 2 Acc}
            else {IntPow 2 Acc} + {EffortTransactionHelper (Value div 10) (Acc+1)}
            end
        end
    in
        {EffortTransactionHelper Transaction.value 0}
    end

    fun {SumEffortListTransactions Transactions} % Calcule l'effort total d'une liste de transactions
        fun {SumEffortListTransactionsHelper Transactions Acc}
            case Transactions of nil then Acc
            [] Ti|Rest then {SumEffortListTransactionsHelper Rest Acc+{EffortTransaction Ti}}
            end
        end
    in
        {SumEffortListTransactionsHelper Transactions 0}
    end
        
    fun{SumHashListTransactions Transactions} % Calcule la somme des hash d'une liste de transactions
        fun {SumHashListTransactionsHelper Transactions Acc}
            case Transactions of nil then Acc
            [] Ti|Rest then {SumHashListTransactionsHelper Rest Acc+{HashTransaction Ti}}
            end
        end
    in
        {SumHashListTransactionsHelper Transactions 0}
    end

    fun {HashBlock Block} % Calcule le hash d'un bloc
        (Block.number + Block.previousHash + {SumHashListTransactions Block.transactions}) mod {IntPow 10 6}
    end

    fun {ValidateTransaction Transaction State} %Verifie si une transaction est valide en fonction de l'état actuel
        if Transaction.nonce \= State.(Transaction.sender).nonce + 1 then false
        elseif Transaction.hash \= {HashTransaction Transaction} then false
        elseif Transaction.value > State.(Transaction.sender).balance then false
        elseif Transaction.value < 0 then false
        elseif Transaction.max_effort < 0 then false
        elseif Transaction.max_effort < {EffortTransaction Transaction} then false
        elseif State.(Transaction.sender).denied then false
        else true
        end
    end

    fun {ValidateBlock Block PreviousBlock} %Verifie si un bloc est valide en fonction du bloc précédent
        if Block.number \= PreviousBlock.number + 1 then false
        elseif Block.previousHash \= PreviousBlock.hash then false
        elseif Block.hash \= {HashBlock Block} then false
        elseif {SumEffortListTransactions Block.transactions} > 300 then false
        else true
        end
    end

    fun {GenesisToState Genesis} % Crée un état initial a partir du genesis
        Addresses = {Arity Genesis}
    in
        {GenesisToStateHelper Genesis Addresses state}
    end

    fun {GenesisToStateHelper Genesis Addresses StateCurrent}
        case Addresses of nil then StateCurrent
        [] Address|Rest then
            NewUser = user(balance:(Genesis.(Address)) nonce:0 txCount:0 denied:false)
            NewState = {AdjoinAt StateCurrent Address NewUser}
        in
            {GenesisToStateHelper Genesis Rest NewState}
        end
    end

    fun {ApplyTransaction Transaction State} % Applique une transaction, mettant a jour les soldes et nonce des utilisateurs dasn un nouvel etat
        NewSender = {AdjoinAt {AdjoinAt State.(Transaction.sender) balance State.(Transaction.sender).balance - Transaction.value} nonce State.(Transaction.sender).nonce + 1}
        NewReceiver = if {HasFeature State Transaction.receiver} then
            {AdjoinAt State.(Transaction.receiver) balance State.(Transaction.receiver).balance + Transaction.value}
        else
            user(balance: Transaction.value nonce: 0 txCount:0 denied:false)
        end
        NewState1 = {AdjoinAt State Transaction.sender NewSender}
        NewState2 = {AdjoinAt NewState1 Transaction.receiver NewReceiver}
    in
        NewState2
    end

    proc {AddTransactionToBlock Transaction Block State NewBlock NewState} % Ajoute une transaction a un bloc apres validation, retourne le bloc et l'etat mis a jour
        NewTransaction = {AdjoinAt Transaction effort {EffortTransaction Transaction}}
        UpdatedSender1 = {AdjoinAt State.(NewTransaction.sender) txCount State.(NewTransaction.sender).txCount + 1}
        UpdatedState = {AdjoinAt State NewTransaction.sender UpdatedSender1}
    in
        if {ValidateTransaction NewTransaction UpdatedState} andthen {SumEffortListTransactions Block.transactions} + NewTransaction.effort =< 300 then
            TempState = {ApplyTransaction NewTransaction UpdatedState}
            UpdatedSender2 = if UpdatedSender1.txCount >= 3 then % On ajoute le sender a la denylist si il a 3 transactions dasn le meme bloc
                {AdjoinAt TempState.(NewTransaction.sender) denied true}
            else
                TempState.(NewTransaction.sender)
            end
            NewState = {AdjoinAt TempState NewTransaction.sender UpdatedSender2}
            NewBlock = {AdjoinAt Block transactions NewTransaction|Block.transactions}
        else
            NewState = UpdatedState
            NewBlock = Block
        end
    end

    fun {LastBlock Blockchain} % fonction permlettant d'obtenir le dernier bloc de la blockchain
        case Blockchain of nil then block(number: ~1 previousHash: 0 transactions: nil hash: 0) %% Genesis block permettant la verification de validite du premier bloc de la blockchain
        []Block|nil then Block
        []Block|Rest then {LastBlock Rest}
        end
    end

    fun {BuildBlock PreviousBlock} % construit un nouveau bloc vide a partir du bloc precedent
        NewBlock = block(number: PreviousBlock.number + 1 previousHash: PreviousBlock.hash transactions: nil hash: 0)
    in
        NewBlock
    end

    fun {FinalizeBlock Block} % Finalise un bloc en calculant son hash
        ReversedTransactionsBlock = {AdjoinAt Block transactions {List.reverse Block.transactions}} % On retoiurne la liste des transactions car les dernieres ont ete ajoute en tete de liste dans AddTransactionToBlock
    in
        {AdjoinAt ReversedTransactionsBlock hash {HashBlock ReversedTransactionsBlock}}
    end

    fun {AddBlockToBlockchain Block Blockchain} % Ajoute un bloc a la blockchain retourne la nouvelle blockchain
        case Blockchain of nil then
            Block|nil
        []B|nil then
            B|Block|nil
        []B|Rest then
            B|{AddBlockToBlockchain Block Rest}
        end
    end
    
    fun {ResetTxCounts State} % Repasse les txCounts de tout les users a 0
        fun{ResetTxCountsHelper State Addresses}
            case Addresses of nil then State
            [] Address|Rest then
                UpdatedUser = {AdjoinAt State.(Address) txCount 0}
                UpdatedState = {AdjoinAt State Address UpdatedUser}
            in
                {ResetTxCountsHelper UpdatedState Rest}
            end
        end
    in
        {ResetTxCountsHelper State {Arity State}}
    end

    proc {ExecuteBlockchainHelper Transactions State CurrentBlock Blockchain FinalState FinalBlockchain}
        case Transactions of nil then % Si plus de transactions a traiter, on finalise le bloc en cours et on l'ajoute a la blockchain si valide
            FinalizedBlock = {FinalizeBlock CurrentBlock} 
        in
            if {ValidateBlock FinalizedBlock {LastBlock Blockchain}} then
                FinalBlockchain = {AddBlockToBlockchain FinalizedBlock Blockchain}
            else % Si le bloc n'est pas valide, on l'ignore
                FinalBlockchain = Blockchain
            end
            FinalState = State
        []Ti|Rest then % Si il reste des transations a traiter, on verifie que la transaction courante appartienne au bloc en cours, si oui on essaye de l'ajouter au bloc, sinon on finalise le bloc en cours et on commence a construire le bloc suivant
            if Ti.block_number == CurrentBlock.number then
                NewBlock NewState
            in
                {AddTransactionToBlock Ti CurrentBlock State NewBlock NewState}
                {ExecuteBlockchainHelper Rest NewState NewBlock Blockchain FinalState FinalBlockchain}
            else
                FinalizedBlock NewBlockchain NewBlock NewState
            in 
                FinalizedBlock = {FinalizeBlock CurrentBlock}
                if {ValidateBlock FinalizedBlock {LastBlock Blockchain}} then
                    NewBlockchain = {AddBlockToBlockchain FinalizedBlock Blockchain}
                else
                    NewBlockchain = Blockchain
                end
                NewState = {ResetTxCounts State} % Reset les txCount de tous les users lorsqu'on passe a un nouveau bloc
                NewBlock = {BuildBlock {LastBlock NewBlockchain}}
                {ExecuteBlockchainHelper Transactions NewState NewBlock NewBlockchain FinalState FinalBlockchain}
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