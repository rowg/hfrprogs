function x2 = filttappered( b, a, x1 );
% FILTTAPPERED  Filters with cosine tappering at ends.
%
% Usage: x2 = filttappered( B, A, x1 )
%
% where B and A are explained in the filter function.
%
% Normally for this function, A is a scalar.  Not sure what it does if it
% isn't.
%
% This function also assumes that B is a symmetric set of weights.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: filttappered.m 396 2007-04-02 16:56:29Z mcook $	
%
% This algorithm is modified from pl64tfilt.m from Steve Lentz and Ed
% Dever.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get rid of singleton dimensions before performing filter.
s0 = size(x1);
x1 = shiftdim( x1, min(find(s0~=1))-1 );

% New size.
s = size(x1);

n = floor( length(b) / 2 );

% Error if data is too short
if ( 2*n > s(1) )
  error( 'Data too short for filter' );
end

cs = repmat(cos( pi * (1:n)' / (2*n) ),[1,s(2:end)]);

% Add on cosine tappered bits to each end.
y = [ cs(end:-1:1,:) .* x1(n:-1:1,:); x1(:,:); cs(:,:) .* x1(end:-1:end-n+1,:) ];

% Apply filter
x2 = filter( b, a, y );

% I am not sure this exactly agrees with osutfilt.  In there it seems
% like x2 = x2( 2*n:end-1), but this doesnt seem quite right.
x2 = x2( 2*n+1:end, : ); 

% Put x2 in original shape just in case it had 3 or more dimensions.
x2 = reshape( x2, s );

% Add back singleton dimensions.
x2 = shiftdim( x2, -min(find(s0~=1))+1 );
