use v6.d;

use ML::AssociationRuleLearning::Apriori;
use ML::AssociationRuleLearning::Eclat;
use Data::Reshapers;
use Data::TypeSystem::Predicates;
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
our sub apriori($transactions, *@args, *%args) is export {
    return frequent-sets($transactions, |@args, method => 'Apriori', |%args);
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
our sub eclat($transactions, *@args, *%args) is export {
    return frequent-sets($transactions, |@args, method => 'Eclat', |%args);
}


#------------------------------------------------------------
#| Find frequent sets.
#| C<$transactions> -- transactions data.
#| C<:$min-support> -- minimum support for frequent sets found; can be an integer or a frequency.
#| C<:$max-number-of-items> -- maximum length of frequent sets found.
#| C<:$min-number-of-items> -- minimum length of frequent sets found.
#| C<:$method> -- method to use, one of Whatever, 'Apriori', or 'Eclat'.
#| C<:$counts> -- should counts be returned or frequencies?.
#| C<:$sep> -- separator to use in data preprocessing.
#| C<:$set-set> -- separator to use in transactional database building.
#| C<:$object> -- should an object be returned or not?
our proto frequent-sets($transactions, |) is export {*}

multi sub frequent-sets($transactions, Numeric $min-support, *%args) {
    return frequent-sets($transactions, :$min-support, |%args);
}

multi sub frequent-sets($transactions is copy,
                        Numeric :$min-support! is copy,
                        Numeric :$min-number-of-items = 1,
                        Numeric :$max-number-of-items = Inf,
                        :$method is copy = Whatever,
                        Bool :$counts = False,
                        Str :$sep = ':',
                        Str :$set-sep = '∩',
                        Bool :$object = False) {


    if $method.isa(Whatever) { $method = 'Eclat' };

    if !($method ~~ Str && $method.lc ∈ <eclat apriori>) {
        die 'The value of the argument method is expected to be Whatever one of \'Eclat\' or \'Apriori\'.';
    }

    if $transactions.elems == 0 {
        warn 'Empty transactions.';
        return Nil;
    }

    my $fsObj;
    if $method.lc eq 'apriori' {
        $fsObj = ML::AssociationRuleLearning::Apriori.new;
    } else {
        $fsObj = ML::AssociationRuleLearning::Eclat.new;
    }

    if $fsObj.is-positional-of-maps($transactions) {
        # Assuming that we given a dataset with named columns.
        # Each row is a transaction, we concatenate the column names to the column values
        # and make a list of lists.
        $transactions = $transactions.map({ ($_.keys X~ $sep) Z~ $_.values })>>.List.List;

        return frequent-sets($transactions, :$min-support, :$min-number-of-items, :$max-number-of-items, :$method, :$sep, :$set-sep, :$object, :$counts);
    }

    if $min-support < 0 {
        die 'The argument min-support is expected to be a non-negative number';
    }

    $fsObj.preprocess($transactions);
    $min-support = $min-support > 1 ?? $min-support / $fsObj.nTransactions !! $min-support;
    my @res = $fsObj.frequent-sets(:$min-support, :$min-number-of-items, :$max-number-of-items, :$counts, sep => $set-sep);

    return $object ?? $fsObj !! @res;
}

#------------------------------------------------------------
#| Find association rules
#| C<$transactions> -- transactions data.
#| C<:$min-support> -- minimum support for association rules found; can be an integer or a frequency.
#| C<:$min-confidence> -- minimum confidence for association rules found; can be an integer or a frequency.
#| C<:$max-number-of-items> -- maximum length of frequent sets found.
#| C<:$min-number-of-items> -- minimum length of frequent sets found.
#| C<:$method> -- method to use, one of Whatever, 'Apriori', or 'Eclat'.
#| C<:$sep> -- separator to use in data preprocessing.
#| C<:$set-set> -- separator to use in transactional database building.
#| C<:$object> -- should an object be returned or not?
our proto association-rules($transactions, |) is export {*}

multi sub association-rules($transactions, Numeric $min-support, Numeric $min-confidence, *%args) {
    return association-rules($transactions, :$min-support, :$min-confidence, |%args);
}

multi sub association-rules($transactions is copy,
                            Numeric :$min-support! is copy,
                            Numeric :$min-confidence! is copy,
                            Numeric :$min-number-of-items = 1,
                            Numeric :$max-number-of-items = Inf,
                            :$method is copy = Whatever,
                            Str :$sep = ':',
                            Str :$set-sep = '∩',
                            Bool :$object = False) {

    if $method.isa(Whatever) { $method = 'Eclat' };

    if !($method ~~ Str && $method.lc ∈ <eclat apriori>) {
        die 'The value of the argument method is expected to be Whatever one of \'Eclat\' or \'Apriori\'.';
    }

    my ML::AssociationRuleLearning::Eclat $eclatObj .= new;
    if $method.lc eq 'apriori' {

        my ML::AssociationRuleLearning::Apriori $aprioriObj =
                apriori($transactions, :$min-support, :$min-number-of-items, :$max-number-of-items, :$sep, :$set-sep):object:!counts;

        # Using Eclat-based measures is faster than using Apriori.
        $eclatObj.preprocess($transactions);
        $eclatObj.freqSets = $aprioriObj.freqSets;

    } else {
        $eclatObj = eclat($transactions, :$min-support, :$min-number-of-items, :$max-number-of-items, :$sep, :$set-sep):object:!counts;
    }

    my @arules = $eclatObj.find-rules($min-confidence);

    return $object ?? $eclatObj !! @arules;
}