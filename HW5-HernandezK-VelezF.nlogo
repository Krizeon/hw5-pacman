; Felix Velez and Kevin Hernandez
; CSCI 390
; 4/4/2018
; HW5 - Pac-Man

globals[
  player ; the player, whom controls pacman
  score ; the game score (shown at top left corner of maze
  score-patch ; the patch that contains a label with the game score
  lives-patch ; the patch where the interface for lives remaining is displayed
  multiplier ; the multiplier for consecutive ghosts eaten during a given "power up" duration
  lives ; amount of lives the player has
  kill-player?
  frame ; current frame
  time-frame ;the frame after the current frame
  framerate ;determines the framerate of the game (default 30 fps)
  inky   ;blue ghost
  blinky ;red ghost
  pinky  ;pink ghost
  clyde  ;orange ghost
  frightened-timer ; the amount of time that ghosts should be "frightened" for while pacman is powered up
  roam-timer ; the amount of time it takes to escape the ghost prison
  time-before-roam ;the amount of time to wait before the next ghost should leave the ghost prison
  wait? ; if true stop the game (used during transitions to the next level
  level-done? ; if true, move to the next level
  player-speed ; the player's speed (does not change after each level)
  enemy-speed ; the ghost's speed (increments slightly every level)
  list-of-fruit ; list of strings: apple, strawberry, apple
  fruit-placed? ;true if a fruit has been placed during a round
]

patches-own [
  wall? ; Agents can't walk through walls -- patches with wall? = true
  player-wall? ; Player can't enter small box in the center. Only the ghosts can.
  intersection? ;patches that are in the middle of a 4-way or 3-way intersection of the maze
]


breed [ pacmans pacman ] ; the agent the player plays as
breed [ ghosts ghost ] ; the colorful autonomous ghosts
breed [ pellets pellet ] ; the small white pelets scattered across the maze
breed [ life-reps life-rep ]
breed [ fruits fruit ]


turtles-own [
  on-intersection? ; true if turtle is on a patch with intersection? = true
  pellet?
  want-up? ;player wants to turn up at next possible turn
  want-down?  ;player wants to turn down at next possible turn
  want-left?  ;player wants to turn left at next possible turn
  want-right?  ;player wants to turn right at next possible turn
  speed ;turtle's speed
]


ghosts-own [
  boxed? ; true if ghost is within the ghost prison, false otherwise
  frightened? ;true if ghost is in frightened mode, false otherwise
  sight-range ; the range of sight in patches, varies by each ghost
]


; setup the entire game!
to setup
  ca
  set fruit-placed? false
  set score-patch patch -12 30 ; label the top left corner
  ask score-patch [set plabel "SCORE: 0000000"]
  set player-speed 0.22
  set enemy-speed player-speed - 0.02 ; set ghosts to be faster than player by a minute amount
  set wait? true ; allow player to get ready at the start of the game, so wait

  set kill-player? false
  set lives 2

  set level-done? true
  set score 0 ; reset score
  set multiplier 200
  setup-patches
  set roam-timer 0
  set time-before-roam 10

  ;create the player
  create-pacmans 1 [
    set size 3
    setxy 0 -15 ;default starting position
    set heading 0
    set color yellow
    set player self
    set shape "pacman"
    set on-intersection? false
    turn-setup ;do not have player start with a bias to turn to one side until player moves with keys
    set speed player-speed
  ]

  ;create Blinky, the red ghost
  create-ghosts 1 [
    set size 4
    setxy -3 3
    set color red
    set heading 0
    set shape "ghost"
    set blinky self
    turn-setup
    set boxed? true
    set frightened? false
    set speed enemy-speed + 0.005
    set sight-range 18 ;longest range of sight
  ]

  ; create Pinky, the pink ghost
  create-ghosts 1 [
    set size 4
    setxy 0 9
    set color pink
    set heading 0
    set shape "ghost"
    set pinky self
    set on-intersection? false
    turn-setup
    set boxed? false
    set frightened? false
    set speed enemy-speed
    set sight-range 12
  ]

  ; create Inky, the blue ghost
  create-ghosts 1 [
    set size 4
    setxy 3 3
    set color blue + 2.5 ; we wanted a slightly brighter blue than the default
    set heading 0
    set shape "ghost"
    set inky self
    turn-setup
    set boxed? true
    set frightened? false
    set speed enemy-speed
    set sight-range 12
  ]

  ; create Clyde, the orange ghost
  create-ghosts 1 [
    set size 4
    setxy 0 3
    set color 25
    set heading 0
    set shape "ghost"
    set clyde self
    turn-setup
    set boxed? true
    set frightened? false
    set speed enemy-speed
    set sight-range 9 ;shortest range of sight
  ]

  setup-lives
  reset-ticks
  reset-timer
  set frame 0
  set time-frame 0
  set framerate 60 ; game runs at 60 frames per second (FPS), so all agents move "at the same time" every frame for consistency
end


; places a fruit near the middle of the maze once per round
to place-fruit
  set list-of-fruit (list "banana" "strawberry" "apple")
  create-fruits 1[
    setxy 0 -3
    set size 3
    set shape one-of list-of-fruit
    if shape = "banana"[ set color yellow ]
    if shape = "strawberry" [ set color pink ]
    if shape = "apple" [ set color red ]
  ]
end


; Visually displays player's lives at the bottom of the screen
to setup-lives
  set lives-patch (patch -20 -30)
  ask lives-patch  [set plabel "LIVES: "]
  let temp -17
  repeat 3[
    create-life-reps 1[
      set shape "pacman"
      set size 2
      set heading 90
      set color yellow
      setxy temp -30
    ]
    set temp temp + 4
  ]
end


; create all the small pellets scattered across the maze
to setup-pellets
  ; room for 196 total pellets
  ; For a place a pellet can be placed at:
  ;    1) Can't be on a wall
  ;    2) No neighbors that are walls (so it's centered)
  ;    3) Not where there's already a pellet
  ;    4) X and y must be evenly divided by 3 (also to be centered)
  repeat 196[

    let good-loc ( one-of patches
      ;1
      with [ (wall? = false)
        ;2
        and (not any? neighbors with [wall? = true])
        ;3
        and (not any? turtles-here)]
      ;4
      with [ (pxcor mod 3 = 0) and (pycor mod 3 = 0) ]
    )
    if good-loc != nobody [
      create-pellets 1 [
        set size .5
        set shape "circle"
        set color white
        setxy ([pxcor] of good-loc) ([pycor] of good-loc)
      ]
    ]
  ]
  ; it was difficult to restrict the program from creating pellets in the small 4 areas where the player cannot go to with making the code really messy.
  ; this kills the ones created in those areas.
  kill-extra-pellets
  set-big-pellets
