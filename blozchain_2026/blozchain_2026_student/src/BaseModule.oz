functor
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain

 
define
    %%Test 2 modifs même ligne
    % j'écris n'importe quoi pour essayer de merger la branche deux
    %% STUDENT START:
    % je suis dans la branche deux 
    declare 
    fun {lol x}
        x + 1
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