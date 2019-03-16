
import Foundation


public enum QuestionOntologyDecodingError: Error, Equatable {
    case notPrepared
    case missingPropertyExactly(String)
    case missingPropertyOneOf(Set<String>)
    case undefinedClassIdentifiers(Set<String>)
    case undefinedPropertyIdentifiers(Set<String>)
    case undefinedIndividualIdentifiers(Set<String>)
}

extension QuestionOntologyDecodingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notPrepared:
            return "The decoder was not prepared. Call QuestionOntology.prepare(decoder:)."
        case .missingPropertyExactly(let name):
            return "The object is missing the required property: \(name)"
        case .missingPropertyOneOf(let names):
            return "The object is missing one of the required properties: "
                + names.joined(separator: ", ")
        case .undefinedClassIdentifiers(let identifiers):
            return "The ontology references the undefined classes: "
                + identifiers.joined(separator: ", ")
        case .undefinedPropertyIdentifiers(let identifiers):
            return "The ontology references the undefined properties: "
                + identifiers.joined(separator: ", ")
        case .undefinedIndividualIdentifiers(let identifiers):
            return "The ontology references the undefined individuals: "
                + identifiers.joined(separator: ", ")
        }
    }
}


// The coding user-info key used to pass the ontology being decoded to the child elements.
// As Decoder's `userInfo` property is read-only, use a box that can be mutated from within
// `QuestionOntology.init(from: Decoder)`

internal let questionOntologyCodingUserInfoKey =
    CodingUserInfoKey(rawValue: "questionOntologyCodingUserInfoKey")!


public final class QuestionOntologyCodingUserInfo<M> where M: OntologyMappings {
    public internal(set) var ontology: QuestionOntology<M>?
    public private(set) var classReferences: Set<String> = []
    public private(set) var propertyReferences: Set<String> = []
    public private(set) var individualReferences: Set<String> = []

    public func reference(class identifier: String) {
        classReferences.insert(identifier)
    }

    public func reference(property identifier: String) {
        propertyReferences.insert(identifier)
    }

    public func reference(individual identifier: String) {
        individualReferences.insert(identifier)
    }
}
