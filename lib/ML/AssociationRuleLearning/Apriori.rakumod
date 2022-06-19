use v6.d;

use Data::Reshapers;
use ML::AssociationRuleLearning::Preprocessing;
use ML::TriesWithFrequencies;

class ML::AssociationRuleLearning::Apriori
        does ML::AssociationRuleLearning::Preprocessing {

    has @.transactions;
    has @.freqSets;
    has $!freqEnough;
    has ML::TriesWithFrequencies::Trie $!trTrans;
    has $.nTransactions is rw = Whatever;
    has @.result is rw;


    ##-------------------------------------------------------
    ## Scan transaction
    ##-------------------------------------------------------

    method scan-transaction($trans, Int $k, Str :$sep = '∩') {
        my @candidates = $trans.combinations($k);
        return @candidates.grep({ $_[^($_.elems-1)].join($sep) ∈ $!freqEnough && $_.tail ∈ $!freqEnough}).List;
    }

    ##-------------------------------------------------------
    ## Support
    ##-------------------------------------------------------

    multi method support($tr, $items, Bool :$count = False) {
    }

    multi method support($tr, $items1, $items2, Bool :$count = False) {
    }

    ##-------------------------------------------------------
    ## Preprocess
    ##-------------------------------------------------------
    method preprocess($transData) {

        if self.is-map-of-sets($transData) {
            # Assuming the we are given an incidence matrix in "row-wise" form.

            $!nTransactions = $transData.elems;
            @!transactions = $transData.map({ $_.keys }).sort.Array;

        } elsif self.is-list-of-lists($transData) {
            # List of lists -- "primary" use case

            $!nTransactions = $transData.elems;
            @!transactions = $transData.map({ $_.unique.sort.Array }).Array;

        } else {
            die 'Do not know how to process the transactions argument.'
        }

        return @!transactions;
    }


    ##-------------------------------------------------------
    ## Apriori
    ##-------------------------------------------------------

    method frequent-sets(Numeric :$min-support!,
                         Numeric :$min-number-of-items = 1,
                         Numeric :$max-number-of-items = Inf,
                         Bool :$counts = False,
                         Str :$sep = '∩') {

        if !($!nTransactions ~~ Numeric && $!nTransactions > 0) {
            die 'No pre-processed transactions. ($!nTransactions is not a positive number).';
        }

        if ! @!transactions {
            die 'No pre-processed transactions. (%!transactions is empty).';
        }

        # Reset accumulated frequent sets holder
        @!freqSets = ();

        # Find initial, single frequent sets
        # Make single items baskets trie
        my $trBase = trie-create(self.really-flat(@!transactions).map({[$_,]}).Array);

        # Remove the items that are not frequent enough
        $trBase = $trBase.remove-by-threshold($min-support * $!nTransactions);

        # Verify early stop
        if $trBase.leafQ {
            warn "All items have support less than $min-support (≈{ ceiling($min-support * self.nTransactions) } transactions.)";
            return Empty;
        }

        # Initial set of frequent sets
        $!freqEnough = Set($trBase.words.grep({ $_.elems == 1 }).List);

        # Gather the first trie
        my %allTries = 1 => $trBase;

        # Main Apriori loop
        for (2...$max-number-of-items) -> $k {

            # Scan the transactions and get viable candidates
            my @candidates = flatten( @!transactions.map({ self.scan-transaction($_, $k, :$sep) }), max-level=>1);

            # Check should exit the loop
            last if !@candidates;

            # Make trie with viable candidates
            my $trSets = trie-create(@candidates);

            # Remove transactions that are not frequent enough
            my $trSets2 = $trSets.remove-by-threshold($min-support * $!nTransactions);

            # Get frequent sets from the trie
            my @new = $trSets2.words.grep({ $_.elems == $k }).map({ $_.join($sep) }).Array;

            # Exit loop if no new frequent sets
            last if !@new.elems;

            # Update frequent sets
            $!freqEnough (|)= @new;

            # Add to gathered tries
            %allTries.push( $k => $trSets2 );
        }

        # Get frequent sets
        @!freqSets = $!freqEnough.keys.map({ $_.split($sep) }).Array;
        my @res = @!freqSets.sort.List;

        # Filter by min length
        @res = @res.grep({ $_.elems ≥ $min-number-of-items }).List;

        # Get counts from tries
        @res = @res.map({ $_ => %allTries{$_.elems}.retrieve($_).value }).Array;

        # Counts to supports
        if !$counts {
            @res = @res.map({ $_.key => $_.value / $!nTransactions }).Array;
        }

        # Result
        @!result = @res;
        return @res;
    }
}