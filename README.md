GearRenter
==========

WoW addon that assists in renting PVP gear. This is useful because an item can drop in RBGs, Ashran, or the Coliseum that you already have. 
If you have it rented out, you can just sell it back.

### How to use

1. Open up the conquest or honor vendor (for whichever gear you have rented).
2. Type the command "/rebuy"
3. Watch as it sells, buys, and then equips your gear.

### Notes

This will not sell gear that has enchants on it. 

### Bugs

Right now it doesn't always finish buying/selling. It works currently using a state machine, and advancing the state
machine when events fire. But this messes up sometimes. I'm thinking about having a timer that polls whether the particular
item is sold, whether it was bought, and whether it was equipped, and advance the state machine that way.