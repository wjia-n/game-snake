# RULES.md — Snake (Meadow Arcade)

The authoritative rules of the game. If the implementation ever conflicts
with this document, fix the implementation.

## 1. Objective
Steer the snake around a 20×20 meadow board, eat fruit to grow longer, and
score as many points as possible before the run ends. In Time Attack, score
as much as possible in 60 seconds.

## 2. Setup
- The board is a fixed 20×20 grid.
- The snake starts 3 segments long in the center, moving right.
- One regular fruit is on the board at all times, on a random free cell.
- The run begins only after a 3·2·1 countdown (tappable to skip).

## 3. Turn order
- Real-time: the snake advances one cell every tick. There are no turns.
- Tick interval depends on difficulty: Relaxed 175ms, Classic 125ms,
  Speedy 85ms, Insane 60ms (Pro only), and shrinks by 3ms per apple eaten
  (floor 45ms).

## 4. Legal moves
- Swipe in any cardinal direction or use the d-pad to steer.
- The snake moves up, down, left or right, one cell per tick.
- Steering queues one direction change; it applies at the next tick.

## 5. Illegal moves
- Reversing directly into your own neck (180° turn) is illegal and ignored —
  the snake keeps gliding in its current direction. No penalty.

## 6. Captures
- Eating the regular fruit grows the snake by one segment and scores
  10 points (+25 streak bonus every 5th consecutive apple).
- Eating the golden fruit grows the snake by one segment and scores 50
  points; it resets the apple streak counter.

## 7. Special rules
- **Golden fruit**: spawns every ~14s (Time Attack: ~7s) on a random free
  cell and vanishes after ~8s (~6s in Time Attack) if uneaten.
- **Streak**: every 5th consecutive regular apple earns +25 bonus points.
  The counter resets when a golden fruit is eaten.
- **Walls**: in Classic Arcade the border is deadly. In Wrap World and
  Time Attack the snake tunnels through walls and reappears on the
  opposite edge.
- **Speed**: the snake accelerates with every apple eaten.
- **Board full**: filling all 400 cells is a legendary instant finish.

## 8. Scoring
- Regular apple: 10 points (+25 bonus every 5th consecutive apple).
- Golden apple: 50 points.
- Scores are saved per (mode, difficulty) pair; only the best is kept.

## 9. Winning conditions
- There is no victory in the endless modes — the goal is always a higher
  score. Filling the board is the legendary perfect finish.

## 10. Draw conditions
- Not applicable (single-player arcade).

## 11. AI strategy
- Not applicable (no bots). Difficulty comes from tick speed and wall rules.

## 12. Edge cases
- Food never spawns on the snake or on the other food.
- If no free cell exists for food, the run ends as a board-full finish.
- Steering input during countdown/idle/paused/over does nothing harmful:
  the first swipe on idle starts the run.
- Pausing (app background, pause button) freezes the tick loop; resuming
  re-arms the current phase — a run can never be lost to interruption.
- A watchdog timer restarts any phase found without a live timer, so the
  game can never freeze mid-run.

## 13. Test cases
1. Snake starts 3 long, moves right after countdown.
2. Eating an apple grows +1 segment and adds 10 to the score.
3. 5th consecutive apple adds the +25 streak bonus.
4. Golden fruit appears on a timer, scores 50, and expires.
5. 180° reversal input is ignored; the snake does not die.
6. Classic mode: hitting the wall ends the run.
7. Wrap mode: crossing the edge reappears on the opposite edge.
8. Eating your own tail ends the run.
9. Time Attack ends exactly at 60s with the results card.
10. Pause freezes movement; resume continues the same run.
11. Best score persists per mode+difficulty across app restarts.
12. Killing the tick timer (background/foreground) recovers via watchdog.
