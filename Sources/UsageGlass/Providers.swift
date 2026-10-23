import Foundation
import Darwin

struct CollectionResult: Decodable, Sendable {
    var snapshots: [ProviderSnapshot]
    var sessions: [SessionUsage]
    var bridgeStatus: String
}
struct BridgeResult: Decodable { var message: String?; var error: String? }
enum ProviderError: Error { case unavailable }

enum Providers {
    static func run(_ argument: String) async throws -> Data {
        try await Task.detached(priority: .utility) {
            // Packaged apps must be self-contained. Never evaluate SwiftPM's fatal
            // Bundle.module accessor inside an app: its fallback embeds a build path.
            let script: URL
            if Bundle.main.bundleURL.pathExtension == "app" {
                guard let resource = Bundle.main.resourceURL?.appendingPathComponent("usageglass_backend.py"),
                      FileManager.default.fileExists(atPath: resource.path) else { throw ProviderError.unavailable }
                script = resource
            } else {
                guard let resource = Bundle.module.url(forResource: "usageglass_backend", withExtension: "py", subdirectory: "Resources"),
                      FileManager.default.fileExists(atPath: resource.path) else { throw ProviderError.unavailable }
                script = resource
            }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = [script.path, argument]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            try process.run()
            // Backend bounds every subprocess/read. This watchdog additionally bounds interpreter failure.
            let watchdog = DispatchWorkItem { if process.isRunning { kill(process.processIdentifier, SIGKILL); try? output.fileHandleForReading.close() } }
            DispatchQueue.global().asyncAfter(deadline: .now() + 25, execute: watchdog)
            var data = Data()
            while let chunk = try output.fileHandleForReading.read(upToCount: 65536), !chunk.isEmpty {
                data.append(chunk)
                if data.count > 4 * 1024 * 1024 {
                    kill(process.processIdentifier, SIGKILL)
                    watchdog.cancel()
                    throw ProviderError.unavailable
                }
            }
            process.waitUntilExit()
            watchdog.cancel()
            guard process.terminationStatus == 0, data.count <= 4 * 1024 * 1024 else { throw ProviderError.unavailable }
            return data
        }.value
    }
    static func collect() async throws -> CollectionResult {
        let data = try await run("--collect")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(CollectionResult.self, from: data)
    }
    static func bridge(install: Bool) async -> String {
        do {
            let result = try JSONDecoder().decode(BridgeResult.self, from: await run(install ? "--install" : "--uninstall"))
            return result.message ?? result.error ?? "Bridge operation unavailable."
        } catch { return "Bridge operation unavailable. Settings were not replaced by this request." }
    }
}