end


; this method determines which patches are walls and which are intersections, as well as
; the one-way prison doors. the maze is imported from a picture.
to setup-patches
  import-pcolors "pacman-maze.png"
  ask patches [
    ifelse pcolor = 104.7 [
      set player-wall? false
      set wall? true
      set intersection? false
    ][
      ifelse pcolor = 17.5[
        set player-wall? true
      ][
        set player-wall? false
        set wall? false
        set intersection? false
      ]
    ]
  ]
  ; determine all the intersections of the maze. they MUST be at the exact center of a patch.
  ask patches with [wall? = false  and (pxcor mod 3 = 0) and (pycor mod 3 = 0)][
    if count (patches in-radius 3 with [wall? = true]) = 4 or count (patches in-radius 2 with [wall? = true]) = 1 [
      ;set pcolor green       ; Used to see the main intersections that the ghosts randomly choose paths from
                              ; uncomment to see which patches are considered intersections!
      set intersection? true
    ]
  ]

  ; makes sure that the patches above the pink barrier are viewed as a wall by the player
  ask patch 0 9 [ set intersection? false set pcolor black] ; our algorithm initially determines this patch as an intersection, so we correct this
  ask patch 0 3 [ set intersection? false set pcolor black] ; same with this patch
  ask patch -1 7 [ set player-wall? true ]
  ask patch  0 7 [ set player-wall? true ]
  ask patch  1 7 [ set player-wall? true ]

