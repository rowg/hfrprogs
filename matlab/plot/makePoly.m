function [X,Y,ptHand,lineHand] = makePoly(functName)
%MAKEPOLY  interactively create a polygon of arbitrary shape.
%
% makePoly will allow the user to interactively create a polygon of 
% arbitrary shape on the current figure.  The figure could have been 
% created using one of matlab's standard plot commands, or one of the 
% m_map plot commands.
%
% Usage:
%        [X,Y,ptH,lineH] = makePoly(functName)
%
% Input:
%       functName - either 'm_ginput' if current figure was created with an
%       m_map function, or 'ginput' if current figure was created with a
%       standard matlab plotting function.  DEFAULTS to m_ginput.
%
% Outputs:
%       X - the x coordinates of the polygon vertices.
%       Y - the y coordinates of the polygon vertices.
%       ptHand - the handle to the plotted polygon vertices.
%       lineHand - the handle to the plotted polygon edges.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: makePoly.m 396 2007-04-02 16:56:29Z mcook $	
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

TryAgain = 1;
while TryAgain
   X =[];
   Y =[];

   fprintf('\nYou will be allowed to create a polygon of any shape.\n')
   fprintf('Use the mouse to position the cross hair and press the LEFT\n')
   fprintf('mouse button to include the point in the perimeter of the polygon.\n')
   fprintf('Use the RIGHT mouse button to select the last point.  The last\n')
   fprintf('point will automatically be connected to the first point to close\n')
   fprintf('the polygon.  Position cross hair and begin selecting points.\n')

   % First point
   [x,y,Bval] = feval(functName,1);
   X = [X; x;];
   Y = [Y; y;];
   
   ptHand = feval(lineFunct,X,Y,'color','r','marker','o', ...
                              'linestyle','none','clipping','off');
   lineHand = feval(lineFunct,X,Y,'color','r', ...
                              'linestyle','-','clipping','off');

   % Middle points
   while Bval < 2
      fprintf('Left mouse button for a point, right button for last point\n');
      [x,y,Bval]=feval(functName,1);
      X = [X; x;];
      Y = [Y; y;];
      delete(ptHand);
      delete(lineHand);
      ptHand = feval(lineFunct,X,Y,'color','r','marker','o', ...
                        'linestyle','none','clipping','off');
      lineHand = feval(lineFunct,X,Y,'color','r', ...
                        'linestyle','-','clipping','off');
      drawnow
   end

   % Connect it back to the first point
   X = [X; X(1);];
   Y = [Y; Y(1);];
   delete(ptHand);
   delete(lineHand);
   ptHand = feval(lineFunct,X,Y,'color','r','marker','o', ...
                   'linestyle','none','clipping','off');
   lineHand = feval(lineFunct,X,Y,'color','r', ...
                   'linestyle','-','clipping','off');
               
   choice = menu35('Choose one of the following', ...
                   'Clear polygon and try again', ...
                   'I''m happy with the polygon');
   TryAgain = 0;
   if choice == 1
      fprintf('Give it another try\n');
      set(ptHand,'Xdata',[],'Ydata',[]);
      set(lineHand, 'Xdata',[],'Ydata',[]);
      TryAgain = 1;
   end
end  
