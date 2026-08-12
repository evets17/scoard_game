# Board Game Scoring Platform

## Product and Design Overview

## 1. Product Vision

The Board Game Scoring Platform is a mobile application for recording, calculating, comparing, and preserving board-game scores.

The application focuses on scoring activities that occur:

* At the end of a round
* At the end of a hand or phase
* At the end of the game

It is not intended to recreate the boards, scorecards, grids, tracks, or other physical components that players actively use during gameplay.

The platform should support several levels of scoring complexity:

* Quick recording of final scores
* Round-based score accumulation
* Structured end-game score tally sheets
* Games that combine round scoring with final bonuses or penalties
* Result-only recording for games that do not require detailed score calculation

A central architectural goal is to make game-specific scoring templates easy to create using AI coding agents.

An AI agent should be able to review a game’s scoring rules and produce a template that uses the application’s existing:

* Player management
* Session management
* Score-entry controls
* Calculations
* Validation
* Persistence
* Synchronization
* History
* Statistics

The same template system should remain understandable and maintainable by human developers and, eventually, advanced users.

---

## 2. Product Scope

The platform supports the process of converting completed gameplay results into recorded scores.

It should answer questions such as:

* What did each player score this round?
* What scoring categories contribute to each player’s final score?
* What is each player’s cumulative score?
* Who is currently leading?
* Has a game-ending score threshold been reached?
* Who won?
* What happened in previous sessions?
* How has a player performed over time?

The platform is not intended to answer gameplay questions such as:

* What move may a player make?
* Where may a value legally be placed?
* Which dice should be kept?
* Which card should be selected?
* Which category must be used during the current turn?
* How many resources does a player currently possess?
* What is the complete current game state?

The app records the results of gameplay. It does not normally manage gameplay itself.

---

## 3. Scoring Terminology

The project should use precise terminology to avoid ambiguity around the phrase “score sheet.”

## 3.1 Gameplay Sheet

A gameplay sheet is an active part of playing a game.

Players write, mark, select, draw, or place values on the sheet during gameplay. The current state of the sheet affects available choices, legal actions, or future strategy.

Examples include:

* The numbered rows and columns used while playing Qwinto
* The category boxes used throughout a game of Yahtzee
* A roll-and-write grid
* A route map on which players draw connections
* A bingo-style card marked during play
* A player board used to track resources and abilities
* A progression track that affects later actions

Although a gameplay sheet may eventually contribute to a final score, its primary purpose is to facilitate gameplay.

Digitally recreating it may require:

* Turn tracking
* Legal-move validation
* Placement constraints
* Game-state management
* Rule enforcement
* Resource tracking
* In-game decision support

That functionality is outside the normal scope of this platform.

## 3.2 Score Tally Sheet

A score tally sheet is a structured form used to collect the scoring elements that make up a completed round score or final game score.

It is typically used after gameplay, or after a defined portion of gameplay, has finished.

A score tally sheet may contain:

* Scoring categories
* Quantities
* Completed objectives
* Sets or collections
* Multipliers
* Subtotals
* Bonuses
* Penalties
* Tie-break values
* Final totals

Many games include a paper tally sheet or scoring pad that helps players calculate final scores. Digitizing this type of scoring workflow is a primary purpose of the application.

## 3.3 Round Score

A round score is calculated after one completed round, hand, or scoring phase.

The underlying gameplay for that round has already occurred. The application records the result.

## 3.4 Cumulative Score

A cumulative score is produced by combining scores from multiple completed rounds.

Depending on the game:

* The highest cumulative score may win.
* The lowest cumulative score may win.
* Reaching a target score may end the game.
* Exceeding a threshold may trigger the final round.

## 3.5 Final Score

A final score is the completed result for one player after all applicable:

* Round scores
* Scoring categories
* Bonuses
* Penalties
* Multipliers
* Tie-break values

have been entered and calculated.

## 3.6 Game Scoring Template

