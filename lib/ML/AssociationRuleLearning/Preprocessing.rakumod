use v6.d;

use Data::Reshapers;


#------------------------------------------------------------
role ML::AssociationRuleLearning::Preprocessing {

    #------------------------------------------------------------
    method is-positional-of-maps($arr -->Bool) {
        $arr ~~ Positional and ([and] $arr.map({ $_ ~~ Map }))
    }

    method is-map-of-sets($arr -->Bool) {
        $arr ~~ Map and ([and] $arr.map({ $_ ~~ Set }))
    }

    method is-list-of-lists($arr -->Bool) {
        $arr ~~ List and ([and] $arr.map({ $_ ~~ List }))
    }

    ##-------------------------------------------------------
    ## Item to transactions indexes
    ##-------------------------------------------------------
    ## Vertical transactions database

    method item-to-transactions-indexes($transactions) {
        my $k = 0;
        $.nTransactions = $transactions.elems;
        return cross-tabulate($transactions.map({ |([|$_] X $k++) }), 0, 1)>>.keys>>.List;
        # I am not sure is this conversion to integer IDs needed --
        # it does not seem to make the computations faster.
        # %itemTransactions = %itemTransactions.map({ $_.key => $_.value>>.Int.List }).Hash;
    }

    ##-------------------------------------------------------
    ## Transpose transaction sets
    ##-------------------------------------------------------
    ## Transpose a map of sets into a map of sets

    method transpose-transaction-sets(Set %transactions) {
        my $items = %transactions.values>>.keys.flat.unique;

        my %itemInverseIndexes = Hash($items Z=> Set());

        for %transactions.kv -> $tr, $set {
            for $set.kv -> $item, $val {
                %itemInverseIndexes{$item} (|)= $tr
            }
        }

        return %itemInverseIndexes;
    }

}
