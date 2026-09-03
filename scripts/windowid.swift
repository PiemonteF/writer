import CoreGraphics

let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
for window in windows
where window[kCGWindowOwnerName as String] as? String == "Writer"
    && window[kCGWindowLayer as String] as? Int == 0 {
    if let number = window[kCGWindowNumber as String] as? Int {
        print(number)
        break
    }
}