end


; Core of the game.
; Each time the player begins a round (whether they die or complete the level)
;    the program sets wait? to be true. While it's true, this function will not move the agents
;    for the first 2 seconds so that the player isn't immediately thrown into the game.
; It always first checks how many lives the player has because if the player has no lives,
;    then the game is over and it calls 'stop'
;
to move
  ; Before the round starts, displays "READY?"
  ifelse wait? [
    ask patch 3 -6 [ set plabel-color yellow set plabel "READY?"]
  ][
    ask patch 3 -6 [ set plabel ""]
  ]

  ask score-patch [set plabel word "SCORE: " score] ;update the score constantly

  ; Runs this if statement only when the player has no lives left.
  ; This stops the game completely.
  if lives < 0 [
    ask turtles [ die ]
    ask patch 4 -6 [ set plabel-color yellow set plabel "GAME OVER"]
    show score
    stop
  ]

  ; Runs everything in this if statement if the round has started
  if not wait? [
    if timer > 3[
      if not any? fruits and not fruit-placed?[
        place-fruit
        set fruit-placed? true
      ]
    ]
    set time-frame round (timer * framerate) ; count 1 frame every 1/60th of a second
    if frame < time-frame + 1[ ; this is run one frame after another, basically means
                               ; check if this is the next frame before performing move procedure.
      move-player

      ; Makes sure ghosts don't stay in frightened mode longer than 8 seconds
      ; Also flashes ghosts for the last three seconds before
      ;     frightened mode ends
      check-frightened

      ; Ghosts that are eaten move to their box and become active again
      ask ghosts with [shape = "eaten"] [
        restart
      ]

      enemy-movement
      set frame frame + 1
    ]
    collisions
    ; Checks if the player has beaten the level (collected all pellets)
    ifelse not any? pellets [
      next-level
      setup-pellets
    ][
      if kill-player? [
       kill-player
      ]
    ]
  ]

  ; This is always run first technically. Makes sure that
  ; the program waits two full seconds before beginning rounds.
  ; That way the player isn't immediately thrown in.
  if (timer >= 2) and wait?[
   set wait? false
    set level-done? false
    reset-timer
  ]
end

; The general movement of every ghost.
; They'll randomly choose whether to turn or continue forward.
; They'll never move backwards.

to scatter
  force-center
  ;handle when and which direction to turn at a marked intersection
  ;when at an intersection, go either forward, left, or right
  if [intersection?] of patch-here = true and on-intersection? = false[
    move-to one-of patches with [intersection? = true and distance myself < 1]
    let patches-to-turn-toward (patch-set patch-ahead 2 patch-left-and-ahead 90 2 patch-right-and-ahead 90 2)
    face one-of patches-to-turn-toward with [wall? = false]
    set on-intersection? true
  ]
  ifelse [wall?] of patch-ahead 2 = false[
    fd speed
    if [intersection?] of patches in-radius 1 = false or [intersection?] of patch-here = false[
      set on-intersection? false
    ]
  ][

    if [wall?] of patch-right-and-ahead 90 2 = false[ ; if ghost reaches a corner where only available turn is right
      rt 90
    ]
    if [wall?] of patch-left-and-ahead 90 2 = false[ ; if ghost reaches a corner where only available turn is left
      lt 90
    ]

    set heading round heading
  ]
end


