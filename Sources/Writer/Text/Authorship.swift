import Foundation

enum Author: Equatable, Hashable {
    case selfTyped
    case ai
    case reference
    case human(String)

    var annotationKey: String {
        switch self {
        case .selfTyped: return "@Self"
        case .ai: return "&AI"
        case .reference: return "*Reference"
        case .human(let name): return "@\(name)"
        }
    }

    static func parse(key: String) -> Author? {
        guard let mark = key.first else { return nil }
        let name = key.dropFirst().trimmingCharacters(in: .whitespaces)
        switch mark {
        case "&": return .ai
        case "*": return .reference
        case "@":
            if name.isEmpty || name.caseInsensitiveCompare("Self") == .orderedSame { return .selfTyped }
            return .human(name)
        default: return nil
        }
    }
}

struct Authorship: Equatable {
    struct Run: Equatable {
        var author: Author
        var length: Int
    }

    private(set) var length: Int
    private(set) var runs: [Run]

    static func selfTyped(length: Int) -> Authorship {
        Authorship(length: length, runs: length == 0 ? [] : [Run(author: .selfTyped, length: length)])
    }

    var isTrivial: Bool {
        runs.allSatisfy { $0.author == .selfTyped }
    }

    func spans() -> [(range: NSRange, author: Author)] {
        var pos = 0
        return runs.map { run in
            let span = (NSRange(location: pos, length: run.length), run.author)
            pos += run.length
            return span
        }
    }

    mutating func replace(location: Int, oldLength: Int, newLength: Int, with author: Author) {
        delete(location, oldLength)
        insert(location, newLength, author)
    }

    mutating func mark(_ range: NSRange, as author: Author) {
        replace(location: range.location, oldLength: range.length, newLength: range.length, with: author)
    }

    mutating func splice(_ other: Authorship, at location: Int) {
        precondition(location >= 0 && location <= length)
        guard other.length > 0 else { return }
        split(at: location)
        var pos = 0
        var index = 0
        while index < runs.count, pos < location {
            pos += runs[index].length
            index += 1
        }
        runs.insert(contentsOf: other.runs.filter { $0.length > 0 }, at: index)
        length += other.length
        coalesce()
    }

    mutating func delete(_ location: Int, _ count: Int) {
        precondition(location >= 0 && count >= 0 && location + count <= length)
        guard count > 0 else { return }
        split(at: location)
        split(at: location + count)
        var pos = 0
        var index = 0
        var remaining = count
        while remaining > 0, index < runs.count {
            if pos == location {
                remaining -= runs[index].length
                runs.remove(at: index)
            } else {
                pos += runs[index].length
                index += 1
            }
        }
        length -= count
        coalesce()
    }

    mutating func insert(_ location: Int, _ count: Int, _ author: Author) {
        precondition(location >= 0 && location <= length && count >= 0)
        guard count > 0 else { return }
        split(at: location)
        var pos = 0
        var index = 0
        while index < runs.count, pos < location {
            pos += runs[index].length
            index += 1
        }
        runs.insert(Run(author: author, length: count), at: index)
        length += count
        coalesce()
    }

    func slice(_ range: NSRange) -> Authorship {
        precondition(range.location >= 0 && NSMaxRange(range) <= length)
        guard range.length > 0 else { return .selfTyped(length: 0) }
        var units: [Run] = []
        var pos = 0
        for run in runs {
            let end = pos + run.length
            let overlap = NSIntersectionRange(NSRange(location: pos, length: run.length), range)
            if overlap.length > 0 { units.append(Run(author: run.author, length: overlap.length)) }
            pos = end
            if pos >= NSMaxRange(range) { break }
        }
        return Authorship(length: range.length, runs: units)
    }

    func ownedRatio(in text: NSString) -> Double {
        guard length == text.length, length > 0 else { return 1 }
        var owned = 0
        var total = 0
        var pos = 0
        let whitespace = CharacterSet.whitespacesAndNewlines as NSCharacterSet
        for run in runs {
            for offset in 0..<run.length {
                if !whitespace.characterIsMember(text.character(at: pos + offset)) {
                    total += 1
                    if run.author == .selfTyped { owned += 1 }
                }
            }
            pos += run.length
        }
        return total == 0 ? 1 : Double(owned) / Double(total)
    }

    private mutating func split(at location: Int) {
        guard location > 0, location < length else { return }
        var pos = 0
        for i in 0..<runs.count {
            let end = pos + runs[i].length
            if location == pos || location == end { return }
            if location < end {
                let left = location - pos
                let author = runs[i].author
                runs[i].length = left
                runs.insert(Run(author: author, length: end - location), at: i + 1)
                return
            }
            pos = end
        }
    }

    private mutating func coalesce() {
        var i = 0
        while i + 1 < runs.count {
            if runs[i].author == runs[i + 1].author {
                runs[i].length += runs[i + 1].length
                runs.remove(at: i + 1)
            } else {
                i += 1
            }
        }
        runs.removeAll { $0.length == 0 }
    }
}
