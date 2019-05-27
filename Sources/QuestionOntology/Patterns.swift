
import ParserDescription
import ParserDescriptionOperators


public enum Tag: String {
    case anyNoun = "N"
    case anyVerb = "V"
    case anyAdjective = "J"
    case adjective = "JJ"
    case comparativeAdjective = "JJR"
    case superlativeAdjective = "JJS"
    case prepositionOrSubordinatingConjunction = "IN"

    public static let broadTags: Set<Tag> = [.anyNoun, .anyVerb, .anyAdjective]

    public var label: Label {
        if Tag.broadTags.contains(self) {
            return .broadTag
        }

        return .fineTag
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

    public static func pattern(lemma: String, tag: Tag) -> TokenPattern {
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
}


public func pattern(lemma: String, tag: Tag) -> TokenPattern {
    return Patterns.pattern(lemma: lemma, tag: tag)
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
