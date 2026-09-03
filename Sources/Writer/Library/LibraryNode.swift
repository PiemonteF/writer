import Foundation

final class LibraryNode {
    static let documentExtensions: Set<String> = ["md", "markdown", "mdown", "txt", "text"]

    let url: URL
    let isDirectory: Bool

    init(url: URL, isDirectory: Bool) {
        self.url = url
        self.isDirectory = isDirectory
    }

    var name: String {
        isDirectory ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent
    }

    lazy var children: [LibraryNode] = Self.load(url)

    func reload() {
        children = Self.load(url)
    }

    func matching(_ query: String) -> [LibraryNode] {
        guard isDirectory else {
            return name.localizedCaseInsensitiveContains(query) ? [self] : []
        }
        return children.flatMap { $0.matching(query) }
    }

    private static func load(_ directory: URL) -> [LibraryNode] {
        let keys: [URLResourceKey] = [.isDirectoryKey]
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])) ?? []
        let nodes = urls.compactMap { url -> LibraryNode? in
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            guard isDirectory || documentExtensions.contains(url.pathExtension.lowercased()) else { return nil }
            return LibraryNode(url: url, isDirectory: isDirectory)
        }
        return nodes.sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
