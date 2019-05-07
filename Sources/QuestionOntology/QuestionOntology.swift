
import protocol ParserDescription.Pattern
import enum ParserDescription.AnyPattern
import class Foundation.JSONDecoder


public protocol OntologyMapping: Codable, Hashable {}


public protocol OntologyMappings {
    associatedtype Class: OntologyMapping
    associatedtype Property: OntologyMapping
    associatedtype Individual: OntologyMapping
}


public typealias OntologyClass = Class
public typealias OntologyProperty = Property
public typealias OntologyIndividual = Individual


public final class QuestionOntology<Mappings>
    where Mappings: OntologyMappings
{

    public typealias Class = OntologyClass<Mappings>
    public typealias Property = OntologyProperty<Mappings>
    public typealias Individual = OntologyIndividual<Mappings>

    public private(set) var classes: [String: Class] = [:]
    public private(set) var properties: [String: Property] = [:]
    public private(set) var individuals: [String: Individual] = [:]

    public private(set) var classMapping: TwoWayDictionary<String, Mappings.Class> = [:]
    public private(set) var propertyMapping: TwoWayDictionary<String, Mappings.Property> = [:]
    public private(set) var individualMapping: TwoWayDictionary<String, Mappings.Individual> = [:]

    public private(set) var personClassIdentifier: String?
    public private(set) var instancePropertyIdentifier: String?
    public private(set) var labelPropertyIdentifier: String?

    public var personClass: Class? {
        set {
            personClassIdentifier = newValue?.identifier
        }
        get {
            return personClassIdentifier.map { classes[$0]! }
        }
    }

    public var instanceProperty: Property? {
        set {
            instancePropertyIdentifier = newValue?.identifier
        }
        get {
            return instancePropertyIdentifier.map { properties[$0]! }
        }
    }

    public var labelProperty: Property? {
        set {
            labelPropertyIdentifier = newValue?.identifier
        }
        get {
            return labelPropertyIdentifier.map { properties[$0]! }
        }
    }

    public init() {}

    @discardableResult
    public func define(class identifier: String) -> ClassBuilder<Mappings> {
        ensureNewDefinition(identifier)
        let newClass = Class(identifier: identifier)
        classes[identifier] = newClass
        return ClassBuilder(ontology: self, class: newClass)
    }

    @discardableResult
    public func define(property identifier: String) -> PropertyBuilder<Mappings> {
        ensureNewDefinition(identifier)
        let newProperty = Property(identifier: identifier)
        properties[identifier] = newProperty
        return PropertyBuilder(ontology: self, property: newProperty)
    }

    @discardableResult
    public func define(individual identifier: String) -> IndividualBuilder<Mappings> {
        ensureNewDefinition(identifier)
        let newIndividual = Individual(identifier: identifier)
        individuals[identifier] = newIndividual
        return IndividualBuilder(ontology: self, individual: newIndividual)
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
    public func map(_ class: Class, to mapped: Mappings.Class) -> QuestionOntology {
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
    public func map(_ property: Property, to mapped: Mappings.Property) -> QuestionOntology {
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
    public func map(_ individual: Individual, to mapped: Mappings.Individual) -> QuestionOntology {
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
        if let individualMapping = mapped as? Mappings.Individual,
            let existingMapping = self.individualMapping[individualMapping]
        {
            fatalError(
                "invalid mapping: \(mapped): "
                    + "already mapped to an individual: \(existingMapping)"
            )
        }
        if let propertyMapping = mapped as? Mappings.Property,
            let existingMapping = self.propertyMapping[propertyMapping]
        {
            fatalError(
                "invalid mapping: \(mapped): "
                    + "already mapped to a property: \(existingMapping)"
            )
        }
        if let classMapping = mapped as? Mappings.Class,
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
            && lhs.instancePropertyIdentifier == rhs.instancePropertyIdentifier
            && lhs.labelPropertyIdentifier == rhs.labelPropertyIdentifier
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
        case instanceProperty = "instance_property"
        case labelProperty = "label_property"
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
        try container.encodeIfPresent(instancePropertyIdentifier, forKey: .instanceProperty)
        try container.encodeIfPresent(labelPropertyIdentifier, forKey: .labelProperty)
    }

    public static func prepare(decoder: JSONDecoder) {
        decoder.userInfo[questionOntologyCodingUserInfoKey] =
            QuestionOntologyCodingUserInfo<Mappings>()
    }

    public static func codingUserInfo(from decoder: Decoder)
        throws -> QuestionOntologyCodingUserInfo<Mappings>
    {
        guard let codingUserInfo =
            decoder.userInfo[questionOntologyCodingUserInfoKey]
                as? QuestionOntologyCodingUserInfo<Mappings>
        else {
            throw QuestionOntologyDecodingError.notPrepared
        }

        return codingUserInfo
    }

    public convenience init(from decoder: Decoder) throws {
        let codingUserInfo =
            try QuestionOntology<Mappings>.codingUserInfo(from: decoder)

        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // decode classes, properties, and individuals

        if let classes =
            try container.decodeIfPresent([Class].self, forKey: .classes)
        {
            for `class` in classes {
                self.classes[`class`.identifier] = `class`
            }
        }

        if let properties =
            try container.decodeIfPresent([Property].self, forKey: .properties)
        {
            for property in properties {
                self.properties[property.identifier] = property
            }
        }

        if let individuals =
            try container.decodeIfPresent([Individual].self, forKey: .individuals)
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
                TwoWayDictionary<String, Mappings.Class>.self,
                forKey: .classMapping
            )
        {
            self.classMapping = classMapping
        }

        if let propertyMapping =
            try container.decodeIfPresent(
                TwoWayDictionary<String, Mappings.Property>.self,
                forKey: .propertyMapping
            )
        {
            self.propertyMapping = propertyMapping
        }

        if let individualMapping =
            try container.decodeIfPresent(
                TwoWayDictionary<String, Mappings.Individual>.self,
                forKey: .individualMapping
            )
        {
            self.individualMapping = individualMapping
        }

        personClassIdentifier =
            try container.decodeIfPresent(String.self, forKey: .personClass)

        instancePropertyIdentifier =
            try container.decodeIfPresent(String.self, forKey: .instanceProperty)

        labelPropertyIdentifier =
            try container.decodeIfPresent(String.self, forKey: .labelProperty)
    }
}
