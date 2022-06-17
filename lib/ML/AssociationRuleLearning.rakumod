use v6.d;

use ML::AssociationRuleLearning::Eclat;
use Data::Reshapers;
use Data::Reshapers::Predicates;
use Hash::Merge;

unit module ML::AssociationRuleLearning;

#------------------------------------------------------------
sub is-map-of-sets($arr) {
    $arr ~~ Map and ([and] $arr.map({ $_ ~~ Set }))
}

sub is-list-of-lists($arr) {
    $arr ~~ List and ([and] $arr.map({ $_ ~~ List }))
}

#------------------------------------------------------------
proto eclat($transactions, |) is export {*}

multi sub eclat($transactions, Numeric $min-support, *%args) {
    return eclat($transactions, :$min-support, |%args);
}

multi sub eclat($transactions is copy,
                Numeric :$min-support!,
                Numeric :$min-number-of-items = 1,
                Numeric :$max-number-of-items = Inf,
                Str :$sep = ':',
                Str :$set-sep = '∩'
                ) {

    my ML::AssociationRuleLearning::Eclat $eclatObj .= new;

    my %itemTransactions;

    if $transactions.elems == 0 {
        warn 'Empty transactions.';
        return Nil;
    }

    if is-array-of-hashes($transactions) {
        # Assuming that we given a dataset
        $transactions = $transactions.map({ ($_.keys X~ $sep) Z~ $_.values })>>.List.List;

        return eclat($transactions, :$min-support, :$min-number-of-items, :$max-number-of-items, :$sep, :$set-sep);

    } elsif is-map-of-sets($transactions) {
        # Assuming the we are given a "column-wise" database
        %itemTransactions = $transactions;

    } elsif is-list-of-lists($transactions) {
        # List of lists -- "primary" use case
        my $k = 0;
        %itemTransactions = cross-tabulate($transactions.map({ |([|$_] X $k++) }), 0, 1)>>.keys>>.List;
        # I am not sure is this conversion to integer IDs needed --
        # it does not seem to make the computations faster.
        # %itemTransactions = %itemTransactions.map({ $_.key => $_.value>>.Int.List }).Hash;

    } else {
        die 'Do not know how to process the transactions argument.'
    }

    my @res = $eclatObj.frequent-sets(%itemTransactions, :$min-support, :$min-number-of-items, :$max-number-of-items, sep => $set-sep);

    return @res;
}