function k = menu35(s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s16,s17,s18)
%MENU35  Generate a command window menu of choices for user input.
%
%   K = MENU35('Choose a color','Red','Blue','Green') displays on
%   the screen:
%
%   ----- Choose a color -----
%
%         1) Red
%         2) Blue
%         3) Green
%
%
%   Select a menu number: 
%
%   The number entered by the user in response to the prompt is
%   returned. 
%   
%   The largest menu that can be created can have 18 choices.

% J.N. Little 4-21-87
% Copyright (c) 1987 by the MathWorks, Inc.
%
% This is the menu function that came with matlab ver. 3.5.
% It isn't graphical, like the menu function that comes with
% ver 4.x, but I think it is much more useful in some circumstances.
%
% Mike Cook - NPS Oceanography Dept.      
% Ver. 1.0 - Increased max. menu size to 18, added some error checking. 

if nargin > 19
   error('Menu is too big, 18 items or less please!')
end

disp(' ')
disp(['----- ',s0,' -----'])
disp(' ')
for i=1:(nargin-1)
	disp(['      ',int2str(i),') ',eval(['s',int2str(i)])])
end
disp(' ')
k = input('Select a menu number: ');
while k < 1 | k > (nargin-1)
   disp([num2str(k),' out of range, try again '])
   k = input('Select a menu number: ');
end

