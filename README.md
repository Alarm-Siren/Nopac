# Nopac
*Version 1.12.143*

A simple game of tasty asterisks and deadly exclamation marks.

Nopac, which is definitely Not Pac-Man, is a simple game of moving your question mark avatar around a randomly generated serious of 15 progressively more difficult dungeons, trying to eat all the orbs whilst avoiding deadly exclamation marks. Occasionally you can get your own back on the pesky foes by eating asterisks, which temporarily turns them into edible commas.

I made it to teach myself the Pascal programming language whilst at sixth-form college.

## Comments, Requests, Bugs & Contributions
All are welcome.  
Please file an Issue or Pull Request at https://github.com/Alarm-Siren/Nopac

## License
Copyright 2012, Nicholas Parks Young. Some Rights Reserved.  
This program is licensed under the GNU LGPL v2.1, which can be found in file LICENSE.txt.

## Building Nopac
The Nopac source code is designed to compile with the [Free Pascal Compiler](https://www.freepascal.org/), version 2.6.0. There are no other dependencies. It may work with more recent versions of FPC, though I have not checked. I have included an example make.bat file, but you'll need to edit it to match the specific directory structures you're using.

## Can I play it without building it myself?
Yes! I have uploaded a pre-built Win32 binary, Have a look in [Releases](https://github.com/Alarm-Siren/Nopac/releases).

## Game Instructions
Move your character with w, a, s and d.  
Press p at any time to quit the game.  
Press k to save your progress, or l to load a previous save.  

? Player - this is you!  
% Block - nothing can move over this, including you.  
o Orbs - You need to collect them all to win, and get 20 points per orb.  
! Baddie - if they eat you, you lose!  
&ast; Baddiesafe - These neutralise baddies for 40 turns and gain you 50 points.  
, Safe Baddie - A neutralised Baddie. Eating one will net you 200 points.  
. Eaten Baddie - You cannot eat them again unless you eat another Baddiesafe.  

