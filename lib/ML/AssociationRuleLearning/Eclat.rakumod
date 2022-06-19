use v6.d;

use ML::AssociationRuleLearning::Measures;
use ML::AssociationRuleLearning::Preprocessing;
use ML::AssociationRuleLearning::RuleFinding;

class ML::AssociationRuleLearning::Eclat
        does ML::AssociationRuleLearning::Preprocessing
        does ML::AssociationRuleLearning::Measures
        does ML::AssociationRuleLearning::RuleFinding {

    has %.itemTransactions;
    has @.freqSets;
    has $.nTransactions is rw = Whatever;
    has @.result is rw;

    ##-------------------------------------------------------
    ## Intersect transactions items transactions
    ##-------------------------------------------------------

    multi method intersect(%itemTrans, @items) {
        my $r = %itemTrans{@items.head};
        $r = %itemTrans{$_} (&) $r for @items.tail(@items.elems - 1).List;
        return $r;
    }

    multi method intersect(%itemTrans, @items1, @items2) {
        my $s1 = self.intersect(%itemTrans, @items1);
        my $s2 = self.intersect(%itemTrans, @items2);
        return $s1 (&) $s2;
    }

    ##-------------------------------------------------------
    ## Extend transactions
    ##-------------------------------------------------------

    multi method extend(%itemTrans, $items, :$sep = '∩') {
        %itemTrans{$items.join($sep)} = self.intersect(%itemTrans, $items);
        return %itemTrans;
    }

    multi method extend(%itemTrans, $items1, $items2, :$sep = '∩') {
        my @items = ($items1 (|) $items2).keys;
        %itemTrans{@items.join($sep)} = self.intersect(%itemTrans, $items1, $items2);
        return %itemTrans;
    }

    ##-------------------------------------------------------
    ## Support
    ##-------------------------------------------------------

    multi method support(%itemTrans, $items, Bool :$count = False) {
        my $tcount = self.intersect(%itemTrans, $items).elems;
        return $count ?? $tcount !! $tcount / $!nTransactions;
    }

    multi method support(%itemTrans, $items1, $items2, Bool :$count = False) {
        my $tcount = self.intersect(%itemTrans, $items1, $items2).elems;
        return $count ?? $tcount !! $tcount / $!nTransactions;
    }

    ##-------------------------------------------------------
    ## Preprocess
    ##-------------------------------------------------------
    method preprocess($transData) {

        if self.is-map-of-sets($transData) {
            # Assuming the we are given an incidence matrix in "row-wise" form.

            $!nTransactions = $transData.elems;
            %!itemTransactions = self.transpose-transaction-sets($transData);

        } elsif self.is-list-of-lists($transData) {
            # List of lists -- "primary" use case

            $!nTransactions = $transData.elems;
            %!itemTransactions = self.item-to-transactions-indexes($transData);

        } else {
            die 'Do not know how to process the transactions argument.'
        }

        return %!itemTransactions;
    }


    ##-------------------------------------------------------
    ## Eclat
    ##-------------------------------------------------------

    method frequent-sets(Numeric :$min-support!,
                         Numeric :$min-number-of-items = 1,
                         Numeric :$max-number-of-items = Inf,
                         Bool :$counts = False,
                         Str :$sep = '∩') {

        if !( $!nTransactions ~~ Numeric && $!nTransactions > 0) {
            die 'No pre-processed transactions. ($!nTransactions is not a positive number).';
        }

        if ! %!itemTransactions {
            die 'No pre-processed transactions. (%!itemTransactions is empty).';
        }

        # Reset accumulated frequent sets holder
        @!freqSets = ();

        # Find initial frequent sets
        my @P = %!itemTransactions.grep({ $_.value.elems / self.nTransactions ≥ $min-support }).map({ ($_.key,) }).Array;

        if !@P {
            warn "All items have support less than $min-support (≈{ceiling($min-support * self.nTransactions)} transactions.)";
            return Empty;
        }

        # Main Eclat loop
        self.find-freq-sets-rec(@P, :$min-support, :$max-number-of-items, :$sep);

        # Get frequent sets
        my @res = @!freqSets.sort.List;

        # Filter by min length
        @res = @res.grep({ $_.elems ≥ $min-number-of-items }).List;

        @res = @res.map({ $_ => self.support(%!itemTransactions, $_, count => $counts) }).Array;

        @!result = @res;
        return @res;
    }

    ##-------------------------------------------------------
    ## Eclat recursive
    ##-------------------------------------------------------

    method find-freq-sets-rec(@P is copy, :$min-support, :$max-number-of-items) {

        @P = @P.grep({ $_.elems ≤ $max-number-of-items }).List;

        for @P -> $Xa {
            @!freqSets = @!freqSets.push($Xa);

            my @P2;

            for @P.grep({ $Xa leg $_ === More }).List -> $Xb {

                my $Xab = ($Xa (|) $Xb).keys.sort.List;
                my $Xab-a = ($Xab (-) $Xa).keys.List.sort.List;

                if $Xab.elems ≤ $max-number-of-items {

                    %!itemTransactions = self.extend(%!itemTransactions, $Xa, $Xab-a);

                    my $tXab = self.support(%!itemTransactions, $Xab);

                    if $tXab ≥ $min-support {
                        @P2.push($Xab)
                    }
                }
            }

            if @P2 {
                self.find-freq-sets-rec(@P2, :$min-support, :$max-number-of-items)
            }

        }
    }

}