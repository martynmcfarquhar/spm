function [fnames, defaults] = mysubs_fields

% function [fnames, defaults] = mysubs_fields
% Additional fields for class cfg_exbranch. See help of
% @cfg_item/subs_fields for general help about this function.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: mysubs_fields.m 1467 2008-04-22 07:46:05Z volkmar $

rev = '$Rev: 1467 $';

fnames={'prog', 'vfiles', 'modality', 'vout', 'sout', 'jout', 'tdeps', 'sdeps','chk','id'};
defaults={{},{},{},{},[],cfg_inv_out,[],[],false,struct('subs',{},'type',{})};