A game scoring template is a reusable configuration that defines how end-of-round or end-of-game scores are:

* Entered
* Calculated
* Validated
* Displayed
* Compared
* Saved

The term “score sheet” should be avoided when it could refer to either a gameplay sheet or score tally sheet.

---

## 4. Scope Examples

## 4.1 Qwinto

Qwinto uses a gameplay sheet that players fill in throughout the game.

A complete digital recreation would need to support:

* Entering individual number placements
* Tracking exact row and column positions
* Enforcing increasing values within rows
* Preventing entries in unusable spaces
* Validating cross-row restrictions
* Recording penalties during play
* Detecting legal and illegal placements

That functionality belongs in a dedicated Qwinto gameplay application.

The Board Game Scoring Platform would instead provide an end-game Qwinto score tally template.

The template might record:

* Orange-row score
* Yellow-row score
* Purple-row score
* Scored pentagon-column values
* Number of penalties
* Penalty-point total
* Final score

The user would obtain these values from the completed physical Qwinto sheet.

The app would:

1. Guide the user through the scoring components.
2. Calculate the final total.
3. Compare players.
4. Determine the winner.
5. Save the result.

## 4.2 Yahtzee

A Yahtzee scorecard is used throughout the game.

Selecting which category receives a dice result is part of the gameplay and affects future decisions. A complete digital Yahtzee scorecard is therefore a gameplay sheet.

The general platform would not normally replace the turn-by-turn scorecard.

A final-result template could instead record:

* Upper-section subtotal
* Upper-section bonus
* Lower-section subtotal
* Yahtzee bonuses
* Other applicable adjustments
* Final score

A dedicated Yahtzee application could support full turn-by-turn category selection, but that is outside the normal template scope.

## 4.3 Skyjo

Skyjo is naturally suited to round-based scoring.

After each round, each player has a completed round score. The platform should record:

* Each player’s round score
* Cumulative totals
* Current standings
* Whether the game-ending threshold has been reached
* The final winner

The application does not need to track cards, columns, turns, or card flips during the round.

## 4.4 End-Game Category Scoring

Many strategy games are played using physical boards, cards, tiles, and tokens. At the end of the game, players calculate points from several sources.

A template may collect:

* Building points
* Objective points
* Resource points
* Set bonuses
* Territory points
* Remaining money
* Completed achievements
* Penalties

This is an ideal use of a structured score tally sheet.

---

## 5. Primary Product Goals

## 5.1 Fast Score Entry

Score entry occurs while players are wrapping up a round or game. It should not interrupt the social experience.

The interface should minimize:

* Typing
* Navigation
* Repeated player selection
* Manual arithmetic
* Unnecessary confirmations
* Re-entry of common values
* Accidental modification of completed scores

Common values and scoring actions should use large, touch-friendly controls.

## 5.2 Flexible Scoring Support

The application should support games ranging from simple final-score recording to detailed category-based scoring.

Supported concepts should include:

* Positive scores
* Negative scores
* Round accumulation
* End-game categories
* Bonuses
* Penalties
* Multipliers
* Calculated subtotals
* Highest-score-wins
* Lowest-score-wins
* Target scores
* Tie-break values
* Team scoring
* Multiple winners
* Manual winner selection

## 5.3 Persistent Play History

The application should preserve:

* Game played
* Participants
* Round scores
* Final scoring categories
* Final totals
* Winner
* Player placement
* Date and time
* Session duration
* Number of rounds
* Template version
* Optional notes
* Optional location
* Incomplete or abandoned sessions

## 5.4 Cross-Device Availability

Players, game definitions, scoring templates, and session history should be stored centrally so they can be accessed from multiple devices.

However, active scoring should not depend on continuous internet access.

## 5.5 AI-Assisted Template Creation

The template architecture should be predictable, constrained, documented, and testable.

An AI coding agent should be able to:

