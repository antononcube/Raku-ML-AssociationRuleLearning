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
# +----------------+---------------+-----------------+----------------+-------------------+
# | passengerAge   | passengerSex  | id              | passengerClass | passengerSurvival |
# +----------------+---------------+-----------------+----------------+-------------------+
# | 20      => 334 | male   => 843 | 477     => 1    | 3rd => 709     | died     => 809   |
# | -1      => 263 | female => 466 | 970     => 1    | 1st => 323     | survived => 500   |
# | 30      => 258 |               | 894     => 1    | 2nd => 277     |                   |
# | 40      => 190 |               | 1039    => 1    |                |                   |
# | 50      => 88  |               | 263     => 1    |                |                   |
# | 60      => 57  |               | 320     => 1    |                |                   |
# | 0       => 56  |               | 340     => 1    |                |                   |
# | (Other) => 63  |               | (Other) => 1302 |                |                   |
# +----------------+---------------+-----------------+----------------+-------------------+
```

**Problem:** Find all combinations values of the variables "passengerAge", "passengerClass", "passengerSex", and
"passengerSurvival" that appear more 200 times in the Titanic dataset.

Here is how we use Eclat's implementation to give an answer:

```perl6
use ML::AssociationRuleLearning;
my @freqSets = eclat(@dsTitanic, min-support => 200, min-number-of-items => 2, max-number-of-items => Inf):counts;
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
# +-------------------------------------------------------------+----------+
# | Frequent-set                                                | Support  |
# +-------------------------------------------------------------+----------+
# | passengerAge:-1 passengerClass:3rd                          | 0.158900 |
# | passengerAge:20 passengerClass:3rd                          | 0.157372 |
# | passengerAge:20 passengerSex:male                           | 0.158136 |
# | passengerAge:20 passengerSurvival:died                      | 0.158136 |
# | passengerClass:1st passengerSurvival:survived               | 0.152788 |
# | passengerClass:3rd passengerSex:female                      | 0.165011 |
# | passengerClass:3rd passengerSex:male                        | 0.376623 |
# | passengerClass:3rd passengerSex:male passengerSurvival:died | 0.319328 |
# | passengerClass:3rd passengerSurvival:died                   | 0.403361 |
# | passengerSex:female passengerSurvival:survived              | 0.258976 |
# | passengerSex:male passengerSurvival:died                    | 0.521008 |
# +-------------------------------------------------------------+----------+
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

**Remark:** For datasets -- i.e. arrays of hashes -- `eclat` preprocess the data by concatenating
column names with corresponding column values. This done in order to prevent "collisions" from of same values from
different columns. If that concatenation is not desired manual preprocessing like this can be used:

