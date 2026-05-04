# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LINFO1104/LSINC1104 course project (UCLouvain). Implement a blockchain in **Mozart/Oz** that processes a genesis state and a list of transactions, builds a chain of blocks, and decodes a secret from the final blockchain.

All work is done inside `blozchain_2026/blozchain_2026_student/`.

## Commands

Run from `blozchain_2026/blozchain_2026_student/`:

```sh
make          # compile all .oz sources to .ozf functors
make run      # compile then execute via ozengine
make clean    # remove all .ozf binaries
make zip      # create submission archive (requires rapport.pdf at project root)
```

Direct compilation and execution:
```sh
ozc -c src/BaseModule.oz -o src/BaseModule.ozf
ozengine Main.ozf
```

## Architecture

```
blozchain_2026/blozchain_2026_student/
├── Main.oz               # entry point — do not modify
├── src/BaseModule.oz     # only file to implement
├── library/FileHelperModule.oz  # provided I/O utilities (read-only)
└── data/
    ├── genesis.txt       # initial balances: address,balance per line
    └── transactions.txt  # 48 transactions: block_number,nonce,hash,sender,receiver,value,max_effort
```

**Main.oz** reads genesis and transaction files via `FileHelperModule`, calls `BaseModule.executeBlockchain`, then calls `BaseModule.decode` on the resulting blockchain and prints the secret.

**BaseModule.oz** (`src/BaseModule.oz`) — the only file to edit. Must export:
- `fun {Decode Blockchain}` → returns a string (the secret decoded from the blockchain)
- `proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}` → unifies `FinalState` and `FinalBlockchain` with the processed results

## Data Formats

**GenesisState** — a record produced by `FileHelperModule.readGenesisFromFile`:
```oz
genesis(14:72768254 15:94347091 32:6036643 37:1239534151)
```
Fields are integer address keys mapped to integer balances.

**Transactions** — a list of `tx` records produced by `FileHelperModule.readTransactionsFromFile`:
```oz
tx(block_number:N nonce:N hash:N sender:N receiver:N value:N max_effort:N)
```
All fields are integers.

**FileHelperModule** also exports `writeLineInFile` and `writeLineLnInFile` for writing to already-open files.

## Oz Language Notes

- Functors: `functor import ... export ... define ... end`
- Functions vs procedures: `fun {F X} ... end` (returns value) vs `proc {P X Y} ... end` (unifies output args)
- Records: `label(field1:val1 field2:val2)` — access with `R.field1`
- Lists: `H|T` pattern, `nil` terminator; `case L of nil then ... [] H|T then ...`
- Unification (`=`) instead of assignment; variables are single-assignment
- Strings are lists of character codes

## Submission

1. Set `NOMA1` and `NOMA2` in `Makefile` to your student IDs (use `00000000` for solo)
2. Place `rapport.pdf` at the root of the student project
3. Run `make zip` — creates `NOMA1_NOMA2.zip` for INGInious submission (one per group)