1. Review the scoring portion of a game’s rules.
2. Identify when scoring occurs.
3. Identify required input values.
4. Identify calculated values.
5. Generate a structured scoring template.
6. Generate validation rules.
7. Generate scoring test cases.
8. Preview and verify the result.

The agent should extract the game’s scoring procedure rather than model the complete gameplay system.

---

## 6. Core Domain Concepts

## 6.1 Player

A player is a reusable identity stored independently of any game session.

Suggested attributes:

* Player ID
* Display name
* Optional nickname
* Optional avatar
* Optional preferred color
* Active or archived status
* Optional account association
* Created date
* Last played date

The player system should support recurring families, households, and game groups.

Users should be able to:

* Select recent players quickly.
* Search saved players.
* Add a guest.
* Convert a guest into a saved player.
* Reorder players for a session.
* Archive players without deleting history.

## 6.2 Player Group

A player group is an optional reusable collection of players.

Examples:

* Family
* Weekly game night
* Children
* Work group
* Vacation group

Selecting a group should preselect its members while still allowing changes for the current session.

## 6.3 Game Definition

A game definition describes the board game.

Suggested fields:

* Game ID
* Name
* Publisher
* Edition
* Minimum players
* Maximum players
* Approximate play time
* Scoring model
* Associated scoring templates
* Winner rule
* Optional cover image
* Optional external reference identifier

The game definition should remain separate from a specific scoring-template version.

## 6.4 Game Scoring Template

A game scoring template defines:

* What score values are entered
* When they are entered
* How they are validated
* How subtotals are calculated
* How the final score is calculated
* How the winner is determined
* What scoring guidance is displayed

## 6.5 Game Session

A game session represents one instance of playing a game.

Suggested lifecycle states:

* Setup
* In progress
* Paused
* Completed
* Abandoned

Completion should indicate that a result was reached, not that later edits become administratively difficult by default.

A session should retain the exact template version used when it was created.

Later template changes must not silently modify historical results.

## 6.6 Round

A round represents a completed scoring interval.

Depending on the game, it may represent:

* A round
* A hand
* A phase
* A chapter
* A scoring cycle

The platform does not need to model the gameplay within the round.

## 6.7 Score Entry

A score entry represents one meaningful scoring input.

Examples include:

* A round score
* A category quantity
* A category subtotal
* A bonus
* A penalty
* A placement
* A tie-break value
* A manual adjustment
* A final total

The system should preserve raw inputs in addition to calculated values.

---

## 7. Supported Scoring Models

## 7.1 Quick Final Score

Used when only the final result needs to be recorded.

Capabilities:

* Enter one final score per player.
* Support positive or negative values.
* Identify highest or lowest score as the winner.
* Record player placement.
* Record ties.
* Save the result.

## 7.2 Quick Running Total

Used when players want to add score changes without a detailed template.

Capabilities:

* Add points.
* Subtract points.
* Replace the current total.
* Show the current total clearly.
* Undo the most recent change.
* Mark the game complete.

This mode may be useful when scoring happens several times but does not require formal rounds.

## 7.3 Round-Based Scoring

Used when each completed round produces a score.

Capabilities:

* Add one score per player per round.
* Support positive and negative values.
* Show round totals.
* Show cumulative totals.
* Highlight the current leader.
* Support highest-score-wins or lowest-score-wins.
* Detect target-score thresholds.
* Allow incomplete rounds.
* Correct previous rounds.
* Optionally track the starting player.

## 7.4 Round Tally Scoring

Some games require multiple values to calculate each round’s score.

For example, a round may include:

* Base points
* Bonus points
* Penalty points
* Completed objectives

The platform should support a score tally sheet for each completed round and then add the round total to the cumulative score.

## 7.5 End-Game Category Scoring

Used when the game produces several final scoring categories.

Capabilities:

* Define numeric or selectable categories.
* Organize categories into sections.
* Calculate subtotals.
* Calculate final totals.
* Apply bonuses and penalties.
* Provide short scoring instructions.
* Record tie-break values.
* Compare players.

