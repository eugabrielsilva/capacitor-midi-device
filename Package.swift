// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "EugabrielsilvaCapacitorMidiDevice", 
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "EugabrielsilvaCapacitorMidiDevice",
            targets: ["CapacitorMIDIDevicePlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "CapacitorMIDIDevicePlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm")
            ],
            path: "ios/Plugin"
        )
    ]
)