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
# +-------------------+---------------+-----------------+----------------+----------------+
# | passengerSurvival | passengerSex  | id              | passengerClass | passengerAge   |
# +-------------------+---------------+-----------------+----------------+----------------+
# | died     => 809   | male   => 843 | 309     => 1    | 3rd => 709     | 20      => 334 |
# | survived => 500   | female => 466 | 212     => 1    | 1st => 323     | -1      => 263 |
# |                   |               | 410     => 1    | 2nd => 277     | 30      => 258 |
# |                   |               | 74      => 1    |                | 40      => 190 |
# |                   |               | 1211    => 1    |                | 50      => 88  |
# |                   |               | 27      => 1    |                | 60      => 57  |
# |                   |               | 78      => 1    |                | 0       => 56  |
# |                   |               | (Other) => 1302 |                | (Other) => 63  |
# +-------------------+---------------+-----------------+----------------+----------------+
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
# +-----------------+---------+
# | Frequent-set    | Support |
# +-----------------+---------+
# | -1 3rd          | 208     |
# | 1st survived    | 200     |
# | 20 3rd          | 206     |
# | 20 died         | 208     |
# | 20 male         | 208     |
# | 3rd died        | 528     |
# | 3rd died male   | 418     |
# | 3rd female      | 216     |
# | 3rd male        | 493     |
# | died male       | 682     |
# | female survived | 339     |
# +-----------------+---------+
```

We can verify the result by looking into these group counts, [AA2]:

```perl6
my $obj = group-by( @dsTitanic, <passengerClass passengerSex>);
.say for $obj>>.elems.grep({ $_.value >= 200 });
$obj = group-by( @dsTitanic, <passengerClass passengerSurvival passengerSex>);
.say for $obj>>.elems.grep({ $_.value >= 200 });
```
```
# 3rd.female => 216
# 3rd.male => 493
# 3rd.died.male => 418
```

-------

## Association rules finding

Here we find association rules with min support 0.3 and min confidence 0.7:

```perl6
association-rules(@dsTitanic, min-support => 0.3, min-confidence => 0.7)
==> to-pretty-table
```
```
# +----------+------------+------------------------+----------+-------+----------+------------+-------------------------------------------+
# | leverage | confidence |       consequent       | support  | count |   lift   | conviction |                antecendent                |
# +----------+------------+------------------------+----------+-------+----------+------------+-------------------------------------------+
# | 0.068615 |  0.744711  | passengerSurvival:died | 0.403361 |  528  | 1.204977 |  1.496229  |             passengerClass:3rd            |
# | 0.122996 |  0.809015  | passengerSurvival:died | 0.521008 |  682  | 1.309025 |  2.000009  |             passengerSex:male             |
# | 0.122996 |  0.843016  |   passengerSex:male    | 0.521008 |  682  | 1.309025 |  2.267729  |           passengerSurvival:died          |
# | 0.086564 |  0.847870  | passengerSurvival:died | 0.319328 |  418  | 1.371894 |  2.510823  |    passengerClass:3rd passengerSex:male   |
# | 0.059562 |  0.791667  |   passengerSex:male    | 0.319328 |  418  | 1.229290 |  1.708785  | passengerClass:3rd passengerSurvival:died |
# +----------+------------+------------------------+----------+-------+----------+------------+-------------------------------------------+
```

### Reusing found frequent sets

The function `eclat` takes the adverb ":object" that makes `eclat` return an object of type
`ML::AssociationRuleLearning::Eclat`, which can be "pipelined" to find association rules.

Here we find frequent sets, return the corresponding object, and retrieve the result:

```perl6
my $eclatObj = eclat(@dsTitanic.map({ $_.values.List }).Array, min-support => 171, min-number-of-items => 2, max-number-of-items => 6):object;
$eclatObj.result.elems
```
```
# 18
```

Here we find association rules and pretty-print them:

```perl6
$eclatObj.find-rules(min-confidence=>0.7)
==> to-pretty-table 
```
```
# +-------------+------------+------------+------------+----------+-------+----------+----------+
# | antecendent | conviction | consequent | confidence | support  | count |   lift   | leverage |
# +-------------+------------+------------+------------+----------+-------+----------+----------+
# |     died    |  2.267729  |    male    |  0.843016  | 0.521008 |  682  | 1.309025 | 0.122996 |
# |     male    |  2.000009  |    died    |  0.809015  | 0.521008 |  682  | 1.309025 | 0.122996 |
# |   3rd died  |  1.708785  |    male    |  0.791667  | 0.319328 |  418  | 1.229290 | 0.059562 |
# |   3rd male  |  2.510823  |    died    |  0.847870  | 0.319328 |  418  | 1.371894 | 0.086564 |
# |   20 died   |  2.313980  |    male    |  0.846154  | 0.134454 |  176  | 1.313897 | 0.032122 |
# |   20 male   |  2.482811  |    died    |  0.846154  | 0.134454 |  176  | 1.369117 | 0.036249 |
# |      -1     |  1.200349  |    male    |  0.703422  | 0.141329 |  185  | 1.092265 | 0.011938 |
# |      -1     |  2.191819  |    3rd     |  0.790875  | 0.158900 |  208  | 1.460162 | 0.050076 |
# |    female   |  2.267729  |  survived  |  0.727468  | 0.258976 |  339  | 1.904511 | 0.122996 |
# |     3rd     |  1.496229  |    died    |  0.744711  | 0.403361 |  528  | 1.204977 | 0.068615 |
# |      -1     |  1.376142  |    died    |  0.722433  | 0.145149 |  190  | 1.168931 | 0.020977 |
# +-------------+------------+------------+------------+----------+-------+----------+----------+
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


