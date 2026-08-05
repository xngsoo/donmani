import ProjectDescription

public enum Donmani {
    public static let organizationName = "xngsoo"
    public static let bundleIDPrefix = "com.xngsoo.donmani"
    public static let appBundleID = "com.xngsoo.donmani"
    public static let destinations: Destinations = [.iPhone]
    public static let deploymentTargets: DeploymentTargets = .iOS("17.0")

    public static let baseSettings: SettingsDictionary = [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
    ]
}

extension Project {
    /// 모든 Feature/Core/UI 모듈은 이 팩토리로 만든다. 빌드 설정·번들 ID 접두사·배포 타깃을 한곳에서 강제한다.
    public static func module(
        name: String,
        product: Product = .framework,
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = [],
        hasTests: Bool = true,
        testDependencies: [TargetDependency] = []
    ) -> Project {
        let main: Target = .target(
            name: name,
            destinations: Donmani.destinations,
            product: product,
            bundleId: "\(Donmani.bundleIDPrefix).\(name.lowercased())",
            deploymentTargets: Donmani.deploymentTargets,
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: resources,
            dependencies: dependencies,
            settings: .settings(base: Donmani.baseSettings)
        )

        let tests: Target = .target(
            name: "\(name)Tests",
            destinations: Donmani.destinations,
            product: .unitTests,
            bundleId: "\(Donmani.bundleIDPrefix).\(name.lowercased()).tests",
            deploymentTargets: Donmani.deploymentTargets,
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: name)] + testDependencies,
            settings: .settings(base: Donmani.baseSettings)
        )

        return Project(
            name: name,
            organizationName: Donmani.organizationName,
            settings: .settings(base: Donmani.baseSettings),
            targets: hasTests ? [main, tests] : [main]
        )
    }
}

extension TargetDependency {
    public static let core = TargetDependency.project(target: "Core", path: .relativeToRoot("Projects/Core"))
    public static let ui = TargetDependency.project(target: "UI", path: .relativeToRoot("Projects/UI"))

    public static func feature(_ name: String) -> TargetDependency {
        .project(target: name, path: .relativeToRoot("Projects/Features/\(name)"))
    }
}
