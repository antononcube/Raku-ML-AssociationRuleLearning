use v6.d;

use Data::Reshapers;

role ML::AssociationRuleLearning::Measures {

    ##-------------------------------------------------------
    ## Confidence
    ##-------------------------------------------------------

    method confidence(%itemTrans, $items1, $items2) {
        return self.support(%itemTrans, $items1, $items2) / self.support(%itemTrans, $items1);
    }

    ##-------------------------------------------------------
    ## Lift
    ##-------------------------------------------------------

    method lift(%itemTrans, $items1, $items2) {
        return self.confidence(%itemTrans, $items1, $items2) / self.support(%itemTrans, $items2);
    }

    ##-------------------------------------------------------
    ## Leverage
    ##-------------------------------------------------------

    method leverage(%itemTrans, $items1, $items2) {
        return self.support(%itemTrans, $items1, $items2) - self.support(%itemTrans, $items1) * self.support(%itemTrans,
                $items2);
    }

    ##-------------------------------------------------------
    ## Conviction
    ##-------------------------------------------------------

    method conviction(%itemTrans, $items1, $items2) {
        return (1 - self.support(%itemTrans, $items2)) / (1 - self.confidence(%itemTrans, $items1, $items2));
    }

}
