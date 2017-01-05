import PackageDescription

let package = Package(
  name: "GrovePiIO",
  dependencies: [
    .Package(url: "https://github.com/ariedoelman/CGrovepi.git", majorVersion: 1)
  ]

)
