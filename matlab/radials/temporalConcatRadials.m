function TT = temporalConcatRadials( T, DR, DB, DH, DD )
% TEMPORALCONCATRADIALS  Concatenate timesteps in a RADIAL structure
%
% Usage: RADIAL = temporalConcatRadials( RADIAL, deltaRange, ...
%                              deltaBear, deltaHead, deltaDist )
%
% This function will take a RADIAL structure array, possibly containing data
% from multiple sites and multiple timesteps at each site, and concatenate
% them along the time direction.  Data from each site will be concatenated
% separately.  The final RADIAL structure array will have only as many
% elements as the number of sites represented by the input RADIAL structure
% array.  As radial grids at a site sometimes have small differences, this
% function allows for some slop in the radial positions, angles and ranges
% (see discussion below).  The list of sites in the original RADIAL
% structure array will be based exclusively on the SiteName inside the
% RADIAL structures.  The output RADIAL structure array will have the
% sites in alphabetical order.  This may be different than the original
% order of the sites!
%
% Inputs
% ------
% RADIAL = RADIAL structure array to be concatenated.
% deltaRange = slop in range below which two radial grid points are to
%          be considered the same.  Defaults to eps.
% deltaBear = slop in bearing below which two radial grid points are to
%             be considered the same.  Defaults to eps.
% deltaHead = slop in heading below which two radial grid points are to
%             be considered the same.  Defaults to eps.
% deltaDist = spatial separation below which two radial grid points are to
%             be considered the same.  Defaults to eps.
%
% Output
% ------
% RADIAL = radial structure that is concatenation of input RADIAL structures.
%
%
%
% Concatenating of multiple radial timesteps is typically complex.  This is
% because radial grids often change from one timestep to the next.  This
% function tries to deal with this in a consistent way.  It begins with the
% first radial structure at a site.  It then looks for grid points, ranges
% and directions in the next radial structure from that site that are
% identical to the first and concatenates these.  It then looks for grid
% points that are within deltaRange, deltaBear, deltaHead AND deltaD of
% existing grid points in the (growing) concatenated radial structure and
% concatenates this data (note that grid points must satisfy all
% conditions).  Whatever is left is assumed to be a new radial grid point at
% that site not in previous radial structures and these are added as such to
% the end of the growing new radial structure.  All missing data is filled
% with NaN.
%
% NOTE: Concatenation will only be attempted on LonLat, RangeBearHead, U, V,
% RadComp, Error, Flag, TimeStamp and FileName. All other elements of the
% structure will contain information from the first structure array from
% that site, with the exception of OtherMatrixVars, which will be left
% empty.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: temporalConcatRadials.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure out input arguments.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for f = { 'DR', 'DB', 'DH', 'DD' }
  f = f{:};
  if ~exist(f,'var')
    eval( [ f '=eps;' ] );
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Protect zeros - will be fixed later.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
matvars = RADIALmatvars;
for k = 1:numel(T)
  for m = matvars
    m = m{:};
    T(k).(m)( T(k).(m) == 0 ) = 9999e5;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make sure matrix vars have the appropriate number of time 
