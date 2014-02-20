function [X,bI,ptHand,lineHand] = makeDomainBoundary( coastfn, functName )
% MAKEDOMAINBOUNDARY Facilitates creating a domain boundary for OMA or masks
%
% makeDomainBoundary is an interactive function that allows one to create
% a domain boundary that contains a mix of open boundaries (i.e. parts of
% the boundary that are over water) and closed boundaries (i.e. parts of
% the boundary that are along the land-ocean interface).  This type of
% boundary is useful for doing open-boundary modal analysis (OMA) or for
% masking radial or total currents.
%
% Use the makePoly function if you want to create an arbitrary polygon.
%
% The appropriate basemap should already be plotted in the currently
% active figure window before calling this function.
%
% NOTE: You may need to smooth or evenly space out boundary points to use
% the final boundary for OMA calculations.  This must be done after running
% this function using the smoothDomainBoundary function.  
%
% NOTE: The returned domain boundary has the last vertex point equal to the
% first (i.e. it is truly closed).  This last vertex MUST be removed before
% using it to generate OMA modes (it is useful to return it with this
% repeated vertex for the smoothDomainBoundary function).
%
% NOTE: As the coastline may contain multiple patches (islands, regions,
% etc.), it is somewhat complicated to decide which part of a closed
% boundary is actually desired.  This function will always choose the
% shortest piece of coastline that connects a pair of boundary points that
% delineate the edges of a closed piece of boundary.  This may not always
% be the desired result, but there is no way to uniquely determine which
% piece of coastline to use.  Also, this function checks to make sure
% that ends of closed sections of the boundary lie on the same landmass.
% If not, you will be forced to restart the current section of the open
% boundary and a warning will be generated.
%
% Usage:
%        [X,bI,ptH,lineH] = makeDomainBoundary(usercoast_filename,functName)
%
% Input:
%       usercoast_filename - the string name of a .mat file containing
%       the coast information.  This .mat file should be generated with
%       makeCoast (in this toolbox) or m_gshhs (in the m_map toolbox).
%       Alternatively, this can be a two column vector of coordinates of
%       the same form as ncst in usercoast .mat files.
%
%       functName - either 'm_ginput' if current figure was created with an
%       m_map function, or 'ginput' if current figure was created with a
%       standard matlab plotting function.  DEFAULTS to m_ginput.
%
% Outputs:
%       X - 2 column matrix of coordinates of the boundary
%
%       bI - vector of indices indicating the boundaries between open and
%       closed boundary sections.
%
%       ptHand - the handle to the plotted boundary vertices.
%
%       lineHand - the handle to the plotted boundary edges.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: makeDomainBoundary.m 428 2007-05-22 17:39:03Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan, Mike Cook
% License: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'functName', 'var' )
  functName = 'm_ginput';
end

% Decide on plot function to use.
switch functName
  case 'm_ginput'
      lineFunct = 'm_line';
      distFunct = 'm_idist';
      zoomFunct = 'm_zoom'; % Not a real function name.
  case 'ginput'
      lineFunct = 'line';
      distFunct = 'dist';
      zoomFunct = 'zoom'; % Not a real function name.
  otherwise
      error( 'Only valid functName inputs are ''m_ginput'' or ''ginput''' );
end
aa = axis;

% Load in coast info.
if ischar(coastfn)
  try
    load(coastfn,'ncst')
  catch
    error( 'The coast filename ''%s'' does not appear to be valid', coastfn );
  end
else
  ncst = coastfn;
end

% Coast is complicated - need perimiter lengths to decide how to go
% around each closed polygon
[ncst,K,pl,tpl] = my_process_ncst( ncst, distFunct );

% Display basic instructions
disp( 'NOTE: Instructions on what to do will appear in the command window' );
disp( 'and on the title bar of the figure window' );
disp( ' ' );

% Get first point of first open boundary
disp( 'GENERAL INSTRUCTIONS:' );
disp( 'You will first be asked to select the corners of an area of the' );
disp( 'plot to zoom in on.  This is useful to make small open boundary' );
disp( 'sections that might be difficult to see looking at the entire' );
disp( 'domain area.' );
disp( ' ' );
disp( 'You will then be asked to select with the mouse the points along an' );
disp( 'open section of the domain edge.  To end a section, hit enter.' );
disp( 'The entire boundary must be entered in an oriented (CW/CCW) sense.' );
disp( ' ' );
disp( 'The first and last points of the open boundary' );
disp( 'section will be converted to the closest coastline points and the' );
disp( 'closed boundary section between open boundaries will be filled in.' );
disp( ' ' );
disp( 'To finish, generate an empty open boundary section by hitting' );
disp( 'enter at the beginning of the section' );
disp( ' ' );

