{Nopac v1.12.143
 Copyright 2012 Nicholas Parks Young.}

program nopac;
uses crt, strings;

const
     key_up = 119;     {w}
     key_left = 97;    {a}
     key_down = 115;   {s}
     key_right = 100;  {d}
     key_quit = 112;   {p}
     key_save = 107;   {k}
     key_load = 108;   {l}

     key_debug = 109;  {m}
     key_debug_enabled = true; {Enable the debug key?}

     block_nothing = 32;     {space}
     block_nopass = 37;      {%}
     block_player = 63;      {?}
     block_baddie = 33;      {!}
     block_points = 111;     {o}
     block_baddiesafe = 42;  {*}
     block_safebaddie = 44;  {,}
     block_eatenbaddie = 46; {.}

     base_max_x = 79;        {Absolute maximum x size}
     base_max_y = 23;        {Abs max x size}
     max_x : byte = 79;      {current max x - related to Level}
     max_y : byte = 23;      {current max y - related to Level}
     min_x = 40;             {Minimum size of the screen on x}
     min_y = 15;             {minimum size of the screen on y}

     score_baddiesafe = 50; {Score achieved for eating a baddiesafe}
     score_baddie = 200;    {Score achieved for eating a baddie in safemode}
     score_orb = 20;        {Score achieved for eating an orb}
     score_movement = -1;   {Score achieved for the player moving.}

     max_baddies : byte = 15;   {current number of baddies}
     abs_max_baddies = 30;      {The maximum no. of baddies possible, i.e. size of the array}
     max_baddiesafe = 4;        {Number of baddiesafes in game}
     baddiesafe_time = 40;      {how long baddies are rendered safe}
     points_start : byte = 25;  {starting number of orbs}
     baddie_distance = 7;       {How close the player can be before baddie follows player}
     max_level = 15;            {if level := max_level, you have won the game!}

     version = '1.12.143';   {Game version identifier}

type
    baddie = record
           x : byte;
           y : byte;
           eaten : byte;
    end;
    savedlevel = record
           version : string;
           level : byte;
           player_x : byte;
           player_y : byte;
           orbs_collected : integer;
           score : integer;
           baddiesafe_timer : integer;
           baddies : array[1..abs_max_baddies] of baddie;
           blocks : array[0..base_max_x, 0..base_max_y] of byte;
    end;


