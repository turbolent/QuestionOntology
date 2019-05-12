
import ParserDescription
import ParserDescriptionOperators


public enum Tag: String {
    case anyNoun = "N"
    case anyVerb = "V"
    case anyAdjective = "J"
    case adjective = "JJ"
    case comparativeAdjective = "JJR"
    case prepositionOrSubordinatingConjunction = "IN"

    var label: Label {
        switch self {
        case .anyNoun, .anyVerb, .anyAdjective:
            return .broadTag
        case .adjective, .comparativeAdjective, .prepositionOrSubordinatingConjunction:
            return .fineTag
        }
    }
}


public enum Label: String {
    case lemma
    case fineTag = "fine_tag"
    case broadTag = "broad_tag"
}

struct Patterns {
    private init() {}

    static let be = pattern(lemma: "be", tag: .anyVerb)
}


public func pattern(lemma: String, tag: Tag) -> TokenPattern {
    return TokenPattern(condition:
        LabelCondition(
            label: Label.lemma.rawValue,
            op: .isEqualTo,
            input: lemma
        ) && LabelCondition(
            label: tag.label.rawValue,
            op: .isEqualTo,
            input: tag.rawValue
        )
    )
}


/// prefix a word (with lemma and tag) with optional be/V, and suffix with preposition
public func comparativePattern(
    be: Bool,
    lemma: String,
    tag: Tag,
    preposition: String
)
    -> AnyPattern
{
    var sequence =
        pattern(
            lemma: lemma,
            tag: tag
        )
        ~ pattern(
            lemma: preposition,
            tag: .prepositionOrSubordinatingConjunction
        )
    if be {
        sequence = Patterns.be ~ sequence
    }
    return .sequence(sequence)
}


/// prefix an adjective and comparative adjective with optional be/V, and suffix with preposition
public func comparativePattern(
    be: Bool,
    adjective: String,
    comparativeAdjective: String,
    preposition: String
)
    -> AnyPattern
{
    var sequence =
        pattern(
            lemma: adjective,
            tag: .adjective
        )
        ~ pattern(
            lemma: comparativeAdjective,
            tag: .comparativeAdjective
        )
        ~ pattern(
            lemma: preposition,
            tag: .prepositionOrSubordinatingConjunction
    )
    if be {
        sequence = Patterns.be ~ sequence
    }
    return .sequence(sequence)
}


extension _Pattern {
    var hasDefinedLength: Bool {
        switch self {
        case let anyPattern as AnyPattern:
            return anyPattern.pattern.hasDefinedLength
        case is TokenPattern:
            return true
        case let orPattern as OrPattern:
            return orPattern.patterns.allSatisfy { $0.hasDefinedLength }
        case let sequencePattern as SequencePattern:
            return sequencePattern.patterns.allSatisfy { $0.hasDefinedLength }
        case let repetitionPattern as RepetitionPattern:
            return repetitionPattern.pattern.hasDefinedLength
                && repetitionPattern.max != nil
        default:
            return false
        }
    }
}
