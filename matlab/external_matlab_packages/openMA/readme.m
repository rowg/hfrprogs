function readme
% OPENMA TOOLBOX README
%
% Creator: David M. Kaplan
% Creation Date: Friday, October 21, 2005
% Date of last edit: $Date: 2007-11-18 02:34:54 -0800 (Sun, 18 Nov 2007) $
%
% Version: 1.5
%
% License: All files in this toolbox are open source (GPL license) unless
% otherwise stated.  The full license is included in the file license.txt.
%
% This toolbox is designed to generate eigen and boundary modes on a domain
% and then fit those modes to data following the work of Lipphardt et
% al. [2000], Lekien et al. [2004] and Kaplan & Lekien [in prep.].  All the
% files generally have sufficient help and there is a brief demo of some of
% the functionality (openMA_demo).
%
% This toolbox depends on matlab's PDE Toolbox for generating modes.
%
% I will also collect here some notes regarding the toolbox, bugs and the
% pdetool.  They are presented in no particular order.  Please read these
% completely before using the toolbox.
%
% 1) All the functions that generate modes use an adaptive mesh method to
% get a good mesh for the PDE problem.  But, especially for the eigenvalue
% problems, the adaptive mesh method doesn't work too well.  So, for best
% results, experience and some fooling around will be necessary to find the
% best mesh.  In my experience, using the adaptive mesh method to find the
% first (constant) boundary mode tends to produce a detailed and relatively
% uniform grid.  This grid can then be used for finding other modes.  The
% adaptive mesh methods in each mode generating function can be turned off
% by setting the number of iterations to zero.
%
% 2) The pdetool has many odd features (i.e. bugs), at least in Matlab
% R13.  I will try to document them here, but some experimentation will
% be necessary.
%
% 3) Using openMA_pdetool_eigenmodes_solve with Dirichlet boundary
% conditions fails after using openMA_pdetool_boundary_modes_solve
% without closing and restarting the pdetool.  This is due to a weird bug
% in pdetool that I can't find a workaround for.  In my experience, it is
% best to close and reopen pdetool after every mode solving operation.
% The same grid can be achieved after each open and close using
% pdetool_getset_mesh.
%
% 4) pdetool uses pdeeig to solve for eigenvalues.  pdeeig generates the
% appropriate matrices and then uses sptarn to get the eigenvalues.
% sptarn is run with the default TOLCONV (100*eps in matlab R13), JMAX
% (100), and MAXMUL (default is N, not sure what N is).  JMAX means that
% the method will only find 100 eigenvalues in the specified range.  If
% there are more than that number in the range, then matlab will exit
% before finding all of them.  I have created the function
% openMA_pdetool_eigenmodes_solve_to_eigmax to solve this problem.  It
% repeatedly searches for eigenmodes until the eig_max is truly reached.
%
% 5) pdetool does not allow you to use the integral of a scalar function as
% a boundary condition, so solving for the boundary modes can be tricky as
% they are arbitrary up to a constant.  Matlab tends to pick a very large
% value for this constant, ruining the precision of the modes themselves.
% To fix this, I have allowed a cheat: setting one small boundary element of
% the mode to have dirichlet boundary conditions.  This fixes the mode and
% stabalizes the solver, but could cause, for example, current through land
% if the boundary segment used is too long.
%
% 6) The functions that solve for the modes generally will normalize all
% modes so that the integral of the magnitude of the currents over the
% domain divided by the domain area is 1.  Furthermore, the boundary
% modes are adjusted so that the integral of the scalar mode over the
% domain is 0 (as prescribed in Lekien et al. [2004]).
%
% 7) pdetool appears to have problems with eigenvalue degeneracy, as
% probably do other methods.  This can produce some strange results when the
% domain has lots of symmetry, like a square or a circle.
%
% 8) Originally I used tsearch for much of the interpolation, but that
% fails in many ways for non-Delaunay grids and has bugs.  So, now I have
% created tsearch_arbitrary to do much the same thing for any old
% triangular grid.  But this is probably slow compared to tsearch.
%
% 9) If you want to close the pdetool when running in batch mode, use
% delete(pde_fig), where pde_fig is the handle of the pdetool, instead of
% close(pde_fig) to close the pdetool.  This will avoid any save dialogues
% that prevent the window from closing without user interaction.
%
% 10) The pdetool has problems with boundary segments that have zero or a
% very small length.  Therefore, one has to be very careful with the
% boundary curve so that it does not contain repeat coordinates or the
% coastline has too much fine detail.  I recommend interpolating the
% coastline so that coast grid points are equally spaced.  If you do not
% do this, pdetool will return some strange errors that are at times
% difficult to decifer.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: readme.m 84 2007-11-18 10:34:54Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

help(mfilename)
 