var
   newgame : boolean;                 {Is this a newgame or not?}
   blocks : array[0..base_max_x, 0..base_max_y] of byte;       {Block storage for screen}
   baddies : array[1..abs_max_baddies] of baddie;    {Baddie information}
   key : char;                        {Player's input character buffer}
   player_x, player_y : integer;      {Players position}
   points_collected, score : integer; {How many orbs collected, and player's score}
   baddiesafe_remain : integer;       {how many turns are left before baddiesafe ends. 0 = off}
   screeninit : boolean;              {Is the WinCrt unit initialised, or not?}
   curlevel : byte;                   {Player's current level}

procedure compatgotoxy (X : byte; Y : byte);
begin
	gotoxy(x+1, y+1);
end;

procedure halt;
begin
     write('Press any key to continue... ');
     readkey;
     compatgotoxy(0, wherey);
     clreol;
end;

function getmaxbaddies(level : byte) : byte;
begin
     getmaxbaddies := round(level * (abs_max_baddies / max_level));
end;

function getmax_x (level : byte) : byte;
begin
     getmax_x := round(level * ((base_max_x - min_x) / max_level)) + min_x;
end;

function getmax_y (level : byte) : byte;
begin
     getmax_y := round(level * ((base_max_y - min_y) / max_level)) + min_y;
end; 

function calcwrap (value : integer; movement : integer; modulus : integer) : integer;
var
   a, b, c : integer;
begin
     a := value + movement;
     b := a mod modulus;
     c :=modulus + b;
     calcwrap := c mod modulus;
end;

procedure movebaddie(i : integer; direction : integer);
begin

     {Decide which way we're going}
     {NOTE: Baddies _are_ allowed to walk over points, but they don't collect them}
     case direction of
     {move up}
     key_up:
            if blocks[baddies[i].x, calcwrap(baddies[i].y, -1, max_y + 1)] <> block_nopass then begin
               baddies[i].y := calcwrap(baddies[i].y, -1, max_y + 1);
            end;
     {move down}
     key_down:
              if blocks[baddies[i].x, calcwrap(baddies[i].y, 1, max_y + 1)] <> block_nopass then begin
                 baddies[i].y := calcwrap(baddies[i].y, 1, max_y + 1);
              end;
     {move left}
     key_left:
              if blocks[calcwrap(baddies[i].x, -1, max_x + 1), baddies[i].y] <> block_nopass then begin
                 baddies[i].x := calcwrap(baddies[i].x, -1, max_x + 1);
              end;
     {move right}
     key_right:
               if blocks[calcwrap(baddies[i].x, 1, max_x + 1), baddies[i].y] <> block_nopass then begin
                  baddies[i].x := calcwrap(baddies[i].x, 1, max_x + 1);
               end;
     end;
end;

procedure movebaddietowardplayer(i : integer);
var
   dist_y, dist_x : integer;
   temp : integer;
begin
     dist_x := abs(baddies[i].x - player_x);
     dist_y := abs(baddies[i].y - player_y);

     if dist_x > dist_y then begin
        {player is closer on y-axis, therefore move on x-axis}
        temp := abs(baddies[i].x + 1 - player_x);
        if temp < dist_x then
           movebaddie(i, key_right)
        else
            movebaddie(i, key_left);
     end   
     else begin
         {player is closer on x-axis therefore move on y-axis}
         temp := abs(baddies[i].y + 1 - player_y);
         if temp < dist_y then
            movebaddie(i, key_down)
         else
             movebaddie(i, key_up);
     end;

end;

procedure printscore;
begin
     compatgotoxy(0, (max_y + 1));
     clreol;
     write('Level: ', curlevel, '/', max_level, '. Score: ', score, '. Orbs collected: ');
     write(points_collected, '/', points_start, '.');
     if baddiesafe_remain > 0 then
        write(' Baddiesafe: ', baddiesafe_remain);
end;

procedure animatebaddies;
var
   i, j, meandist : integer;
begin

     for i := 1 to max_baddies do
     begin

          meandist := round((abs(baddies[i].x - player_x) + abs(baddies[i].y - player_y)) / 2);
          if (meandist < baddie_distance) and (baddiesafe_remain = 0) and (baddies[i].eaten = 0) then begin
             case random(10) of
             0: movebaddie(i, key_up);
             1: movebaddie(i, key_down);
             2: movebaddie(i, key_left);
             3: movebaddie(i, key_right);
             4, 5, 6, 7, 8: movebaddietowardplayer(i);
             {9: do not move baddie}
             end;
          end else begin
              case random(8) of
              0: movebaddie(i, key_up);
              1: movebaddie(i, key_down);
              2: movebaddie(i, key_left);
              3: movebaddie(i, key_right);
              4, 5: movebaddietowardplayer(i);
              {6, 7: do not move baddie}
              end;
          end;
     end;

end;

procedure createscreen;
begin
{     if screeninit = true then donewincrt;
     screensize.x := max_x + 1;
     screensize.y := max_y + 2;
     windowsize.x := screensize.x * 10;
     windowsize.y := screensize.y * 17;}
     {strcopy(windowtitle, 'Nopac');}
     {initwincrt;}
     screeninit := true;
end;

procedure init;
begin

     randomize;

     createscreen;

     newgame := false;

     writeln('Nopac v', version);
     writeln('Copyright 2012 Nicholas Parks Young.');

     writeln;
     writeln('GAME INSTRUCTIONS');
     writeln('-----------------');
     writeln('Move your character with ', chr(key_up), ', ', chr(key_left), ', ', chr(key_down), ' and ', chr(key_right), '.');
     writeln('Press ', chr(key_quit), ' at any time to quit the game.');
     writeln('Press ', chr(key_save), ' to save your progress, or ', chr(key_load), ' to load a previous save.');
     writeln;
     writeln(chr(block_player), ' Player - this is you!');
     writeln(chr(block_nopass), ' Block - nothing can move over this, including you.');
     writeln(chr(block_points), ' Orbs - You need to collect them all to win, and get ', score_orb, ' points per orb.');
     writeln(chr(block_baddie), ' Baddie - if they eat you, you lose!');
     write(chr(block_baddiesafe), ' Baddiesafe - These neutralise baddies for ', baddiesafe_time, ' turns');
     writeln(' and gain you ', score_baddiesafe, ' points.');
     writeln(chr(block_safebaddie), ' Safe Baddie - A neutralised Baddie. Eating one will net you ', score_baddie, ' points.');
     writeln(chr(block_eatenbaddie), ' Eaten Baddie - You cannot eat them again unless you eat another Baddiesafe.');


     writeln;
     halt;

end;

procedure refreshscreen;
var i, j, k : integer;
begin
     {clrscr;}
     {draw blocks, points and baddiesafe}
     for j := 0 to max_y do begin
         compatgotoxy(0,j);
         for i := 0 to max_x do begin
             write(chr(blocks[i,j]));          
         end;
     end;
     {draw the baddies}
     for k := 1 to max_baddies do begin
         compatgotoxy(baddies[k].x, baddies[k].y);
         if (baddies[k].eaten = 1) then
            write(chr(block_eatenbaddie))
         else
             if baddiesafe_remain > 0 then
               write(chr(block_safebaddie))
             else
                 write(chr(block_baddie));
     end;
     {draw the player}
     compatgotoxy(player_x, player_y);
     write(chr(block_player));
     if newgame = true then begin
        compatgotoxy(player_x - 2, player_y);
        write('>');
        compatgotoxy(player_x - 1, player_y);
        write('>');
        compatgotoxy(player_x + 1, player_y);
        write('<');
        compatgotoxy(player_x + 2, player_y);
        write('<');
        newgame := false;
     end;
     {refresh visible score counter}
     printscore;
end;

procedure resetbaddieseaten;
var i : integer;
begin
     {Reset the baddie_eaten array when baddiesafe_remain = 0}
     for i := 1 to max_baddies do
         baddies[i].eaten := 0;
end;

procedure generatelevel;
var
   i, j, temp_x, temp_y : integer;
   proceed : boolean;
begin

     {Set level parameters}
     max_x := getmax_x(curlevel);
     max_y := getmax_y(curlevel);
     max_baddies := getmaxbaddies(curlevel);

     {change screensize to match new params}
     {Commented - Doesn't work as intended since DonWinCrt procedure also kills the program}
     {createscreen;}
     clrscr;

     {Clear out all old data}
     for i := 0 to base_max_x do begin
         for j := 0 to base_max_y do begin
             blocks[i, j] := block_nothing;
         end;
     end;
     for i := 1 to max_baddies do begin
         baddies[i].x := 0;
         baddies[i].y := 0;
         baddies[i].eaten := 0;
     end;


     {Generate random blockages}
     for i := 0 to max_x do begin
         for j := 0 to max_y do begin
             case random(5) of
             1:   blocks[i,j] := block_nopass;
             else
                 blocks[i,j] := block_nothing;
             end;
         end;
     end; 

     {Generate points}
     for i := 1 to points_start do begin
         repeat
               proceed := false;
               temp_x := random(max_x);
               temp_y := random(max_y);
               if blocks[temp_x, temp_y] = block_nothing then begin
                  proceed := true;
                  blocks[temp_x, temp_y] := block_points;
               end;
         until proceed = true;
     end;

     {Generate Baddie Safe-mode thingies}
     for i := 1 to max_baddiesafe do begin
         repeat
               proceed := false;
               temp_x := random(max_x);
               temp_y := random(max_y);
               if blocks[temp_x, temp_y] = block_nothing then begin
                  proceed := true;
                  blocks[temp_x, temp_y] := block_baddiesafe;
               end;
         until proceed = true;
     end;

     {Generate player start}
     proceed := false;
     repeat
           player_x := random(max_x - 2) + 2;
           player_y := random(max_y - 2) + 2;
           if blocks[player_x, player_y] = block_nothing then
              proceed := true;
     until proceed = true;

     {Generate baddies}
     for i := 1 to max_baddies do begin
         repeat
               proceed := false;
               temp_x := random(max_x);
               temp_y := random(max_y);
               if blocks[temp_x, temp_y] = block_nothing then begin
                  if (player_x <> temp_x) and (player_y <> temp_y) then begin
                     proceed := true;
                     baddies[i].x := temp_x;
                     baddies[i].y := temp_y;
                     baddies[i].eaten := 0;
                  end;
               end;
         until proceed = true;
     end;

     {Reset player variables}
     {score := 0;}
     points_collected := 0;
     newgame := true;
     baddiesafe_remain := 0;

     {Reset baddies to non-safe mode}
     resetbaddieseaten;

end;

procedure gameover (win : boolean);
var locX, locY : byte;
begin

     {Clear the Baddiesafe timer, so that the
         Press Any Key To Continue text
         doesn't spill the line over the edge!}
     {It isn't neccessary for any other reason,
         since generate level already does it.}
     baddiesafe_remain := 0;

     if (curlevel = max_level) and (win = true) then begin

        {User won entire game!}

        locX := round((max_x + 1) / 2) - 10;
        locY := round((max_y + 2) / 2) - 3;
        compatgotoxy(locX, locY);
        write('                    ');
        locY := locY + 1;
        compatgotoxy(locX, locY);
        write(' +----------------+ ');
        locY := locY + 1;
        compatgotoxy(locX, locY);
        write(' | YOU WON NOPAC! | ');
        locY := locY + 1;
        compatgotoxy(locX, locY);
        write(' |   WELL DONE!   | ');
        locY := locY + 1;
        compatgotoxy(locX, locY);
        write(' +----------------+ ');
        locY := locY + 1;
        compatgotoxy(locX, locY);
        write('                    ');
        printscore;
        write('  ');

     end else begin

     {User won only the level, or lost}

        locX := round((max_x + 1) / 2) - 6;
        locY := round((max_y + 2) / 2) - 3;
        compatgotoxy(locX, locY);
        write('            ');
        locY := locY + 1;
        compatgotoxy(locX, locY);
        write(' +--------+ ');
        locY := locY + 1;
        compatgotoxy(locX, locY);
        if win = false then
           write(' |YOU LOST| ')
        else
           write(' |YOU WON!| ');
        locY := locY + 1;
        compatgotoxy(locX, locY);
        write(' +--------+ ');
        locY := locY + 1;
        compatgotoxy(locX, locY);
        write('            ');
        printscore;
        write('  ');

     end;

     {Wait for user}
     halt;

     {change level and reset score as necessary}
     if win = false then begin
       curlevel := 1;
       score := 0;
     end else
         if curlevel = max_level then begin
            curlevel := 1;
            score := 0;  {reset score when they won the game}
         end else
             curlevel := curlevel + 1;

     {Create new level}
     clrscr;
     generatelevel;
     refreshscreen;
end;

procedure checkplayerlocation;
var i : integer;
begin
     {Check if the player stepped on any points or baddiesafes}
     case blocks[player_x, player_y] of
          block_points: begin
             blocks[player_x, player_y] := block_nothing;
             score := score + score_orb;
             points_collected := points_collected + 1;
          end;
          block_baddiesafe: begin
             blocks[player_x, player_y] := block_nothing;
             score := score + score_baddiesafe;
             baddiesafe_remain := baddiesafe_time;
             resetbaddieseaten;
          end;
     end;
      
     {check if the player has collided with a baddie}
     if (baddiesafe_remain = 0) then begin
        {baddiesafe mode is disabled}
        for i := 1 to max_baddies do begin
            if (player_x = baddies[i].x) and (player_y = baddies[i].y) and (baddies[i].eaten = 0) then
               gameover(false);
        end;
     end else begin
         {baddiesafe mode is enabled}
         for i := 1 to max_baddies do begin
             if (player_x = baddies[i].x) and (player_y = baddies[i].y) then begin
                if baddies[i].eaten = 0 then begin
                   baddies[i].eaten := 1;
                   score := score + score_baddie;
                end;
             end;
         end;
     end;

     {Have they won the level?}
     if points_collected = points_start then
        gameover(true);
end;

procedure savegame;
var
   level : savedlevel;
   filename : string;
   filetext : file of savedlevel;
   i, j : byte;

begin

     clrscr;

     {get the filename from user}
     writeln('Enter a filepath to save to: ');
     readln(filename);
     writeln('Saving...');

     {Open the file for writing}
     assign(filetext, filename);
     rewrite(filetext);

     {Put all the information into this local struct}
     level.version := concat('Nopac ', version);
     level.level := curlevel;
     {level.max_x := max_x;
     level.max_y := max_y;
     level.max_baddies := max_baddies;
     level.max_orbs := points_start;}
     level.player_x := player_x;
     level.player_y := player_y;
     level.orbs_collected := points_collected;
     level.score := score;
     level.baddiesafe_timer := baddiesafe_remain;

     for i := 1 to max_baddies do
         level.baddies[i] := baddies[i];

     for i := 0 to max_x do
         for j := 0 to max_y do
             level.blocks[i, j] := blocks[i, j];



     {Write file}
     write(filetext, level);


     {close the filehandle}
     close(filetext);

     {Return to main game}
     writeln('Save successful. Press any key to continue...');
     readkey;
     refreshscreen;

end;

procedure loadgame;
var
   level : savedlevel;
   filename : string;
   filetext : file of savedlevel;
   i, j : byte;

begin

     clrscr;

     {get the filename from user}
     writeln('Enter a filepath to load from: ');
     readln(filename);

     if length(filename) < 1 then
        {Filename is too short; this will freeze the program.}
        writeln('You have to enter a valid file path!')
     else begin

          writeln('Loading...');

          {Open the file for writing}
          assign(filetext, filename);
          reset(filetext);

          if filesize(filetext) = 1 then begin

             {Load the level}
             read(filetext, level);

             if (level.version = concat('Nopac ', version)) AND (level.level > 0 ) AND (level.level <= max_level) then begin

                {Valid file, at least supposedly.}

                {Read the file data out into the game vars}
                curlevel := level.level;
                max_baddies := getmaxbaddies(level.level);
                max_x := getmax_x(level.level);
                max_y := getmax_y(level.level);
                player_x := level.player_x;
                player_y := level.player_y;
                points_collected := level.orbs_collected;
                score := level.score;
                baddiesafe_remain := level.baddiesafe_timer;

                for i := 1 to getmaxbaddies(level.level) do
                    baddies[i] := level.baddies[i];

                for i := 0 to getmax_x(level.level) do
                    for j := 0 to getmax_y(level.level) do
                        blocks[i, j] := level.blocks[i, j];

                writeln('File successfully loaded.');

             end else
                 writeln('That is not a valid Nopac file.')
          end else 
              writeln('That is not a valid Nopac file.');

          {close the filehandle}
          close(filetext);

     end;

     {Return to main game}
     writeln('Press any key to continue...');
     readkey;
     refreshscreen;

end;

procedure moveplayer (direction : integer);
begin
     case direction of
          {Player move up}
          key_up:
                if blocks[player_x, calcwrap(player_y, -1, max_y + 1)] <> block_nopass then begin
                   player_y := calcwrap(player_y, -1, max_y + 1);
                end;

          {Player move down}
          key_down:
                if blocks[player_x, calcwrap(player_y, 1, max_y + 1)] <> block_nopass then begin
                   player_y := calcwrap(player_y, 1, max_y + 1);
                end;

          {Player move left}
          key_left:
                if blocks[calcwrap(player_x, -1, max_x + 1), player_y] <> block_nopass then begin
                   player_x := calcwrap(player_x, -1, max_x + 1);
                end;

          {player move right}
          key_right:
                if blocks[calcwrap(player_x, 1, max_x + 1), player_y] <> block_nopass then begin
                   player_x := calcwrap(player_x, 1, max_x + 1);
                end;
     end;

     {Move baddies}
     animatebaddies;

     {decrement baddiesafe counter}
     if baddiesafe_remain <> 0 then
        baddiesafe_remain := baddiesafe_remain - 1;

     {Alter player score for movements}
     score := score + score_movement;

     {refresh screen}
     refreshscreen;

     {check what the player stepped on.}
     checkplayerlocation;

end;

{Main game loop}
begin
     {Intialize}
     init;

     {Generate a new level}
     curlevel := 1;
     generatelevel;
     refreshscreen;

     repeat

           {get user input}
           key := readkey;

           {Decide what to do with user input}
           case ord(key) of

           key_debug: if key_debug_enabled = true then gameover(true);

           key_save:  savegame;
           key_load:  loadgame;
           key_up:    moveplayer(key_up);

           key_down:  moveplayer(key_down);
           key_left:  moveplayer(key_left);
           key_right: moveplayer(key_right);

     end;

     {halt main loop on key_quit}
     until key = chr(key_quit);

     {Game done}
     {donewincrt;}

end.