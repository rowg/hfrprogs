function sp = cart2magn( u, v )
% CART2MAGN  Convenience function that gets the magnitude of a set of (u,v)
% vectors.
%
% Usage: speed = cart2magn( u, v )
%

sp = sqrt( u.^2 + v.^2 );
