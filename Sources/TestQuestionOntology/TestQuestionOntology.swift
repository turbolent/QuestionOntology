import QuestionOntology
import ParserDescription
import ParserDescriptionOperators


public typealias TestQuestionOntology =
    QuestionOntology<WikidataOntologyMappings>


struct Patterns {
    private init() {}

    static let be = pattern(lemma: "be", tag: .anyVerb)
    static let `in` = pattern(lemma: "in", tag: .prepositionOrSubordinatingConjunction)
    static let on = pattern(lemma: "on", tag: .prepositionOrSubordinatingConjunction)
    static let of = pattern(lemma: "of", tag: .prepositionOrSubordinatingConjunction)
    static let than = pattern(lemma: "than", tag: .prepositionOrSubordinatingConjunction)
    static let after = pattern(lemma: "after", tag: .prepositionOrSubordinatingConjunction)
    static let before = pattern(lemma: "before", tag: .prepositionOrSubordinatingConjunction)
    static let more = pattern(lemma: "more", tag: .comparativeAdjective)
    static let less = pattern(lemma: "less", tag: .comparativeAdjective)
}


public let testQuestionOntology: TestQuestionOntology = {
    let ontology = TestQuestionOntology()

    let isInstanceOf = ontology.define(property: "isInstanceOf")
        .map(to: .property(Wikidata.P.31))

    let isSubclassOf = ontology.define(property: "isSubclassOf")
        .makeTransitive()
        .map(to: .property(Wikidata.P.279))

    ontology.instanceProperty =
        ontology.define(property: "isA")
            .hasEquivalent(
                outgoing: isInstanceOf,
                outgoing: isSubclassOf
            )
            .property

    ontology.labelProperty =
        ontology.define(property: "label")
            .map(to: .label)
            .property

    let Person = ontology.define(class: "Person")
        .map(to: Wikidata.Q.5)
        .hasPatterns(
            .named(pattern(lemma: "person", tag: .anyNoun)),
            .named(pattern(lemma: "people", tag: .anyNoun))
        )

    ontology.personClass = Person.class

    let hasLocation = ontology.define(property: "hasLocation")
        .map(to: .property(Wikidata.P.276))
        .hasPatterns(
            .value(
                Patterns.be.opt()
                    ~ pattern(lemma: "locate", tag: .anyVerb)
                    ~ Patterns.in
            )
        )

    let Place = ontology.define(class: "Place")
        .hasEquivalent(outgoing: hasLocation)
        .hasPattern(
            .named(pattern(lemma: "place", tag: .anyNoun))
        )
        .hasRelation(outgoing: hasLocation)
        .hasRelation(
            outgoing: hasLocation,
            pattern: Patterns.of
        )
        .hasRelation(
            outgoing: hasLocation,
            pattern: Patterns.in
        )

    let City = ontology.define(class: "City")
        .isSubClass(of: Place)
        .map(to: Wikidata.Q.515)
        .hasPattern(
            .named(pattern(lemma: "city", tag: .anyNoun))
        )

    let hasPopulation = ontology.define(property: "hasPopulation")
        .map(to: .property(Wikidata.P.1082))
        .hasPatterns(
            .adjective(lemma: "large"),
            .superlativeAdjective(
                lemma: "large",
                order: .descending
            ),
            .superlativeAdjective(
                lemma: "small",
                order: .ascending
            ),
            .value(
                Patterns.be.opt(),
                filter: .comparative(
                    pattern(lemma: "large", tag: .comparativeAdjective) ~ Patterns.than,
                    comparison: .greaterThan
                )
            ),
            .value(
                Patterns.be.opt(),
                filter: .comparative(
                    pattern(lemma: "small", tag: .comparativeAdjective) ~ Patterns.than,
                    comparison: .lessThan
                )
            )
        )

    ontology.define(property: "populates")
        .hasEquivalent(incoming: hasPopulation)
        .hasPatterns(
            .inverse(
                pattern(lemma: "live", tag: .anyVerb)
                    ~ pattern(lemma: "in", tag: .prepositionOrSubordinatingConjunction),
                filter: .comparative(
                    Patterns.more ~ Patterns.than,
                    comparison: .greaterThan
                )
            ),
            .inverse(
                pattern(lemma: "live", tag: .anyVerb)
                    ~ pattern(lemma: "in", tag: .prepositionOrSubordinatingConjunction),
                filter: .comparative(
                    Patterns.less ~ Patterns.than,
                    comparison: .lessThan
                )
            )
        )

    ontology.define(class: "Population")
        .hasEquivalent(incoming: hasPopulation)
        .hasPatterns(
            .named(
                pattern(lemma: "population", tag: .anyNoun)
                    ~ pattern(lemma: "size", tag: .anyNoun).opt()
            ),
            .named(pattern(lemma: "size", tag: .anyNoun))
        )
        .hasRelation(incoming: hasPopulation)
        .hasRelation(
            incoming: hasPopulation,
            pattern: Patterns.of
        )

    let hasDateOfBirth = ontology.define(property: "hasDateOfBirth")
        .map(to: .property(Wikidata.P.569))
        .hasPatterns(
            .value(
                Patterns.be ~ pattern(lemma: "bear", tag: .anyVerb),
                filter: .comparative(
                    Patterns.after,
                    comparison: .greaterThan
                )
            ),
            .value(
                Patterns.be ~ pattern(lemma: "bear", tag: .anyVerb),
                filter: .comparative(
                    Patterns.before,
                    comparison: .lessThan
                )
            )
        )

    let hasDateOfDeath = ontology.define(property: "hasDateOfDeath")
        .map(to: .property(Wikidata.P.570))
        .hasPatterns(
            .value(
                pattern(lemma: "die", tag: .anyVerb),
                filter: .comparative(
                    Patterns.after,
                    comparison: .greaterThan
                )
            ),
            .value(
                pattern(lemma: "die", tag: .anyVerb),
                filter: .comparative(
                    Patterns.before,
                    comparison: .lessThan
                )
            )
        )

    let hasPlaceOfBirth = ontology.define(property: "hasPlaceOfBirth")
        .map(to: .property(Wikidata.P.19))
        .hasPattern(
            .value(
                (
                    Patterns.be
                        || pattern(lemma: "come", tag: .anyVerb)
                ).opt()
                    ~ pattern(lemma: "from", tag: .prepositionOrSubordinatingConjunction)
            )
        )

    let hasPlaceOfDeath = ontology.define(property: "hasPlaceOfDeath")
        .map(to: .property(Wikidata.P.20))

    ontology.define(property: "born")
        .hasEquivalent(outgoing: hasDateOfBirth)
        .hasEquivalent(outgoing: hasPlaceOfBirth)
        .hasPatterns(
            .named(
                Patterns.be ~ pattern(lemma: "bear", tag: .anyVerb)
            ),
            .adjective(lemma: "alive"),
            .value(
                Patterns.be
                    ~ pattern(lemma: "bear", tag: .anyVerb)
                    ~ (Patterns.in || Patterns.on)
            )
        )

    ontology.define(class: "BirthPlace")
        .isSubClass(of: Place)
        .hasEquivalent(incoming: hasPlaceOfBirth)
        .hasPatterns(
            .named(
                pattern(lemma: "birth", tag: .anyNoun)
                    ~ pattern(lemma: "place", tag: .anyNoun)
            ),
            .named(
                pattern(lemma: "place", tag: .anyNoun)
                    ~ Patterns.of
                    ~ pattern(lemma: "birth", tag: .anyNoun)
            )
        )
        .hasRelation(incoming: hasPlaceOfBirth)
        .hasRelation(
            incoming: hasPlaceOfBirth,
            pattern: Patterns.of
        )

    ontology.define(class: "DeathPlace")
        .isSubClass(of: Place)
        .hasEquivalent(incoming: hasPlaceOfDeath)
        .hasPatterns(
            .named(
                pattern(lemma: "death", tag: .anyNoun)
                    ~ pattern(lemma: "place", tag: .anyNoun)
            ),
            .named(
                pattern(lemma: "place", tag: .anyNoun)
                    ~ Patterns.of
                    ~ pattern(lemma: "death", tag: .anyNoun)
            )
        )
        .hasRelation(incoming: hasPlaceOfDeath)
        .hasRelation(
            incoming: hasPlaceOfDeath,
            pattern: Patterns.of
        )

    ontology.define(property: "died")
        .hasEquivalent(outgoing: hasDateOfDeath)
        .hasEquivalent(outgoing: hasPlaceOfDeath)
        .hasPatterns(
            .named(
                pattern(lemma: "die", tag: .anyVerb)
            ),
            .adjective(lemma: "dead"),
            .value(
                pattern(lemma: "die", tag: .anyVerb)
                    ~ (Patterns.in || Patterns.on)
            )
        )

    ontology.define(property: "hasAge")
        .map(to: .operation(
            .age(
                birthDateProperty: hasDateOfBirth,
                deathDateProperty: hasDateOfDeath
            ))
        )
        .hasPatterns(
            .adjective(lemma: "old"),
            .adjective(
                lemma: "old",
                filter: .comparative(
                    Patterns.more ~ Patterns.than,
                    comparison: .greaterThan
                )
            ),
            .adjective(
                lemma: "old",
                filter: .comparative(
                    Patterns.less ~ Patterns.than,
                    comparison: .greaterThan
                )
            ),
            .superlativeAdjective(
                lemma: "old",
                order: .descending
            ),
            .superlativeAdjective(
                lemma: "young",
                order: .ascending
            ),
            .value(
                Patterns.be,
                filter: .comparative(
                    pattern(lemma: "old", tag: .comparativeAdjective) ~ Patterns.than,
                    comparison: .greaterThan
                )
            ),
            .value(
                Patterns.be,
                filter: .comparative(
                    pattern(lemma: "young", tag: .comparativeAdjective) ~ Patterns.than,
                    comparison: .lessThan
                )
            )
        )

    let hasParent = ontology.define(property: "hasParent")

    let hasMother = ontology.define(property: "hasMother")
        .isSubProperty(of: hasParent)
        .map(to: .property(Wikidata.P.25))

    let hasFather = ontology.define(property: "hasFather")
        .isSubProperty(of: hasParent)
        .map(to: .property(Wikidata.P.22))

    let hasGender = ontology.define(property: "hasGender")
        .map(to: .property(Wikidata.P.21))

    let Gender = ontology.define(class: "Gender")
        .hasPattern(
            .named(pattern(lemma: "gender", tag: .anyNoun))
        )
        .hasRelation(incoming: hasGender)
        .hasRelation(
            incoming: hasGender,
            pattern: Patterns.of
        )

    let male = ontology.define(individual: "male")
        .isA(Gender)
        .map(to: Wikidata.Q.6581097)

    let female = ontology.define(individual: "female")
        .isA(Gender)
        .map(to: Wikidata.Q.6581072)

    let Male = ontology.define(class: "Male")
        .isSubClass(of: Person)
        .hasEquivalent(outgoing: hasGender, male)
        .hasPatterns(
            .named(pattern(lemma: "male", tag: .anyNoun)),
            .named(pattern(lemma: "man", tag: .anyNoun))
        )

    let Female = ontology.define(class: "Female")
        .isSubClass(of: Person)
        .hasEquivalent(outgoing: hasGender, female)
        .hasPatterns(
            .named(pattern(lemma: "female", tag: .anyNoun)),
            .named(pattern(lemma: "woman", tag: .anyNoun))
        )

    let hasChild = ontology.define(property: "hasChild")
        .hasEquivalent(incoming: hasFather)
        .hasEquivalent(incoming: hasMother)

    hasParent.hasEquivalent(incoming: hasChild)

    let Parent = ontology.define(class: "Parent")
        .isSubClass(of: Person)
        .hasEquivalent(outgoing: hasChild)
        .hasPattern(
            .named(pattern(lemma: "parent", tag: .anyNoun))
        )
        .hasRelation(incoming: hasParent)
        .hasRelation(
            incoming: hasParent,
            pattern: Patterns.of
        )

    ontology.define(class: "Mother")
        .isSubClass(of: Parent)
        .isSubClass(of: Female)
        .hasEquivalent(incoming: hasMother)
        .hasPattern(
            .named(pattern(lemma: "mother", tag: .anyNoun))
        )
        .hasRelation(incoming: hasMother)
        .hasRelation(
            incoming: hasMother,
            pattern: Patterns.of
        )

    ontology.define(class: "Father")
        .isSubClass(of: Parent)
        .isSubClass(of: Male)
        .hasEquivalent(incoming: hasFather)
        .hasPattern(
            .named(pattern(lemma: "father", tag: .anyNoun))
        )
        .hasRelation(incoming: hasFather)
        .hasRelation(
            incoming: hasFather,
            pattern: Patterns.of
        )

    let Child = ontology.define(class: "Child")
        .isSubClass(of: Person)
        .hasEquivalent(incoming: hasChild)
        .hasPattern(
            .named(pattern(lemma: "child", tag: .anyNoun))
        )
        .hasRelation(incoming: hasChild)
        .hasRelation(
            incoming: hasChild,
            pattern: Patterns.of
        )

    ontology.define(class: "Daughter")
        .isSubClass(of: Child)
        .isSubClass(of: Female)
        .hasPattern(
            .named(pattern(lemma: "daughter", tag: .anyNoun))
        )
        // TODO: relation

    ontology.define(class: "Son")
        .isSubClass(of: Child)
        .isSubClass(of: Male)
        .hasPattern(
            .named(pattern(lemma: "son", tag: .anyNoun))
        )
        // TODO: relation

    let hasSpouse = ontology.define(property: "hasSpouse")
        .makeSymmetric()
        .map(to: .property(Wikidata.P.26))
        .hasPatterns(
            .named(
                Patterns.be.opt()
                    ~ pattern(lemma: "marry", tag: .anyVerb)
            ),
            .inverse(
                pattern(lemma: "do", tag: .anyVerb)
                    ~ pattern(lemma: "marry", tag: .anyVerb)
            ),
            .value(
                Patterns.be
                    ~ pattern(lemma: "marry", tag: .anyVerb)
                    ~ pattern(lemma: "to", tag: .prepositionOrSubordinatingConjunction)
            )
        )

    let Spouse = ontology.define(class: "Spouse")
        .isSubClass(of: Person)
        .hasEquivalent(outgoing: hasSpouse)
        .hasPattern(
            .named(pattern(lemma: "spouse", tag: .anyNoun))
        )
        .hasRelation(outgoing: hasSpouse)
        .hasRelation(
            outgoing: hasSpouse,
            pattern: Patterns.of
        )

    ontology.define(class: "Wife")
        .isSubClass(of: Spouse)
        .isSubClass(of: Female)
        .map(to: Wikidata.Q.188830)
        .hasPattern(
            .named(pattern(lemma: "wife", tag: .anyNoun))
        )
        .hasRelation(outgoing: hasSpouse)
        .hasRelation(
            outgoing: hasSpouse,
            pattern: Patterns.of
        )

    ontology.define(class: "Husband")
        .isSubClass(of: Spouse)
        .isSubClass(of: Male)
        .map(to: Wikidata.Q.212878)
        .hasPattern(
            .named(pattern(lemma: "husband", tag: .anyNoun))
        )
        .hasRelation(outgoing: hasSpouse)
        .hasRelation(
            outgoing: hasSpouse,
            pattern: Patterns.of
        )

    let hasSibling = ontology.define(property: "hasSibling")
        .makeSymmetric()
        .map(to: .property(Wikidata.P.3373))

    let Sibling = ontology.define(class: "Sibling")
        .isSubClass(of: Person)
        .hasEquivalent(outgoing: hasSibling)
        .hasPattern(
            .named(pattern(lemma: "sibling", tag: .anyNoun))
        )
        .hasRelation(outgoing: hasSibling)
        .hasRelation(
            outgoing: hasSibling,
            pattern: Patterns.of
        )

    let hasSister = ontology.define(property: "hasSister")
        .isSubProperty(of: hasSibling)
        .map(to: .property(Wikidata.P.9))

    let hasBrother = ontology.define(property: "hasBrother")
        .isSubProperty(of: hasSibling)
        .map(to: .property(Wikidata.P.7))

    ontology.define(class: "Sister")
        .isSubClass(of: Sibling)
        .isSubClass(of: Female)
        .hasEquivalent(incoming: hasSister)
        .hasPattern(
            .named(pattern(lemma: "sister", tag: .anyNoun))
        )
        .hasRelation(incoming: hasSister)
        .hasRelation(
            incoming: hasSister,
            pattern: Patterns.of
        )

    ontology.define(class: "Brother")
        .isSubClass(of: Sibling)
        .isSubClass(of: Male)
        .hasEquivalent(incoming: hasBrother)
        .hasPattern(
            .named(pattern(lemma: "brother", tag: .anyNoun))
        )
        .hasRelation(incoming: hasBrother)
        .hasRelation(
            incoming: hasBrother,
            pattern: Patterns.of
        )

    let GrandParent = ontology.define(class: "GrandParent")
        .isSubClass(of: Parent)
        .hasEquivalent(
            outgoing: hasChild,
            outgoing: hasChild
        )
        .hasPattern(
            .named(pattern(lemma: "grandparent", tag: .anyNoun))
        )
        // TODO: relation

    ontology.define(class: "GrandMother")
        .isSubClass(of: GrandParent)
        .isSubClass(of: Female)
        .hasPattern(
            .named(pattern(lemma: "grandmother", tag: .anyNoun))
        )
        // TODO: relation

    ontology.define(class: "GrandFather")
        .isSubClass(of: GrandParent)
        .isSubClass(of: Male)
        .hasPattern(
            .named(pattern(lemma: "grandfather", tag: .anyNoun))
        )
        // TODO: relation

    let GrandChild = ontology.define(class: "GrandChild")
        .isSubClass(of: Child)
        .hasEquivalent(
            incoming: hasChild,
            incoming: hasChild
        )
        .hasPattern(
            .named(pattern(lemma: "grandchild", tag: .anyNoun))
        )
        // TODO: relation

    ontology.define(class: "GrandDaughter")
        .isSubClass(of: GrandChild)
        .isSubClass(of: Female)
        .hasPattern(
            .named(pattern(lemma: "granddaughter", tag: .anyNoun))
        )
        // TODO: relation

    ontology.define(class: "GrandSon")
        .isSubClass(of: GrandChild)
        .isSubClass(of: Male)
        .hasPattern(
            .named(pattern(lemma: "grandson", tag: .anyNoun))
        )
        // TODO: relation

    return ontology
}()
