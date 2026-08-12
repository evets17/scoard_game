# Overview
This document is an attempt to brainstorm around scoring and to establish an understanding and explore approaches/use cases that inform us on our design.

## Why Scoard Game
I see Scoard Game solving two main goals:

- Aiding in scoring a game: The idea here is that Scoard Game helps track and calculate game scores while playing a game.  Can think of this as managing a give game's scores.

- Tracking historical plays: the idea here is that Scoard Game is a play history log that keeps track of plays over time, who played, who won, etc.

A user may primarily use the app to accomplish one or both of these.   

Examples:
- Scoring game of Skyjo: A user is tracking a game of Skyjo, there are 7 players and numerous rounds of play.  Scoard Game value is keeping track of that game, instead of writing scores on a piece of paper, trying to add scores by hand, Scoard Game lets the user just type in each persons score for round and it tallies, orders by highest lowest score, etc.    This is example of aiding in scoring.  The synergy is, the act of using scoard game this way also serves historical play as when done, scoard game will remember this game.

- Weekly Chess Match: Two people have a tradition of playing chess once a week.   They want to track their wins and losses.  scoard game is used to go in and record won/lost/draw for whenever they play.   here the users do not need scoard board to manage a given games score, there is no tallying, no multiple rounds, etc.  The simple recording of a games score, is also the saving.  

The synergy I see here is both of these examples utilize the same path.  It's the same process to accomplish both.  The nuance is in the "how" a given game is scored, simple win/loss vs more complex tracking.

## Usability is the goal NOT rules enforcement.
When I think of scoard game's mission, it's to make things easy for the user track and record, not to be a referee.   

When thinking of design, the goal is not to be a rules enforcer, but rather a scribe.  

This thinking should inform us in our design.  The player should be in control, not the app controlling the player.   

There is a balance here, sometimes having controls or limits can be a usability aid.

Here are some specific thoughts around this scribe not referee paradigm 
### Game Over
I think the concept of game over trigger should NOT be built into the App.  The App/game template should NOT have an explicit concept of game over controls or rules specifically.  

The user "determines" when a game is over.

### Triggered Conditions - generic vs specific paradigms
I could see a concept of triggered conditions.  

The idea here is a game template could define a rule like this:

WHEN (Any Player Score Greater Than 200) THEN (Show message: 'Score 200 Reached!')

Here is an example of incorporating a concept of game over condition into a template, without the template really "knowing" it's a game over trigger.  This is a usability aid as a message to user, but not a rules enforcement.

We could imagine scenario where in general games are played until a player exceeds 200 points, but in the moment the players all decide, let's keep going, and play to 300.   scoard game is fine with this, the score 200 reached trigger can be ignored, the user decides when game is over.

## Everything is a formula
Everything is probably too strong of a word here, but in our template design, we should consider that any "value" or rule can be expressed as a formula (substitutions).

### Variables
The idea is that there are all these variables "available" for our formulas to use.   Some examples:

- Number of players
- Current Round
- Player Score

Then these variables can be referenced in various contexts in our templates.

#### Template Defined variables
Idea is a game template could define custom variables.

These variables could be formulas themselves like:
**WinConditionScore** = If {NumberOfPlayers} eq 3 Then Return 5 ElseIf 
{NumberOfPlayers} eq 4 Then Return 4 ElseIf {NumberOfPlayers} in [5,6] Then Return 3 Else Return 6

or could be user provided/prompted at run-time:
**PlayUntil** = <prompt user>  Type: Numeric   Label: "Winning Score?"

**FlowersScoreDouble** = <prompt user>  Type: Boolean   Label: "Double Points for Flowers"

Idea here is game options are just user prompted variables.  scoard game doesn't know why you are asking a user for this information, but it just sets them as variables to be used in other places.

Using our conditions trigger idea above we could see our templates supporting something like this:

NotifyTrigger: TopScoreReached
Condition: Any({Players}.{FinalScore}) > {PlayUntil} 
Message: "A score has exceeded {PlayUntil}!"

in this example we see concept of a game template having a triggered nofification where variables are substituted into formulas and text strings.

The Everything is a formula could manifest in properties like "Include" or "Visible".   An example would be having a variable like:

**IncludeForestExpansion** = <prompt user>  Type: Boolean   Label: "Include Forest Expansion Rules"

Then perhaps our template scoring value object has a property of "Include" that we set to {IncludeForestExpansion}, this determines if a given scoring element is displayed to user or not.   This is thinking of handling expansions and such, but it's just setting variables, and once again the users are just being prompted, the template doesn't have an explicit expansions concept, it just has concept of prompting users for values to assign variables.

## Real World Use Cases - Games
Here is taking some real games and thinking through some of these ideas in context of real scenarios

### Chess
I referenced Chess above when talking about use case of wanting to track wins and losses over time.  

