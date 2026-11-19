// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "FormUI",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(
            name: "FormUI",
            type: .static,
            targets: ["FormUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [
        .target(
            name: "MacroUtils",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "FormUICore",
            dependencies: []
        ),
        .macro(
            name: "FormUIMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "MacroUtils",
            ]
        ),
        .target(
            name: "FormUI",
            dependencies: [
                "FormUICore",
                "FormUIMacros"
            ]
        ),
        .testTarget(
            name: "FormUITests",
            dependencies: [
                "FormUI"
            ]
        ),
    ]
)
