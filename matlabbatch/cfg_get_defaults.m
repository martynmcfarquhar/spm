function varargout = cfg_get_defaults(defstr, varargin)

% function varargout = cfg_get_defaults(defspec, varargin)
% Get/set defaults for various properties of matlabbatch utilities.
% The values can be modified permanently by editing the file
% private/cfg_mlbatch_defaults.m 
% or for the current MATLAB session by calling
% cfg_get_defaults(defspec, defval).
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: copyright_cfg.m 218 2008-04-17 10:34:11Z glauche $

rev = '$Rev: 218 $';

persistent local_def;
if isempty(local_def)
   local_def = cfg_mlbatch_defaults;
end;

% construct subscript reference struct from dot delimited tag string
tags = textscan(defstr,'%s', 'delimiter','.');
subs = struct('type','.','subs',tags{1}');

if nargin == 1
    varargout{1} = subsref(local_def, subs);
else
    local_def = subsasgn(local_def, subs, varargin{1});
end;
