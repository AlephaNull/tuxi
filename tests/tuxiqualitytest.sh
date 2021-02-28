#!/usr/bin/env sh

if ! [ -f testqueries.txt ]; then
    printf "Y'all got anymore of those testqueries(.txt)?"
    exit 1
fi
rm testoutputs.txt 2>/dev/null
rm totals.txt 2>/dev/null

raw=false
use_tee=false
red=$(tput setaf 1)
run=""
#defaults if raw != true

while getopts "rt" o; do
    case "${o}" in
    r)
        raw=true
        ;;
    t)
        use_tee=true
        ;;
    *)
        exit 1
        ;;
    esac
done
#this took to long for me to figure out

$raw && red=""

t_did_you_mean() { printf "Testing error correction¬\n" | tee -a testoutputs.txt; }
t_define() { printf "Testing word definition¬\n" | tee -a testoutputs.txt; }
t_kno_val() { printf "Testing chemistry snippets¬\n" | tee -a testoutputs.txt; }
t_math() { printf "Testing Math¬\n" | tee -a testoutputs.txt; }
t_kno_top() { printf "Testing Knowledge Graph - top¬\n" | tee -a testoutputs.txt; }
t_quotes() { printf "Testing Quotes¬\n" | tee -a testoutputs.txt; }
t_basic() { printf "Testing basic answers¬\n" | tee -a testoutputs.txt; }
t_richcast() { printf "Testing cast list¬\n" | tee -a testoutputs.txt; }
t_lists() { printf "Testing simple lists¬\n" | tee -a testoutputs.txt; }
t_feat() { printf "Testing featured snippets¬\n" | tee -a testoutputs.txt; }
t_lyrics() { printf "Testing song lyrics¬\n" | tee -a testoutputs.txt; }
t_weather() { printf "Testing weather information¬\n" | tee -a testoutputs.txt; }
t_unit() { printf "Testing unit conversion¬\n" | tee -a testoutputs.txt; }
t_currency() { printf "Testing currency conversion¬\n" | tee -a testoutputs.txt; }
t_trans() { printf "Testing translation¬\n" | tee -a testoutputs.txt; }
t_sport_fixture() { printf "Testing sports fixtures¬\n" | tee -a testoutputs.txt; }
t_rich() { printf "Testing Rich Answer¬\n" | tee -a testoutputs.txt; }
t_kno_right() { printf "Testing Knowledge Graph - right¬\n" | tee -a testoutputs.txt; }

printf "${red}Test Output - If you don't know what you're doing here, hit h to figure out controls, or q if you aren't developing\n" >>testoutputs.txt
printf "${red}###################################################################################################################\n" >>testoutputs.txt
printf "${red}###################################################################################################################\n" >>testoutputs.txt
printf "${red}###################################################################################################################\n" >>testoutputs.txt

if ! $raw; then
    printf "Testing help message¬\n" && ../tuxi -h 1>>testoutputs.txt && printf "\tpassed.\n" || printf "\tFailed...\n"
fi
#Help message cant be sent as raw, tuxi -r -h does not work

cycle=1
until [ $cycle -eq 3 ]; do
    case $cycle in
    1) run="-d -p" ;;    # default search with debug info and pipe disabled
    2) run="-d -p -b" ;; # same as above but also with smart search
    *) exit 1 ;;
    esac
    $raw && run="-r ${run}"
    printf "\n--> Starting run: %s | flags in use: %s\n\n" "$cycle" "$run" | tee -a testoutputs.txt
    good=true
    cat testqueries.txt | sed -e '/^\s*#.*$/d' -e '/^[[:space:]]*$/d' | while read -r x; do
        reason=""
        target=$(printf '%s' "$x" | cut -d ' ' -f1)
        query=$(printf '%s' "$x" | sed 's/^ *[^ ][^ ]*  *//')
        printf "\n" && "t_${target}"
        printf "target: %b | query: %b\n" "$target" "$query" | tee -a testoutputs.txt
        result="$(../tuxi $run "$query")"
        nr_check="$(printf '%b\n' "$result" | grep 'No Result!')"
        if [ -n "$nr_check" ]; then
            echo "FAILED" >>totals.txt
            good=false
            reason="no results"
        elif [ "$target" = 'did_you_mean' ]; then
            dym_check="$(printf '%b\n' "$result" | head -n1 | grep ' you mean')"
            if [ -n "$dym_check" ]; then
                echo "PASSED" >>totals.txt
                good=true
            else
                echo "FAILED" >>totals.txt
                good=false
                reason="no correction"
            fi
        else
            answer=$(printf '%b\n' "$result" | grep "Answer selected: " | awk '{print $NF}')
            [ "$answer" = 'lyrics_int' ] || [ "$answer" = 'lyrics_us' ] && answer='lyrics'
            if [ "$answer" = "$target" ]; then
                echo "PASSED" >>totals.txt
                good=true
            else
                echo "FAILED" >>totals.txt
                good=false
                reason="wrong answer"
            fi
        fi
        if $use_tee; then
            printf '%b\n' "$result" | tee -a testoutputs.txt
        else
            printf '%b\n' "$result" 1>>testoutputs.txt
        fi
        if $good; then
            printf '|--> passed \n\n' | tee -a testoutputs.txt
        else
            printf '|-->> FAILED! | Reason: %b\n\n' "$reason" | tee -a testoutputs.txt
        fi
    done
    passed=$(cat totals.txt | grep -c PASSED)
    failed=$(cat totals.txt | grep -c FAILED)
    printf '\n-->> END RUN %s | Results: PASSED %s FAILED %s\n' $cycle $passed $failed | tee -a testoutputs.txt
    cycle=$(($cycle + 1))
    rm totals.txt
done

if ! $raw; then
    less -R testoutputs.txt
fi
#dont show the raw, just output it to the file
