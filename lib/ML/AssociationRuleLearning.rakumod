
use v6.d;

use ML::AssociationRuleLearning::Eclat;

unit module ML::AssociationRuleLearning;

sub eclat(%trans, Numeric :$min-support!, Numeric :$max-number-of-items = Inf, Str :$sep = '∩') is export {

}