; determines all the autonomous behaviors of the ghosts
to enemy-movement
  ask ghosts with [shape != "eaten"] [
    ifelse not boxed? [
      ; normal movement
      scatter
      let target pacmans in-cone sight-range 150
      if any? target[ chase ]
      ;ask patches in-cone sight-range 45 [if pacmans-on myself = true [chase]]
    ][
      ; Otherwise slowly frees the ghosts until they've all started roaming
      ; but they won't leave if they're frightened.
      ; Also stops ghosts in the process of leaving the prison since they'd be safe there.
      if not frightened? [
        ; Each ghost has a time given to them to wait until before they can roam (time-before-roam).
        ; Went that time has passed, they start roaming.
        ; It's a variable because the times will change as the player progresses through levels.
        ; The "self" check makes sure a ghost can't make another ghost move when they shouldn't
        if (timer - roam-timer >= time-before-roam) and (self = clyde) [
          if [boxed?] of clyde = true[
            ask clyde [set heading 0 roam ]
          ]
        ]

        if ((timer - roam-timer) >= (time-before-roam * 2 )) and (self = inky) [
          if [boxed?] of inky = true[
            ask inky [ set heading 270 roam if xcor < 0 [ move-to patch 0 3]]
          ]
        ]

        if ((timer - roam-timer) >= (time-before-roam * 3 )) and (self = blinky) [
          if [boxed?] of blinky = true[
            ask blinky [ set heading 90 roam if xcor > 0 [ move-to patch 0 3]]
          ]
        ]

        if (self = pinky) [
          ask pinky [roam]
        ]
      ]
    ]
  ]
end



; Checks how long ghosts have been in frightened state since
; the last eaten power pellet.

to check-frightened
  ; Waits for a ghost to be in the "frightened" state for a max of 8 seconds
  ; before becoming harmful again.
  ifelse timer - frightened-timer > 8 [
    ask ghosts with [shape != "eaten"] [
      set shape "ghost"
      set speed enemy-speed
      set frightened? false
    ]
  ][
    ; Makes ghosts  that are frightened flash for the last 3 seconds before
    ; they return to normal
    ask ghosts with [frightened? and shape != "eaten"] [
      if (timer - frightened-timer) > 5 and (timer - frightened-timer) < 6  [
        set shape "flashing frightened"
      ]
      if (timer - frightened-timer) > 6 and (timer - frightened-timer) < 7 [
        set shape "frightened"
      ]
      if (timer - frightened-timer) > 7 and (timer - frightened-timer) < 8 [
        set shape "flashing frightened"
      ]
    ]
  ]
end


; procedure for leaving the ghost prison
to roam

  ; First checks if the ghost is in the middle of their prison so they can leave it.
  ; If not, moves them towards it.
  ; If so, then checks if they're out of the box.
  ;        If not, makes them move upwards until they are.

  ifelse xcor = 0 [
    ifelse ycor >= 9 [
      setxy 0 9            ; just to be sure that the ghost is centered precisely.
      set boxed? false
    ][
      set heading 0
      fd speed
    ]
  ][
   fd speed
  ]
end


;procedure for making eaten ghosts glide back to their starting position in the prison
to restart
  face patch 0 3
  set speed enemy-speed
  fd speed
  if (pxcor = 0 and pycor = 3) [
    setxy 0 3
    set heading 0
    set boxed? true
    set frightened? false
    set shape "ghost"
  ]
end


; determines what agents should do when colliding into each other

