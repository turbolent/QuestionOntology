
import protocol ParserDescription.Pattern
import enum ParserDescription.AnyPattern
import class Foundation.JSONDecoder


public protocol OntologyMapping: Codable, Hashable {}


public protocol OntologyMappings {
    associatedtype Class: OntologyMapping
    associatedtype Property: OntologyMapping
    associatedtype Individual: OntologyMapping
}


public final class QuestionOntology<M> where M: OntologyMappings {

    public private(set) var classes: [String: Class<M>] = [:]
    public private(set) var properties: [String: Property<M>] = [:]
    public private(set) var individuals: [String: Individual<M>] = [:]

    public private(set) var classMapping: TwoWayDictionary<String, M.Class> = [:]
    public private(set) var propertyMapping: TwoWayDictionary<String, M.Property> = [:]
    public private(set) var individualMapping: TwoWayDictionary<String, M.Individual> = [:]

    public private(set) var personClassIdentifier: String?

    public var personClass: Class<M>? {
        set {
            personClassIdentifier = newValue?.identifier
        }
        get {
            return personClassIdentifier.map { classes[$0]! }
        }
    }

    public init() {}

    @discardableResult
    public func define(class identifier: String) -> Class<M> {
        ensureNewDefinition(identifier)
        let newClass = Class(identifier: identifier, ontology: self)
        classes[identifier] = newClass
        return newClass
    }

    @discardableResult
    public func define(property identifier: String) -> Property<M> {
        ensureNewDefinition(identifier)
        let newProperty = Property(identifier: identifier, ontology: self)
        properties[identifier] = newProperty
        return newProperty
    }

    @discardableResult
    public func define(individual identifier: String) -> Individual<M> {
        ensureNewDefinition(identifier)
        let newIndividual = Individual(identifier: identifier, ontology: self)
        individuals[identifier] = newIndividual
        return newIndividual
    }

    private func ensureNewDefinition(_ identifier: String) {
        if let existingIndividual = individuals[identifier] {
            fatalError(
                "invalid definition: \(identifier): "
                    + "already defined as an individual: \(existingIndividual)"
            )
        }
        if let existingProperty = properties[identifier] {
            fatalError(
                "invalid definition: \(identifier): "
                    + "already defined as a property: \(existingProperty)"
            )
        }
        if let existingClass = classes[identifier] {
            fatalError(
                "invalid definition: \(identifier): "
                    + "already defined as a class: \(existingClass)"
            )
        }
    }

    @discardableResult
    public func map(_ class: Class<M>, to mapped: M.Class) -> QuestionOntology {
        ensureNewMapping(mapped)
        if let existingMapping = classMapping[`class`.identifier] {
            fatalError(
                "invalid mapping: \(mapped): class \(`class`) "
                    + "already mapped to \(existingMapping)"
            )
        }
        classMapping[`class`.identifier] = mapped
        return self
    }

    @discardableResult
    public func map(_ property: Property<M>, to mapped: M.Property) -> QuestionOntology {
        ensureNewMapping(mapped)
        if let existingMapping = propertyMapping[property.identifier] {
            fatalError(
                "invalid mapping: \(mapped): property \(property) "
                    + "already mapped to \(existingMapping)"
            )
        }
        propertyMapping[property.identifier] = mapped
        return self
    }

    @discardableResult
    public func map(_ individual: Individual<M>, to mapped: M.Individual) -> QuestionOntology {
        ensureNewMapping(mapped)
        if let existingMapping = individualMapping[individual.identifier] {
            fatalError(
                "invalid mapping: \(mapped): individual \(individual) "
                    + "already mapped to \(existingMapping)"
            )
        }
        individualMapping[individual.identifier] = mapped
        return self
    }

    private func ensureNewMapping(_ mapped: Any) {
        if let individualMapping = mapped as? M.Individual,
            let existingMapping = self.individualMapping[individualMapping]
        {
            fatalError(
                "invalid mapping: \(mapped): "
                    + "already mapped to an individual: \(existingMapping)"
            )
        }
        if let propertyMapping = mapped as? M.Property,
            let existingMapping = self.propertyMapping[propertyMapping]
        {
            fatalError(
                "invalid mapping: \(mapped): "
                    + "already mapped to a property: \(existingMapping)"
            )
        }
        if let classMapping = mapped as? M.Class,
            let existingMapping = self.classMapping[classMapping]
        {
            fatalError(
                "invalid mapping: \(mapped): "
                    + "already mapped to a class: \(existingMapping)"
            )
        }
    }
}


extension QuestionOntology: Equatable {

