# galAKUxian

A pseudo GAPLUS experience.
 
## Something like a note

I have not written a single line of code in this project.

I just played the game, said "this is too fast", "the hitbox feels wrong",
"the enemies should bounce like juggling" — and Claude wrote everything.

This is what programming looks like for me in the LLM era.
I don't know if this is good or bad, but it was a lot of fun.

One of our goals was to push the limits of bash. No C, no Python, no game
engine — just bash, tput and stty. Some things I'm particularly proud of:

- Smooth star scrolling using Braille characters as sub-character pixels
- Fixed-point physics (×16) for gravity and bouncing in the challenging stage
- A juggling mechanic where enemies speed up every time you shoot them
- Capture beam with spiral animation, escort ships, boss battles
- All of it running at ~25fps in a terminal

By the way, the name is a parody of Galaxian, yet the gameplay is a pseudo
Gaplus experience. This is entirely intentional — blame me, not the LLM.

And yes, I can write perfect English now, too. (thanks to LLM)

## Requires

bash, tput (ncurses), stty

## Run

`bash start.sh`

## Debug

`bash start.sh rush`  
`bash start.sh boss`  
`bash start.sh challenge`

EOF
