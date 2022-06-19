# Raku ML::AssociationRuleLearning

[![SparkyCI](http://sparrowhub.io:2222/project/gh-antononcube-Raku-ML-AssociationRuleLearning/badge)](http://sparrowhub.io:2222)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

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
# +-----------------+---------------+----------------+----------------+-------------------+
# | id              | passengerSex  | passengerClass | passengerAge   | passengerSurvival |
# +-----------------+---------------+----------------+----------------+-------------------+
# | 220     => 1    | male   => 843 | 3rd => 709     | 20      => 334 | died     => 809   |
# | 985     => 1    | female => 466 | 1st => 323     | -1      => 263 | survived => 500   |
# | 776     => 1    |               | 2nd => 277     | 30      => 258 |                   |
# | 76      => 1    |               |                | 40      => 190 |                   |
# | 1150    => 1    |               |                | 50      => 88  |                   |
# | 491     => 1    |               |                | 60      => 57  |                   |
# | 882     => 1    |               |                | 0       => 56  |                   |
# | (Other) => 1302 |               |                | (Other) => 63  |                   |
# +-----------------+---------------+----------------+----------------+-------------------+
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
# +----------+-------------------------------------------------------------+
# | Support  | Frequent-set                                                |
# +----------+-------------------------------------------------------------+
# | 0.158900 | passengerAge:-1 passengerClass:3rd                          |
# | 0.157372 | passengerAge:20 passengerClass:3rd                          |
# | 0.158136 | passengerAge:20 passengerSex:male                           |
# | 0.158136 | passengerAge:20 passengerSurvival:died                      |
# | 0.152788 | passengerClass:1st passengerSurvival:survived               |
# | 0.165011 | passengerClass:3rd passengerSex:female                      |
# | 0.376623 | passengerClass:3rd passengerSex:male                        |
# | 0.319328 | passengerClass:3rd passengerSex:male passengerSurvival:died |
# | 0.403361 | passengerClass:3rd passengerSurvival:died                   |
# | 0.258976 | passengerSex:female passengerSurvival:survived              |
# | 0.521008 | passengerSex:male passengerSurvival:died                    |
# +----------+-------------------------------------------------------------+
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
# [(female 30 survived 1st 1) (0 2 1st male survived) (female 0 1st died 3) (male 1st died 30 4) (20 died 5 female 1st) (1st survived 50 male 6) (1st 60 survived 7 female) (died 40 1st 8 male) (1st survived female 9 50) (died 1st 10 70 male) (1st died male 11 50) (1st 12 survived 20 female) (survived 20 1st female 13) (30 survived 1st 14 female) (male 80 1st 15 survived) (1st male died -1 16) (died male 20 1st 17) (female 1st survived 50 18) (30 survived 1st female 19) (40 20 male died 1st) (40 21 male 1st survived) (1st survived female 22 50) (30 survived male 1st 23) (female 40 1st 24 survived) (survived female 1st 30 25) (died 20 1st male 26) (1st male 27 20 survived) (20 survived 1st female 28) (29 40 survived 1st female) (male 1st 30 survived 30) (40 31 male 1st died) (32 40 1st male survived) (30 female survived 33 1st) (34 60 survived 1st female) (male 35 40 died 1st) (40 36 female 1st survived) (1st female 37 20 survived) (1st -1 survived male 38) (40 died male 39 1st) (died male 1st 50 40) (died male 41 -1 1st) (40 1st survived female 42) (female 43 1st survived 60) (60 1st 44 survived female) (1st 45 40 survived female) (male 46 40 died 1st) (male died -1 47 1st) (1st survived male 48 40) (survived 1st 50 49 female) (40 survived 50 male 1st) (51 1st female survived 60) (male 30 1st 52 died) (53 died 30 1st male) (1st male 20 died 54) (male 55 survived 10 1st) (56 survived 10 1st female) (40 1st survived male 57) (40 1st female 58 survived) (59 50 died male 1st) (-1 60 1st survived female) (male 61 1st 40 died) (female survived 80 1st 62) (1st male 63 died 50) (50 64 female survived 1st) (survived 30 male 1st 65) (female 1st survived 30 66) (female 67 survived 1st 40) (1st survived female 68 30) (69 male survived 40 1st) (female survived 70 1st -1) (died 1st male 71 -1) (died 30 72 male 1st) (73 survived female 1st 30) (74 1st female survived 20) (-1 male 75 1st died) (male 50 76 1st died) (40 survived 1st female 77) (78 male died 1st 40) (survived 60 female 79 1st) (80 survived female 60 1st) (1st died 81 male -1) (1st 70 died male 82) (83 40 female 1st survived) (survived 1st 60 84 female) (85 1st died male 40) (female survived 86 1st 40) (87 survived 50 male 1st) (male 88 1st survived 30) (30 female 1st 89 survived) (male died 30 90 1st) (1st female 91 30 survived) (30 92 1st survived male) (20 survived 1st 93 female) (male survived 1st 50 94) (0 male survived 95 1st) (survived 50 96 female 1st) (male 1st 50 97 died) (30 98 survived 1st female) (survived 99 female 1st 50) (100 survived 1st female 50) ...]
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
# +----------+-------------------------------------------+------------+----------+----------+------------------------+------------+-------+
# |   lift   |                antecendent                | conviction | support  | leverage |       consequent       | confidence | count |
# +----------+-------------------------------------------+------------+----------+----------+------------------------+------------+-------+
# | 1.309025 |             passengerSex:male             |  2.000009  | 0.521008 | 0.122996 | passengerSurvival:died |  0.809015  |  682  |
# | 1.309025 |           passengerSurvival:died          |  2.267729  | 0.521008 | 0.122996 |   passengerSex:male    |  0.843016  |  682  |
# | 1.371894 |    passengerClass:3rd passengerSex:male   |  2.510823  | 0.319328 | 0.086564 | passengerSurvival:died |  0.847870  |  418  |
# | 1.229290 | passengerClass:3rd passengerSurvival:died |  1.708785  | 0.319328 | 0.059562 |   passengerSex:male    |  0.791667  |  418  |
# | 1.204977 |             passengerClass:3rd            |  1.496229  | 0.403361 | 0.068615 | passengerSurvival:died |  0.744711  |  528  |
# +----------+-------------------------------------------+------------+----------+----------+------------------------+------------+-------+
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
# +------------+-------+----------+-------------+----------+------------+----------+------------+
# | conviction | count |   lift   | antecendent | support  | confidence | leverage | consequent |
# +------------+-------+----------+-------------+----------+------------+----------+------------+
# |  2.267729  |  339  | 1.904511 |    female   | 0.258976 |  0.727468  | 0.122996 |  survived  |
# |  2.267729  |  682  | 1.309025 |     died    | 0.521008 |  0.843016  | 0.122996 |    male    |
# |  2.000009  |  682  | 1.309025 |     male    | 0.521008 |  0.809015  | 0.122996 |    died    |
# |  2.313980  |  176  | 1.313897 |   20 died   | 0.134454 |  0.846154  | 0.032122 |    male    |
# |  2.482811  |  176  | 1.369117 |   20 male   | 0.134454 |  0.846154  | 0.036249 |    died    |
# |  1.708785  |  418  | 1.229290 |   3rd died  | 0.319328 |  0.791667  | 0.059562 |    male    |
# |  2.510823  |  418  | 1.371894 |   3rd male  | 0.319328 |  0.847870  | 0.086564 |    died    |
# |  2.181917  |  159  | 1.299438 |   -1 died   | 0.121467 |  0.836842  | 0.027990 |    male    |
# |  2.717870  |  159  | 1.390646 |   -1 male   | 0.121467 |  0.859459  | 0.034121 |    died    |
# |  1.200349  |  185  | 1.092265 |      -1     | 0.141329 |  0.703422  | 0.011938 |    male    |
# |  1.496229  |  528  | 1.204977 |     3rd     | 0.403361 |  0.744711  | 0.068615 |    died    |
# |  1.588999  |  158  | 1.229093 |    -1 3rd   | 0.120703 |  0.759615  | 0.022498 |    died    |
# |  2.721543  |  158  | 1.535313 |   -1 died   | 0.120703 |  0.831579  | 0.042085 |    3rd     |
# |  1.376142  |  190  | 1.168931 |      -1     | 0.145149 |  0.722433  | 0.020977 |    died    |
# |  2.191819  |  208  | 1.460162 |      -1     | 0.158900 |  0.790875  | 0.050076 |    3rd     |
# +------------+-------+----------+-------------+----------+------------+----------+------------+
```

**Remark:** Note that because of the specified min confidence, the number of association rules is "contained" --
a (much) larger number of rules would be produced with, say, `min-confidence=>0.2`.


-------

## Implementation considerations

### UML diagram

Here is a UML diagram that shows package's structure:

![](./resources/class-diagram.png)


The
[PlantUML spec](./resources/class-diagram.puml)
and
[diagram](./resources/class-diagram.png)
were obtained with the CLI script `to-uml-spec` of the package "UML::Translators", [AAp6].

Here we get the [PlantUML spec](./resources/class-diagram.puml):

```shell
to-uml-spec ML::AssociationRuleLearning > ./resources/class-diagram.puml
```

Here get the [diagram](./resources/class-diagram.png):

```shell
to-uml-spec ML::AssociationRuleLearning | java -jar ~/PlantUML/plantuml-1.2022.5.jar -pipe > ./resources/class-diagram.png
```

### Eclat

We can say that Eclat uses a "vertical database representation" of the transactions.

Eclat is based on Raku's 
[sets, bags, and mixes](https://docs.raku.org/language/setbagmix)
functionalities.

Eclat represents the transactions as a hash of sets:

- The keys of the hash are items

- The elements of the sets are transaction identifiers.

(In other words, for each item an inverse index is made.)

This representation allows for quick calculations of item combinations support.

### Apriori 

Apriori uses the standard, horizontal database transactions representation.

We can say that Apriori:

- Generates candidates for item frequent sets using the routine 
  [`combinations`](https://docs.raku.org/routine/combinations)

- Filters candidates by 
  [Tries with frequencies](https://github.com/antononcube/Raku-ML-TriesWithFrequencies) 
  creation and removal by threshold

Apriori is usually (much) slower than Eclat. 
Historically, Apriori is the first ARL method, and its implementation in the package is didactic.

### Association rules

We can say that the association rule finding function is a general one, but that function
does require fast computation of confidence, lift, etc. Hence Eclat's transactions representation
is used.

Association rules finding with Apriori is the same as with Eclat. 
The package function `assocition-rules` with the option setting `method=>'Apriori'`
simply sends frequent sets found with Apriori to the Eclat based association rule finding.

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

[AAp6] Anton Antonov,
[UML::Translators Raku package](https://github.com/antononcube/Raku-UML-Translators),
(2022),
[GitHub/antononcube](https://github.com/antononcube).