[X,bI,ptHand,lineHand,II] = deal([]);
lastPossible = false;
while 1
  % Unzoom - do it now just in case it wasn't done
  axis( aa );
  switch zoomFunct
    case 'zoom'
    case 'm_zoom'
      m_grid;
  end
  
  % Zoom
  title( { 'Select two corners of zoom area', ...
           'Just hit enter to finish domain boundary' }, ...
         'fontsize', 18 );
  xxx = 1;
  while mod(size(xxx,1),2) ~= 0
    xxx = ginput( 2 );
    if mod(size(xxx,1),2) ~= 0
      warning( 'You must select two corners for zoom.' );
      title( { 'Only one point selected', ...
               'PLEASE reselect two corners of zoom area' }, ...
             'fontsize', 16 );
    end
  end

  % If empty leave loop
  if isempty(xxx)
    if lastPossible, break; 
    else
      [X,bI,ptHand,lineHand] = removelast(X,bI,ptHand,lineHand,xx,yy);
      [II,LL,d] = getnearest( distFunct, X(end,:), ncst, K );
      continue;
    end
  end
  
  xxx = sort(xxx);
  
  switch zoomFunct
    case 'zoom'
    case 'm_zoom'
      m_ungrid;
  end
  axis( xxx(:)' );
  
  % Display useful title
  title( { 'Select points of open boundary', ...
           'Hit enter after last point - empty section finishes' }, ...
         'fontsize', 16 );
  
  % Select first open boundary point
  [x,y] = feval(functName,1);

  % If empty, leave loop
  if isempty(x)
    if lastPossible, break; 
    else
      [X,bI,ptHand,lineHand] = removelast(X,bI,ptHand,lineHand,xx,yy);
      [II,LL,d] = getnearest( distFunct, X(end,:), ncst, K );
      continue;
    end
  end
  
  % Replace first point with coastline point
  [I,L,d] = getnearest( distFunct, [x, y], ncst, K );

  % Get closed boundary piece
  if isempty(II)
    II = I;
    LL = L;
    I0 = I;
    L0 = L;
    yy = [];
  else
    % Restart open boundary if it can't be closed
    if L ~= LL
      warning( 'Closed boundary spans multiple land masses.  Restarting!' );
      continue
    end
    
    yy = getshortest( ncst, K, pl, tpl, II, I, L );
    
    % Plot closed boundary piece
    lineHand(end+1) = feval( lineFunct, yy(:,1), yy(:,2), 'color', 'b', ...
                             'marker', 'none', 'linestyle', '-', 'clipping', ...
                             'off' );
  end
  xx = ncst(I,:);
  
  % Plot open boundary points
  pH = feval(lineFunct,xx(:,1),xx(:,2),'color','r','marker','o', ...
             'linestyle','none','clipping','off');

  % Get rest of boundary points
  ii = true;
  while ii
    [x,y] = feval(functName,1);
    
    % If empty, fix last boundary point and prepare to exit
    % Otherwise just add new point onto end
    if isempty(x)
      ii = false;      
      [II,LL,d] = getnearest( distFunct, xx(end,:), ncst, K );
      xx(end,:) = ncst(II,:);
      lastPossible = LL == L0;
    else
      xx = [ xx; x, y ];
    end
  
    % Delete old open boundary plot pieces
    try, delete(pH), delete(lH), end
    
    % Plot new ones
    pH = feval(lineFunct,xx(:,1),xx(:,2),'color','r','marker','o', ...
               'linestyle','none','clipping','off');
    lH = feval(lineFunct,xx(:,1),xx(:,2),'color','r','marker','none', ...
               'linestyle','-','clipping','off');
  end
    
  % Put pieces together
  X = [ X; yy(2:end-1,:) ];
  bI(end+1) = size(X,1)+1;
  X = [ X; xx ];
  bI(end+1) = size(X,1);
  
  ptHand(end+1) = pH;
  lineHand(end+1) = lH;

  clear lH pH
  
end

% Unzoom - just to make sure it gets done
axis( aa );
switch zoomFunct
  case 'zoom'
  case 'm_zoom'
    m_ungrid;
    m_grid;
end
  
% Add last closed boundary piece
yy = getshortest( ncst, K, pl, tpl, II, I0, L0 );

% Plot closed boundary piece
lineHand(end+1) = feval( lineFunct, yy(:,1), yy(:,2), 'color', 'b', ...
                         'marker', 'none', 'linestyle', '-', 'clipping', ...
                         'off' );

X = [ X; yy(2:end,:) ];


%%%------------------SUBFUNCTIONS----------------------%%%
function [ncst,k,pl,tpl] = my_process_ncst( ncst, distFunct )

% Surround in NaN's just like m_map should have already done.
if ~isnan(ncst(1,1)), ncst(end+1,:) = NaN; ncst = ncst([end,1:end-1],:); end
if ~isnan(ncst(end,1)), ncst(end+1,:) = NaN; end

k = find( isnan(ncst(:,1)) );

tpl = zeros(numel(k)-1,1);
pl = ncst(:,1);
for l = 1:numel(k)-1
  kk = k(l)+1:k(l+1)-1;

  % eps deals with problem of NaN's for duplicates
  dd = feval( distFunct, ncst(kk,1), ncst(kk,2), ncst(kk([2:end,1]),1)+10*eps(ncst(kk(1))), ...
              ncst(kk([2:end,1]),2) )+10*eps(ncst(kk(1)));
  
  pl(kk) = dd;
  tpl(l) = sum(dd);
end

%%%%
function [I, l, d ] = getnearest( distFunct, x, ncst, k )

[d,I] = min( feval( distFunct, x(1), x(2), ncst(:,1), ncst(:,2) ) );
l = sum( k < I );

%%%%
function yy = getshortest( ncst, k, pl, tpl, I1, I2, L )

if I2 >= I1
  ll = I1:I2;
  p = sum(pl(ll(1:end-1)));
  
  if p/tpl(L) > 0.5
    ll = [ I1:-1:k(L)+1, k(L+1)-1:-1:I2 ];
  end
else
  ll = I1:-1:I2;
  p = sum(pl(ll(2:end)));
  
  if p/tpl(L) > 0.5
    ll = [ I1:k(L+1)-1, k(L)+1:I2 ];
  end
end

yy = ncst(ll,:);

%%%%
function [X,bI,ptHand,lineHand] = removelast(X,bI,ptHand,lineHand,xx,yy)

warning( 'Closed boundary spans multiple land masses.  Restarting!' );

n = size(yy,1) - 2 + size(xx,1);
X = X(1:end-n,:);
bI(end-1:end) = [];

delete(ptHand(end))
delete(lineHand(end-1:end))

ptHand(end) = [];
lineHand(end-1:end) = [];

