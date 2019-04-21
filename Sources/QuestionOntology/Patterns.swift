
import ParserDescription
import ParserDescriptionOperators


public enum Tag: String {
    case anyNoun = "N"
    case anyVerb = "V"
    case anyAdjective = "J"
    case comparativeAdjective = "JJR"
    case prepositionOrSubordinatingConjunction = "IN"

    var label: Label {
        switch self {
        case .anyNoun, .anyVerb, .anyAdjective:
            return .broadTag
        case .comparativeAdjective, .prepositionOrSubordinatingConjunction:
            return .fineTag
        }
    }
}


public enum Label: String {
    case lemma
    case fineTag = "fine_tag"
    case broadTag = "broad_tag"
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