to collisions
  ; Anytime the score is increased, the player is asked to show it.

  ;;;Pellet interactions
  ask pellets [
   if distance player <= 1 [
      ifelse size = 2 [

        ; If a power pellet is eaten, more points and enable frightened mode
        set score (score + 50)
        ask ghosts with [shape != "eaten"] [frightened-mode]
      ][
        set score (score + 10)
      ]
      die
    ]
  ]

  ;;;Fruit interactions
  ask fruits[
    if distance player <= 1[
      ;score given depends on the fruit
      if shape = "banana" [set score score + 3000]
      if shape = "strawberry" [set score score + 1000]
      if shape = "apple" [set score score + 500]
      die
    ]
  ]

  ;;;Ghost interactions
  ask ghosts [
    ;Ghosts not in frightened mode can kill the player
    ifelse frightened? = false[
      if distance player < 1 [
        set kill-player? true
      ]
    ][
      ;Ghosts not in frightened mode can be eaten and reset
      if (distance player < 1.25) and (shape != "eaten") [
        ; There's a score multiplier that increases with each
        ; eaten consecutive ghost eaten, maxing at 1600.
        set score (score + multiplier)
        if multiplier < 1600[
          set multiplier (multiplier * 2)
        ]
        get-eaten

      ]
    ]
  ]
end


; makes ghost become harmless eyes
to get-eaten
  set shape "eaten"
end


; Is called when the player completes a level.
; Resets all variables and agent positions
;    ---It's also called when a player dies because
;       we realised it needs the same variable and agent resets.
to next-level
  set fruit-placed? false

  set multiplier 200
  set roam-timer 0
  set level-done? true
  set wait? true
  set enemy-speed enemy-speed + 0.01
  ask ghosts [set speed enemy-speed]

  if time-before-roam > 3 [
    set time-before-roam (time-before-roam * 0.8)
  ]

  ask player [
    setxy 0 -15
    set heading 0
    set size 3
    set color yellow
    set hidden? false
  ]
  ask pinky  [ setxy 0 9 set frightened? false set shape "ghost" set heading 0 ]
  ask blinky [ setxy -3 3 set frightened? false set boxed? true set shape "ghost" set heading 0 ]
  ask inky   [ setxy 3 3 set frightened? false set boxed? true set shape "ghost" set heading 0 ]
  ask clyde  [ setxy 0 3 set frightened? false set boxed? true set shape "ghost" set heading 0 ]

  reset-ticks
  reset-timer
  set frame 0
  set time-frame 0
end


; kill the player and subtract lives
to kill-player
   repeat 5 [ ;animate pacman's death (mini explosion?)
   ask player [
      set size (size - 0.3)
      set color (color + 1)

      wait 0.1
    ]
  ]
  if any? fruits [ask fruits [die]]
  ask one-of life-reps [die]
  set lives (lives - 1)
  set kill-player? false

  ifelse lives >= 0 [
    ; calls next-level because it requires the same variable and agent resets
    next-level
  ][
    ask patch 3 -6 [ set plabel-color red set plabel "GAME OVER"]
  ]
end


; chase the player if within the ghost's wide line of sight by trying to track the player's nearby movements
; ghosts in chasing mode will try to take the shorter path to the player
to chase
  let temp-distance 0 ;the distance from the ghost's current patch to the player
  let player-position patch-at [pxcor] of player [pycor] of player ;the patch where the player rests at this moment

  if [intersection?] of patch-here = true and on-intersection? = false[
    move-to one-of patches with [intersection? = true and distance myself < 1 ]
    let patches-to-turn-toward (patch-set patch-ahead 2 patch-ahead -2 patch-left-and-ahead 90 2 patch-right-and-ahead 90 2)
    ask patch-here [set temp-distance distance player]

    if any? patches-to-turn-toward with [wall? = false and distance player < temp-distance][
      face one-of patches-to-turn-toward with [wall? = false and distance player < temp-distance]
    ]
    set on-intersection? true
  ]
  ifelse [wall?] of patch-ahead 2 = false[
    if [intersection?] of patches in-radius 1 = false or [intersection?] of patch-here = false[
      set on-intersection? false
    ]
  ][

    if [wall?] of patch-right-and-ahead 90 2 = false[ ; if ghost reaches a corner where only available turn is right
      rt 90
    ]
    if [wall?] of patch-left-and-ahead 90 2 = false[ ; if ghost reaches a corner where only available turn is left
      lt 90
    ]

    set heading round heading
  ]

