function I = findGaps( X, Y, gapsize )
% FINDGAPS  Finds gaps in data over a certain size.
%
% This function will find gaps either due to uneven spacing or NaN
% values.
%
% Usage: I = findGaps( X, Y, gapsize )
%        I = findGaps( Y, gapsize )
%
% Inputs
% ------
% X = x values associated with data in Y.  X should be a single column
%     vector. If only two input arguments are given to the function, then
%     X = (1:size(Y,1))'.
% Y = A logical matrix with same number of rows as elements in X and an
%     arbitrary number of columns. True indicates that data is present for
%     that value of X and that column, false indicates missing data.  Gaps
%     will be found in each column.
% gapsize = all gaps greater in size than this will be returned.  gapsize
%           should be in units of X.  Gap size will be determined as the
%           separation between true values in a column (as opposed to the
%           separation between the first false in a series and the last).
%
% Outputs
% -------
% I = A four column matrix of gaps.  The columns are (1) starting row index
%     of gap, (2) ending row index of gap, (3) Y column index of gap, (4)
%     gap size.  Starts and ends of gaps will be row indices of the good
%     data points (i.e., true values in Y) that bookend the gap, except in 
%     the case of a gap at the beginnig or end of a column.  In these 
%     latter cases, the indice returned will be 0 or size(Y,1)+1, but the
%     gap will be by necessity measured from the beginning or end of the
%     column.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: findGaps.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
  gapsize = Y;
  Y = X;
  X = (1:size(X,1))';
end

% For simplicity, just loop over columns.  There must be a better way, but
% can't think of it.
I = [];
% This allows Y to have more than 2 dims, but the indices returned will
% be as if it was 2 dimensional.  Problem solved by sub2ind and ind2sub
for k = 1:numel(Y)/size(Y,1) 
  YY = Y(:,k);
  XX = X( [1; find(YY); end] );
  II = [0; find(YY); size(Y,1)+1];

  DD = diff( XX(:) );
  JJ = find( DD > gapsize );
  
  DD = DD( JJ );
  II = [ II( JJ ), II( JJ+1 ) ];
  
  I = [ I; II, repmat(k,[length(JJ),1]), DD ];
end
