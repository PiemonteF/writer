import CryptoKit
import Foundation

enum AnnotationBlock {
    static func parse(_ file: String) -> (body: String, authorship: Authorship) {
        guard let split = split(file) else {
            return (file, .selfTyped(length: (file as NSString).length))
        }
        // The newline before `---` is a separator. If the body itself ended in a
        // newline, that same byte is also content; the hash picks the right candidate.
        let candidates = [split.body, split.body + "\n"]
        for body in candidates {
            let utf16 = (body as NSString).length
            if let parsed = authorship(from: split.block, body: body), parsed.length == utf16 {
                return (body, parsed)
            }
        }
        let body = split.body
        return (body, .selfTyped(length: (body as NSString).length))
    }

    static func render(body: String, authorship: Authorship) -> String {
        guard !authorship.isTrivial else { return body }
        let graphemes = groupedGraphemes(authorship, in: body)
        var lines = [
            "---",
            "Annotations: 0,\(body.count) SHA-256 \(digest(body))",
        ]
        for (author, ranges) in graphemes {
            let values = ranges.map { "\($0.location),\($0.length)" }.joined(separator: " ")
            lines.append("\(author.annotationKey): \(values)")
        }
        lines.append("...")
        let trailer = lines.joined(separator: "\n") + "\n"
        if body.isEmpty { return trailer }
        return body.hasSuffix("\n") ? body + trailer : body + "\n" + trailer
    }

    static func split(_ file: String) -> (body: String, block: String)? {
        let marker = "---\nAnnotations:"
        if file.hasPrefix(marker) { return ("", file) }
        guard let range = file.range(of: "\n" + marker, options: .backwards) else { return nil }
        return (String(file[..<range.lowerBound]), String(file[file.index(after: range.lowerBound)...]))
    }

    private static func authorship(from block: String, body: String) -> Authorship? {
        let lines = block.split(whereSeparator: \.isNewline).map(String.init)
        guard let header = lines.first(where: { $0.hasPrefix("Annotations:") }) else { return nil }
        let headerPattern = try! NSRegularExpression(pattern: #"^Annotations:\s*(\d+),(\d+)\s+SHA-256\s+([0-9a-fA-F]+)\s*$"#)
        let headerNS = header as NSString
        guard let match = headerPattern.firstMatch(in: header, range: NSRange(location: 0, length: headerNS.length)) else { return nil }
        let annotatedLength = Int(headerNS.substring(with: match.range(at: 2))) ?? -1
        let hash = headerNS.substring(with: match.range(at: 3)).lowercased()
        guard annotatedLength == body.count, hash == digest(body) else { return nil }

        var runs: [(NSRange, Author)] = []
        let rangePattern = try! NSRegularExpression(pattern: #"(\d+),(\d+)"#)
        for line in lines {
            guard line != "---", line != "...", !line.hasPrefix("Annotations:") else { continue }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            guard let author = Author.parse(key: key) else { continue }
            let rest = String(line[line.index(after: colon)...]) as NSString
            for match in rangePattern.matches(in: rest as String, range: NSRange(location: 0, length: rest.length)) {
                let location = Int(rest.substring(with: match.range(at: 1))) ?? 0
                let length = Int(rest.substring(with: match.range(at: 2))) ?? 0
                let utf16 = utf16Range(grapheme: NSRange(location: location, length: length), in: body)
                if utf16.length > 0 { runs.append((utf16, author)) }
            }
        }
        return fromGraphemeRuns(runs, utf16Length: (body as NSString).length)
    }

    private static func fromGraphemeRuns(_ labeled: [(NSRange, Author)], utf16Length: Int) -> Authorship {
        var authorship = Authorship.selfTyped(length: utf16Length)
        for (range, author) in labeled where author != .selfTyped && NSMaxRange(range) <= utf16Length {
            authorship.mark(range, as: author)
        }
        return authorship
    }

    private static func groupedGraphemes(_ authorship: Authorship, in text: String) -> [(Author, [NSRange])] {
        var groups: [(Author, [NSRange])] = []
        var index: [Author: Int] = [:]
        for (range, author) in authorship.spans() where range.length > 0 {
            let grapheme = graphemeRange(utf16: range, in: text)
            guard grapheme.length > 0 else { continue }
            if let existing = index[author] {
                groups[existing].1.append(grapheme)
            } else {
                index[author] = groups.count
                groups.append((author, [grapheme]))
            }
        }
        return groups
    }

    static func digest(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    static func utf16Range(grapheme: NSRange, in text: String) -> NSRange {
        guard grapheme.location >= 0, grapheme.length >= 0 else { return NSRange(location: 0, length: 0) }
        guard let start = text.index(text.startIndex, offsetBy: grapheme.location, limitedBy: text.endIndex) else {
            return NSRange(location: (text as NSString).length, length: 0)
        }
        let end = text.index(start, offsetBy: grapheme.length, limitedBy: text.endIndex) ?? text.endIndex
        return NSRange(start..<end, in: text)
    }

    static func graphemeRange(utf16: NSRange, in text: String) -> NSRange {
        let ns = text as NSString
        guard utf16.location >= 0, NSMaxRange(utf16) <= ns.length else { return NSRange(location: 0, length: 0) }
        let prefix = ns.substring(to: utf16.location)
        let slice = ns.substring(with: utf16)
        return NSRange(location: prefix.count, length: slice.count)
    }
}
