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

    static func warning(_ message: String, error: Error? = nil) {
        logger.warning("\(message, privacy: .public)")
        if let error {
            logger.warning("\(String(describing: error), privacy: .private)")
        }
    }

    static func error(_ message: String, error: Error? = nil) {
        logger.error("\(message, privacy: .public)")
        if let error {
            logger.error("\(String(describing: error), privacy: .private)")
        }
    }
}
