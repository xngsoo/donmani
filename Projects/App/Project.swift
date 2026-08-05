import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Donmani",
    organizationName: Donmani.organizationName,
    settings: .settings(base: Donmani.baseSettings),
    targets: [
        .target(
            name: "Donmani",
            destinations: Donmani.destinations,
            product: .app,
            bundleId: Donmani.appBundleID,
            deploymentTargets: Donmani.deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "돈마니",
                "UILaunchScreen": ["UIColorName": "AccentColor"],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .feature("FeatureHome"),
                .core,
                .ui,
            ],
            settings: .settings(base: Donmani.baseSettings)
        ),
    ]
)
