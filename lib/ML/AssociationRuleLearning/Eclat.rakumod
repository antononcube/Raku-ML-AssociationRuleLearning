use v6.d;

class ML::AssociationRuleLearning::Eclat {

    has %!itemTransactions;
    has @!freqSets;

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

    multi method support(%itemTrans, $items) {
        return self.intersect(%itemTrans, $items).elems;
    }

    multi method support(%itemTrans, $items1, $items2) {
        return self.intersect(%itemTrans, $items1, $items2).elems;
    }

    ##-------------------------------------------------------
    ## Eclat
    ##-------------------------------------------------------

    method frequent-sets(%itemTrans,
                         Numeric :$min-support!,
                         Numeric :$min-number-of-items = 1,
                         Numeric :$max-number-of-items = Inf,
                         Str :$sep = '∩') {

        # Reset accumulated frequent sets holder
        @!freqSets = ();

        # Get transactions
        %!itemTransactions = %itemTrans.clone;

        # Find initial frequent sets
        my @P = %itemTrans.grep({ $_.value.elems ≥ $min-support }).map({ ($_.key,) }).Array;

        # Main Eclat loop
        self.find-freq-sets-rec(@P, :$min-support, :$max-number-of-items, :$sep);

        # Get frequent sets
        my @res = @!freqSets.sort.List;

        # Filter by min length
        @res = @res.grep({ $_.elems ≥ $min-number-of-items }).List;

        return @res.map({ $_ => self.support(%!itemTransactions, $_) }).Array;
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