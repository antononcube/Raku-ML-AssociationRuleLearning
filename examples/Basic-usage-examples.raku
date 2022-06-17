#!/usr/bin/env perl6

use lib '.';
use lib './lib';

use ML::AssociationRuleLearning;
use Data::ExampleDatasets;
use Data::Reshapers;
use Data::Summarizers;

#my $url = 'https://raw.githubusercontent.com/antononcube/Raku-Data-Reshapers/main/resources/dfTitanic.csv';
#my @dsTitanic = example-dataset($url, :headers);
my @dsTitanic = get-titanic-dataset();
records-summary(@dsTitanic);

say @dsTitanic.pick(3);


say @dsTitanic.map({ $_.values.List }).Array.raku;

my $tstart = now;
my @freqSets = eclat(@dsTitanic.map({ $_.values.List }).Array, min-support => 171, min-number-of-items => 2, max-number-of-items => 6);
my $tend = now;
say "Titanic frequent sets finding time : {$tend - $tstart}";

say @freqSets;

say to-pretty-table(@freqSets.map({ %( Frequent-set => $_.key.join(' '), Support => $_.value) }), align => 'l');
#
#my @freqSets2 = eclat(@dsTitanic, min-support => 171, max-number-of-items => 3);
#
#say to-pretty-table(@freqSets2.map({ %( Frequent-set => $_.key.join(' '), Support => $_.value) }), align => 'l');
