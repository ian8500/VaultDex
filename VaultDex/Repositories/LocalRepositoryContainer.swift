import Foundation

enum VaultRuntimeMode: String, Equatable {
    case demo
    case supabase
    case offline

    var displayName: String {
        switch self {
        case .demo: "Demo"
        case .supabase: "Cloud"
        case .offline: "Offline Cache"
        }
    }
}

struct LocalRepositoryContainer {
    let demoRepository: DemoVaultRepository

    static func demo(repository: DemoVaultRepository = .shared) -> LocalRepositoryContainer {
        LocalRepositoryContainer(demoRepository: repository)
    }
}
