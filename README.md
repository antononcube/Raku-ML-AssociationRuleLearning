# Raku ML::AssociationRuleLearning

[![SparkyCI](http://sparrowhub.io:2222/project/gh-antononcube-Raku-ML-AssociationRuleLearning/badge)](http://sparrowhub.io:2222)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

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
# | 904     => 1    | male   => 843 | 3rd => 709     | 20      => 334 | died     => 809   |
# | 1253    => 1    | female => 466 | 1st => 323     | -1      => 263 | survived => 500   |
# | 1187    => 1    |               | 2nd => 277     | 30      => 258 |                   |
# | 66      => 1    |               |                | 40      => 190 |                   |
# | 393     => 1    |               |                | 50      => 88  |                   |
# | 371     => 1    |               |                | 60      => 57  |                   |
# | 485     => 1    |               |                | 0       => 56  |                   |
# | (Other) => 1302 |               |                | (Other) => 63  |                   |
# +-----------------+---------------+----------------+----------------+-------------------+
```

**Problem:** Find all combinations values of the variables "passengerAge", "passengerClass", "passengerSex", and
"passengerSurvival" that appear more than 200 times in the Titanic dataset.

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
# 3rd.male => 493
# 3rd.female => 216
# 3rd.died.male => 418
```

Or these contingency tables:

```perl6
my $obj = group-by( @dsTitanic, "passengerClass") ;
$obj = $obj.map({ $_.key => cross-tabulate( $_.value, "passengerSex", "passengerSurvival" ) });
.say for $obj.Array;
```
```
# 1st => {female => {died => 5, survived => 139}, male => {died => 118, survived => 61}}
# 2nd => {female => {died => 12, survived => 94}, male => {died => 146, survived => 25}}
# 3rd => {female => {died => 110, survived => 106}, male => {died => 418, survived => 75}}
```

**Remark:** For datasets -- i.e. arrays of hashes -- `eclat` preprocess the data by concatenating
column names with corresponding column values. This done in order to prevent "collisions" from of same values from
different columns. If that concatenation is not desired manual preprocessing like this can be used:

```perl6
@dsTitanic.map({ $_.values.List }).Array
```
```
# [(30 1 1st female survived) (male 1st 0 survived 2) (1st 0 died 3 female) (male 4 died 30 1st) (died 1st female 5 20) (1st male 6 50 survived) (7 female survived 60 1st) (1st died 8 male 40) (9 1st 50 female survived) (70 died male 1st 10) (50 died 11 1st male) (20 female survived 1st 12) (13 survived female 1st 20) (female 30 1st survived 14) (male 1st 80 15 survived) (16 male 1st -1 died) (17 male died 1st 20) (18 survived female 1st 50) (survived 1st female 19 30) (died 1st 40 20 male) (survived 1st 21 40 male) (1st survived female 50 22) (23 male survived 30 1st) (1st 24 40 survived female) (25 survived female 1st 30) (20 26 male died 1st) (survived 20 1st male 27) (28 1st female survived 20) (survived female 40 29 1st) (1st 30 survived 30 male) (1st 40 male died 31) (32 40 1st male survived) (1st 30 survived female 33) (1st 34 female survived 60) (died 1st 35 40 male) (1st 40 survived 36 female) (37 20 survived female 1st) (-1 1st male survived 38) (male 39 died 40 1st) (died 1st male 50 40) (41 male -1 1st died) (40 survived 42 1st female) (60 survived 43 1st female) (44 60 survived 1st female) (45 40 female survived 1st) (died 46 male 1st 40) (1st male died 47 -1) (48 1st 40 male survived) (1st 49 female survived 50) (50 1st male survived 40) (51 female survived 60 1st) (1st 52 died 30 male) (30 1st male died 53) (20 54 died 1st male) (10 1st survived male 55) (10 1st survived female 56) (57 1st survived 40 male) (female 1st 40 survived 58) (50 male died 59 1st) (survived 60 female -1 1st) (died male 40 1st 61) (female 1st survived 62 80) (died 63 50 male 1st) (survived 50 female 1st 64) (1st male 30 65 survived) (66 female 30 1st survived) (1st 40 survived female 67) (1st female 68 30 survived) (male 40 1st 69 survived) (female 70 1st survived -1) (1st -1 male 71 died) (30 72 male 1st died) (female 30 survived 73 1st) (female 20 survived 1st 74) (-1 male died 1st 75) (male 1st 50 died 76) (77 survived 1st female 40) (40 male 1st died 78) (79 female 60 1st survived) (60 survived 80 1st female) (1st 81 -1 died male) (70 1st died 82 male) (survived 1st 83 female 40) (84 1st female 60 survived) (40 male 85 1st died) (survived 86 40 female 1st) (survived male 87 1st 50) (survived male 30 88 1st) (30 1st survived 89 female) (male 30 90 died 1st) (survived 1st 91 female 30) (92 30 male survived 1st) (1st 93 survived 20 female) (survived 94 male 1st 50) (95 1st survived male 0) (96 50 1st female survived) (97 male 50 1st died) (30 98 survived 1st female) (1st 99 survived female 50) (100 female 50 1st survived) ...]
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
# +------------+----------+-------+------------+----------+------------------------+----------+-------------------------------------------+
# | confidence | support  | count | conviction | leverage |       consequent       |   lift   |                antecendent                |
# +------------+----------+-------+------------+----------+------------------------+----------+-------------------------------------------+
# |  0.809015  | 0.521008 |  682  |  2.000009  | 0.122996 | passengerSurvival:died | 1.309025 |             passengerSex:male             |
# |  0.843016  | 0.521008 |  682  |  2.267729  | 0.122996 |   passengerSex:male    | 1.309025 |           passengerSurvival:died          |
# |  0.847870  | 0.319328 |  418  |  2.510823  | 0.086564 | passengerSurvival:died | 1.371894 |    passengerClass:3rd passengerSex:male   |
# |  0.791667  | 0.319328 |  418  |  1.708785  | 0.059562 |   passengerSex:male    | 1.229290 | passengerClass:3rd passengerSurvival:died |
# |  0.744711  | 0.403361 |  528  |  1.496229  | 0.068615 | passengerSurvival:died | 1.204977 |             passengerClass:3rd            |
# +------------+----------+-------+------------+----------+------------------------+----------+-------------------------------------------+
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
# +-------------+-------+----------+------------+----------+------------+----------+------------+
# | antecendent | count |   lift   | confidence | support  | consequent | leverage | conviction |
# +-------------+-------+----------+------------+----------+------------+----------+------------+
# |    female   |  339  | 1.904511 |  0.727468  | 0.258976 |  survived  | 0.122996 |  2.267729  |
# |      -1     |  208  | 1.460162 |  0.790875  | 0.158900 |    3rd     | 0.050076 |  2.191819  |
# |      -1     |  185  | 1.092265 |  0.703422  | 0.141329 |    male    | 0.011938 |  1.200349  |
# |     died    |  682  | 1.309025 |  0.843016  | 0.521008 |    male    | 0.122996 |  2.267729  |
# |     male    |  682  | 1.309025 |  0.809015  | 0.521008 |    died    | 0.122996 |  2.000009  |
# |   -1 died   |  159  | 1.299438 |  0.836842  | 0.121467 |    male    | 0.027990 |  2.181917  |
# |   -1 male   |  159  | 1.390646 |  0.859459  | 0.121467 |    died    | 0.034121 |  2.717870  |
# |   3rd died  |  418  | 1.229290 |  0.791667  | 0.319328 |    male    | 0.059562 |  1.708785  |
# |   3rd male  |  418  | 1.371894 |  0.847870  | 0.319328 |    died    | 0.086564 |  2.510823  |
# |   20 died   |  176  | 1.313897 |  0.846154  | 0.134454 |    male    | 0.032122 |  2.313980  |
# |   20 male   |  176  | 1.369117 |  0.846154  | 0.134454 |    died    | 0.036249 |  2.482811  |
# |      -1     |  190  | 1.168931 |  0.722433  | 0.145149 |    died    | 0.020977 |  1.376142  |
# |     3rd     |  528  | 1.204977 |  0.744711  | 0.403361 |    died    | 0.068615 |  1.496229  |
# |    -1 3rd   |  158  | 1.229093 |  0.759615  | 0.120703 |    died    | 0.022498 |  1.588999  |
# |   -1 died   |  158  | 1.535313 |  0.831579  | 0.120703 |    3rd     | 0.042085 |  2.721543  |
# +-------------+-------+----------+------------+----------+------------+----------+------------+
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

[AAp1a] Anton Antonov
[Implementation of the Apriori algorithm via Tries in Mathematica](https://github.com/antononcube/MathematicaForPrediction/blob/master/Misc/AprioriAlgorithmViaTries.m),
(2022),
[MathematicaForPrediction at GitHub/antononcube](https://github.com/antononcube/MathematicaForPrediction/).

[AAp2] Anton Antonov,
[Implementation of the Eclat algorithm in Mathematica](https://github.com/antononcube/MathematicaForPrediction/blob/master/EclatAlgorithm.m),
(2022),
[MathematicaForPrediction at GitHub/antononcube](https://github.com/antononcube/MathematicaForPrediction/).

[AAp3] Anton Antonov,
[Data::Generators Raku package](https://raku.land/cpan:ANTONOV/Data::Generators),
(2021),
[GitHub/antononcube](https://github.com/antononcube).

[AAp4] Anton Antonov,
[Data::Reshapers Raku package](https://raku.land/cpan:ANTONOV/Data::Reshapers),
(2021),
[GitHub/antononcube](https://github.com/antononcube).

[AAp5] Anton Antonov,
[Data::Summarizers Raku package](https://raku.land/cpan:ANTONOV/Data::Summarizers),
(2021),
[GitHub/antononcube](https://github.com/antononcube).

[AAp6] Anton Antonov,
[UML::Translators Raku package](https://raku.land/zef:antononcube/UML::Translators),
(2022),
[GitHub/antononcube](https://github.com/antononcube).

[AAp7] Anton Antonov,
[ML::TrieWithFrequencies Raku package](https://raku.land/cpan:ANTONOV/ML::TriesWithFrequencies),
(2021),
[GitHub/antononcube](https://github.com/antononcube).

