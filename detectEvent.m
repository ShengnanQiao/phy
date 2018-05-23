
function [nEvent, startpoint,endpoint] = detectEvent(data, threshold, polarity)

% [nEvent, startpoint,endpoint] = detectEvent(data, threshold, polarity) 
%
% Detect the onset and offset timing of events with given threshold and
% polarity 
%
% INPUT
% data: raw datapoints contain the events
% threshold: mannually set threshold value
% polarity: polarity of events
%
% OUTPUT
% nEvent: number of events detected
% startpoint: an array for startpoint of all events
% endpoint: an arry for endpoint of all events

% initializing
startpoint=[];
endpoint=[];

% get indexies of all datapoints with their values greater or smaller than 
% the threshold depends on the polarity
if polarity == 'positive'
    s = find(data > threshold);
else
    s = find(data < threshold);
end

% get indexies separating different events
% e.g.,s = [2,3,4,5,6,10,11,12,13,14], then d = 5
d=find(diff(s)~=1);
nEvent=length(d)+1;

% exact indexies of startpoints and endpoints for all events
startpoint(1)=s(1);
startpoint(2:nEvent)=s(d+1);
endpoint(1:nEvent-1)=s(d);
endpoint(nEvent)=s(end);

end