## 7.6 Hybrid Round and Final Scoring

Some games accumulate round scores and then apply end-game scoring.

The application should support:

* Round totals
* Cumulative totals
* End-game categories
* Final bonuses
* Final penalties
* Tie-break fields
* Final score calculation

## 7.7 Placement or Result-Only Scoring

Some games do not require numeric scores to be preserved.

A session may record:

* Winner
* Final placement
* Win or loss
* Team result
* Draw
* Completion status

This allows the platform to track game history even when the detailed scoring system is not modeled.

---

## 8. Template Architecture

## 8.1 Recommended Hybrid Architecture

The template system should use three levels.

### Level 1: Standard Scoring Presets

Built-in models requiring minimal configuration:

* Quick final score
* Running total
* Round scoring
* Round tally scoring
* End-game category scoring
* Placement scoring

These presets should support a large percentage of games.

### Level 2: Declarative Templates

Templates should normally be defined using structured data such as JSON or YAML.

The definition should describe the score-entry and calculation workflow without implementing arbitrary application code.

Conceptual example:

```yaml
template:
  id: skyjo-standard
  version: 1.0.0
  name: Skyjo
  scoringModel: rounds

players:
  minimum: 2
  maximum: 8

rounds:
  repeatable: true
  startingNumber: 1

scoreEntry:
  type: integer
  minimum: -30
  maximum: 300
  default: 0

totals:
  calculation: sum
  winner: lowest

endCondition:
  type: playerTotalThreshold
  threshold: 100
  evaluateAfterRound: true

display:
  showRoundTable: true
  showCumulativeTotal: true
  highlightLeader: true
```

### Level 3: Registered Extensions

Custom code may be used when a scoring workflow cannot reasonably be represented by the declarative model.

Extensions could provide:

* A specialized tally-entry control
* A custom category selector
* A game-specific scoring algorithm
* A unique summary display
* Complex but score-focused validation

Extensions should not become complete digital gameplay implementations.

They should still rely on the core platform for:

* Player selection
* Session lifecycle
* Persistence
* Synchronization
* Undo
* History
* Statistics
* Accessibility
* Template metadata
* Error handling

## 8.2 Why Templates Should Not Be Entirely Code-Based

Making every game template a separate code module would create:

* Greater risk from AI-generated code
* More testing requirements
* Security concerns
* Inconsistent interfaces
* Duplicated functionality
* Application releases for minor template changes
* More difficult template sharing
* More difficult version management

Most templates should therefore be declarative.

Custom code should be reserved for scoring requirements that cannot be represented using standard primitives.

---

## 9. Template Scope Rule

Before adding a feature to a template, apply the following test:

> Is this feature needed to enter, calculate, validate, compare, or preserve a score after a round or game?

When the answer is yes, it may belong in the scoring template.

> Is this feature primarily used to perform moves, make gameplay decisions, enforce turn rules, or maintain game state during play?

When the answer is yes, it is normally outside the platform’s scope.

A limited exception may exist when a small value must be recorded during play solely because it contributes directly to later scoring.

Such exceptions should remain minimal and should not cause the template to become a digital recreation of the game.

---

## 10. Template Schema

The template schema should define a limited, versioned vocabulary.

## 10.1 Metadata

* Template ID
* Template version
* Display name
* Game reference
* Author
* Description
* Source
* Supported languages
* Minimum application version
* Schema version

## 10.2 Player Rules

* Minimum players
* Maximum players
* Team support
* Player ordering
* Starting-player tracking
* Duplicate-player restrictions

## 10.3 Scoring Timing

* Final score only
* End of round
* End of hand
* End of phase
* End of game
* Round plus end-game scoring

## 10.4 Session Structure

* Single scoring event
* Fixed number of rounds
* Repeatable rounds
* Optional rounds
* Final scoring stage
* Shared score values
* Team score values