```perl6
@dsTitanic.map({ $_.values.List }).Array
```
```
# [(survived 1st 1 female 30) (2 male 0 1st survived) (3 died 0 1st female) (died male 30 4 1st) (died female 20 1st 5) (1st survived 50 6 male) (survived female 60 7 1st) (male died 8 1st 40) (survived female 1st 50 9) (1st died 10 male 70) (male died 1st 50 11) (survived 1st female 20 12) (20 13 1st female survived) (30 female survived 14 1st) (male survived 80 1st 15) (-1 male 16 died 1st) (1st 17 20 male died) (female 18 1st 50 survived) (1st survived 19 female 30) (1st 40 male died 20) (40 survived male 21 1st) (1st 50 female survived 22) (male survived 1st 23 30) (40 survived 24 1st female) (female 25 survived 30 1st) (died 20 26 male 1st) (male 20 survived 27 1st) (28 1st survived female 20) (1st 29 survived female 40) (male survived 30 1st 30) (died 31 1st male 40) (male survived 1st 40 32) (female 30 33 survived 1st) (survived 34 60 1st female) (male died 35 40 1st) (survived 1st 40 36 female) (37 female 20 survived 1st) (1st male 38 survived -1) (1st 39 male died 40) (died 40 male 1st 50) (-1 1st died 41 male) (survived 42 1st female 40) (female 43 survived 1st 60) (survived 1st female 44 60) (45 40 female 1st survived) (1st 46 male died 40) (1st male -1 47 died) (40 male 48 1st survived) (survived 50 1st 49 female) (50 40 survived 1st male) (51 60 1st female survived) (30 male died 52 1st) (30 died 53 male 1st) (20 died 1st male 54) (10 survived male 1st 55) (survived 10 56 1st female) (57 40 survived 1st male) (58 40 female 1st survived) (1st male died 50 59) (female 1st survived 60 -1) (male 1st 40 died 61) (1st female survived 80 62) (1st died 63 male 50) (survived 50 female 1st 64) (30 65 male 1st survived) (survived 30 66 female 1st) (female 67 1st 40 survived) (68 female 30 survived 1st) (69 male 1st survived 40) (-1 survived 70 1st female) (71 died 1st -1 male) (died 1st male 72 30) (female 73 survived 1st 30) (1st survived 20 74 female) (1st 75 died male -1) (76 male 50 died 1st) (survived 1st 77 40 female) (78 40 male 1st died) (79 60 1st female survived) (survived 1st female 60 80) (81 1st male -1 died) (70 82 1st male died) (1st female 83 40 survived) (survived 84 1st 60 female) (1st 85 died male 40) (female 40 survived 1st 86) (1st survived male 87 50) (88 survived 30 male 1st) (89 1st survived female 30) (1st died male 90 30) (1st female survived 30 91) (male 1st 30 survived 92) (1st 93 20 survived female) (1st survived 94 male 50) (0 survived male 1st 95) (1st 50 female 96 survived) (50 male 97 1st died) (30 female 98 1st survived) (female survived 99 50 1st) (female survived 100 1st 50) ...]
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
# +----------+----------+----------+------------+------------------------+-------------------------------------------+------------+-------+
# | support  |   lift   | leverage | confidence |       consequent       |                antecendent                | conviction | count |
# +----------+----------+----------+------------+------------------------+-------------------------------------------+------------+-------+
# | 0.403361 | 1.204977 | 0.068615 |  0.744711  | passengerSurvival:died |             passengerClass:3rd            |  1.496229  |  528  |
# | 0.521008 | 1.309025 | 0.122996 |  0.809015  | passengerSurvival:died |             passengerSex:male             |  2.000009  |  682  |
# | 0.521008 | 1.309025 | 0.122996 |  0.843016  |   passengerSex:male    |           passengerSurvival:died          |  2.267729  |  682  |
# | 0.319328 | 1.371894 | 0.086564 |  0.847870  | passengerSurvival:died |    passengerClass:3rd passengerSex:male   |  2.510823  |  418  |
# | 0.319328 | 1.229290 | 0.059562 |  0.791667  |   passengerSex:male    | passengerClass:3rd passengerSurvival:died |  1.708785  |  418  |
# +----------+----------+----------+------------+------------------------+-------------------------------------------+------------+-------+
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
# +----------+------------+----------+----------+-------------+-------+------------+------------+
# |   lift   | confidence | leverage | support  | antecendent | count | consequent | conviction |
# +----------+------------+----------+----------+-------------+-------+------------+------------+
# | 1.092265 |  0.703422  | 0.011938 | 0.141329 |      -1     |  185  |    male    |  1.200349  |
# | 1.309025 |  0.843016  | 0.122996 | 0.521008 |     died    |  682  |    male    |  2.267729  |
# | 1.309025 |  0.809015  | 0.122996 | 0.521008 |     male    |  682  |    died    |  2.000009  |
# | 1.229290 |  0.791667  | 0.059562 | 0.319328 |   3rd died  |  418  |    male    |  1.708785  |
# | 1.371894 |  0.847870  | 0.086564 | 0.319328 |   3rd male  |  418  |    died    |  2.510823  |
# | 1.313897 |  0.846154  | 0.032122 | 0.134454 |   20 died   |  176  |    male    |  2.313980  |
# | 1.369117 |  0.846154  | 0.036249 | 0.134454 |   20 male   |  176  |    died    |  2.482811  |
# | 1.299438 |  0.836842  | 0.027990 | 0.121467 |   -1 died   |  159  |    male    |  2.181917  |
# | 1.390646 |  0.859459  | 0.034121 | 0.121467 |   -1 male   |  159  |    died    |  2.717870  |
# | 1.460162 |  0.790875  | 0.050076 | 0.158900 |      -1     |  208  |    3rd     |  2.191819  |
# | 1.904511 |  0.727468  | 0.122996 | 0.258976 |    female   |  339  |  survived  |  2.267729  |
# | 1.204977 |  0.744711  | 0.068615 | 0.403361 |     3rd     |  528  |    died    |  1.496229  |
# | 1.229093 |  0.759615  | 0.022498 | 0.120703 |    -1 3rd   |  158  |    died    |  1.588999  |
# | 1.535313 |  0.831579  | 0.042085 | 0.120703 |   -1 died   |  158  |    3rd     |  2.721543  |
# | 1.168931 |  0.722433  | 0.020977 | 0.145149 |      -1     |  190  |    died    |  1.376142  |
# +----------+------------+----------+----------+-------------+-------+------------+------------+
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


