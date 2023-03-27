#!/usr/bin/fish

# set DIR "perf_data/record"

set SUFFIX ''
set DIR 'perf_data/record/'
set POLICY "$argv[1]"
set RECORD_1 "$argv[2]"
set RECORD_2 "$argv[3]"

if [ "$argv[-1]" = 'icache' ]
    set SUFFIX '_icache'
else if [ "$argv[-1]" = 'branch' ]
    set SUFFIX '_branch'
end

set DIFF_GRAPH "$POLICY"_$RECORD_1-$RECORD_2$SUFFIX.svg
set NEG_DIFF neg_"$POLICY"_$RECORD_2-$RECORD_1$SUFFIX.svg

sudo perf script -i "$DIR/no_filter/$RECORD_1$SUFFIX.data" > out.stacks1
sudo perf script -i "$DIR/$POLICY/$RECORD_2$SUFFIX.data" > out.stacks2

cd FlameGraph
./stackcollapse-perf.pl ../out.stacks1 > out.folded1
./stackcollapse-perf.pl ../out.stacks2 > out.folded2
./difffolded.pl -n out.folded1 out.folded2 | ./flamegraph.pl > $DIFF_GRAPH
./difffolded.pl -n out.folded2 out.folded1 | ./flamegraph.pl --negate > $NEG_DIFF

cd ..
cp FlameGraph/"$DIFF_GRAPH" .
cp FlameGraph/"$NEG_DIFF" .

echo "Generated differential flame graphs $DIFF_GRAPH and $NEG_DIFF"