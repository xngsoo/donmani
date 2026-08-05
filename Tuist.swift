import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("26.0"),
        generationOptions: .options(
            defaultSwiftVersion: "6.0"
        )
    )
)
