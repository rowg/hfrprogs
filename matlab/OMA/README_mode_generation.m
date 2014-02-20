% README_MODE_GENERATION explains steps for OMA mode generation
%
% Generating modes for doing open-boundary modal analysis (OMA) is not hard,
% but requires some basic understanding of how it works.  Some of the
% reasons that mode generation is complicated is due to some unusual
% "features" of the Matlab PDE Toolbox used by the openMA toolbox to do the
% mode generation.  Many of these are explained in more detail in the openMA
% toolbox: openMA/readme.m
%
% The basic steps to generating modes are:
%
% 1) Create a domain boundary
% 
%    The PDE Toolbox is rather picky about the domain boundary.  The
%    polygon that defines the domain boundary must contain segments that
%    are not too small.  In particular, it cannot contain any duplicate
%    points, including the first and last points (i.e. the last point
%    should really be the next-to-last point).  If duplicate points or
%    very small segments are in the boundary, then the PDE Toolbox will
%    fail with a vague error like "no geometry data".
%
%    I typically avoid this problem by interpolating the coastline so that
%    no edge segment is smaller than a certain size, say 0.2-1.0 km.  Too
%    detailed a coastline can also lead to a very high density of triangles
%    along the coastal boundary, thereby potentially reducing the density in
%    other parts of the domain.
%
% 2) Find out which edges correspond to special boundary segments
%
%    One must determine which of the boundary segments correspond to the
%    open boundaries and which will be used as the special "Dirichlet"
%    boundary segment.  The first of these is the oceanic part of the
%    domain edge.  The second is a special boundary segment used as a
%    cludge to control the normalization of the boundary modes (see
%    openMA_pdetool_boundary_modes_solve for more details).  This segment
%    is usually chosen to be an inconspicuous segment of the closed
%    boundary - any place that is unlikely to have large currents or
%    have Lagrangian trajectories entering it.
%
%    The numbers of these segments must correspond to the numbers used by
%    the PDE Toolbox.  The way to determine these is to run
%    generate_OMA_modes with the keyboard option set to true.  This
%    option stops the generation process in several key points so that
%    one can examine the domain in the PDE Toolbox.  The first stopping
%    point is used to determine the special segments.  Select "Boundary
%    Mode" in the PDE Toolbox and then select "Show Edge Labels".  This
%    will show the number used by the PDE Toolbox to identify each
%    segment of the boundary.  This can be used to select those that
%    correspond to open boundaries (these must be listed in spatial
%    order, i.e., in a counter-clockwise sense, which may differ from
%    numerical order), and the segment (or possibly segments) that will
%    be used for the Dirichlet boundary segment.  Type return in matlab
%    to continue the function.
%
%    The second break point in generate_OMA_modes can be used to look at
%    the triangular mesh to be used for mode generation by selection
%    "Mesh Mode".  This is the last break point.  Typically, one kills
%    generate_OMA_modes at this point and restarts it with the
%    appropriate open boundary and dirichlet segment numbers.
%
% 3) Choose a minimum spatial scale for the modes
%
%    This defines how many modes to use, which controls the spatial
%    smoothing of the fits.  The smaller this number, the more modes are
%    required and the finer the detail of the fit.
%
% 4) Run generate_OMA_modes and get some coffee
%
%    This can take a while depending on the minimum spatial scale and the
%    domain size.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: README_mode_generation.m 460 2007-07-20 19:24:22Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

help(mfilename)

