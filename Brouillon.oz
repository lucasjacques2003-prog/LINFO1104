functor
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain

define

    %% =====================================================
    %% Constantes
    %% =====================================================
    HashModulo     = 1000000
    BlockMaxEffort = 300

    %% =====================================================
    %% Fonctions de hachage (2.1.2)
    %% =====================================================

    fun {TransactionHash T}
        (T.nonce + T.sender + T.receiver + T.value) mod HashModulo
    end

    fun {SumTxHashes Txs}
        case Txs of nil then 0
        [] H|R then H.hash + {SumTxHashes R}
        end
    end

    fun {BlockHashFun Number PrevHash Txs}
        (Number + PrevHash + {SumTxHashes Txs}) mod HashModulo
    end

    %% =====================================================
    %% Calcul de l'effort (2.1.3)
    %% =====================================================

    fun {NumDigits N}
        if N < 10 then 1
        else 1 + {NumDigits N div 10}
        end
    end

    fun {Pow2 N}
        if N == 0 then 1
        else 2 * {Pow2 N-1}
        end
    end

    %% effort = somme(2^i, i = 0..len(value)-1)
    fun {ComputeEffort Value}
        Len = {NumDigits Value}
        fun {Loop I Acc}
            if I >= Len then Acc
            else {Loop (I+1) (Acc + {Pow2 I})}
            end
        end
    in
        {Loop 0 0}
    end

    %% Ajoute le champ effort à une transaction
    fun {AddEffort T}
        {AdjoinAt T effort {ComputeEffort T.value}}
    end

    %% =====================================================
    %% Gestion de l'état (2.1.6)
    %% =====================================================

    %% Convertit le record genesis (address:balance) en état interne
    %% (address:user(balance:_ nonce:_))
    fun {GenesisToState Genesis}
        fun {Build Fs Acc}
            case Fs of nil then Acc
            [] F|R then
                {Build R {AdjoinAt Acc F user(balance:Genesis.F nonce:0)}}
            end
        end
    in
        {Build {Arity Genesis} state}
    end

    %% Utilisateur inconnu => balance 0, nonce 0 (sera créé à la réception)
    fun {GetUser State Addr}
        if {HasFeature State Addr} then State.Addr
        else user(balance:0 nonce:0)
        end
    end

    fun {SetUser State Addr UInfo}
        {AdjoinAt State Addr UInfo}
    end

    %% =====================================================
    %% Validation d'une transaction (2.1.4)
    %% T doit contenir le champ effort déjà calculé.
    %% =====================================================
    fun {IsValidTransaction T State}
        SInfo = {GetUser State T.sender}
    in
        T.value      >= 0                      andthen
        T.max_effort >= 0                      andthen
        T.effort     =< T.max_effort           andthen
        T.nonce      == SInfo.nonce + 1        andthen
        T.hash       \= 0                      andthen
        T.hash       == {TransactionHash T}    andthen
        SInfo.balance >= T.value
    end

    %% Applique une transaction valide à l'état.
    %% Sender d'abord, receiver ensuite (gère le cas sender == receiver).
    fun {ApplyTransaction T State}
        SInfo  = {GetUser State T.sender}
        State1 = {SetUser State T.sender
                  user(balance:SInfo.balance-T.value nonce:T.nonce)}
        RInfo  = {GetUser State1 T.receiver}
    in
        {SetUser State1 T.receiver
         user(balance:RInfo.balance+T.value nonce:RInfo.nonce)}
    end

    %% =====================================================
    %% Construction des blocs (2.1.5 + 2.1.7)
    %% =====================================================

    %% Pour les transactions destinées à UN bloc :
    %% - calcule leur effort,
    %% - garde uniquement les transactions valides,
    %% - s'arrête d'ajouter dès que l'effort cumulé dépasserait 300,
    %% - met à jour l'état après chaque transaction acceptée.
    %% Retourne TxsValides#EtatFinal (transactions dans l'ordre original).
    fun {ProcessBlockTxs Txs State CurEffort Acc}
        case Txs of nil then {Reverse Acc} # State
        [] T|R then
            local TWE = {AddEffort T} in
                if {IsValidTransaction TWE State} andthen
                   CurEffort + TWE.effort =< BlockMaxEffort
                then
                    {ProcessBlockTxs R
                                     {ApplyTransaction TWE State}
                                     (CurEffort + TWE.effort)
                                     (TWE|Acc)}
                else
                    %% Transaction invalide OU dépassement d'effort :
                    %% on ignore et on continue avec les suivantes.
                    {ProcessBlockTxs R State CurEffort Acc}
                end
            end
        end
    end

    %% Découpe en tête le préfixe contigu de transactions du même block_number.
    fun {SplitGroup L BN Acc}
        case L of nil then {Reverse Acc} # nil
        [] H|R then
            if H.block_number == BN then {SplitGroup R BN (H|Acc)}
            else {Reverse Acc} # L
            end
        end
    end

    %% Regroupe les transactions (déjà triées) par block_number.
    %% Renvoie une liste de paires BlockNumber#ListeDeTxs.
    fun {GroupByBlock Txs}
        case Txs of nil then nil
        [] T|_ then
            local
                BN    = T.block_number
                Split = {SplitGroup Txs BN nil}
            in
                (BN # Split.1) | {GroupByBlock Split.2}
            end
        end
    end

    %% Construit la chaîne bloc par bloc.
    %% Retourne Blockchain#EtatFinal (blocs dans l'ordre croissant).
    fun {BuildBlockchain Groups State PrevHash Acc}
        case Groups of nil then {Reverse Acc} # State
        [] G|R then
            local
                BN        = G.1
                Txs       = G.2
                Result    = {ProcessBlockTxs Txs State 0 nil}
                ValidTxs  = Result.1
                NewState  = Result.2
                BHash     = {BlockHashFun BN PrevHash ValidTxs}
                B         = block(number:BN
                                  previousHash:PrevHash
                                  transactions:ValidTxs
                                  hash:BHash)
            in
                {BuildBlockchain R NewState BHash (B|Acc)}
            end
        end
    end

    %% =====================================================
    %% Fonctions exportées
    %% =====================================================

    fun {Decode Blockchain}
        ""   %% À implémenter en 2.2
    end

    proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        InitialState = {GenesisToState GenesisState}
        Groups       = {GroupByBlock Transactions}
        Result       = {BuildBlockchain Groups InitialState 0 nil}
    in
        FinalBlockchain = Result.1
        FinalState      = Result.2
    end
end