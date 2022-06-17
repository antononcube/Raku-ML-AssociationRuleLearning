#!/usr/bin/env perl6

use lib '.';
use lib './lib';

use ML::AssociationRuleLearning;
use ML::AssociationRuleLearning::Eclat;
use Data::ExampleDatasets;
use Data::Reshapers;
use Data::Summarizers;
use Hash::Merge;

#my $url = 'https://raw.githubusercontent.com/antononcube/Raku-Data-Reshapers/main/resources/dfTitanic.csv';
#my @dsTitanic = example-dataset($url, :headers);
my @dsTitanic = get-titanic-dataset();
records-summary(@dsTitanic);

say @dsTitanic.pick(3);

my %itemTransactions;
say (@dsTitanic[0].keys (-) 'id').keys;
for (@dsTitanic[0].keys (-) 'id').keys -> $colName {
    # This is to visualize
    #%itemTransactions = merge-hash( %itemTransactions, cross-tabulate(@dsTitanic[^12], $colName, 'id').map({ $_.key => $_.value.keys }).Hash );
    %itemTransactions = merge-hash( %itemTransactions, cross-tabulate(@dsTitanic, $colName, 'id'));
}

#say to-pretty-table(%itemTransactions);
#say %itemTransactions;

my ML::AssociationRuleLearning::Eclat $eclatObj .= new;

#`(
say $eclatObj.intersect(%itemTransactions, <male died>);
say $eclatObj.intersect(%itemTransactions, <male died>, <3rd died>);

say $eclatObj.support(%itemTransactions, <male died>, <3rd died>);

say $eclatObj.extend(%itemTransactions, <male died>, <3rd died>).map({ $_.key => $_.value.elems });

say (<male died> leg <3rd died>) === More;
)

#.say for $eclatObj.frequent-sets(%itemTransactions, min-support => 171);
say to-pretty-table($eclatObj.frequent-sets(%itemTransactions, min-support => 171).map({ %( Frequent-set => $_.key.join(' '), Support => $_.value) }), align => 'l');