    public static func == (lhs: QuestionOntology, rhs: QuestionOntology) -> Bool {
        return lhs.classes == rhs.classes
            && lhs.properties == rhs.properties
            && lhs.individuals == rhs.individuals
            && lhs.classMapping == rhs.classMapping
            && lhs.propertyMapping == rhs.propertyMapping
            && lhs.individualMapping == rhs.individualMapping
            && lhs.personClassIdentifier == rhs.personClassIdentifier
    }
}


extension QuestionOntology: Codable {

    internal enum CodingKeys: String, CodingKey {
        case classes
        case properties
        case individuals
        case classMapping = "class_mapping"
        case propertyMapping = "property_mapping"
        case individualMapping = "individual_mapping"
        case personClass = "person_class"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let classes = self.classes.values
            .sorted { $0.identifier < $1.identifier }
        if !classes.isEmpty {
            try container.encode(classes, forKey: .classes)
        }

        let properties = self.properties.values
            .sorted { $0.identifier < $1.identifier }
        if !properties.isEmpty {
            try container.encode(properties, forKey: .properties)
        }

        let individuals = self.individuals.values
            .sorted { $0.identifier < $1.identifier }
        if !individuals.isEmpty {
            try container.encode(individuals, forKey: .individuals)
        }

        if !classMapping.isEmpty {
            try container.encode(classMapping, forKey: .classMapping)
        }

        if !propertyMapping.isEmpty {
            try container.encode(propertyMapping, forKey: .propertyMapping)
        }

        if !individualMapping.isEmpty {
            try container.encode(individualMapping, forKey: .individualMapping)
        }

        try container.encodeIfPresent(personClassIdentifier, forKey: .personClass)
    }

    public static func prepare(decoder: JSONDecoder) {
        decoder.userInfo[questionOntologyCodingUserInfoKey] =
            QuestionOntologyCodingUserInfo<M>()
    }

    public static func codingUserInfo(from decoder: Decoder)
        throws -> QuestionOntologyCodingUserInfo<M>
    {
        guard let codingUserInfo =
            decoder.userInfo[questionOntologyCodingUserInfoKey]
                as? QuestionOntologyCodingUserInfo<M>
        else {
            throw QuestionOntologyDecodingError.notPrepared
        }

        return codingUserInfo
    }

    public convenience init(from decoder: Decoder) throws {
        let codingUserInfo =
            try QuestionOntology<M>.codingUserInfo(from: decoder)

        self.init()
        codingUserInfo.ontology = self

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // decode classes, properties, and individuals

        if let classes =
            try container.decodeIfPresent([Class<M>].self, forKey: .classes)
        {
            for `class` in classes {
                self.classes[`class`.identifier] = `class`
            }
        }

        if let properties =
            try container.decodeIfPresent([Property<M>].self, forKey: .properties)
        {
            for property in properties {
                self.properties[property.identifier] = property
            }
        }

        if let individuals =
            try container.decodeIfPresent([Individual<M>].self, forKey: .individuals)
        {
            for individual in individuals {
                self.individuals[individual.identifier] = individual
            }
        }

        // check references to classes, properties, and individuals

        let undefinedClasses = codingUserInfo.classReferences.filter {
            classes[$0] == nil
        }
        guard undefinedClasses.isEmpty else {
            throw QuestionOntologyDecodingError
                .undefinedClassIdentifiers(undefinedClasses)
        }

        let undefinedProperties = codingUserInfo.propertyReferences.filter {
            properties[$0] == nil
        }
        guard undefinedProperties.isEmpty else {
            throw QuestionOntologyDecodingError
                .undefinedPropertyIdentifiers(undefinedProperties)
        }

        let undefinedIndividuals = codingUserInfo.individualReferences.filter {
            individuals[$0] == nil
        }
        guard undefinedIndividuals.isEmpty else {
            throw QuestionOntologyDecodingError
                .undefinedIndividualIdentifiers(undefinedIndividuals)
        }

        // mappings

        if let classMapping =
            try container.decodeIfPresent(
                TwoWayDictionary<String, M.Class>.self,
                forKey: .classMapping
            )
        {
            self.classMapping = classMapping
        }

        if let propertyMapping =
            try container.decodeIfPresent(
                TwoWayDictionary<String, M.Property>.self,
                forKey: .propertyMapping
            )
        {
            self.propertyMapping = propertyMapping
        }

        if let individualMapping =
            try container.decodeIfPresent(
                TwoWayDictionary<String, M.Individual>.self,
                forKey: .individualMapping
            )
        {
            self.individualMapping = individualMapping
        }

        personClassIdentifier =
            try container.decodeIfPresent(String.self, forKey: .personClass)
    }
}
