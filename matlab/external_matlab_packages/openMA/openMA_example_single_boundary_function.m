function t = openMA_example_single_boundary_function(s)
% This function would be used with openMA_pdetool_single_boundary_mode as
% the open boundary function.  It just does a constant normal component
% along the open boundary.

% t must be the same size as the input s or the function will not work correctly.
t = repmat( 1, size(s) );

