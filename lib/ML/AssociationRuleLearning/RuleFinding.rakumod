use v6.d;

use Data::Reshapers;

role ML::AssociationRuleLearning::RuleFinding {

    ##-------------------------------------------------------
    ## Find association rules
    ##-------------------------------------------------------

    multi method find-rules(Numeric $min-confidence) {
        return self.freqSets.map({ |self.find-rules($_, $min-confidence) }).List;
    }

    multi method find-rules($items, Numeric $min-confidence) {
        return self.find-rules(self.itemTransactions, $items, $min-confidence);
    }

    multi method find-rules(%itemTrans, $items, Numeric $min-confidence) {

        my @antecedents = $items.combinations[1 .. *- 2];
        my @candidates = @antecedents.map({ $_ => ($items (-) $_).keys.List }).List;

        my @res = do
        for @candidates -> $c {
            %( antecendent => $c.key,
               consequent => $c.value,
               support => self.support(%itemTrans, $c.key, $c.value),
               count => self.support(%itemTrans, $c.key, $c.value):count,
               confidence => self.confidence(%itemTrans, $c.key, $c.value),
               lift => self.lift(%itemTrans, $c.key, $c.value),
               leverage => self.leverage(%itemTrans, $c.key, $c.value),
               conviction => self.convication(%itemTrans, $c.key, $c.value))
        }

        @res = @res.grep({ $_<confidence> ≥ $min-confidence }).List;
        return @res;
    }
}