## 10.5 Input Fields

Supported field types may include:

* Integer
* Decimal
* Boolean
* Text
* Single choice
* Multiple choice
* Counter
* Quantity selector
* Range
* Placement
* Player reference
* Calculated value
* Tie-break value
* Manual adjustment

## 10.6 Calculations

Supported calculations may include:

* Sum
* Difference
* Product
* Minimum
* Maximum
* Count
* Conditional count
* Conditional value
* Lookup table
* Capped value
* Floor or ceiling
* Rounded value
* Set scoring
* Multipliers
* Registered custom calculation

## 10.7 Validation

Supported validation may include:

* Required
* Minimum
* Maximum
* Allowed values
* Whole number only
* Uniqueness
* Maximum selections
* Mutually exclusive choices
* Conditional availability
* Cross-field comparison
* Completion requirements
* Warning-only conditions

## 10.8 Presentation

Supported layout concepts may include:

* Sections
* Rows
* Columns
* Cards
* Tabs
* Collapsible groups
* Player-focused view
* All-player view
* Summary view
* Help text
* Icons
* Scoring examples

The layout system should organize score tallying. It should not provide a general-purpose digital game board framework.

## 10.9 Completion Rules

* Manual completion
* Fixed number of rounds
* Target score reached
* All required fields completed
* Final-scoring stage completed
* Custom registered condition

## 10.10 Winner Rules

* Highest score
* Lowest score
* Closest to target
* Placement field
* Team winner
* Multiple winners
* Manual winner
* Ordered tie-break rules

---

## 11. Reusable Score-Entry Components

The platform should provide a library of consistent controls.

Suggested components include:

* Numeric keypad
* Increment and decrement buttons
* Quick-value buttons
* Recently used values
* Counter
* Toggle
* Checkbox
* Radio selection
* Dropdown
* Segmented control
* Stepper
* Quantity selector
* Rank selector
* Player selector
* Bonus entry
* Penalty entry
* Calculated subtotal
* Final-total display
* Tie-break entry
* Scoring-guidance block

Each control should support:

* Touch-friendly sizing
* Keyboard entry where appropriate
* Validation
* Undo
* Disabled state
* Read-only state
* Help text
* Accessibility labels
* Optional haptic feedback
* Template-driven configuration

Gameplay-oriented components should not be part of the normal template library, including:

* Full game boards
* Roll-and-write placement grids
* Card hands
* Tile placement systems
* Token movement
* Dice-resolution systems
* Turn automation
* Game-state simulation

---

## 12. User Experience

## 12.1 Home Screen

The home screen should prioritize common actions:

* Resume active session
* Start quick scoring
* Select a recent game
* Select a favorite game
* Reuse a recent player group
* Review recent results

## 12.2 Session Setup

A typical setup flow should be:

1. Select a game or Quick Score.
2. Select a scoring template when multiple templates exist.
3. Select saved players.
4. Add guests.
5. Arrange player order.
6. Configure optional scoring settings.
7. Start the session.

The setup process should remember common player combinations and game settings.

## 12.3 Active Round Scoring

For round-based games, the screen should clearly show:

* Game name
* Current round
* Player names
* Round score entry
* Cumulative totals
* Missing entries
* Current leader
* Complete-round action
* Undo

Completing a round should require minimal interaction.

## 12.4 End-Game Tallying

For category-based games, the app should guide the user through final scoring in a logical sequence.

Possible workflow:

1. Select a player.
2. Enter scoring-category values.
3. Review calculated subtotals.
4. Resolve warnings or missing values.
5. Confirm the player’s final score.
6. Move to the next player.
7. Review the full scoreboard.
8. Complete the session.

## 12.5 Focused Player View

One player’s scoring form occupies most of the screen.

Navigation may use:

* Swipe gestures
* Player tabs
* Previous and next buttons
* Compact player selector

This view is appropriate for detailed end-game tally sheets.

