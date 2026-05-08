functor
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain


define
    %% STUDENT START:
    fun {HashTransaction Transaction}
        Transaction.nonce + Transaction.sender + Transaction.receiver + Transaction.value
    end

    fun {IntPow Base Exp}
        if Exp == 0 then 1
        else Base * {IntPow Base Exp-1}
        end
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
    fun{SumHashListTransactions Transactions}
        case Transactions of nil then 0
        [] Ti|Rest then {HashTransaction Ti} + {SumHashListTransactions Rest}
        end
    end
    fun{HashBlock Block}
        Block.number + Block.previousHash + {SumHashListTransactions Block.transactions}
    end
    fun{ValidateTransaction Transaction State}
        if Transaction.nonce \= State.(Transaction.sender).nonce + 1 then false
        elseif Transaction.hash \= {HashTransaction Transaction} then false
        elseif Transaction.value > State.(Transaction.sender).balance then false
        elseif Transaction.value < 0 then false
        elseif Transaction.max_effort < 0 then false
        elseif Transaction.max_effort < {EffortTransaction Transaction} then false
        else true
        end
    end
    fun{ValidateBlock Block PreviousBlock}
        if Block.number \= PreviousBlock.number + 1 then false
        elseif Block.previousHash \= PreviousBlock.hash then false
        elseif Block.hash \= {HashBlock Block} then false
        else true
        end
    end

    %% PUT ANY AUXILIARY/HELPER FUNCTIONS THAT YOU NEED

    %% STUDENT END

    fun {Decode Blockchain} 
        %% STUDENT START:
        ""   % placeholder %%test branch1 merge plusieurs modifs
        %% STUDENT END
    end

    proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        %% STUDENT START:
        skip   % placeholder
        %% STUDENT END
    end
end