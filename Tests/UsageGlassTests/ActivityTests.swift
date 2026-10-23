import Testing
import Foundation
@testable import UsageGlass

struct ActivityTests {
    let now = Date()
    func ago(_ s: TimeInterval) -> Date { now.addingTimeInterval(-s) }

    @Test func MostRecentFreshProviderWins() {
        #expect(ActivityProbe.choose(latest: [.claude: ago(10), .codex: ago(60)], previous: nil, now: now) == .claude)
        #expect(ActivityProbe.choose(latest: [.claude: ago(80), .codex: ago(5)], previous: nil, now: now) == .codex)
    }
    @Test func NothingRecentMeansNone() {
        #expect(ActivityProbe.choose(latest: [.claude: ago(4000), .codex: ago(9000)], previous: nil, now: now) == nil)
        #expect(ActivityProbe.choose(latest: [:], previous: .claude, now: now) == nil)
    }
    @Test func HoldsPreviousThroughShortIdle() {
        #expect(ActivityProbe.choose(latest: [.claude: ago(300)], previous: .claude, now: now) == .claude)
        #expect(ActivityProbe.choose(latest: [.claude: ago(700)], previous: .claude, now: now) == nil)
    }
    @Test func NoFlappingWhenBothFresh() {
        // Codex is only 5s newer than Claude: stay on Claude. 30s newer: switch.
        #expect(ActivityProbe.choose(latest: [.claude: ago(20), .codex: ago(15)], previous: .claude, now: now) == .claude)
        #expect(ActivityProbe.choose(latest: [.claude: ago(60), .codex: ago(5)], previous: .claude, now: now) == .codex)
    }
}