% dimensions.  This helps to deal with empties.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:numel(T)
  for m = matvars
    m = m{:};
    if isempty(T(k).(m))
      T(k).(m) = zeros(0,length(T(k).TimeStamp));
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get list of sites
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sites = unique( { T.SiteName } ); % List of sites

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over sites and concatenate each one.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TT = RADIALstruct; % Initial empty one stripped off later.
for s = sites(:)'
  I = strmatch( s{:}, { T.SiteName }, 'exact' );
  I = I(:)';
  
  % First from that site and some cleanup
  TT(end+1,1) = T(I(1));
  TT(end).FileName = cellstr( TT(end).FileName );
  TT(end).OtherMatrixVars = [];
  
  % Add processing steps
  TT(end).ProcessingSteps{end+1} = mfilename;
  
  % For singletons we are done.
  if numel(I) == 1
    continue
  end

  % Otherwise, must concatenate
  for II = I(2:end)
    vv = T(II);
  
    % Current dimensions of TT(end)
    DIM = [ size(TT(end).LonLat,1), length(TT(end).TimeStamp) ];
    
    % Sizes of vv
    DVV = [ size(vv.LonLat,1), length(vv.TimeStamp) ];

    if DVV(2) == 0
      warning( 'Ignoring empty TimeStamp.' );
      continue
    end
   
    % Add on simple stuff
    TT(end).TimeStamp = [ TT(end).TimeStamp, vv.TimeStamp ];
    TT(end).FileName = [ TT(end).FileName, cellstr(vv.FileName) ];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % First pull out grid points in current RADIAL that are trully
    % identical to existing grid points.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [C,IA,IB] = intersect( [ vv.LonLat, vv.RangeBearHead], ...
                           [ TT(end).LonLat, TT(end).RangeBearHead ], 'rows' );
      
    % Move over points with mate.
    for m = matvars
      m = m{:};
      TT(end).(m)(IB, DIM(2)+(1:DVV(2)) ) = vv.(m)( IA, : );
      vv.(m)(IA,:) = [];
    end
    
    % Get rid of grid points that are already in grid.
    vv.LonLat(IA,:) = [];
    vv.RangeBearHead(IA,:) = [];

    if isempty(vv.LonLat), continue, end
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Next proceed to look for points that are close enough
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Assume that number of remaining grid points is low and loop over
    % them.
    % As distance calculations are very slow for large matrices, 
    % do calculation in pieces.  Chopping things up like this in
    % reasonably large chunks makes things MUCH quicker than doing each
    % remaining radial grid point individually!
    ss = size(vv.LonLat,1);

    % Reasonable number of radial points to do at once.
    nn = ceil( min( 1e6 / size(TT(end).LonLat,1), ss ) ); 

    ii = [ (1:nn:ss), ss+1 ];
    ii = [ ii(1:end-1); ...
           ii(2:end)-1 ]; % Set of starts and ends of chunks
      
    for i = ii
      % Current dimensions of TT(end).LonLat - reset to keep track of growth
      DIM(1) = size(TT(end).LonLat,1);
    
      LL = vv.LonLat(i(1):i(2),:);
      RBH = vv.RangeBearHead(i(1):i(2),:);
      JJ = i(1):i(2); % Set of indices

      %%% (1) Commenting this out because m_idist is very slow
      % dd = m_idist( LL(:,1)', LL(:,2)', TT(end).LonLat(:,1), TT(end).LonLat(:,2) ...
      %              ) / 1e3;
      %%% (2) Commenting this out because it is bad to calculate distance
      %%%     from a single center point on a spherical earth.
      % dd = lonlat2dist( TT(end).LonLat, LL');
      %%% (3) Looping with lonlat2dist is best blend of accuracy & speed
      dd = repmat(NaN,[DIM(1),size(LL,1)]);
      for k = 1:DIM(1) % Need to loop to get accurate dist based at each
                       % existing grid point.
        dd(k,:) = lonlat2dist( TT(end).LonLat(k,:), LL');
      end
      
      rr = abs( repmat( TT(end).RangeBearHead(:,1), [1,size(RBH,1)] ) - ...
                repmat( RBH(:,1)', [size(TT(end).RangeBearHead,1),1] ) );
      bb = abs( repmat( TT(end).RangeBearHead(:,2), [1,size(RBH,1)] ) - ...
                repmat( RBH(:,2)', [size(TT(end).RangeBearHead,1),1] ) );
      hh = abs( repmat( TT(end).RangeBearHead(:,3), [1,size(RBH,1)] ) - ...
                repmat( RBH(:,3)', [size(TT(end).RangeBearHead,1),1] ) );
      
      % Find all points sufficiently close
      [IB,IA] = find( (dd < DD) & (rr < DR) & (bb < DB) & (hh < DH) );

      % Deal with mess if you are close to multiple grid points - just
      % use first.
      s = length(IA);
      [IA,I] = unique(IA);
      IB = IB(I);
      
      if length(IA) ~= s
        warning( 'Multiple matches for some grid points.' );
      end
      
      % Move over points with mate.
      for m = matvars
        m = m{:};
        TT(end).(m)(IB,DIM(2)+(1:DVV(2))) = vv.(m)(JJ(IA),:);
      end
      
      % Get rid of grid points that are already in grid.
      LL(IA,:) = [];
      RBH(IA,:) = [];
      JJ(IA) = [];
      
      if isempty(LL), continue, end

      % Number of remaining radial points.
      ss = size( LL, 1 );
        
      % Add new points to grid.
      TT(end).LonLat = [ TT(end).LonLat; LL ];
      TT(end).RangeBearHead = [ TT(end).RangeBearHead; RBH ];
      
      % Add data for new points.
      for m = matvars
        m = m{:};
        TT(end).(m)( DIM(1)+(1:ss), DIM(2)+(1:DVV(2)) ) = vv.(m)(JJ,:);
      end
    end
  
  end

  % Fix any problem of missing empty data.
  % This is a cludge that could hide problems with input data.
  DIM = [ size(TT(end).LonLat,1), length(TT(end).TimeStamp) ];  
  ss = size(TT(end).RadComp);
  if DIM(2) > ss(2)
    for m = matvars
      m = m{:};
      TT(end).(m)(1:ss(1),ss(2)+1:DIM(2)) = 0;
    end
  end
  
end
TT(1) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fix zeros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:numel(TT)
  for m = matvars
    m = m{:};
    TT(k).(m)( TT(k).(m) == 0 ) = NaN;
    TT(k).(m)( TT(k).(m) == 9999e5 ) = 0;
  end
end
