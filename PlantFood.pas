{*
 *  Copyright (C) 2005 - William Bell
 *
 *  This file is part of PlantFood version 1.14
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 *  Coded by William Bell (2004-07-03)
 *  email william.bell@frog.za.net
 *  first coded in Turbo Pascal ~1991
 *
 *  This program is compiled using Free Pascal
 *  get it at http://www.freepascal.org/
 *}

program plantfood;
uses video, crt, dos, keyboard;

{-----------------------------------------------------------------------------}
const
  nme:array[1..5] of string=('Nitrogen','Phosphate','Potassium','Calcium','Magnesium');
  maj_ele:array[1..5] of string[4] = ('N','P','K','Ca','Mg');

  cRecipeSelection : char = #2;
  cSelectionForN : char = #3;
  cSelectionForP : char = #4;
  cSelectionForK : char = #5;
  cSelectionForCa : char = #6;
  cSelectionForMg : char = #7;
  cDisplayResults : char = #8;

  cDisplayAbout : char = #49;     { F1  }
  cCustomRecipe : char = #50;     { F2  }
  cAddNewSalt : char = #51;       { F3  }
  cExitProgram : char = #27;      { Esc }

{-----------------------------------------------------------------------------}
var
  SaltData:array[0..200,1..2]  of string[32];
  finalmass:array[1..6] of real;
  finalsalt:array[1..6] of string[32];
  nmdta:array[0..200] of string[32];
  massalt:array[1..5] of real;
  ppmdta:array[0..200,1..6] of string[4];
  ppmelem:array[1..5] of real;
  rto:array[1..11] of real;
  saltnme:array[1..8] of string[32];
  RecipeName:string[32];
  ans,j,cnt,bg,e:integer;
  s:real;
  docTotalRecipes : integer;
  docTotalSalts : integer;
  ckl :integer;
  sltdta:array[0..50,1..2] of string[32];
  vidmode : TVideoMode;
  colorAttr : Word;
  M : TVideoMode;

{-----------------------------------------------------------------------------}
Procedure ForegroundColor(color : Word);
begin
  colorAttr := (colorAttr and $f000) or color shl 8;
end;

{-----------------------------------------------------------------------------}
Procedure BackgroundColor(color : Word);
begin
  // White does not work but reverts to light gray
  colorAttr := (colorAttr and $0f00) or color shl 12;
end;

{-----------------------------------------------------------------------------}
Procedure TextOut(X,Y : Word;Const S : String);

Var
  P,I,M: Word;

begin
  P:=((X-1)+(Y-1)*ScreenWidth);
  M:=Length(S);
  If P+M>ScreenWidth*ScreenHeight then
    M:=ScreenWidth*ScreenHeight-P;
  For I:=1 to M do
    VideoBuf^[P+I-1]:=Ord(S[i])+colorAttr;
end;

{-----------------------------------------------------------------------------}
Procedure ClearTheScreen;
Var
  I,M,Attr: Word;
begin
  Attr:=$20+colorAttr;
  M:=ScreenWidth*ScreenHeight;
  For I:=1 to M do
    VideoBuf^[I]:=Attr;
end;

{-----------------------------------------------------------------------------}
Function itoa (I : Longint) : String;

Var S : String;

begin
 Str(I, S);
 itoa := S;
end;

{-----------------------------------------------------------------------------}
Function ftoa (I : Double) : String;

Var S : String;

begin
 Str(I:4:1, S );
 ftoa := S;
end;

{-----------------------------------------------------------------------------}
Function getString(var name :string) : char;
var
  rtc: char;
  x, y :byte;   {initial x,y position}
  wp : integer; {write pointer}
  mode :byte;  {0 = insert , 1 = overwrite }
  istr :string;
