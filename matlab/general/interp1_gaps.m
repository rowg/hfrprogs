function YI = interp1_gaps( maxgap, varargin )
% INTERP1_GAPS  1D interpolation that deals with NaN's and doesn't
% interpolate if the gap in data is too big.
%
% Usage: YI = interp1_gaps( maxgap, X, Y, XI, ... )
%        YI = interp1_gaps( maxgap, Y, XI, ... )
%        YI = interp1_gaps( maxgap, Y, ... )
%
% Inputs
% ------
% maxgap = maximum gap size to fill.  Gap size will be determined with
%          findGaps.  See that function for details.
% Other arguments = function as they would in interp1, except that XI may
%                   be absent.  In this case, XI = (1:size(Y,1))'.  This
%                   could be useful for filling gaps.
% ... = additional arguments for interp1, such as the method and
%       extrapval.
%
% Outputs
% -------
% YI = interpolation of columns of Y, except that gaps larger than maxgap
%      will be left as NaN.  Gaps at the beginning and end of each column
%      of Y that are larger than maxgap will cause produce NaN for all XI <
%      min(X) and for all XI > max(X) (in addition to inside the gap
%      itself).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: interp1_gaps.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal with input arguments.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ii = [];
for k = 1:length(varargin)
  ii(k) = ischar( varargin{k} );
end
ii = min(find(ii));
if isempty(ii), ii = length(varargin)+1; end

vv = varargin(1:ii-1); % Start of arg list
varargin = varargin(ii:end); % End of argument list

switch length(vv)
  case 3
    [X,Y,XI] = deal( vv{:} );
  case 2
    [Y,XI] = deal( vv{:} );
  case 1
    Y = vv{1};
  otherwise
    error( 'Bad input arguments' );
end

if isvector(Y)
  Y = Y(:);
end

if ~exist('X','var')
  X = (1:size(Y,1))';
end
X = X(:);

if ~exist('XI','var')
  XI = X;
end
XI = XI(:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sort things nicely
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ss = size(Y);
[X,I] = sort(X);
Y = Y(I,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now do normal 1D interpolation ignoring gaps
% Have to loop over columns as not sure where NaNs
% might be.  More efficient methods exist, but 
% harder to implement.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
YI = repmat( NaN, [ length(XI), ss(2:end) ] );
I = ~isnan(Y);
for k = 1:numel(Y)/size(Y,1)
  ss = sum(I(:,k));
  if ss == 0 % None - don't worry about it
    continue
  elseif ss == 1 % If just one point try to put in place
    if any(X(I(:,k)) == XI)
      YI(X(I(:,k)) == XI,k) = Y(I(:,k),k);
    end
  else % 2 or more
    YI(:,k) = interp1( X(I(:,k)), Y(I(:,k),k), XI, varargin{:} );
  end
end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find gaps and their sizes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GG = findGaps( X, I, maxgap );

% Deal with beginning and end gaps appropriately
X = [ -inf; X; inf ];
GG(:,1:2) = GG(:,1:2) + 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Go back and remove data in gaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:numel(Y)/size(Y,1)
  G = GG( GG(:,3) == k, 1:2 );
  if isempty(G), continue, end
  
  x = X( G );  
  if isvector(x), x = x(:)'; end

  for l = 1:size(x,1)
    YI( XI > x(l,1) & XI < x(l,2), k ) = NaN;
  end
end
