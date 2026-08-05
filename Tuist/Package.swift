// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(
    productTypes: [:]
)
#endif

let package = Package(
    name: "Donmani",
    dependencies: [
        // 외부 SPM 의존성은 여기에 추가한 뒤 `tuist install` → `tuist generate`
    ]
)
