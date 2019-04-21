
import ParserDescription
import ParserDescriptionOperators


public enum Tag: String {
    case anyNoun = "N"
    case anyVerb = "V"
    case anyAdjective = "JJ"
    case comparativeAdjective = "JJR"
    case prepositionOrSubordinatingConjunction = "IN"

    var operation: Operation {
        switch self {
        case .anyNoun, .anyVerb, .anyAdjective:
            return .hasPrefix
        case .comparativeAdjective, .prepositionOrSubordinatingConjunction:
            return .isEqualTo
        }
    }
}


private enum Label: String {
    case lemma
    case tag
}


public func pattern(lemma: String, tag: Tag) -> TokenPattern {
    return TokenPattern(condition:
        LabelCondition(
            label: Label.lemma.rawValue,
            op: .isEqualTo,
            input: lemma
        ) && LabelCondition(
            label: Label.tag.rawValue,
            op: tag.operation,
            input: tag.rawValue
        )
    )
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
