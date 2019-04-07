import XCTest
import QuestionOntology
import DiffedAssertEqual
import ParserDescription
import ParserDescriptionOperators
import TestQuestionOntology


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

        let ontology = testQuestionOntology

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

    func testInvalidPropertyEquivalents() throws {
        let encoded = """
        {
          "properties": [
            {
              "identifier": "foo",
              "equivalents": [
                {
                  "segments": [
                    {"incoming": "non-existent"}
                  ]
                }
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

    func testInvalidClassEquivalents() throws {
        let encoded = """
        {
          "classes": [
            {
              "identifier": "foo",
              "equivalents": [
                {
                  "segments": [
                    {"outgoing": "non-existent"}
                  ]
                }
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

    func testInvalidClassEquivalents2() throws {
        let encoded = """
        {
          "classes": [
            {
              "identifier": "foo",
              "equivalents": [
                {
                  "segments": [
                    {"individual": "non-existent"}
                  ]
                }
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
