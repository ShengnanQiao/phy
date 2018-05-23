function t = readLabChart (filename,varargin)
% function to import Labchart data from an exported .mat file, and generate 
% a TS object for easy analysis and visualization.
%
% filename: the file name of the exported .mat file
% block: index of block to be imported, e.g., 1
% channels: indexes of channels to be imported, one channel for response, 
% one channel for stimulus, e.g., [1,3]
% interval: specific time interval, e.g., [100,320]

p = inputParser;

% required argument
p.addRequired('filename');
% optional arguments: block, default 1; channel, default [1,2]; interval,
% default [];
p.addOptional('block',1);
p.addOptional('channels',[1,2]);
p.addOptional('interval',[]);

% parse varargin
p.parse(filename,varargin{:});
block    = p.Results.block;
channels = p.Results.channels;
interval = p.Results.interval;

% load the .mat file
temp = load(filename,'data','dataend','datastart','samplerate');

% get samplerate
samplerate = temp.samplerate(1,1);

% in the loaded files, all original datapoints from all blocks and
% all channels are combined to single file, temp.data; to extract
% datapoints for specific blocks and channels, use temp.datastart and
% temp.dataend. Each column represents each block, each row represents each
% channel.

% if interval is defaut as empty, read the whole block
if isempty(interval)
    resp = temp.data(temp.datastart(channels(1),block):temp.dataend(channels(1),block));
    stim = temp.data(temp.datastart(channels(2),block):temp.dataend(channels(2),block));
else
    interval = interval * samplerate;
    % n of interval
    n = size(interval,1);
    
    % response
    rpoints = interval + temp.datastart(channels(1),block);
    % stimulus
    spoints = interval + temp.datastart(channels(2),block);
    
    % read intervals and concatenate them
    resp    =[];
    stim    =[];
    for i = 1:n
        d = temp.data(rpoints(i,1):rpoints(i,2));
        resp = cat(2,resp,d);
        s = temp.data(spoints(i,1):spoints(i,2));
        stim = cat(2,stim,s);
    end
end

% generate a TS object and plot the raw data
t = TS(resp,stim);
% figure; t.plt;
end