begin
    mode := 0; { insert }
    CursorOn;  { small cursor }
    x := wherex;
    y := wherey;
    wp := 0;
    name := '';
    repeat
      rtc := readkey;
      if (rtc = #0) then
      begin
        rtc := readkey;  { ignore }
	case rtc of
	#71: { home }
	begin
	  gotoxy(x, y);
          wp := 0;
	end;
	#75: { left key }
	begin
	  if (wp > 0) then
	  begin
            gotoxy(x + wp-1, y);
            wp := wp - 1;
	  end;
	end;
	#77: { right key }
	begin
	  if (wp < length(name)) then
	  begin
            wp := wp + 1;
            gotoxy(x+wp, y);
	  end;
	end;
	#79: { end }
	begin
          wp := length(name);
	  gotoxy(x+wp, y);
	end;
	#82: { insert }
	  if (mode=0) then
	  begin
	    mode := 1;
	    CursorBig;
	  end
	  else
	  begin
	    mode := 0;
	    CursorOn;
	  end;
	#83: { delete }
	begin
	  if (wp < length(name)) then
	  begin
	    delete(name, wp+1, 1);
	    gotoxy(x, y);
	    write(name, ' ');
	    gotoxy(x+wp, y);
	  end;
	end;
	end;
      end
      else
      begin
        if (rtc = #8) then   	{ bksp }
	begin
	  if (wp > 0) then
	  begin
	    delete(name, wp, 1);
	    gotoxy(x, y);
	    write(name, ' ');
            wp := wp - 1;
	    gotoxy(x+wp, y);
	  end;
	end;
        if (rtc >= ' ') and (rtc <= 'z') then
	begin
          istr := rtc;
	  if (mode = 1) then
	    delete(name, wp+1, 1);
          wp := wp + 1;
          insert(istr, name, wp);
          gotoxy(x, y);
          write(name);
          gotoxy(x+wp, y);
	end;
      end;
    until (rtc = #27) or (rtc = #9) or (rtc = #13); {esc, tab, cr}
    getString := rtc;
end;

{*****************************************************************************}
procedure loadata;
var
  eN,eK,eP,eCa,eMg:string[4];
  pltnme:string[25];
  f,h:text;
  snme,strg:string;
  i:integer;

begin
  { read in recipes }
  assign (f,'ppm.txt');
  i:=0;
  reset(f);
  while not eof(f) do
  begin
    readln(f,pltnme,eN,eP,eK,eCa,eMg);
    inc(i);
    nmdta[i]:=pltnme;
    str(i,ppmdta[i,1]);
    ppmdta[i,2]:=eN;
    ppmdta[i,3]:=eP;
    ppmdta[i,4]:=eK;
    ppmdta[i,5]:=eCa;
    ppmdta[i,6]:=eMg;
  end;
  close(f);
  if i>17 then i := 17;
  i := i + 1;
  nmdta[i] := 'User Defined             ';
  ppmdta[i,1] := '18';
  ppmdta[i,2]:='    ';
  ppmdta[i,3]:='    ';
  ppmdta[i,4]:='    ';
  ppmdta[i,5]:='    ';
  ppmdta[i,6]:='    ';
  docTotalRecipes := i;


  { read in salts }
  assign(h,'salts.txt');
  reset(h);
  docTotalSalts := 0;
  while not eof(h) do
  begin
    readln(h,snme);
    readln(h,strg);
    inc(docTotalSalts);
    SaltData[docTotalSalts, 1] := snme;
    SaltData[docTotalSalts, 2] := strg;
  end;
  close(h);
end;

{*****************************************************************************}
procedure DrawBorder;
const
  tline ='+------------------------------------------------------------------------------+';
  mline ='|                                                                              |';
  bline ='+------------------------------------------------------------------------------+';
  tiline ='                                                                               ';
var
  i:integer;
begin
//  DoneVideo;
  //GetVideoMode(M);
  //TextOut(1,1,'clearing screen');
  ClearTheScreen;
{*  gotoxy(1, 1);
  for (x:=1 to vidmode.Col do
  begin
    for (y:=1 to vidmode.Row do
    begin
    end;
  end;
  writeln(tline);
  for i := 1 to 7 do
    writeln(mline,mline,mline);
  writeln (mline,bline,tiline);*}
end;

{-----------------------------------------------------------------------------}
Function DisplayAboutScreen :char;
const
  t :integer = 4;
var
  ch :char;
  y :integer;
begin

  ForegroundColor(DarkGray);
  BackgroundColor(Black);
  DrawBorder;
  ForegroundColor(White);
  TextOut(36, t, 'PlantFood');
  ForegroundColor(LightGray);
  TextOut(34, t+2, 'Version 1.14');
  TextOut(25, t+4, 'Copyright (C) 2004 William Bell');
  TextOut(29, t+7, 'Coded by: William Bell');
  TextOut(26, t+8, 'email: William.Bell@frog.za.net');
  TextOut(35, t+10, 'For my Dad');
  ForegroundColor(DarkGray);
  y := t+12;
  TextOut(6, y+1, 'This program is free software; you can redistribute it and/or modify');
  TextOut(6, y+2, 'it under the terms of the GNU General Public License as published by');
  TextOut(6, y+3, 'the Free Software Foundation; either version 2 of the License, or');
  TextOut(6, y+4, '(at your option) any later version.');
  TextOut(6, y+5, 'A copy of this license can be found in the file GNU.txt included with');
  TextOut(6, y+6, 'this program.');
  ForegroundColor(LightGray);

  TextOut((M.Col div 2) - 12, M.Row, 'Press Any Key to continue');
  UpdateScreen(True);
  DisplayAboutScreen := cRecipeSelection;
  ch := readkey;
  if (ch = #0) then ch := readkey;
end;

{-----------------------------------------------------------------------------}
Procedure DisplayMainScreen;
var
  i,j :integer;
  tempstring :string;
begin
  BackgroundColor(LightGray);
  ForegroundColor(Black);
  DrawBorder;
  //ForegroundColor(Black);
  TextOut(1, M.Row, '   Use cursor keys    1-About    2-Custom Values    3-Add Salt    Esc-Quit');
  TextOut(8, 2, 'PlantFood calculates the masses of various salts needed to');
  TextOut(8, 3, 'supply a plants specific nutrient needs');
  //ForegroundColor(Black);
  TextOut(9, 5, 'NAME                          N     P     K    Ca     Mg');
  //ForegroundColor(Black);
  for i:= 1 to docTotalRecipes do
  begin
    str(i, tempstring);
    TextOut(5, 5+i, tempstring);
    TextOut(9, 5+i, nmdta[i]);
    for j:= 2 to 6 do
      TextOut(25+j*6, 5+i, ppmdta[i,j]);
  end;
  UpdateScreen(True);
end;

{-----------------------------------------------------------------------------}
Function MakeCustomRecipe :char;
var
  mlw  : integer;
  i : integer;
  rtc :char;
Begin
  mlw:=38;
  gotoxy(5, docTotalRecipes+5);
  write(docTotalRecipes , '                                                           ');
  gotoxy(9, docTotalRecipes+5);
  rtc := getString(nmdta[0]);
  if (rtc <> cExitProgram) then
  begin
    for i:=1 to 5 do
    begin
      gotoxy(mlw,docTotalRecipes+5);
      getString(ppmdta[0,i+1]);
      mlw:=mlw+6;
    end;
    rtc := cSelectionForN;
  end;
  if (rtc = cExitProgram) then
    rtc := cRecipeSelection;
  MakeCustomRecipe := rtc;
end;

{*****************************************************************************}
Function SelectRecipe :char;
var
  t, pt, i, j :integer;
  chd :char;
  code : word;
begin
  DisplayMainScreen;
  t:=1;
  pt := t;
  repeat
    { Remove previous highlight }
    ForegroundColor(Black); BackgroundColor(White);
    TextOut(4,pt+5, '                                                              ');
    TextOut(5,pt+5, itoa(pt));
    TextOut(9,pt+5, nmdta[pt]);
    for j:= 2 to 6 do
      TextOut(25+j*6, 5+pt, ppmdta[pt,j]);
    { Highlight }
    ForegroundColor(White); BackgroundColor(Black);
    TextOut(4,t+5, '                                                              ');
    TextOut(5,t+5, itoa(t));
    TextOut(9,t+5, nmdta[t]);
    for j:= 2 to 6 do
      TextOut(25+j*6, 5+t, ppmdta[t,j]);
    UpdateScreen(True);
    chd:=readkey;
    if chd=#0 then
    begin
      chd:=readkey;
      if (chd='P') or (chd='H') then
      begin
        pt := t;
        if (t=docTotalRecipes) and (chd=#80)  then t:=0;
        if (t=1) and (chd=#72) and (wherey=6) then t:=docTotalRecipes+1;
        if (chd=#72) and (t>1) then dec(t) else inc(t);
      end;
    end;
  until (chd=#13) or (chd=cExitProgram) or
        (chd=cAddNewSalt) or (chd = cCustomRecipe) or (chd=cDisplayAbout);
  ans:=t;
  if (chd = cDisplayAbout) then
  begin
    SelectRecipe := chd;
    exit;
  end;
  if (chd=cCustomRecipe) or (ans=18) then
  begin
    ans := 0;
    chd := MakeCustomRecipe;
    if (chd = cExitProgram) then
    begin
      SelectRecipe := cRecipeSelection;
      exit;
    end;
  end;
  begin
    RecipeName := nmdta[ans];
    for i:= 1 to 5 do
    begin
      val(ppmdta[ans,i+1],ppmelem[i],code);
    end;
    if (chd = #13) then
       chd := cSelectionForN;
  end;
  SelectRecipe := chd;
end;

{*****************************************************************************}
procedure SearchElement(var chemName,find:string;var num:integer);
var p1,p2,y,K,nu,nu1,i:integer;
    cm:string;
begin
  num:=0;nu:=0;p1:=0;p2:=0;nu1:=0;
  y:=pos(find, chemName);
  K:=length(find);
  while y > 0 do
  begin
    inc(num);
{   if (num>1) and (pos('(', chemName)>0) and (y>pos('(',chemName)) then dec(num); }
    cm:=copy(chemName, y+K,1);
    if (cm>#47) and (cm<#58) then
    begin
      nu:=ord(cm[1])-48;
      nu1:=nu;
      num:=num+nu-1;
      delete(chemName, y+K,1);
    end
    else nu1:=1;
    p1:=pos('(',chemName);
    p2:=pos(')',chemName);
    if (y>p1) and (y<p2) then
    begin
      cm:=copy(chemName, p2+1,1);
      nu:=ord(cm[1])-48;
      num:=num*nu
    end;
    i:=pos('.', chemName);
    if y>i then
    begin
      cm:=copy(chemName, i+1, 1);
      if (cm>#47) and (cm<#58) then
      begin
        nu:=ord(cm[1])-48;
        num:=num+nu1*nu-nu1;
      end;
    end;
    delete(chemName, y, K);
    if p1+1=p2 then delete(chemName, p1, 3);
    y:=pos(find, chemName);
  end;
end;

{*****************************************************************************}
procedure el_st_rto(chemName:string);
const
  elements:array[1..11] of string = ('Mg','Na','Cl','Ca','H','N','O','P','S','K','C');
  atomw:array[1..11] of real = (24.305,22.98977,35.453,40.08,1.0079,14.0067,15.9994,30.97376,32.06,39.0983,12.011);
var
  dta : array[1..11] of real;
  nu, cit : integer;
  find : string;
  mol : real;
begin
  mol:=0;
  for cit:= 1 to 11 do
  begin
    find:=elements[cit];
    SearchElement(chemName, find, nu);
    dta[cit]:=atomw[cit]*nu;
    mol:=mol+dta[cit];
  { if (nu>0) and (st) then writeln('|       Number of ',elements[cit],' molecules  : ',nu);}
  end;
{ if st then writeln('|       Atomic weight of salt is : ',mol:10:5);}
  for cit:= 1 to 11 do
    rto[cit]:=dta[cit]/mol;
 {if (chemName <> '') and (st) then
  begin
    gotoxy(5,20);
    writeln('I am unable to identify "',chemName, '"');
    delay(2000);
    gotoxy(5,20); write('                                              ');
  end;}
  rto[5]:=rto[1];
  rto[1]:=rto[6];
  rto[2]:=rto[8];
  rto[3]:=rto[10];
  rto[6]:=rto[9];
end;

{*****************************************************************************}
procedure calculate(st:boolean;var a:boolean);
var
  num:real;
  begin
    a:=true;
    el_st_rto(saltnme[cnt]);
    num:=0;
    for e:=1 to 5 do  { get the highest ratio }
          if (rto[e]>num) and (ppmelem[e]>0) then  bg:=e;
    for e:=1 to 5 do  { calculate the total mass so far }
      begin
      if rto[e]>0 then
         begin
         massalt[e]:=ppmelem[e]/rto[e];
         end
       else massalt[e]:=0;
      end;
    for e:=1 to 5 do { check that bg in the biggest }
      begin
      if massalt[e]>0 then
        begin
        if (massalt[bg]>massalt[e])  then
          begin
          bg:=e;
          end;
        end;
     end;
{     for e:=1 to 5 do
         write('  ',massalt[e]:3:3);writeln(' BG',bg);delay(5000);}
     if (cnt<>bg) and (not(st)) then
      begin
      a:=false;
      exit;
      end;
     if not(st) then
        begin
        a:=true;
        exit;
        end;
   finalmass[cnt]:=massalt[bg];
   for e:=1 to 5 do
     begin
{     writeln('ppm',ppmelem[e]:3:2,'mass',massalt[bg]:4:2,' rto',rto[e]:1:3);
     repeat until keypressed;}
     ppmelem[e]:=ppmelem[e]-massalt[bg]*rto[e];
     s:=s+massalt[bg]*rto[6];
     if round(ppmelem[e]*10000)=0 then ppmelem[e]:=0;
     end;
end;

{*****************************************************************************}
Function AddNewSalt :char;
const
  y :integer = 16;
var
  snme :string;
  str :string;
  ch:char;
  i,ds:string;
  bl:integer;
  h :text;
begin
  ForegroundColor(Black); BackgroundColor(LightGray);
  DrawBorder;
  TextOut(34, 2,'Add New Salt');
  TextOut(7, 4,'Remember you can always manually edit the ppm.txt file to do this!');
  TextOut(19, 8,'Type in the salt name');
  UpdateScreen(True);
  gotoxy(19, 10);
  snme:='';
  getString(snme); { read salt name }
  TextOut(19, 13,'Type in the chemical formula');
  TextOut(19, 14,'IMPORTANT: Make sure the case is correct. (Na not NA or na)');

  gotoxy(19, y);
  str:='';
  ds:='';
  repeat
    ch:=readkey;
    bl:=length(ds);
    case ch of
      #0:  { Ignore extended key pressed }
        ch:=readkey;
      #8:
        begin { Backspace }
          if length(str) > 0 then
          begin
            gotoxy(wherex-1, y);
            if copy(ds,bl,1)=' ' then gotoxy(wherex, y+1);
            write(' ');
            if copy(ds,bl,1)=' ' then gotoxy(wherex, y-1);
            delete(ds,bl,1);
            delete(str,bl,1);
          end;
        end;
      #48..#57:
        begin  { 0 - 9 }
          str:=concat(str,ch);
          i:=copy(ds,bl,1);
          if (i=#46) or (i > #47) and (i < #57) then
          begin
            ds:=concat(ds,ch);
          end
          else
          begin
            ds:=concat(ds,' ');
            gotoxy(wherex, y+1);
            write(ch);
            gotoxy(wherex, y-1);
          end;
        end;
      #40,#41,#46:
      begin   {( ) .}
          str:=concat(str,ch);
          ds:=concat(ds,ch);
        end;
      #97..#122:
        begin  { a-z }
          str:=concat(str,ch);
          ds:=concat(ds,ch);
        end;
      #65..#90:
         begin { A-Z }
           str:=concat(str,ch);
           ds:=concat(ds,ch);
         end;
    end;
    gotoxy(19, y);
    write(ds);
  until (length(str)=20) or (ch=#13) or (ch=cExitProgram);

  saltnme[cnt] := str;
  gotoxy(2,24); write('Esc-Cancel  S-Save');
  ch:=readkey;
  if (ch='s') or (ch='S') then
  begin
    assign(h,'salts.txt');
    append(h);
    writeln(h,snme);
    writeln(h,str);
    close(h);
    inc(docTotalSalts);
    SaltData[docTotalSalts, 1] := snme;
    SaltData[docTotalSalts, 2] := str;
  end;
  AddNewSalt := cRecipeSelection;
end;

{-----------------------------------------------------------------------------}
Procedure WriteSalt(var x,y :integer; var saltname : string);
var
	i : integer;
	pc,c :char;
begin
	c := saltname[1]; pc := c;
	for i:= 1 to length(saltname) do { output chemical name }
	begin
		c := saltname[i];
		if (c > '0') and (c < ':') and (pc <> '.') then
		begin
			gotoxy(x,y+1); write(c);
		end
		else
		begin
			gotoxy(x,y); write(c);
		end;
		x := x + 1;
		pc := c;
	end;
end;

{-----------------------------------------------------------------------------}
function chooseSalt(ln:integer) :integer;
var
	x, y, c, pc :integer;
	chd, ch :char;
begin
	c := 1; pc := c;
	repeat
		{ remove previous highlight }
		textcolor(Black); textbackground(LightGray);
		y := pc*3;
		gotoxy(17, y); write(pc);
		gotoxy(20, y); write(sltdta[pc,1]);
		x := 52;
		WriteSalt(x,y,sltdta[pc,2]);
		{ Highlight }
		textcolor(LightGray); textbackground(Black);
		y := c*3;
		gotoxy(17, y); write(c);
		gotoxy(20, y); write(sltdta[c,1]);
		x := 52;
		WriteSalt(x,y,sltdta[c,2]);
		pc := c;
		chd:=readkey;
		if chd=#0 then
		begin
			ch:=readkey;
			if (ch=#80) then   { down, go to first entry }
			begin
				if (c=ln) then
				begin
					c := 1;
				end
				else
				begin
					c := c + 1;
				end;
			end;
			if (ch=#72) then    { up, go to last entry }
			begin
				if (c=1) then
				begin
					c := ln;
				end
				else
				begin
					c := c -1;
				end;
			end;
		end;
	until (chd=#13) or (chd=#27) or (ch=#8); {BkSp}
	if (chd=#27) or (ch=#8) then c:=-1;
	chooseSalt := c;
end;

{-----------------------------------------------------------------------------}
Procedure PriorityCalculation;
var
	vi : integer;
	count : integer;
	d : integer;
	a : string;
	kk : integer;
	st : boolean;
	ab : boolean;
	numoccur:array[1..5] of integer;
begin
  {  Priority calculation   }
  if ckl>-1 then
  begin
    for vi:=1 to 5 do
      numoccur[vi]:=0;
    for vi:= 1 to 5 do
    begin
      for count:=1 to 5 do
        if pos(maj_ele[count], saltnme[vi]) > 0 then
          inc(numoccur[count]);
    end;
    for count:=5 downto 1 do
    begin
      for vi:=1 to 4 do
      begin
        if numoccur[vi]>numoccur[vi+1] then
        begin
          d:=numoccur[vi];
          numoccur[vi]:=numoccur[vi+1];
          numoccur[vi+1]:=d;
          a:=saltnme[vi];
          saltnme[vi]:=saltnme[vi+1];
          saltnme[vi+1]:=a;
          a := finalsalt[vi];
          finalsalt[vi]:=finalsalt[vi+1];
          finalsalt[vi+1]:=a;
        end;
      end;
    end;
    kk:=0;
    repeat
      inc(kk);
    until numoccur[kk]>1;
    for vi:=1 to 5 do
      numoccur[vi]:=0;
    for vi:= kk to 5 do
    begin
      for count:=1 to 5 do
        if pos(maj_ele[count],saltnme[vi])>0 then  inc(numoccur[count]);
    end;
    for vi:=1 to 5 do
    begin
      if numoccur[vi]=1 then
      begin
        for count:=kk+1 to 5  do
        begin
          if pos(maj_ele[vi],saltnme[count])>0 then
          begin
            a:=saltnme[count];
            saltnme[count]:=saltnme[count-1];
            saltnme[count-1]:=a;
            a:= finalsalt[count];
            finalsalt[count]:=finalsalt[count-1];
            finalsalt[count-1]:=a;
          end;
        end;
      end;
    end;
    for count:=1 to 5 do
    begin
      cnt:=count;
      st:=true;
      calculate(st,ab);
    end;
  end;
end;

{-----------------------------------------------------------------------------}
Function DisplaySalts(var majorType : char) :char;
var
  stnme :string;
  lng,ln,i,vi, n,count,x,y:integer;
  aa,st,ab:boolean;
begin
  lng:=docTotalSalts;
  i := ord(majorType) - ord(cSelectionForN) + 1;
  {for i:=1 to 5 do}
  BackgroundColor(White);
  ForegroundColor(Black);
  DrawBorder;
  begin
    n:=0;
    for vi:=1 to lng do
    begin
      if (pos(maj_ele[i], SaltData[vi,2])>0) then
      begin
        st:=false;
        cnt:=i;
        saltnme[i] := SaltData[vi,2];
        calculate(st,ab);
        if ab  then
        begin
          aa:=true;
          for count:= 1 to i-1 do
            if saltnme[count] = SaltData[vi,2] then aa:=false;
              if aa then
              begin
                inc(n);
                saltnme[i] := SaltData[vi,2];
                sltdta[n,1] := SaltData[vi,1];
                sltdta[n,2] := SaltData[vi,2];
                sltdta[n+1,1]:='';
                sltdta[n+1,2]:='';
              end;
        end;
      end;
    end;
    ln:=n;

    if ln>7 then ln:=7; { max of 7 salts listed }
    for vi:=1 to ln do
    begin
      TextOut(17, vi*3, itoa(vi));
      TextOut(20, vi*3, sltdta[vi,1]);
      stnme:=sltdta[vi,2];
      x := 52;
      y := vi*3;
      WriteSalt(x,y,stnme);
    end;
    TextOut(15, 1, 'Select');
    TextOut(22, 1, nme[i]);
    TextOut(35, 1, 'source, Esc-Go Back');
    UpdateScreen(True);
    ckl := chooseSalt(ln);

    if ckl<>-1 then  { accept data }
    begin
      finalsalt[i]:=sltdta[ckl,1];
      saltnme[i]:=sltdta[ckl,2];
      if (cSelectionForMg <> majorType) then
      begin
        DisplaySalts := succ(majorType);
        exit;
      end;
    end;
  end; {for i }

  if (ckl = -1) then { go to previous screen }
  begin
    DisplaySalts := pred(majorType);
    exit;
  end;
  PriorityCalculation;
  DisplaySalts := cDisplayResults;
end;

{-----------------------------------------------------------------------------}
Function DisplayResults : char;
var
  i : integer;
begin
  DrawBorder;
  TextOut(9,3,'Nutrient needs of');
  TextOut(27,3, RecipeName);
  TextOut(9,5,'N          P          K          Ca         Mg         S');
  for i:=1 to 5 do
  begin
    TextOut(7+(i-1)*11,6,ppmdta[ans, i+1]);
  end;
  TextOut(7+55,6, ftoa(s));
  TextOut(9,8,'Salts to be mixed with 200 liters water');
  for i:= 1 to 5 do
  begin
    TextOut(9,9+i,finalsalt[i]);
    TextOut(45,9+i, ftoa(finalmass[i]/5));
  end;
  TextOut(9,16,'PPM still lacking.');
  TextOut(9,18,'N          P          K          Ca         Mg');
  s:=0;
  for i:=1 to 5 do
  begin
    TextOut(i*11-2, 19,ftoa(ppmelem[i]));
    s:=s+ppmelem[i];
  end;
  if s<>0 then
  begin
    ForegroundColor(Yellow);
    TextOut(22, 22, 'IMPOSSIBLE - try another combination');
    ForegroundColor(Black);
  end;
  TextOut(19,M.Row,'Esc - Quit       Any other key - Go again.');
  UpdateScreen(True);
  DisplayResults := readkey;
  if (DisplayResults <> cExitProgram) then
  begin
    DisplayResults := cRecipeSelection;
  end;
end;

{-----------------------------------------------------------------------------}
Procedure Initialize;
begin
  InitVideo;
  InitKeyboard;
  ForegroundColor(LightGray); BackgroundColor(Black);
  GetVideoMode(M);
  ClearTheScreen;
  RecipeName := '';
  for j:=1 to 8 do
    saltnme[j] := '';
end;

{*****************************************************************************}
var
  rtc  : char;
begin                 {  MAIN  }
  loadata;
  rtc := cRecipeSelection;
  repeat
    GetVideoMode(vidmode);
    if (rtc = cRecipeSelection) then
    begin
      Initialize;
      rtc := SelectRecipe;
    end;
    if (rtc = cAddNewSalt) then
    begin
      rtc := AddNewSalt;
    end;
    if (rtc = cDisplayAbout) then
    begin
      rtc := DisplayAboutScreen;
    end;
    while (rtc >= cSelectionForN) and (rtc <= cSelectionForMg) do
    begin
      rtc := DisplaySalts(rtc);
    end;
    if (rtc = cDisplayResults) then
    begin
      rtc := DisplayResults;
    end;
    if (rtc = cExitProgram) then
    begin
      break;
    end;
  until (rtc = 'Q') or (rtc = 'q') or (rtc = cExitProgram);
	ClearScreen;
	DoneVideo;
end.