What makes chess interesting?
- Fixed Player count:  Chess is two player only game.  Should our templates have a "Player Count" concept?   Our Scribe over Referee philosophy kind of leads us to answering NO here, as the player should be in control.  If we consider usability, is allowing a user to do a 3 player chess score a usability concern?   I'm going to say no, this would not be a point of confusion.  To me, knowing the documented Player Count would "nice information" to have (for any game).   Looking at it here, I would say having a "built in" player count on our template is not needed, but having a Game Notes would be nice where one could highlight that chess is 2 player game.

- Win/Lose/Draw: Chess does not have complicated scoring points system.  A given player either wins, loses, or draw (tie).   under the covers is this still a numeric, a 1 or 0?   If we consider it in that light, chess is no different than skyjo, in that high score wins.  1 is greater than 0.   Some concepts here:
-- Max Score - the max score one can have is 1
-- Min Score - the min score one can have is 0
-- Ties allowed - in chess two players can end with the same score.

Should our template have concept of max and min score?  If we are limited to expressing our chess score in numerics, then I would say yes, It would help usability to guide players to not allow a score of 6 to 4 in chess.

However, for usability in this case, are there "better" avenues.  What about concept of ENUM.  Consider if our template had an "Allowed Values" concept for a score value instead?   And what if our "Allowed Values" could be an ENUM List like this:

-1 = None
0 = WasCheckmated
1 = DeliveredCheckmate

The above keeps things simple, in that high score wins, same score tie.  
we could imagine our UI only exposing the "Allowed Values".  and could see instead of showing 0 and 1, show descriptive text instead, but really it's a numeric under the covers. 

Should scoard board have the ability to create a trigger that conceptually does:

WHEN Any Player Score Is Set To 1 THEN Other Players Score = 0
Or
WHEN Any Player Score Is Set To 0 THEN Other Players Score = 1

expanding on the "Is Set To" probably would be a Set By User, to avoid circular reference triggers.
I say this would be a nice usability design.  Allowing a Chess template to "auto-set" a value based on rules.  This falls into the make it easy for user.    

However, to serve chess fully we probably want to consider resignation path.  

In other words player can win by checkmating opponent or oppoent resigning.  So how to incorporate Resign:

-1 = None
0 = WasCheckmated
1 = Resigned
2 = WonByResignation
3 = DeliveredCheckmate

here we now have more allowed values, and our high score wins still holds.  Ideally we would be able to create usability triggers as described above that makes it easy for user to set one player's score, and have the other auto set.  However, the template would NOT be expected to police cases like player 1 set to '2 = WonByResignation' and player 2 set to '3 = DeliveredCheckmate'.  Conceptually this is not valid per chess rules, but it is not scoard game's job to enforce rules, it is just recording what the player tells it to.   

This example highlights how rules enforcement and usability can be a fine line.  Our usability rules of auto setting values, can "feel like" a rules enforcement, but the spirit remains that we are doing it to make it easier for user to record results, not to police the user.

## Love Letter
Here is Love Letter scoring at high level:
```
At the end of each round, a player may earn:

1 token for winning the round, plus

1 token for being the sole Spy player

So a single player can earn up to 2 tokens in one round.

📌 Example
Alice wins the round → +1 token

Alice also played the only Spy → +1 token

Alice earns 2 tokens total

If Bob also played a Spy, then:

Alice wins the round → +1 token

Spy bonus → no one gets it

🏆 Game victory
As usual, the first player to reach the target number of tokens (varies by player count) wins the game.

2 players	6 tokens
3 players	5 tokens
4 players	4 tokens
5 players	3 tokens
6 players	3 tokens
```

Some Interesting Concepts:
- Round scoring:  Love Letter has rounds of scoring, but the game itself provides an easy way to track by handing out score tokens.  I could imagine scoring a love letter game not "needing/wanting" a round scoring approach in scoard game app.   So for this discussion, we will assume we are building a final score entry template for love letter and NOT faciliting round scoring here.

- Player Count determines Win Condition:  Above I used Love Letter's number of players determines what is needed to win game.  being able to aid the user by automatically knowing the player count and informing or showing the win condition in the app would be a nice usability feature.  even if we are only entering final score, it would be nice if that app was able to trigger an info message on the screen like:  "3 Player Game, First to 5 Tokens Wins".   
Using concept of a NotifyTrigger:

NotifyTrigger: WinCondition
Condition: StartOfGame 
Message: "{NumberOfPlayers} Player Game, First to {WinConditionScore} Tokens Wins"

- Low Score Range: The amount of points that can be scored is low, always single digits.  Some games need to allow users to enter large range of numbers and some like Love Letter are single digits.  When thinking of usability a one size fits all for entering numbers may not be best.  We mentioned a concept of "Allowed Values" in our chess example, this has similar feel in that Love Letter probably is well served with a choice list of 0-9 or something when setting a value.  

### Skyjo
here is Skyjo scoring rules:
```
At the end of a round, add up all card values in your 4×3 grid.

Negative cards (‑2, ‑1) reduce your score.

High cards (10–12) hurt you.

Column rule:  
If you have three identical cards in a vertical column, that column is removed and scores 0 points.

Round‑ending penalty:  
If the player who ended the round does not have the lowest score, their round score is doubled.

Game end:  
When any player’s cumulative score reaches 100 or more, the game ends.
The player with the lowest total score wins.
```

