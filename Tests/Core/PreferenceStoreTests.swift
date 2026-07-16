import XCTest
@testable import Core

final class PreferenceStoreTests: XCTestCase {
    func testBoolPreferenceRoundTrip() {
        let suite = UserDefaults(suiteName: "test.mihon.prefs.\(UUID().uuidString)")!
        defer { suite.removePersistentDomain(forName: suite.dictionaryRepresentation().keys.first.map { _ in suite.suiteName! } ?? "") }

        let store = UserDefaultsPreferenceStore(defaults: suite)
        let pref = store.getBool("flag", default: false)
        XCTAssertFalse(pref.get())
        pref.set(true)
        XCTAssertTrue(pref.get())
    }

    func testReadingModeFlagsMatchAndroid() {
        XCTAssertEqual(ReadingMode.default.flagValue, 0)
        XCTAssertEqual(ReadingMode.leftToRight.flagValue, 1)
        XCTAssertEqual(ReadingMode.rightToLeft.flagValue, 2)
        XCTAssertEqual(ReadingMode.vertical.flagValue, 3)
        XCTAssertEqual(ReadingMode.webtoon.flagValue, 4)
        XCTAssertEqual(ReadingMode.continuousVertical.flagValue, 5)
        XCTAssertEqual(ReadingMode.fromPreference(2), .rightToLeft)
    }

    func testCodablePreference() {
        let suiteName = "test.mihon.theme.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        let store = UserDefaultsPreferenceStore(defaults: suite)
        let pref = store.getObject("theme", default: ThemeMode.system)
        pref.set(.dark)
        XCTAssertEqual(pref.get(), .dark)
        suite.removePersistentDomain(forName: suiteName)
    }
}