end

; Called when the player eats a power pellet.
; Sets all currently roaming ghosts to their frightened state
to frightened-mode
  set frightened-timer timer
  set speed (speed * 0.5)
  if not any? ghosts with [shape = "frightened"] [
   set multiplier 200
  ]
  ; If a ghost has been eaten (shape is not just the pair of eyes),
  ; it cannot enter frightened mode again until it resets itself in the 'prison'.
  ask ghosts with [shape != "eaten"] [
    set shape "frightened"
    set frightened? true
  ]
end




;-------- Next 4 procedures change the direction the agent will turn at the next available turn

; Agent will turn up, turning off any other turn request.
to turn-up
  set want-up? true
  set want-down? false
  set want-left? false
  set want-right? false
end


; Agent will turn right, turning off any other turn request.
to turn-right
  set want-up? false
  set want-down? false
  set want-left? false
  set want-right? true
end


; Agent will turn down, turning off any other turn request.
to turn-down
  set want-up? false
  set want-down? true
  set want-left? false
  set want-right? false
end


; Agent will turn left, turning off any other turn request.
to turn-left
  set want-up? false
  set want-down? false
  set want-left? true
  set want-right? false
end


; No turn request given at the start. Player chooses.
to turn-setup
  set want-up? false
  set want-down? false
  set want-left? false
  set want-right? false
end


; this method makes sure that the player and any moving agent is centered on each
; patch for ease of movement. with this method, the distance that an agent may jump
; to be at the exact center of a patch is nominal.
to force-center
  if heading = 0 or heading = 180[ ; turns |-o---| to |--o--| if agents are out of alignment
    set xcor round xcor
  ]
    if  heading = 270 or heading = 90[ ; turns  ===  to ===   if agents are out of alignment
    set ycor round ycor                ;         =       o
  ]                                    ;        _o_     ===
end


;animate Pac-man so that his mouth opens every other frame
to animate-pacman
  ask player[
    if time-frame mod 4 = 0 [set shape "pacman"]
    if time-frame mod 4 = 2 [set shape "circle"]
  ]
end


; player movement is set up so that the user only has to tap in the direction that they want to go in next
; just once, so the need to hold down a key to change direction is eliminated. Due to this implementation,
; the player is constantly moving unless they are in front of a wall.
to move-player
  ask player [
    force-center ;always stay centered on every patch when moving
    if want-up? [
      ask patch ([pxcor] of player) (([pycor] of player) + 1) [
        ifelse any? neighbors with [wall? = true] [
        ] [
          ask player [set heading 0]
        ]
      ]
    ]
    if want-down? [
      ask patch ([pxcor] of player) (([pycor] of player) - 1) [
        ifelse any? neighbors with [wall? = true] [
        ] [
          ask player [set heading 180]
        ]
      ]
    ]
    if want-right? [
      ask patch (([pxcor] of player) + 1) ([pycor] of player) [
        ifelse any? neighbors with [wall? = true] [
        ] [
          ask player [set heading 90]
        ]
      ]
    ]
    if want-left? [
      ask patch (([pxcor] of player) - 1) ([pycor] of player) [
        ifelse any? neighbors with [wall? = true] [
        ] [
          ask player [set heading 270]
        ]
      ]
    ]

    ; if no walls are ahead of the player, move and animate
    if [wall?] of patch-ahead 2 = false  and [player-wall?] of patch-ahead 3 = false[
      fd speed
      animate-pacman
    ]
  ]

end


; Code places pellets in areas the player can't reach. This deletes those pellets.
to kill-extra-pellets
  ask turtles with [ (ycor = 9)  and (xcor < -19) ] [ die ]
  ask turtles with [ (ycor = 9)  and (xcor >  19) ] [ die ]
  ask turtles with [ (ycor = -3) and (xcor < -19) ] [ die ]
  ask turtles with [ (ycor = -3) and (xcor >  19) ] [ die ]
  ask turtles with [ (ycor = -3) and (xcor =   0) ] [ die ]
