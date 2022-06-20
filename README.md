# Raku ML::AssociationRuleLearning

[![SparkyCI](http://sparrowhub.io:2222/project/gh-antononcube-Raku-ML-AssociationRuleLearning/badge)](http://sparrowhub.io:2222)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

This repository has the code of a Raku package for
[Association Rule Learning (ARL)](https://en.wikipedia.org/wiki/Association_rule_learning)
functions, [Wk1].

The ARL framework includes the algorithms 
[Apriori](https://en.wikipedia.org/wiki/Apriori_algorithm) 
and 
[Eclat](https://en.wikipedia.org/wiki/Association_rule_learning#Eclat_algorithm), 
and the measures 
[confidence](https://en.wikipedia.org/wiki/Association_rule_learning#Confidence),
[lift](https://en.wikipedia.org/wiki/Association_rule_learning#Lift), and 
[conviction](https://en.wikipedia.org/wiki/Association_rule_learning#Conviction), 
(and others.)

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
# +-------------------+----------------+----------------+---------------+-----------------+
# | passengerSurvival | passengerAge   | passengerClass | passengerSex  | id              |
# +-------------------+----------------+----------------+---------------+-----------------+
# | died     => 809   | 20      => 334 | 3rd => 709     | male   => 843 | 1036    => 1    |
# | survived => 500   | -1      => 263 | 1st => 323     | female => 466 | 655     => 1    |
# |                   | 30      => 258 | 2nd => 277     |               | 50      => 1    |
# |                   | 40      => 190 |                |               | 1230    => 1    |
# |                   | 50      => 88  |                |               | 320     => 1    |
# |                   | 60      => 57  |                |               | 1126    => 1    |
# |                   | 0       => 56  |                |               | 779     => 1    |
# |                   | (Other) => 63  |                |               | (Other) => 1302 |
# +-------------------+----------------+----------------+---------------+-----------------+
```

**Problem:** Find all combinations of values of the variables "passengerAge", "passengerClass", "passengerSex", and
"passengerSurvival" that appear more than 200 times in the Titanic dataset.

Here is how we use the function `frequent-sets` to give an answer:

```perl6
use ML::AssociationRuleLearning;
my @freqSets = frequent-sets(@dsTitanic, min-support => 200, min-number-of-items => 2, max-number-of-items => Inf):counts;
@freqSets.elems
```
```
# 11
```

The function `frequent-sets` returns the frequent sets together with their support.

Here we tabulate the result:

```perl6
say to-pretty-table(@freqSets.map({ %( Frequent-set => $_.key.join(' '), Count => $_.value) }), align => 'l');
```
```
# +-------+-------------------------------------------------------------+
# | Count | Frequent-set                                                |
# +-------+-------------------------------------------------------------+
# | 208   | passengerAge:-1 passengerClass:3rd                          |
# | 206   | passengerAge:20 passengerClass:3rd                          |
# | 207   | passengerAge:20 passengerSex:male                           |
# | 207   | passengerAge:20 passengerSurvival:died                      |
# | 200   | passengerClass:1st passengerSurvival:survived               |
# | 216   | passengerClass:3rd passengerSex:female                      |
# | 493   | passengerClass:3rd passengerSex:male                        |
# | 418   | passengerClass:3rd passengerSex:male passengerSurvival:died |
# | 528   | passengerClass:3rd passengerSurvival:died                   |
# | 339   | passengerSex:female passengerSurvival:survived              |
# | 682   | passengerSex:male passengerSurvival:died                    |
# +-------+-------------------------------------------------------------+
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

**Remark:** For datasets -- i.e. arrays of hashes -- `frequent-sets` preprocesses the data by concatenating
column names with corresponding column values. This is done in order to prevent "collisions" of same values 
coming from different columns. If that concatenation is not desired then manual preprocessing like this can be used:

```{perl6, eval=FALSE}
@dsTitanic.map({ $_.values.List }).Array
```

**Remark:** `frequent-sets`'s argument `min-support` can take both integers greater than 1 and frequencies between 0 and 1.
(If an integer greater than one is given, then the corresponding frequency is derived.)

**Remark:** By default `frequent-sets` uses the Eclat algorithm. The functions `apriori` and `eclat`
call `frequent-sets` with the option settings `method=>'Apriori'` and `method=>'Eclat'` respectively.

-------

## Association rules finding

Here we find association rules with min support 0.3 and min confidence 0.7:

```perl6
association-rules(@dsTitanic, min-support => 0.3, min-confidence => 0.7)
==> to-pretty-table
```
```
# +------------------------+-------+----------+-------------------------------------------+----------+------------+------------+----------+
# |       consequent       | count | support  |                antecendent                | leverage | conviction | confidence |   lift   |
# +------------------------+-------+----------+-------------------------------------------+----------+------------+------------+----------+
# | passengerSurvival:died |  528  | 0.403361 |             passengerClass:3rd            | 0.068615 |  1.496229  |  0.744711  | 1.204977 |
# | passengerSurvival:died |  682  | 0.521008 |             passengerSex:male             | 0.122996 |  2.000009  |  0.809015  | 1.309025 |
# |   passengerSex:male    |  682  | 0.521008 |           passengerSurvival:died          | 0.122996 |  2.267729  |  0.843016  | 1.309025 |
# | passengerSurvival:died |  418  | 0.319328 |    passengerClass:3rd passengerSex:male   | 0.086564 |  2.510823  |  0.847870  | 1.371894 |
# |   passengerSex:male    |  418  | 0.319328 | passengerClass:3rd passengerSurvival:died | 0.059562 |  1.708785  |  0.791667  | 1.229290 |
# +------------------------+-------+----------+-------------------------------------------+----------+------------+------------+----------+
```

### Reusing found frequent sets

The function `frequent-sets` takes the adverb ":object" that makes `frequent-sets` return an object of type
`ML::AssociationRuleLearning::Apriori` or `ML::AssociationRuleLearning::Eclat`, 
which can be "pipelined" to find association rules.

Here we find frequent sets, return the corresponding object, and retrieve the result:

```perl6
my $eclatObj = frequent-sets(@dsTitanic.map({ $_.values.List }).Array, min-support => 0.12, min-number-of-items => 2, max-number-of-items => 6):object;
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
# +------------+-------+-------------+----------+----------+------------+----------+------------+
# | confidence | count | antecendent | leverage |   lift   | consequent | support  | conviction |
# +------------+-------+-------------+----------+----------+------------+----------+------------+
# |  0.790875  |  208  |      -1     | 0.050076 | 1.460162 |    3rd     | 0.158900 |  2.191819  |
# |  0.703422  |  185  |      -1     | 0.011938 | 1.092265 |    male    | 0.141329 |  1.200349  |
# |  0.843016  |  682  |     died    | 0.122996 | 1.309025 |    male    | 0.521008 |  2.267729  |
# |  0.809015  |  682  |     male    | 0.122996 | 1.309025 |    died    | 0.521008 |  2.000009  |
# |  0.791667  |  418  |   3rd died  | 0.059562 | 1.229290 |    male    | 0.319328 |  1.708785  |
# |  0.847870  |  418  |   3rd male  | 0.086564 | 1.371894 |    died    | 0.319328 |  2.510823  |
# |  0.836842  |  159  |   -1 died   | 0.027990 | 1.299438 |    male    | 0.121467 |  2.181917  |
# |  0.859459  |  159  |   -1 male   | 0.034121 | 1.390646 |    died    | 0.121467 |  2.717870  |
# |  0.846154  |  176  |   20 died   | 0.032122 | 1.313897 |    male    | 0.134454 |  2.313980  |
# |  0.846154  |  176  |   20 male   | 0.036249 | 1.369117 |    died    | 0.134454 |  2.482811  |
# |  0.727468  |  339  |    female   | 0.122996 | 1.904511 |  survived  | 0.258976 |  2.267729  |
# |  0.744711  |  528  |     3rd     | 0.068615 | 1.204977 |    died    | 0.403361 |  1.496229  |
# |  0.759615  |  158  |    -1 3rd   | 0.022498 | 1.229093 |    died    | 0.120703 |  1.588999  |
# |  0.831579  |  158  |   -1 died   | 0.042085 | 1.535313 |    3rd     | 0.120703 |  2.721543  |
# |  0.722433  |  190  |      -1     | 0.020977 | 1.168931 |    died    | 0.145149 |  1.376142  |
# +------------+-------+-------------+----------+----------+------------+----------+------------+
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

**Remark:** Maybe it is a good idea to have an abstract class named, say,
`ML::AssociationRuleLearning::AbstractFinder` that is a parent of both
`ML::AssociationRuleLearning::Apriori` and `ML::AssociationRuleLearning::Eclat`,
but I have not found to be necessary. (At this point of development.)

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

