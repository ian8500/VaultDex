import Foundation

enum VaultRuntimeMode: String, Equatable {
    case demo
    case supabase

    var displayName: String {
        switch self {
        case .demo: "Local Demo"
        case .supabase: "Supabase"
        }
    }
}

struct LocalRepositoryContainer {
    let demoRepository: DemoVaultRepository

    static func demo(repository: DemoVaultRepository = .shared) -> LocalRepositoryContainer {
        LocalRepositoryContainer(demoRepository: repository)
    }
}

