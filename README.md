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

## Frequent sets finding 

Here we get the Titanic dataset (from "Data::Reshapers") and summarize it:

```perl6
use Data::Reshapers;
use Data::Summarizers;
my @dsTitanic = get-titanic-dataset();
records-summary(@dsTitanic);
```
```
# +----------------+-------------------+---------------+-----------------+----------------+
# | passengerAge   | passengerSurvival | passengerSex  | id              | passengerClass |
# +----------------+-------------------+---------------+-----------------+----------------+
# | 20      => 334 | died     => 809   | male   => 843 | 300     => 1    | 3rd => 709     |
# | -1      => 263 | survived => 500   | female => 466 | 744     => 1    | 1st => 323     |
# | 30      => 258 |                   |               | 949     => 1    | 2nd => 277     |
# | 40      => 190 |                   |               | 152     => 1    |                |
# | 50      => 88  |                   |               | 257     => 1    |                |
# | 60      => 57  |                   |               | 223     => 1    |                |
# | 0       => 56  |                   |               | 1010    => 1    |                |
# | (Other) => 63  |                   |               | (Other) => 1302 |                |
# +----------------+-------------------+---------------+-----------------+----------------+
```

**Problem:** Find all combinations values of the variables "passengerAge", "passengerClass", "passengerSex", and
"passengerSurvival" that appear more 200 times in the Titanic dataset.

Here is how we use Eclat's implementation to give an answer:

```perl6
use ML::AssociationRuleLearning;
my @freqSets = eclat(@dsTitanic.map({ $_.values.List }).Array, min-support => 200, min-number-of-items => 2, max-number-of-items => Inf):counts;
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
my $obj = group-by( @dsTitanic, <passengerClass passengerSex>);
.say for $obj>>.elems.grep({ $_.value >= 200 });
$obj = group-by( @dsTitanic, <passengerClass passengerSurvival passengerSex>);
.say for $obj>>.elems.grep({ $_.value >= 200 });
```
```
# 3rd.male => 493
# 3rd.female => 216
# 3rd.died.male => 418
```

**Remark:** `elcat`'s argument `min-support` can take both integers greater than 1 and frequencies between 0 and 1.
(If an integer greater than one is given, then the corresponding frequency is derived.)

-------

## Association rules finding

Here we find association rules with min support 0.3 and min confidence 0.7:

```perl6
association-rules(@dsTitanic, min-support => 0.3, min-confidence => 0.7)
==> to-pretty-table
```
```
# +----------+-------------------------------------------+------------+------------------------+------------+----------+----------+-------+
# | support  |                antecendent                | conviction |       consequent       | confidence | leverage |   lift   | count |
# +----------+-------------------------------------------+------------+------------------------+------------+----------+----------+-------+
# | 0.403361 |             passengerClass:3rd            |  1.496229  | passengerSurvival:died |  0.744711  | 0.068615 | 1.204977 |  528  |
# | 0.521008 |             passengerSex:male             |  2.000009  | passengerSurvival:died |  0.809015  | 0.122996 | 1.309025 |  682  |
# | 0.521008 |           passengerSurvival:died          |  2.267729  |   passengerSex:male    |  0.843016  | 0.122996 | 1.309025 |  682  |
# | 0.319328 |    passengerClass:3rd passengerSex:male   |  2.510823  | passengerSurvival:died |  0.847870  | 0.086564 | 1.371894 |  418  |
# | 0.319328 | passengerClass:3rd passengerSurvival:died |  1.708785  |   passengerSex:male    |  0.791667  | 0.059562 | 1.229290 |  418  |
# +----------+-------------------------------------------+------------+------------------------+------------+----------+----------+-------+
```

### Reusing found frequent sets

The function `eclat` takes the adverb ":object" that makes `eclat` return an object of type
`ML::AssociationRuleLearning::Eclat`, which can be "pipelined" to find association rules.

Here we find frequent sets, return the corresponding object, and retrieve the result:

```perl6
my $eclatObj = eclat(@dsTitanic.map({ $_.values.List }).Array, min-support => 0.12, min-number-of-items => 2, max-number-of-items => 6):object;
$eclatObj.result.elems
```
```
# 23
```

Here we find association rules and pretty-print them:

```perl6
$eclatObj.find-rules(min-confidence=>0.7)
==> to-pretty-table 
```
```
# +----------+----------+-------+------------+-------------+------------+------------+----------+
# |   lift   | leverage | count | consequent | antecendent | conviction | confidence | support  |
# +----------+----------+-------+------------+-------------+------------+------------+----------+
# | 1.460162 | 0.050076 |  208  |    3rd     |      -1     |  2.191819  |  0.790875  | 0.158900 |
# | 1.092265 | 0.011938 |  185  |    male    |      -1     |  1.200349  |  0.703422  | 0.141329 |
# | 1.309025 | 0.122996 |  682  |    male    |     died    |  2.267729  |  0.843016  | 0.521008 |
# | 1.309025 | 0.122996 |  682  |    died    |     male    |  2.000009  |  0.809015  | 0.521008 |
# | 1.299438 | 0.027990 |  159  |    male    |   -1 died   |  2.181917  |  0.836842  | 0.121467 |
# | 1.390646 | 0.034121 |  159  |    died    |   -1 male   |  2.717870  |  0.859459  | 0.121467 |
# | 1.229290 | 0.059562 |  418  |    male    |   3rd died  |  1.708785  |  0.791667  | 0.319328 |
# | 1.371894 | 0.086564 |  418  |    died    |   3rd male  |  2.510823  |  0.847870  | 0.319328 |
# | 1.313897 | 0.032122 |  176  |    male    |   20 died   |  2.313980  |  0.846154  | 0.134454 |
# | 1.369117 | 0.036249 |  176  |    died    |   20 male   |  2.482811  |  0.846154  | 0.134454 |
# | 1.904511 | 0.122996 |  339  |  survived  |    female   |  2.267729  |  0.727468  | 0.258976 |
# | 1.168931 | 0.020977 |  190  |    died    |      -1     |  1.376142  |  0.722433  | 0.145149 |
# | 1.204977 | 0.068615 |  528  |    died    |     3rd     |  1.496229  |  0.744711  | 0.403361 |
# | 1.229093 | 0.022498 |  158  |    died    |    -1 3rd   |  1.588999  |  0.759615  | 0.120703 |
# | 1.535313 | 0.042085 |  158  |    3rd     |   -1 died   |  2.721543  |  0.831579  | 0.120703 |
# +----------+----------+-------+------------+-------------+------------+------------+----------+
```

**Remark:** Note that because of the specified min confidence, the number of association rules is "contained" --
a (much) larger number of rules would be produced with, say, `min-confidence=>0.2`.

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