Some interesting elements of Skyjo:
- Round scoring - Skyjo is a game that benefits from tracking round scoring, as the points can be large and varied, and often plays over numerous rounds.  Scoard Game is nice for keeping track round by round the score.  Knowing the current cumualtive score is desired.

Skyjo is example where you play to a certain score.  Might be nice to be able to prompt user for what they are playing to for that game, so then the game can notify when that number is reached.

- Varied Scores - Unlike love letter any given round a score can vary widely between players and between rounds.   In given round it is not uncommon to have someone score -points and another person score 48 points.  So here we want score entry method that makes setting these scores easy and quick.  

Advanced scoring aid thought - with skyjo, at the end of the round a player takes all the cards that are in front of them on the grid and adds them up.   One approach to a skyjo template would be to simply track the final score each round.  Another approach would be to have it where you enter the cards remaining into scoard game and it calculates the round total.   This would could be in the form of kind of calculator approach, or a running total approach, where you click a value and then have an "Add to Score" type option.  Given that cards range from -2 to 12 points in skyjo, one could imagine having a number picker with those values, and you select a number and say add to score for each card, or a means of just enter the final round score.  

### Shushi Go
here is high level approach to scoring sushi go:
```
🍣 High‑level scoring structure
The game is played over three rounds.

In each round, players draft cards and build a tableau.

When the round ends, everyone scores their tableau based on the sets and patterns they formed (e.g., maki majority, sashimi sets, dumpling counts, etc.).

Your round score is added to your running total.

After three rounds, the player with the highest total score wins.
```

Interesting elements about sushi Go:
- Fixed rounds - unlike skyjo, sushi go has fixed 3 rounds.  One could imagine creating a template for this game using either standard final score scoring or round scoring.   

since the rounds is fixed to 3, you could envision a score card that tracks R1, R2, R3 as sub items, that roll up to final score, actually using built in rounds scoring.   Or, could imaging setting up the scoring as traditional round scoring, but would only ever have 3 rounds.

- Round Scoring Aid - for really advanced template, could consider allowing for creating a scoring aid, where user enters what cards they drafted and having the app derive the final score based on the set rules of the game.  different cards score differently based on rules that may involve having other cards or having certain number of cards, etc.  This level of score aid would be quite advanced feature of templates, and not something to consider initially, but perhaps at some point templates could accomodate this.

### Bean Bags
Standard rules state:
```
🌽 High‑level scoring overview
A game is played to 21 points (exact 21 is not required in standard rules).

Each round (called an inning), both teams throw four bags.

After all bags are thrown, you calculate each team’s points for that inning:

1 point for each bag on the board.

3 points for each bag in the hole.

The team with the higher total for that inning scores the difference between the two totals.

Example: Team A scores 7, Team B scores 4 → Team A earns 3 points.

This is called cancellation scoring — your points cancel out your opponent’s points.

🏆 Winning the game
Innings continue until one team reaches 21 or more.

If both teams exceed 21 in the same inning, the higher score wins.
```
Consider also this variant scoring approach:
```
🌽 Exact‑21 with fallback to 15 (house rule overview)
You must finish the game by landing exactly 21 points.

If your cancellation scoring for the inning would put you over 21, you do not win.

Instead, your score is reset down to 15, and the game continues.

Your opponent keeps whatever score they had — only the player who busts drops to 15.

This creates a push‑your‑luck endgame where players often try to score just enough without overshooting.
```

Interesting elements to Bean Bags:
- optional variant rule: the 'exact 21' rule vs standard.  when looking at our scribe vs referee angle, this alternate scoring in some ways shouldn't really matter, as we are not asking the app to enforce the rules.  But once again it may be nice for the app to help guide scoring or give feedback.   One could imagine having a prompted variable of "Use Exact 21 Rule", that can be chosen prior to scoring a game, then in the template a notify trigger being defined if based on if that is set, indicating when there is a "bust" or "win".

- Team game:  this is an example of a team game, where there is two sides, but often each side would have two players (or more).   So we may want to consider the concept of Teams, where when defining "who's playing" we actually assign them to teams, and then score them as one.  We could imagine a construct where you have an Add Team type button when selecting players, that first time clicked, creates a "Team 1" and "Team 2" group, and then subsequent add team would add "Team 3" and so on.  Renaming the teams would be desirable so can name "Team Blue" and "Team Red" for example.   Maybe the game template automatically can identify teams?  One could imagine create a Player called Blue and a Player called Red and doing it that way, however, we then lose a history of who played, and who won.  We may want to look back at games and see things like, when Josh and Dan were on a team, they're tean won 3 times, but when Josh was on team with Katie, they only won once.  

- Round/Innings - here we see round scoring as feasible approach.  Do we want to allow a game template to override terminology, so can have a "Round Label" that coudl be set to "Inning" for this game so uses that terminology in the UI?    

Also could see the scoring setup as a "running total" approach as well, where you don't really track the rounds, but simply keep adding to the total until the win condition is met.  To me both approaches would be valid, it just what kind of experience feels better for the game.