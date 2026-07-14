import XCTest

final class PokemonFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func element(labeled label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    @MainActor
    func testListLoadsAndNavigatesToDetail() throws {
        let firstRow = element(labeled: "Bulbasaur")
        XCTAssertTrue(firstRow.waitForExistence(timeout: 15), "Expected the list to load Bulbasaur from the real API")

        firstRow.tap()

        let detailTitle = app.navigationBars["Bulbasaur"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 15), "Expected navigation to the Bulbasaur detail screen")

        let statsHeader = app.staticTexts["Estadísticas"]
        XCTAssertTrue(statsHeader.waitForExistence(timeout: 15), "Expected detail content to finish loading")
    }

    @MainActor
    func testListShowsMultiplePokemonRows() throws {
        XCTAssertTrue(element(labeled: "Bulbasaur").waitForExistence(timeout: 15))
        XCTAssertTrue(element(labeled: "Charmander").waitForExistence(timeout: 15))
        XCTAssertTrue(element(labeled: "Squirtle").waitForExistence(timeout: 15))
    }
}
