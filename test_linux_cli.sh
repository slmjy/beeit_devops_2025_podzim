#!/bin/bash
#===========================================
#------------- Testovací skript ------------
#===========================================

TEST_SKORE=0

echo "--------- Test 1: Spuštění Manuálu (funkce -h) ---------"
VYSTUP=$(./linux_cli.sh -h) 
RC=$? # ulozeni return code

if [ $RC -eq 0 ] && echo "$VYSTUP" | grep -q "MANUÁL"; then
    echo "kód je 0."
    TEST_SKORE=$((TEST_SKORE + 1))
else
    echo "Chyba"
fi

echo "--------- Úspěšný testy: $TEST_SKORE ---------"

# Pri selhani aspon jednoho testu skonci chybou
if [ $TEST_SKORE -lt 1 ]; then
    exit 1 
fi
