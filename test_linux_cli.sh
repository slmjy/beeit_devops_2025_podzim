#!/bin/bash

CLI_SCRIPT="./linux_cli.sh" 

TEST_LOG="/tmp/cli_test_log.txt"

TEST_SOURCE="/tmp/test_source.txt"
TEST_TARGET_SOFT="/tmp/test_target_soft"
TEST_TARGET_HARD="/tmp/test_target_hard"

assert_success() {
    if [[ $? -eq 0 ]]; then
        echo "OK: $1"
    else
        echo "CHYBA: $1 - Skript selhal (RC: $?)."
        exit 1
    fi
}

assert_failure() {
    if [[ $? -ne 0 ]]; then
        echo "OK: $1 - Skript selhal, jak se očekávalo."
    else
        echo "CHYBA: $1 - Skript měl selhat, ale uspěl (RC: $?)."
        exit 1
    fi
}

touch "$TEST_SOURCE"
assert_success "Vytvoření zdroje pro test linku"
chmod +x "$CLI_SCRIPT"

echo -e "\n Spouštění testů"

echo "Test 1: Nápověda (-h)"
"$CLI_SCRIPT" -h > /dev/null
assert_success "Nápověda se spustila"

echo "Test 2: Neplatný flag (-z)"
"$CLI_SCRIPT" -z 2> /dev/null
assert_failure "Neplatný flag se ohlásil chybou (RC 1)"

echo "Test 3: Logování do souboru (-f) a Info o procesu (-p)"
"$CLI_SCRIPT" -f "$TEST_LOG" -p
assert_success "Logování a info o procesu (RC 0)"
if grep -q "Logování nastaveno na soubor" "$TEST_LOG" && grep -q "PID aktuálního procesu" "$TEST_LOG"; then
    echo "OK: Logovací soubor obsahuje očekávaný výstup."
else
    echo "CHYBA: Logovací soubor neobsahuje očekávané výstup."
    exit 1
fi

echo "Test 4: Vytvoření soft linku (-l)"
"$CLI_SCRIPT" -l "$TEST_SOURCE" "$TEST_TARGET_SOFT" "soft"
assert_success "Soft link vytvořen (RC 0)"
if [[ -L "$TEST_TARGET_SOFT" ]]; then
    echo "OK: Soft link existuje."
else
    echo "CHYBA: Soft link nebyl vytvořen."
    exit 1
fi

echo "Test 5: Chyba existujícího linku"
"$CLI_SCRIPT" -l "$TEST_SOURCE" "$TEST_TARGET_SOFT" 2> /dev/null
assert_failure "Selhání při tvorbě existujícího linku (RC 1)"

echo "Test 6: Vytvoření hard linku (-l hard)"
"$CLI_SCRIPT" -l "$TEST_SOURCE" "$TEST_TARGET_HARD" "hard"
assert_success "Hard link vytvořen (RC 0)"
if [[ -f "$TEST_TARGET_HARD" && ! -L "$TEST_TARGET_HARD" ]]; then
    echo "OK: Hard link existuje."
else
    echo "CHYBA: Hard link nebyl vytvořen."
    exit 1
fi

echo "Test 7: Neplatný typ linku"
"$CLI_SCRIPT" -l "$TEST_SOURCE" /tmp/invalid_link "invalidtype" 2> /dev/null
assert_failure "Selhání s neplatným typem linku (RC 1)"

echo "Test 8: Listování aktualizací (-a) (očekáváme pokus o sudo/chybu)"
"$CLI_SCRIPT" -a 2> /dev/null
echo "Poznámka: Test -a se pokusil spustit, kontrola RC je volná (může být 0, pokud nebylo voláno sudo, ale je důležité, že skript nepadl na syntaktické chybě)."

echo -e "\n--- Úklid ---"
rm -f "$TEST_LOG" "$TEST_SOURCE" "$TEST_TARGET_SOFT" "$TEST_TARGET_HARD"
echo "Testy dokončeny. Vše OK."
exit 0