// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "QuestionOntology",
    products: [
        .library(
            name: "QuestionOntology",
            targets: ["QuestionOntology"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/turbolent/DiffedAssertEqual.git", from: "0.1.0"),
        .package(url: "https://github.com/turbolent/ParserDescription.git", from: "0.4.0"),
    ],
    targets: [
        .target(
            name: "QuestionOntology",
            dependencies: [
                "ParserDescription",
                "ParserDescriptionOperators"
            ]
        ),
        .testTarget(
            name: "QuestionOntologyTests",
            dependencies: [
                "QuestionOntology",
                "DiffedAssertEqual",
                "ParserDescription",
                "ParserDescriptionOperators"
            ]
        ),
    ]
)