## 12.6 Cross-Player Scoreboard

The scoreboard should make it easy to identify:

* Current leader
* Current trailing player
* Ties
* Missing score entries
* Completed players
* Round-by-round changes
* Final placement

## 12.7 Shared-Device Use

The initial product should assume:

* One device
* One primary scorekeeper
* Players may pass the device between them
* Participants do not need separate accounts

Multi-device collaborative scoring can be considered later.

---

## 13. Data and Persistence

## 13.1 Local-First Operation

Active scoring should be saved immediately to a local database.

The app should continue functioning when:

* Internet access is unavailable.
* The cloud service is unavailable.
* The user changes apps.
* The screen locks.
* The application restarts.
* The device temporarily loses connectivity.

Unsynchronized changes should upload when connectivity returns.

## 13.2 Cloud Synchronization

Cloud synchronization should support:

* Players
* Player groups
* Games
* Templates
* Sessions
* Rounds
* Score entries
* Results
* Preferences
* Statistics

Each synchronized record should include:

* Stable unique ID
* Created timestamp
* Modified timestamp
* Revision or version
* Synchronization status
* Soft-delete marker where appropriate

## 13.3 Session Ownership

The first version should use one primary session owner.

Later collaboration options may include:

* Shared session code
* Invitation link
* QR-code join
* Multiple scorekeepers
* Player-specific entry
* Local-network session

Collaborative editing should not be required for the first release.

---

## 14. Corrections and Result Integrity

Score corrections are common and should be safe.

The platform should normally treat the current stored score state as authoritative.

The default correction model should be simple direct editing:

* change the value
* recompute the result
* continue using the updated score

Example:

```text
Round 3 score entered as 17
Round 3 score corrected to 12
Session completed
Final result recalculated from the corrected value
```

Benefits include:

* Simple direct correction of entered values
* Recovery from accidental misentry
* Lightweight completion behavior
* Simpler template-driven scoring behavior
* Less storage and lifecycle complexity

Completion should communicate that a result was reached.

It should not automatically behave like a hard lock or require an audit-style correction workflow.

If the product keeps a later "reopen" concept, it should remain a lightweight UI affordance rather than a heavy lifecycle boundary.

---

## 15. History and Statistics

## 15.1 Session History

Users should be able to review:

* Date played
* Game
* Players
* Round scores
* Final categories
* Final totals
* Winner
* Placement
* Duration
* Notes

## 15.2 Player Statistics

Possible statistics include:

* Games played
* Wins
* Win percentage
* Average score
* Highest score
* Lowest score
* Recent results
* Results by game

## 15.3 Game Statistics

Possible statistics include:

* Number of sessions
* Most frequent players
* Average duration
* Average number of rounds
* Highest recorded score
* Lowest recorded score
* Most recent sessions

## 15.4 Group Statistics

Possible statistics include:

* Head-to-head results
* Most frequent winner
* Game-night history
* Common player groups
* Results by player combination

Statistics must respect whether a game rewards high or low scores.

---

## 16. Template Creation Workflow

## 16.1 Developer Template Workflow

The initial template workflow may use structured files rather than a complete visual editor.

A developer should be able to:

1. Create a game definition.
2. Select a scoring model.
3. Define fields and sections.
4. Define calculations.
5. Define validation.
6. Define completion and winner rules.
7. Preview the mobile interface.
8. Simulate scoring scenarios.
9. Run automated tests.
10. Package and publish the template.

## 16.2 Future Human Template Builder

A future visual builder could allow an advanced user to:

1. Select a standard scoring model.
2. Add scoring sections.
3. Add input fields.
4. Configure formulas.
5. Configure bonuses and penalties.
6. Configure winner rules.
7. Preview player and scoreboard views.
8. Test sample scores.
9. Save or publish the template.

## 16.3 AI-Assisted Template Generation

A recommended agent workflow is:

