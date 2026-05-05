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