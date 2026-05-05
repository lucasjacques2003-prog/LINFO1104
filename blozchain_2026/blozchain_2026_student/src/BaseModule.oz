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