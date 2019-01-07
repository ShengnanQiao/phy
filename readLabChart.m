function t = readLabChart (filename,varargin)
% function to import Labchart data from an exported .mat file, and generate 
% a TS object for easy analysis and visualization.
%
% filename: the file name of the exported .mat file
% block: index of block to be imported, e.g., 1 
% interval: specific time interval, e.g., [100,320]

p = inputParser;

% required argument
p.addRequired('filename');
% optional arguments: block, default 1; channel, default [1,2]; interval,
% default [];
p.addOptional('block',1);
p.addOptional('interval',[]);

% p.addOptional('channels',[1,2]);
% parse varargin
p.parse(filename,varargin{:});
block    = p.Results.block;
interval = p.Results.interval;
% channels = p.Results.channels;

% load the .mat file
temp = load(filename,'data','dataend','datastart','samplerate');

% get samplerate
samplerate = temp.samplerate(1,1);

%%
% in the loaded files, all original datapoints from all blocks and
% all channels are combined to single file, temp.data; to extract
% datapoints for specific blocks and channels, use temp.datastart and
% temp.dataend. Each column represents each block, each row represents each
% channel.
% for example, there are 2 blocks, 4 channels in the following data.
% datastart =
%           1     9032001
%     2258001    11173801
%     4516001    13315601
%     6774001    15457401
%
% by defaut, channel 1 is the response, other channels are stimulus, for
% example, voltage/current pulus, white light etc. For special experiments,
% multi-channels for responses, in the inputparser, another parameter could
% be define to separte the response and stimulus.

% channels
c = size(temp.datastart,1);

% if interval is defaut as empty, read the whole block
if isempty(interval)
    resp = temp.data(temp.datastart(1,block):temp.dataend(1,block));
    for i = 2:c
        s(:,i-1) = temp.data(temp.datastart(i,block):temp.dataend(i,block));
    end
    stim = sum(s,2);
else
    interval = interval * samplerate;
    % n of interval
    n = size(interval,1);
    % response
    rpoints = interval + temp.datastart(1,block);
    % stimulus
    for i = 1:c-1
    spoints(:,:,i) = interval + temp.datastart(i+1,block);
    end
    
    % read intervals and concatenate them
    resp    =[];
    stim    =[];
    for i = 1:n % interval
        d = temp.data(rpoints(i,1):rpoints(i,2));
        resp = cat(2,resp,d);
        for j = 1:c-1 % channel
        s(:,j) = temp.data(spoints(i,1,j):spoints(i,2,j));
        end
        stim = cat(2,stim,sum(s,2));
    end
end

% generate a TS object and plot the raw data
t = TS(resp,stim);
% detect stimulus
t.detectSti(0.1);
% plot
figure; t.plt;
end