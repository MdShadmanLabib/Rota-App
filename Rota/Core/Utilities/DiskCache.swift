import Foundation

/// Tiny Codable disk cache for offline-first reads.
/// Stores JSON blobs in the caches directory keyed by a string.
struct DiskCache {
    static let shared = DiskCache()

    private let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("RotaCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    private func url(for key: String) -> URL {
        directory.appendingPathComponent(key.replacingOccurrences(of: "/", with: "_") + ".json")
    }

    func save<T: Encodable>(_ value: T, for key: String) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url(for: key), options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, for key: String) -> T? {
        guard let data = try? Data(contentsOf: url(for: key)) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    func clear() {
        try? FileManager.default.removeItem(at: directory)
    }
}
