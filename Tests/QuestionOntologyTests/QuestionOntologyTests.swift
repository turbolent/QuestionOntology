import XCTest
import QuestionOntology
import DiffedAssertEqual
import ParserDescription
import ParserDescriptionOperators


@available(OSX 10.13, *)
final class QuestionOntologyTests: XCTestCase {

    static let fileURL = URL(fileURLWithPath: #file)

    private func loadFixture(path: String) throws -> Data {
        let url = URL(
            fileURLWithPath: path,
            relativeTo: QuestionOntologyTests.fileURL
        )
        return try Data(contentsOf: url)
    }

    func testDefinitions() throws {

        let ontology = QuestionOntology<WikidataOntologyMappings>()

        let Person = ontology.define(class: "Person")
            .map(to: Wikidata.Q.5)
            .hasPatterns(
                pattern(lemma: "person", tag: .noun),
                pattern(lemma: "people", tag: .noun)
            )

        let hasDateOfBirth = ontology.define(property: "hasDateOfBirth")
            .map(to: .property(Wikidata.P.569))

        let hasDateOfDeath = ontology.define(property: "hasDateOfDeath")
            .map(to: .property(Wikidata.P.570))

        ontology.define(property: "hasAge")
            .map(to: .operation(
                .age(
                    birthDateProperty: hasDateOfBirth,
                    deathDateProperty: hasDateOfDeath
                ))
            )

        let hasPlaceOfBirth = ontology.define(property: "hasPlaceOfBirth")
            .map(to: .property(Wikidata.P.19))

        let hasPlaceOfDeath = ontology.define(property: "hasPlaceOfDeath")
            .map(to: .property(Wikidata.P.20))

        let hasParent = ontology.define(property: "hasParent")

        let hasMother = ontology.define(property: "hasMother")
            .isSubProperty(of: hasParent)
            .map(to: .property(Wikidata.P.25))

        let hasFather = ontology.define(property: "hasFather")
            .isSubProperty(of: hasParent)
            .map(to: .property(Wikidata.P.22))

        let Gender = ontology.define(class: "Gender")

        let male = ontology.define(individual: "male")
            .isA(Gender)
            .map(to: Wikidata.Q.6581097)

        let female = ontology.define(individual: "female")
            .isA(Gender)
            .map(to: Wikidata.Q.6581072)

        let hasGender = ontology.define(property: "hasGender")
            .map(to: .property(Wikidata.P.21))

        let Male = ontology.define(class: "Male")
            .isSubClass(of: Person)
            .hasEquivalent(outgoing: hasGender, male)
            .hasPatterns(
                pattern(lemma: "male", tag: .noun),
                pattern(lemma: "man", tag: .noun)
            )

        let Female = ontology.define(class: "Female")
            .isSubClass(of: Person)
            .hasEquivalent(outgoing: hasGender, female)
            .hasPatterns(
                pattern(lemma: "female", tag: .noun),
                pattern(lemma: "woman", tag: .noun)
            )

        let hasChild = ontology.define(property: "hasChild")
            .hasEquivalent(incoming: hasFather)
            .hasEquivalent(incoming: hasMother)

        hasParent.hasEquivalent(incoming: hasChild)

        let Parent = ontology.define(class: "Parent")
            .isSubClass(of: Person)
            .hasEquivalent(outgoing: hasChild)
            .hasPattern(pattern(lemma: "parent", tag: .noun))

        ontology.define(class: "Mother")
            .isSubClass(of: Parent)
            .isSubClass(of: Female)
            .hasEquivalent(incoming: hasMother)
            .hasPattern(pattern(lemma: "mother", tag: .noun))

        ontology.define(class: "Father")
            .isSubClass(of: Parent)
            .isSubClass(of: Male)
            .hasEquivalent(incoming: hasFather)
            .hasPattern(pattern(lemma: "father", tag: .noun))

        let Child = ontology.define(class: "Child")
            .isSubClass(of: Person)
            .hasEquivalent(incoming: hasChild)
            .hasPattern(pattern(lemma: "child", tag: .noun))

        ontology.define(class: "Daughter")
            .isSubClass(of: Child)
            .isSubClass(of: Female)
            .hasPattern(pattern(lemma: "daughter", tag: .noun))

        ontology.define(class: "Son")
            .isSubClass(of: Child)
            .isSubClass(of: Male)
            .hasPattern(pattern(lemma: "son", tag: .noun))

        let hasSpouse = ontology.define(property: "hasSpouse")
            .makeSymmetric()
            .map(to: .property(Wikidata.P.26))

        let Spouse = ontology.define(class: "Spouse")
            .hasPattern(pattern(lemma: "spouse", tag: .noun))

        ontology.define(class: "Wife")
            .isSubClass(of: Spouse)
            .isSubClass(of: Female)
            .map(to: Wikidata.Q.188830)
            .hasPattern(pattern(lemma: "wife", tag: .noun))

        ontology.define(class: "Husband")
            .isSubClass(of: Spouse)
            .isSubClass(of: Male)
            .map(to: Wikidata.Q.212878)
            .hasPattern(pattern(lemma: "husband", tag: .noun))

        let hasSibling = ontology.define(property: "hasSibling")
            .makeSymmetric()
            .map(to: .property(Wikidata.P.3373))

        let Sibling = ontology.define(class: "Sibling")
            .isSubClass(of: Person)
            .hasEquivalent(outgoing: hasSibling)
            .hasPattern(pattern(lemma: "sibling", tag: .noun))

        ontology.define(class: "Sister")
            .isSubClass(of: Sibling)
            .isSubClass(of: Female)
            .hasPattern(pattern(lemma: "sister", tag: .noun))

        ontology.define(class: "Brother")
            .isSubClass(of: Sibling)
            .isSubClass(of: Male)
            .hasPattern(pattern(lemma: "brother", tag: .noun))

        ontology.define(property: "hasBrother")
            .isSubProperty(of: hasSibling)
            .map(to: .property(Wikidata.P.7))

        ontology.define(property: "hasSister")
            .isSubProperty(of: hasSibling)
            .map(to: .property(Wikidata.P.9))

        let GrandParent = ontology.define(class: "GrandParent")
            .isSubClass(of: Parent)
            .hasEquivalent(
                outgoing: hasChild,
                outgoing: hasChild
            )
            .hasPattern(pattern(lemma: "grandparent", tag: .noun))

        ontology.define(class: "GrandMother")
            .isSubClass(of: GrandParent)
            .isSubClass(of: Female)
            .hasPattern(pattern(lemma: "grandmother", tag: .noun))

        ontology.define(class: "GrandFather")
            .isSubClass(of: GrandParent)
            .isSubClass(of: Male)
            .hasPattern(pattern(lemma: "grandfather", tag: .noun))

        let GrandChild = ontology.define(class: "GrandChild")
            .isSubClass(of: Child)
            .hasEquivalent(
                incoming: hasChild,
                incoming: hasChild
            )
            .hasPattern(pattern(lemma: "grandchild", tag: .noun))

        ontology.define(class: "GrandDaughter")
            .isSubClass(of: GrandChild)
            .isSubClass(of: Female)
            .hasPattern(pattern(lemma: "granddaughter", tag: .noun))

        ontology.define(class: "GrandSon")
            .isSubClass(of: GrandChild)
            .isSubClass(of: Male)
            .hasPattern(pattern(lemma: "grandson", tag: .noun))


        ontology.add(
            namedPropertyPattern:
                pattern(lemma: "be", tag: .verb)
                    ~ pattern(lemma: "bear", tag: .verb),
            properties: hasDateOfBirth, hasPlaceOfBirth
        )

        ontology.add(
            namedPropertyPattern:
                pattern(lemma: "die", tag: .verb),
            properties: hasDateOfDeath, hasPlaceOfDeath
        )

        ontology.add(
            namedPropertyPattern:
                pattern(lemma: "be", tag: .verb).opt()
                    ~ pattern(lemma: "marry", tag: .verb),
            properties: hasSpouse
        )


        let expectedOntologyJSON =
            String(data: try loadFixture(path: "ontology.json"), encoding: .utf8)!

        diffedAssertJSONEqual(
            expectedOntologyJSON,
            ontology
        )

        let encoded = try JSONEncoder().encode(ontology)

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)

        let decodedOntology =
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded
            )

