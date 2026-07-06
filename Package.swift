// swift-tools-version:5.9
import PackageDescription

// App de barra de menú (macOS 13+) que muestra la campaña Yanbal actual.
// El motor de cálculo vive en la librería CampaignKit (Foundation puro y testeable);
// el ejecutable YanbalCampanas es la capa SwiftUI. build.sh empaqueta el .app.
let package = Package(
  name: "YanbalCampanas",
  platforms: [
    .macOS(.v13),
  ],
  targets: [
    .target(
      name: "CampaignKit",
      path: "Sources/CampaignKit"
    ),
    .executableTarget(
      name: "YanbalCampanas",
      dependencies: ["CampaignKit"],
      path: "Sources/YanbalCampanas"
    ),
    .testTarget(
      name: "CampaignKitTests",
      dependencies: ["CampaignKit"],
      path: "Tests/CampaignKitTests"
    ),
  ]
)
