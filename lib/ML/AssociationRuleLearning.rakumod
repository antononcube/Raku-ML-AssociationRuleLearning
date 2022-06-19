use v6.d;

use ML::AssociationRuleLearning::Apriori;
use ML::AssociationRuleLearning::Eclat;
use Data::Reshapers;
use Data::Reshapers::Predicates;
use Hash::Merge;

unit module ML::AssociationRuleLearning;


#------------------------------------------------------------
#| Find frequent sets using the Apriori algorithm.
#| C<$transactions> -- transactions data.
#| C<:$min-support> -- minimum support for frequent sets found; can be an integer or a frequency.
#| C<:$max-number-of-items> -- maximum length of frequent sets found.
#| C<:$min-number-of-items> -- minimum length of frequent sets found.
#| C<:$counts> -- should counts be returned or frequencies?.
#| C<:$sep> -- separator to use in data preprocessing.
#| C<:$set-set> -- separator to use in transactional database building.
#| C<:$object> -- should an object be returned or not?
proto apriori($transactions, |) is export {*}

multi sub apriori($transactions, Numeric $min-support, *%args) {
    return apriori($transactions, :$min-support, |%args);
}

multi sub apriori($transactions is copy,
                Numeric :$min-support! is copy,
                Numeric :$min-number-of-items = 1,
                Numeric :$max-number-of-items = Inf,
                Bool :$counts = False,
                Str :$sep = ':',
                Str :$set-sep = '∩',
                Bool :$object = False) {

    my ML::AssociationRuleLearning::Apriori $aprioriObj .= new;

    if $transactions.elems == 0 {
        warn 'Empty transactions.';
        return Nil;
    }

    if $aprioriObj.is-positional-of-maps($transactions) {
        # Assuming that we given a dataset with named columns.
        # Each row is a transaction, we concatenate the column names to the column values
        # and make a list of lists.
        $transactions = $transactions.map({ ($_.keys X~ $sep) Z~ $_.values })>>.List.List;

        return apriori($transactions, :$min-support, :$min-number-of-items, :$max-number-of-items, :$sep, :$set-sep, :$object);
    }

    if $min-support < 0 {
        die 'The argument min-support is expected to be a non-negative number';
    }

    $aprioriObj.preprocess($transactions);
    $min-support = $min-support > 1 ?? $min-support / $aprioriObj.nTransactions !! $min-support;
    my @res = $aprioriObj.frequent-sets(:$min-support, :$min-number-of-items, :$max-number-of-items, :$counts, sep => $set-sep);

    return $object ?? $aprioriObj !! @res;
}


#------------------------------------------------------------
#| Find frequent sets using the Eclat algorithm.
#| C<$transactions> -- transactions data.
#| C<:$min-support> -- minimum support for frequent sets found; can be an integer or a frequency.
#| C<:$max-number-of-items> -- maximum length of frequent sets found.
#| C<:$min-number-of-items> -- minimum length of frequent sets found.
#| C<:$counts> -- should counts be returned or frequencies?.
#| C<:$sep> -- separator to use in data preprocessing.
#| C<:$set-set> -- separator to use in transactional database building.
#| C<:$object> -- should an object be returned or not?
proto eclat($transactions, |) is export {*}

multi sub eclat($transactions, Numeric $min-support, *%args) {
    return eclat($transactions, :$min-support, |%args);
}

multi sub eclat($transactions is copy,
                Numeric :$min-support! is copy,
                Numeric :$min-number-of-items = 1,
                Numeric :$max-number-of-items = Inf,
                Bool :$counts = False,
                Str :$sep = ':',
                Str :$set-sep = '∩',
                Bool :$object = False) {

    my ML::AssociationRuleLearning::Eclat $eclatObj .= new;

    if $transactions.elems == 0 {
        warn 'Empty transactions.';
        return Nil;
    }

    if $eclatObj.is-positional-of-maps($transactions) {
        # Assuming that we given a dataset with named columns.
        # Each row is a transaction, we concatenate the column names to the column values
        # and make a list of lists.
        $transactions = $transactions.map({ ($_.keys X~ $sep) Z~ $_.values })>>.List.List;

        return eclat($transactions, :$min-support, :$min-number-of-items, :$max-number-of-items, :$sep, :$set-sep, :$object);
    }

    if $min-support < 0 {
        die 'The argument min-support is expected to be a non-negative number';
    }

    $eclatObj.preprocess($transactions);
    $min-support = $min-support > 1 ?? $min-support / $eclatObj.nTransactions !! $min-support;
    my @res = $eclatObj.frequent-sets(:$min-support, :$min-number-of-items, :$max-number-of-items, :$counts, sep => $set-sep);

    return $object ?? $eclatObj !! @res;
}

#------------------------------------------------------------
#| Find association rules
proto association-rules($transactions, |) is export {*}

multi sub association-rules($transactions, Numeric $min-support, Numeric $min-confidence, *%args) {
    return association-rules($transactions, :$min-support, :$min-confidence, |%args);
}

multi sub association-rules($transactions is copy,
                            Numeric :$min-support! is copy,
                            Numeric :$min-confidence! is copy,
                            Numeric :$min-number-of-items = 1,
                            Numeric :$max-number-of-items = Inf,
                            Str :$sep = ':',
                            Str :$set-sep = '∩',
                            :$method is copy = Whatever) {

    if $method.isa(Whatever) { $method = 'eclat' };

    if !( $method ~~ Str && $method.lc ∈ <eclat apriori>) {
        die 'The value of the argument method is expected to be Whatever one of \'Eclat\' or \'Apriori\'.';
    }

    my $fsObj;
    if $method.lc eq 'apriori' {
         $fsObj = apriori($transactions, :$min-support, :$min-number-of-items, :$max-number-of-items, :$sep, :$set-sep):object:!counts;
    } else {
        $fsObj = eclat($transactions, :$min-support, :$min-number-of-items, :$max-number-of-items, :$sep, :$set-sep):object:!counts;
    }

    my @arules = $fsObj.find-rules($min-confidence);

    return @arules;
}