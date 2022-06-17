# Raku ML::AssociationRuleLearning

Raku package for association rule learning.

This repository has the code of a Raku package for
[Association Rule Learning (ARL)](https://en.wikipedia.org/wiki/Association_rule_learning)
functions, [Wk1].

ARL framework includes the algorithms 
[Apriori](https://en.wikipedia.org/wiki/Apriori_algorithm) 
and 
[Eclat](https://en.wikipedia.org/wiki/Association_rule_learning#Eclat_algorithm), 
and the measures 
[confidence](https://en.wikipedia.org/wiki/Association_rule_learning#Confidence),
[lift](https://en.wikipedia.org/wiki/Association_rule_learning#Lift), and 
[conviction](https://en.wikipedia.org/wiki/Association_rule_learning#Conviction).

For computational introduction to ARL utilization (in Mathematica) see the article
["Movie genre associations"](https://mathematicaforprediction.wordpress.com/2013/10/06/movie-genre-associations/),
[AA1].

The examples below use the packages
["Data::Generators"](https://raku.land/cpan:ANTONOV/Data::Generators),
["Data::Reshapers"](https://raku.land/cpan:ANTONOV/Data::Reshapers), and
["Data::Summarizers"](https://raku.land/cpan:ANTONOV/Data::Summarizers), described in the article
["Introduction to data wrangling with Raku"](https://rakuforprediction.wordpress.com/2021/12/31/introduction-to-data-wrangling-with-raku/),
[AA2].

-------

## Installation

Via zef-ecosystem:

```shell
zef install ML::AssociationRuleLearning
```

From GitHub:

```shell
zef install https://github.com/antononcube/Raku-ML-AssociationRuleLearning
```


-------

## Usage examples

### Frequent sets

Here we get the Titanic dataset (from "Data::Reshapers") and summarize it:

```perl6
use Data::Reshapers;
use Data::Summarizers;
my @dsTitanic = get-titanic-dataset();
records-summary(@dsTitanic);
```
```
# +----------------+-----------------+----------------+-------------------+---------------+
# | passengerClass | id              | passengerAge   | passengerSurvival | passengerSex  |
# +----------------+-----------------+----------------+-------------------+---------------+
# | 3rd => 709     | 947     => 1    | 20      => 334 | died     => 809   | male   => 843 |
# | 1st => 323     | 750     => 1    | -1      => 263 | survived => 500   | female => 466 |
# | 2nd => 277     | 59      => 1    | 30      => 258 |                   |               |
# |                | 315     => 1    | 40      => 190 |                   |               |
# |                | 1233    => 1    | 50      => 88  |                   |               |
# |                | 716     => 1    | 60      => 57  |                   |               |
# |                | 505     => 1    | 0       => 56  |                   |               |
# |                | (Other) => 1302 | (Other) => 63  |                   |               |
# +----------------+-----------------+----------------+-------------------+---------------+
```

**Problem:** Find all combinations values of the variables "passengerAge", "passengerClass", "passengerSex", and
"passengerSurvival" that appear more 200 times in the Titanic dataset.

Here is how we use Eclat's implementation to give an answer:

```perl6
use ML::AssociationRuleLearning;
my @freqSets = eclat(@dsTitanic.map({ $_.values.List }).Array, min-support => 200, min-number-of-items => 2, max-number-of-items => Inf);
@freqSets.elems
```
```
# 11
```

The function `eclat` returns the frequent sets together with their support.

Here we tabulate the result:

```perl6
say to-pretty-table(@freqSets.map({ %( Frequent-set => $_.key.join(' '), Support => $_.value) }), align => 'l');
```
```
# +---------+-----------------+
# | Support | Frequent-set    |
# +---------+-----------------+
# | 208     | -1 3rd          |
# | 200     | 1st survived    |
# | 206     | 20 3rd          |
# | 208     | 20 died         |
# | 208     | 20 male         |
# | 528     | 3rd died        |
# | 418     | 3rd died male   |
# | 216     | 3rd female      |
# | 493     | 3rd male        |
# | 682     | died male       |
# | 339     | female survived |
# +---------+-----------------+
```

We can verify the result by looking into these group counts, [AA2]:

```perl6
my $obj = @dsTitanic ;
$obj = group-by( $obj, <passengerClass passengerSex>) ;
.say for $obj>>.elems
```
```
# 3rd.male => 493
# 2nd.male => 171
# 2nd.female => 106
# 3rd.female => 216
# 1st.male => 179
# 1st.female => 144
```

### Association rules

**TBD...**


-------

## References

### Articles

[Wk1] Wikipedia entry, ["Association Rule Learning"](https://en.wikipedia.org/wiki/Association_rule_learning).

[AA1] Anton Antonov,
["Movie genre associations"](https://mathematicaforprediction.wordpress.com/2013/10/06/movie-genre-associations/),
(2013),
[MathematicaForPrediction at WordPress](https://mathematicaforprediction.wordpress.com).

[AA2] Anton Antonov,
["Introduction to data wrangling with Raku"](https://rakuforprediction.wordpress.com/2021/12/31/introduction-to-data-wrangling-with-raku/),
(2021),
[RakuForPrediction at WordPress](https://rakuforprediction.wordpress.com).

### Packages

[AAp1] Anton Antonov,
[Implementation of the Apriori algorithm in Mathematica](https://github.com/antononcube/MathematicaForPrediction/blob/master/AprioriAlgorithm.m),
(2014-2016),
[MathematicaForPrediction at GitHub/antononcube](https://github.com/antononcube/MathematicaForPrediction/).

[AAp2] Anton Antonov,
[Implementation of the Eclat algorithm in Mathematica](https://github.com/antononcube/MathematicaForPrediction/blob/master/EclatAlgorithm.m),
(2022),
[MathematicaForPrediction at GitHub/antononcube](https://github.com/antononcube/MathematicaForPrediction/).

[AAp3] Anton Antonov,
[Data::Generators Raku package](https://github.com/antononcube/Raku-Data-Generators),
(2021),
[GitHub/antononcube](https://github.com/antononcube).

[AAp4] Anton Antonov,
[Data::Reshapers Raku package](https://github.com/antononcube/Raku-Data-Reshapers),
(2021),
[GitHub/antononcube](https://github.com/antononcube).

[AAp5] Anton Antonov,
[Data::Summarizers Raku package](https://github.com/antononcube/Raku-Data-Summarizers),
(2021),
[GitHub/antononcube](https://github.com/antononcube).


