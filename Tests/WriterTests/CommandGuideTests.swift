import XCTest
@testable import Writer

final class CommandGuideTests: XCTestCase {
    func testEveryCommandHasATitleAndSummary() {
        XCTAssertGreaterThan(CommandGuide.items.count, 40)
        for item in CommandGuide.items {
            XCTAssertFalse(item.title.isEmpty, item.title)
            XCTAssertFalse(item.summary.isEmpty, item.title)
            XCTAssertFalse(item.group.isEmpty, item.title)
        }
    }

    func testMatchingFindsNameShortcutAndSummary() {
        XCTAssertEqual(CommandGuide.matching("").count, CommandGuide.items.count)
        XCTAssertTrue(CommandGuide.matching("focus").contains { $0.title == "Focus Mode" })
        XCTAssertTrue(CommandGuide.matching("⌥⌘R").contains { $0.title == "Live Markdown Preview" })
        XCTAssertTrue(CommandGuide.matching("sidebar").contains { $0.title == "Library" })
        XCTAssertTrue(CommandGuide.matching("xyzzy").isEmpty)
    }

    func testRowsInsertGroupHeaders() {
        let rows = CommandGuide.rows(matching: "Heading")
        XCTAssertEqual(rows.first, .group("Writer"))
        XCTAssertTrue(rows.contains(.command(CommandGuide.items.first { $0.title == "Heading Tree" }!)))
        XCTAssertTrue(rows.contains(.group("Format")))
    }

    func testCommandsWindowLoads() {
        let controller = CommandGuideController()
        XCTAssertEqual(controller.window?.title, "Commands")
        XCTAssertNotNil(controller.window?.contentViewController as? CommandGuideViewController)
    }

    func testMenuListsCommandsAtTheTopOfViewAndHelp() {
        let menu = MainMenu.build()
        let view = menu.item(withTitle: "View")!.submenu!
        XCTAssertEqual(view.items.first?.title, "Commands…")
        XCTAssertEqual(view.items.first?.keyEquivalent, "/")
        XCTAssertEqual(view.items.first?.keyEquivalentModifierMask, .command)
        XCTAssertEqual(menu.item(withTitle: "Help")?.submenu?.item(withTitle: "Commands…")?.action,
                       #selector(AppDelegate.showCommands(_:)))
    }

    func testCatalogTitlesAppearInTheMenu() {
        let menu = MainMenu.build()
        func flatten(_ menu: NSMenu) -> [String] {
            menu.items.flatMap { [$0.title] + ($0.submenu.map(flatten) ?? []) }
        }
        let titles = Set(flatten(menu))
        for item in CommandGuide.items {
            XCTAssertTrue(titles.contains(item.title), "Missing menu item for \(item.title)")
        }
    }
}