        XCTAssertEqual(ontology, decodedOntology)
    }

    func testInvalidSuperProperties() throws {
        let encoded = """
        {
          "properties": [
            {
              "identifier": "foo",
              "superproperties": ["non-existent"]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedPropertyIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidPropertyEquivalencies() throws {
        let encoded = """
        {
          "properties": [
            {
              "identifier": "foo",
              "equivalencies": [
                [
                  {"incoming": "non-existent"}
                ]
              ]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedPropertyIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidClassEquivalencies() throws {
        let encoded = """
        {
          "classes": [
            {
              "identifier": "foo",
              "equivalencies": [
                [
                  {"outgoing": "non-existent"}
                ]
              ]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedPropertyIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidClassEquivalencies2() throws {
        let encoded = """
        {
          "classes": [
            {
              "identifier": "foo",
              "equivalencies": [
                [
                  {"individual": "non-existent"}
                ]
              ]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedIndividualIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidSuperClasses() throws {
        let encoded = """
        {
          "classes": [
            {
              "identifier": "foo",
              "superclasses": ["non-existent"]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedClassIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidTypes() throws {
        let encoded = """
        {
          "individuals": [
            {
              "identifier": "foo",
              "types": ["non-existent"]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedClassIdentifiers(["non-existent"]), error)
        }
    }
}
