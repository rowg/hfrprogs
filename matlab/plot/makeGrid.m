function [Xin,Yin] = makeGrid(functName)
%MAKEGRID  interactively create a grid of points.
%
% makeGrid will allow the user to create a rectangular grid within an
% interactively created polygon on the current figure.  The figure could 
% have been created using one of matlab's standard plot commands, or one 
% of the m_map plot commands.
%
% Usage:
%        [X,Y] = makeGrid(functName)
%
% Inputs:
%       functName - either 'm_ginput' if current figure was created with an
%       m_map function, or 'ginput' if current figure was created with a
%       standard matlab plotting function.  DEFAULTS to m_ginput.
%
% Outputs:
%       X - the x coordinates of the grid points.
%       Y - the y coordinates of the grid points.
%
% makeGrid calls makePoly and LonLat_grid
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: makeGrid.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'functName', 'var' )
  functName = 'm_ginput';
end

switch functName
  case 'm_ginput'
      lineFunct = 'm_line';
  case 'ginput'
      lineFunct = 'line';
  otherwise
      error( 'Only valid inputs are ''m_ginput'' or ''ginput''' );
end

[X,Y] = makePoly(functName); 

% Find the 4 corners of the smallest square that will totally enclose
% the user created polygon.
maxX = max(X);
minX = min(X);
maxY = max(Y);
minY = min(Y);

% Create the grid within the polygon created by makePoly.
TryAgain = 1;
while TryAgain

   choice = menu35('Choose One of the Following Units for Grid Spacings (delta)', ...
                   'Current plot units (presumably geographic / Lon,Lat)', ...
                   'Kilometers (assumes plot is in Lon,Lat coordinates)');
   switch choice
     case 1
       disp( 'You have chosen to use plot units for grid delta''s.');
       disp( '----------------------------------------');
       dx = input('Enter the delta X for the grid --> ');
       dy = input('Enter the delta Y for the grid --> ');
       du = 'LonLat';

     case 2
       disp( 'You have chosen to use kilometer units for grid delta''s.');
       disp( ['KM delta''s will be converted to lon,lat delta''s at center ' ...
              'of polygon.']);
       disp( '----------------------------------------');
       dx = input('Enter the delta X for the grid --> ');
       dy = input('Enter the delta Y for the grid --> ');
       du = 'km';
   end
   
   [Xgrid,Ygrid] = LonLat_grid([minX,minY],[maxX,maxY],[dx,dy],du );

   status = inpolygon(Xgrid(:),Ygrid(:),X,Y);
   index = find(status == 1);
   Xin = Xgrid(index);
   Yin = Ygrid(index);
   Xin = Xin(:);
   Yin = Yin(:);
   fprintf('Here''s the grid that will be saved (black o''s)\n');
   inPts = feval(lineFunct,Xin,Yin,'linestyle','o','color','k');

   choice = menu35('Choose One of the Following Options', ...
                   'Clear grid and try again', ...
                   'I''m happy');
   TryAgain = 0;
   if choice == 1
      fprintf('Give it another try\n');
      set(inPts,'Xdata',[],'Ydata',[]);
      TryAgain = 1;
   end
end
