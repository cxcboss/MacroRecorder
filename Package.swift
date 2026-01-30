// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacroRecorder",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "MacroRecorder",
            dependencies: [],
            path: ".",
            sources: [
                "MacroRecorderApp.swift", 
                "ContentView.swift", 
                "MacroViewModel.swift", 
                "MouseRecorder.swift", 
                "MousePlayer.swift",
                "MacroModel.swift",
                "MacroStorageManager.swift"
            ],
            resources: [.process("Assets.xcassets")],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .unsafeFlags(["-framework", "CoreGraphics"])
            ]
        )
    ]
)