1. Provide the game rules.
2. Instruct the agent to focus only on end-of-round and end-of-game scoring.
3. Identify when scoring occurs.
4. Identify required player inputs.
5. Identify values that can be calculated.
6. Identify bonuses and penalties.
7. Identify winner and tie-break rules.
8. Generate the template.
9. Validate it against the schema.
10. Generate scoring tests.
11. Preview the template.
12. Correct rule or usability problems.
13. Publish the approved version.

The agent should not automatically reproduce every area of a physical scorecard.

For a roll-and-write game, the default assumption should be:

* The physical sheet remains in use during gameplay.
* The app records the final scoring components.
* The app calculates and stores the result.

---

## 17. Agent-Friendly Design Principles

The template platform should be:

* Explicit
* Strongly typed
* Versioned
* Schema validated
* Deterministic
* Composable
* Well documented
* Supported by examples
* Testable outside the full mobile application
* Protected from arbitrary code execution

The platform should avoid undocumented conventions and implicit behaviors that make generated templates difficult to reason about.

---

## 18. Template Validation and Testing

Every template should pass automated validation.

Validation should detect:

* Missing metadata
* Duplicate field IDs
* Invalid field references
* Unsupported control types
* Invalid calculation dependencies
* Circular calculations
* Invalid ranges
* Missing completion rules
* Invalid winner rules
* Unsupported schema versions
* Application-version incompatibility

Templates should also include scenario-based scoring tests.

Conceptual example:

```yaml
tests:
  - name: Three-round lowest-score game
    players:
      - id: player1
      - id: player2

    rounds:
      - scores:
          player1: 10
          player2: 20
      - scores:
          player1: 15
          player2: 5
      - scores:
          player1: 12
          player2: 18

    expected:
      totals:
        player1: 37
        player2: 43
      winner: player1
```

For category-based scoring, tests should verify:

* Subtotals
* Bonuses
* Penalties
* Multipliers
* Final totals
* Tie-break behavior

Generated tests are especially important for AI-created templates.

---

## 19. Template Distribution

Templates may eventually come from:

* Built-in application templates
* Official downloadable templates
* Community templates
* Private user-created templates
* Imported local files
* AI-generated templates

Suggested template states:

* Draft
* Validated
* Locally tested
* Published
* Verified
* Deprecated
* Incompatible

Each template should identify:

* Author
* Source
* Version
* Compatibility
* Verification status

A community template should not be presented as official solely because it references a known game.

---

## 20. Template Versioning

Template versioning is essential.

Templates may change because of:

* Corrected scoring logic
* Rule clarifications
* Improved entry workflow
* New game editions
* Added validation
* Schema changes
* Application changes

Historical sessions should retain:

* Template ID
* Template version
* Raw score entries
* Calculated results
* Winner result at completion

New template versions should be used for new sessions.

Completed historical sessions should not be silently recalculated.

---

## 21. Suggested Application Areas

## Home

* Resume active session
* Start quick score
* Recent games
* Favorite games
* Recent player groups
* Recent results

## Games

* Search games
* Favorite games
* Built-in templates
* Custom templates
* Template variants
* Create or import template

## Players

* Saved players
* Player groups
* Player details
* Player history
* Archived players

## History

* Completed sessions
* Filter by game
* Filter by player
* Session detail
* Review or correct session

## Statistics

* Player statistics
* Game statistics
* Group statistics

## Settings

* Account
* Synchronization
* Appearance
* Score-entry preferences
* Template management
* Data export
* Backup and restore

---

## 22. Recommended Initial Release Scope

## Phase 1: Core Scoring

* Local player list
* Player groups
* Quick final-score mode
* Running-total mode
* Round-based scoring
* Session history
* Undo and corrections
* Highest-score and lowest-score winner rules
* Local persistence
* Basic game definitions

## Phase 2: Structured Score Tally Templates

* Versioned template schema
* End-game category scoring
* Round tally scoring
* Reusable input components
* Automatic calculations
* Validation rules
* Template preview tool
* Template test runner
* Bundled example templates