end


; Sets up the large power pellets on the corners of the maze
to set-big-pellets
  ask turtles with [ (ycor =  27)  and (xcor = -24) ] [ set size 2 set color yellow ]
  ask turtles with [ (ycor = -27)  and (xcor = -24) ] [ set size 2 set color yellow ]
  ask turtles with [ (ycor = -27)  and (xcor =  24) ] [ set size 2 set color yellow ]
  ask turtles with [ (ycor =  27)  and (xcor =  24) ] [ set size 2 set color yellow ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
674
523
-1
-1
8.0
1
14
1
1
1
0
1
1
1
-28
28
-31
31
0
0
1
ticks
60.0

BUTTON
17
44
80
77
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
16
106
132
139
PLAY PAC-MAN
move
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
77
181
140
214
up
ask player [turn-up]
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
79
234
142
267
down
ask player [turn-down]
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
5
235
72
268
left
ask player [turn-left]
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
149
234
212
267
right
ask player [turn-right]
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

@#$#@#$#@
## Kevin Hernandez, Felix Velez HW5: Pac-Man!

## HOW TO PLAY

To start the game, first press the "setup" button. Then press
"PLAY PAC-MAN"

You are Pac-Man! And boy are you hungry for pellets!

Your goal is to eat every pellet in the level while trying to avoid the
4 spooky ghosts looking to scare you. Do that, and you move on to the next level.
But you only have 3 tries!

The only conrtols are using WASD to move Pac-Man through the maze. You
do not have to hold the keys. Just press the direction to want Pac-Man to turn
once and he'll do it when he can.

In the four corners of the maze are power pellets. These big ones
allow Pac-Man to eat even the ghosts (for a limited time)
and send them back to their little box.

If you eat ghosts consecutively, the points for each ghost multiplies.


## THE AGENTS

The agents include Pac-Man (the player) and the 4 ghosts (autonomous).

One by one a new ghost is programmed to leave the prison to pursue the player. Generally, they will randomly choose directions (except backwards). But if the player is within their line of sight, they will try to track down the player by following the player's movements.

Each ghost is slightly different in speed and vision. For example, Blinky (red ghost) has the largest range of sight, while Clyde (orange ghost) has the smallest. As the player progresses to new levels, the ghosts slowly get more agressive, increasing their speed and shortening the time they stay in their prison.

## CREDITS

We used this page as a reference in recreating the behaviors from the Pac-Man game:

-http://gameinternals.com/post/2072558330/understanding-pac-man-ghost-behavior


Other pages include:

-The Netlogo Online Dictionary
-Stack Overflow
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

apple
false
0
Polygon -7500403 true true 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

banana
false
0
Polygon -7500403 false true 25 78 29 86 30 95 27 103 17 122 12 151 18 181 39 211 61 234 96 247 155 259 203 257 243 245 275 229 288 205 284 192 260 188 249 187 214 187 188 188 181 189 144 189 122 183 107 175 89 158 69 126 56 95 50 83 38 68
Polygon -7500403 true true 39 69 26 77 30 88 29 103 17 124 12 152 18 179 34 205 60 233 99 249 155 260 196 259 237 248 272 230 289 205 284 194 264 190 244 188 221 188 185 191 170 191 145 190 123 186 108 178 87 157 68 126 59 103 52 88
Line -16777216 false 54 169 81 195
Line -16777216 false 75 193 82 199
Line -16777216 false 99 211 118 217
Line -16777216 false 241 211 254 210
Line -16777216 false 261 224 276 214
Polygon -16777216 true false 283 196 273 204 287 208
Polygon -16777216 true false 36 114 34 129 40 136
Polygon -16777216 true false 46 146 53 161 53 152
Line -16777216 false 65 132 82 162
Line -16777216 false 156 250 199 250
Polygon -16777216 true false 26 77 30 90 50 85 39 69

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

eaten
false
0
Rectangle -16777216 true false 120 225 210 225
Circle -1 true false 86 86 67
Circle -1 true false 161 86 67
Circle -13345367 true false 193 118 32
Circle -13345367 true false 118 118 32

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flashing frightened
false
0
Rectangle -1 true false 60 120 240 225
Circle -1 true false 63 33 175
Rectangle -16777216 true false 120 225 210 225
Polygon -1 true false 60 210 60 255 90 225 120 255 150 225 180 255 210 225 240 255 240 210 60 210
Rectangle -13345367 true false 105 105 135 135
Rectangle -13345367 true false 165 105 195 135
Rectangle -13345367 true false 90 180 105 195
Rectangle -13345367 true false 135 180 165 195
Rectangle -13345367 true false 195 180 210 195
Rectangle -13345367 true false 165 195 195 210
Rectangle -13345367 true false 105 195 135 210
Rectangle -13345367 true false 210 195 225 210
Rectangle -13345367 true false 75 195 90 210

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

frightened
false
0
Rectangle -13345367 true false 60 120 240 225
Circle -13345367 true false 63 33 175
Rectangle -16777216 true false 120 225 210 225
Polygon -13345367 true false 60 210 60 255 90 225 120 255 150 225 180 255 210 225 240 255 240 210 60 210
Rectangle -1 true false 105 105 135 135
Rectangle -1 true false 165 105 195 135
Rectangle -1 true false 90 180 105 195
Rectangle -1 true false 135 180 165 195
Rectangle -1 true false 195 180 210 195
Rectangle -1 true false 165 195 195 210
Rectangle -1 true false 105 195 135 210
Rectangle -1 true false 210 195 225 210
Rectangle -1 true false 75 195 90 210

ghost
false
0
Rectangle -7500403 true true 60 120 240 225
Circle -7500403 true true 63 33 175
Rectangle -16777216 true false 120 225 210 225
Circle -1 true false 86 86 67
Circle -1 true false 161 86 67
Circle -13345367 true false 193 118 32
Circle -13345367 true false 118 118 32
Polygon -7500403 true true 60 210 60 255 90 225 120 255 150 225 180 255 210 225 240 255 240 210 60 210

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

moon
false
0
Polygon -7500403 true true 175 7 83 36 25 108 27 186 79 250 134 271 205 274 281 239 207 233 152 216 113 185 104 132 110 77 132 51

pacman
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 45 45 150 150 255 30 195 0 105 0 45 30 45 45

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

strawberry
false
0
Polygon -7500403 false true 149 47 103 36 72 45 58 62 37 88 35 114 34 141 84 243 122 290 151 280 162 288 194 287 239 227 284 122 267 64 224 45 194 38
Polygon -7500403 true true 72 47 38 88 34 139 85 245 122 289 150 281 164 288 194 288 239 228 284 123 267 65 225 46 193 39 149 48 104 38
Polygon -10899396 true false 136 62 91 62 136 77 136 92 151 122 166 107 166 77 196 92 241 92 226 77 196 62 226 62 241 47 166 57 136 32
Polygon -16777216 false false 135 62 90 62 135 75 135 90 150 120 166 107 165 75 196 92 240 92 225 75 195 61 226 62 239 47 165 56 135 30
Line -16777216 false 105 120 90 135
Line -16777216 false 75 120 90 135
Line -16777216 false 75 150 60 165
Line -16777216 false 45 150 60 165
Line -16777216 false 90 180 105 195
Line -16777216 false 120 180 105 195
Line -16777216 false 120 225 105 240
Line -16777216 false 90 225 105 240
Line -16777216 false 120 255 135 270
Line -16777216 false 120 135 135 150
Line -16777216 false 135 210 150 225
Line -16777216 false 165 180 180 195

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
