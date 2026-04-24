import Foundation

/// Single home for every user-facing string. Keeps tone consistent:
/// - casual, not cutesy
/// - first person plural ("we'll…") keeps it warm
/// - no em dashes
/// - verbs not nouns where possible ("Start a home" not "Create household")
enum Copy {
    enum Tab {
        static let home = "Home"
        static let activity = "Activity"
        static let me = "Me"
    }

    enum Hub {
        static let morningGreeting = "Morning"
        static let afternoonGreeting = "Afternoon"
        static let eveningGreeting = "Evening"
        static let nightGreeting = "Late one"

        static let doItNowTitle = "Do it now"
        static let doItNowEmptyTitle = "Inbox zero"
        static let doItNowEmptySubtitle = "Nothing on your plate. Enjoy."
        static let doItNowPrimary = "Done"
        static let doItNowMore: (Int) -> String = { n in
            n == 0 ? "Last one" : "\(n) more today"
        }

        static let moodTitle = "Not feeling it?"
        static let moodSubtitle = "Tell us the vibe, we'll reshuffle."
        static let moodActive: (String) -> String = { mood in
            "Vibe: \(mood)"
        }
        static let moodClear = "Clear"

        static let balanceTitle = "Who's ahead?"
        static let balanceSubtitleAhead: (String, Int) -> String = { name, delta in
            "You're \(delta) ahead of \(name) this week"
        }
        static let balanceSubtitleBehind: (String, Int) -> String = { name, delta in
            "\(name) is \(delta) ahead. Catch up?"
        }
        static let balanceSubtitleTied = "All square this week"
        static let balanceSubtitleSolo = "Just you, doing the work."

        static let addChoreTitle = "Add a chore"
        static let addChoreSubtitle = "Something new to share."

        static let inviteTitle = "Invite the crew"
        static let inviteSubtitle = "Chores are better shared. Send a code."
        static let invitePrimary = "Get a code"

        static let headingOutTitle = "Heading out?"
        static let headingOutSubtitle: (Int) -> String = { n in
            "\(n) quick errand\(n == 1 ? "" : "s") on the way out."
        }
    }

    enum Activity {
        static let navTitle = "Activity"
        static let upcomingHeader = "What's coming"
        static let recentHeader = "Lately"
        static let emptyTitle = "Nothing to show yet"
        static let emptySubtitle = "Finish a chore and it'll turn up here."

        static let completedBy: (String, String) -> String = { person, title in
            "\(person) finished \(title)"
        }
        static let addedBy: (String, String) -> String = { person, title in
            "\(person) added \(title)"
        }
        static let wasYesterday = "Was yesterday"
    }

    enum Me {
        static let navTitle = "Me"
        static let signedInAs = "That's you"
        static let karma = "Karma"
        static let thisWeek = "This week"
        static let allTime = "All time"
        static let choreLibrary = "Chore library"
        static let choreLibrarySubtitle = "Everything on rotation"
        static let household = "The crew"
        static let householdSubtitle = "Members, categories, rules"
        static let editProfile = "Edit profile"
    }

    enum Mood {
        static let sheetTitle = "How's your battery?"
        static let dismiss = "Never mind"

        static let tiredTitle = "Tired"
        static let tiredSubtitle = "Light stuff only."
        static let rushingTitle = "Rushing"
        static let rushingSubtitle = "Quick hits, 10 min or less."
        static let skipTitle = "Skip something"
        static let skipSubtitle = "Pick a category to dodge today."
        static let bringItTitle = "Bring it on"
        static let bringItSubtitle = "Show me everything."

        static let avoidSheetTitle = "Skip the…"
        static let skipCategory: (String) -> String = { n in "Skip the \(n.lowercased())" }
    }

    enum Wizard {
        static let pageDotOf: (Int, Int) -> String = { i, total in "Step \(i) of \(total)" }
        static let next = "Next"
        static let back = "Back"
        static let addChore = "Add chore"
        static let saveChanges = "Save"

        // Step 1: What
        static let whatTitle = "What's the chore?"
        static let whatFieldPlaceholders = [
            "Empty the dishwasher",
            "Put the bins out",
            "Feed the cat",
            "Vacuum the lounge",
            "Take out recycling",
            "Water the plants"
        ]
        static let whatCategoryHeading = "What kind?"

        // Step 2: When
        static let whenTitle = "When should it happen?"
        static let whenOnce = "Just once"
        static let whenDaily = "Every day"
        static let whenSomeDays = "Some days"
        static let whenWeekly = "Every week"
        static let whenTimeHeading = "What time should we nudge you?"
        static let whenTimePreview: (String) -> String = { t in "We'll buzz at \(t)" }

        // Step 3: Who + Effort
        static let whoEffortTitle = "How heavy, and who's on it?"
        static let effortHeading = "How big a job?"
        static let whoHeading = "Who's doing it?"
        static let whoOpen = "Open to anyone"
    }

    enum Completion {
        static let karmaDelta: (Int) -> String = { n in "+\(n) karma" }
        static let verdictOvertook: (String, Int) -> String = { name, delta in
            "You just overtook \(name) by \(delta)"
        }
        static let verdictBehind: (String, Int) -> String = { name, delta in
            "\(name) is still \(delta) ahead"
        }
        static let verdictTied = "You're tied. It's anybody's week."
        static let verdictSolo = "One down. Keep rolling."
        static let verdictRemaining: (Int) -> String = { n in
            n == 0 ? "That's the lot. Done." : "\(n) to go"
        }
    }

    enum Onboarding {
        static let welcomeKicker = "ChoresApp"
        static let welcomeTitle = "Chores that don't suck."
        static let welcomeBullet1 = "Split the work, fairly."
        static let welcomeBullet2 = "Reminders you actually want."
        static let welcomeBullet3 = "Reshuffle when you're wrecked."
        static let welcomeStart = "Start a home"
        static let welcomeJoin = "Got a code?"

        static let homeTitle = "Name your home"
        static let homeSubtitle = "Something your people will call it."
        static let homeHint = "You can change it later."
        static let homePlaceholder = "The Burrow"
        static let homeContinue = "Continue"

        static let youTitle = "Who are you?"
        static let youSubtitle = "Pick a face your crew will recognise."
        static let youPlaceholder = "Your name"
        static let youContinue = "Continue"

        static let inviteTitle = "Bring the crew?"
        static let inviteSubtitle = "Chores split sweetly with two or more. You can do this later."
        static let inviteShareCode = "Share a code"
        static let inviteSkip = "Skip, just me"

        static let startersTitle = "Pick a starting kit"
        static let startersSubtitle = "We'll seed a few chores you can edit. Skip if you'd rather start blank."
        static let startersContinue = "Use these"
        static let startersSkip = "Blank slate"

        static let doneTitle = "You're in."
        static let doneSubtitle = "Let's sort the place out."
        static let doneCTA = "Take me home"
    }

    enum Common {
        static let cancel = "Cancel"
        static let save = "Save"
        static let done = "Done"
        static let retire = "Retire this chore"
        static let edit = "Edit"
        static let delete = "Delete"
        static let skipToday = "Skip today"
        static let reassign = "Reassign"

        static let karma: (Int) -> String = { n in
            "\(n) karma"
        }
        static let pointsShort: (Int) -> String = { n in
            "\(n)k"
        }
    }
}