## Phase 3: Cloud and Cross-Device Support

* User accounts
* Cloud synchronization
* Cross-device players
* Cross-device session history
* Backup and restore
* Offline synchronization queue

## Phase 4: Template Creation and Distribution

* Template documentation
* AI-agent instructions
* Visual template builder
* Template publishing
* Template catalog
* Import and export

## Phase 5: Advanced Scoring Features

* Team scoring
* Custom statistics
* Registered scoring extensions
* Shared sessions
* Multi-device score entry
* Community template verification

Full digital gameplay sheets should remain outside the normal roadmap unless developed as separate specialized applications.

---

## 23. Architectural Boundaries

The following concerns belong to the core platform:

* Players
* Player groups
* Games
* Sessions
* Rounds
* Persistence
* Synchronization
* Undo
* Corrections
* Template loading
* Schema validation
* Standard calculations
* Standard controls
* History
* Statistics
* Accessibility
* Localization

The following concerns belong to scoring templates:

* Round score fields
* Final scoring categories
* Bonuses
* Penalties
* Multipliers
* Calculation formulas
* Validation rules
* Completion conditions
* Winner rules
* Tie breakers
* Scoring instructions
* Score-tally layout

The following concerns are outside the normal platform scope:

* Legal move enforcement
* Turn automation
* Card-hand simulation
* Dice decision support
* Tile placement
* Route drawing
* Roll-and-write number placement
* Complete resource tracking
* Full game-state management
* Digital recreation of physical gameplay boards

---

## 24. Key Product Risks

## 24.1 Template System Becomes Too Generic

Attempting to represent every scoring system in one configuration language could make templates harder to build than custom code.

Mitigation:

* Focus on common scoring patterns.
* Add new primitives only when supported by real use cases.
* Retain controlled extension points.
* Avoid building a generic gameplay engine.

## 24.2 Scope Expands Into Gameplay Simulation

A template may gradually begin to reproduce the physical game.

Mitigation:

* Apply the score-scope rule to every requested feature.
* Keep templates focused on completed round or game results.
* Treat full gameplay recreations as separate applications.

## 24.3 Score Entry Is Slower Than Paper

A flexible system may still fail if score entry is cumbersome.

Mitigation:

* Measure the number of taps required.
* Provide quick-value controls.
* Preserve recent input values.
* Support rapid next-player navigation.
* Test templates during real game sessions.

## 24.4 Cloud Dependency Interrupts Scoring

The app cannot become unusable because internet access is unavailable.

Mitigation:

* Use local-first persistence.
* Synchronize asynchronously.
* Never require connectivity to continue a session.

## 24.5 AI-Generated Templates Calculate Scores Incorrectly

A template may be syntactically valid but misunderstand the rules.

Mitigation:

* Require generated tests.
* Store rule references.
* Preview templates.
* Run scoring simulations.
* Mark templates as verified or unverified.
* Preserve template versions.

## 24.6 Template Interfaces Become Inconsistent

Excessive template flexibility may produce confusing scoring workflows.

Mitigation:

* Standardize navigation.
* Standardize player switching.
* Standardize completion actions.
* Standardize totals and validation.
* Allow templates to configure content without replacing core interaction patterns.

---

## 25. Central Design Principle

The platform should make the scoring experience consistent while allowing each game’s scoring rules to vary.

Players should always recognize how to:

* Select a game
* Select participants
* Enter round or final scoring values
* Correct an error
* Compare players
* Complete a round
* Complete a game
* Review history

Game templates should customize:

* What is scored
* When scoring occurs
* Which values are entered
* How values are validated
* How totals are calculated
* How the winner is determined

They should not normally customize or recreate how the game itself is played.

The application is a platform for **end-of-round and end-of-game score tallying, calculation, comparison, and history**. It is not a general-purpose digital replacement for board-game play surfaces.
