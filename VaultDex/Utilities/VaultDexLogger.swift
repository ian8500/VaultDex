import Foundation
import OSLog

enum VaultDexLogger {
    private static let logger = Logger(subsystem: "ID.VaultDex", category: "VaultDex")

    static func debug(_ message: String) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }

    static func info(_ message: String) {
        #if DEBUG
        logger.info("\(message, privacy: .public)")
        #endif
    }

    static func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
