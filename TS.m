classdef TS < handle
    % Define a class for processing time-series electrophysiological or imaging data
    properties (Access = public)
        
        % resp: data for cell responses, including raw data, metadata and statistics;
        %
        % stim: data for stimulus, inclding raw data, metadata
        %
        resp
        stim
        seg
    end
    
    properties(Constant)
        
        sr =  4000; % sampling rate
        
    end
    
    
    methods
        
        function obj = TS(d1,d2)
            
            if isstruct(d1)
                obj.resp = d1;
            else
                obj.resp.data(:,1) = d1;
            end
            
            if isstruct(d2)
                obj.stim = d2;
            else
                obj.stim.data(:,1) = d2;
            end
        end
        
        
        
        function obj = detectSti(obj,threshold)
            % function to detect all tiggers of the stimulus
            
            % threshold: threshold to detect the timing of triggers, e.g., 1
            
            if isempty(obj.stim.data)
                return;
            end
            
            obj.stim.threshold = threshold;
            % first, use function detectEvent to detect the onset and offset
            
            [nsti, startpoint, endpoint] = detectEvent(obj.stim.data(:,1), threshold, 'positive');
            
            % correct stimulus (due to the light stimulus software)
            
            for i = 2:nsti
                if startpoint(i) - endpoint(i-1) < 1 * obj.sr % the interval is less than 1s, due to software
                    startpoint(i) = endpoint(i) - (endpoint(i-1)-startpoint(i-1));
                end
            end 
            
            obj.stim.startpoint = startpoint;
            obj.stim.endpoint   = endpoint;
            
            % generate new stimulus data
            obj.stim.data(:,2) = 0;
            for n = 1: nsti
                obj.stim.data(startpoint(n):endpoint(n),2)   = 2;
            end
            
        end
        
        function obj = setStiPattern(obj,pat)
            % function to set pattern for stimulus. For example, for light
            % responses, concentric spots with different diameters were
            % given and repeat 3 times, after defining this pattern, it is
            % convenient to average the responses.
            % pattern: numbers to set stimulus pattern for all channels
            
            if isempty(obj.stim.data)
                return;
            end
            if length(pat) ==1 % single number
                nsti = 1: length(obj.stim.startpoint);
                for p = 1:pat-1
                    obj.stim.pat(p).trailN = nsti(find(mod(nsti, pat)==p));
                end
                obj.stim.pat(pat).trailN = nsti(find(mod(nsti, pat)==0));
            else
                for i=1:length(pat)
                    obj.stim.pat(i).trailN=pat{i};
                end
            end
        end
        
        function obj = segtrace(obj,prestimlength,tracelength)
            % function to segment traces with fixed length
            %
            % tracelength: length of whole trace
            % prestimlength: length before stimulus onset
            
            
            prestimlength = prestimlength * obj.sr;
            tracelength   = tracelength * obj.sr;
            
            % define a trace with single stimulus
            nsti = length(obj.stim.startpoint);
            
            %
            obj.seg = [];
            %
            for i = 1: nsti
                tracestart = obj.stim.startpoint(i) - prestimlength;
                traceend   = tracestart + tracelength - 1;
                
                % segmented response traces
                obj.seg.d(:,i)    = obj.resp.data(tracestart:traceend,1);
                
                % automatically ajust baseline to 0 
%                 obj.seg.d(:,i) = adjustbaseline(obj.seg.d(:,i), bin);
                
                % segmented stimulus traces
                obj.seg.s(:,i)    = obj.stim.data(tracestart:traceend,2);
                
                % stimulus info in segmented traces
                obj.seg.si(1,i)   = prestimlength + 1;
                obj.seg.si(2,i)   = obj.seg.si(1,i) + obj.stim.endpoint(i) - obj.stim.startpoint(i);
                
                % for easy plot, add timing, here for better visulization,
                % add 1s space between traces
                space = 1 * obj.sr;
                obj.seg.t(:,i)   = ((tracelength + space) * (i-1) +1 : 1 : (tracelength + space) * i - space) / obj.sr;
            end
            
        end
        
        function obj = getPeakAmplitude(obj,onLength,offLength)
            % function to measure the peak amplitudes
            %
            % baseline: baseline value
            % onLength: an time interval set to measure the peak ON after
            % stimulus onset;
            % offLength: a time interval set to measure the peak off after
            % stimulus offset
            
            onLength = onLength * obj.sr;
            offLength = offLength * obj.sr;
            
            % get on/off peak from segmented traces with adjusted baseline
            for i = 1: length(obj.stim.startpoint)
                s = obj.seg.si;
                obj.resp.peakAmp(1,i) = min (obj.seg.d(s(1,i):s(1,i) + onLength, i));
                obj.resp.peakAmp(2,i) = min (obj.seg.d(s(2,i):s(2,i) + offLength,i));
            end
        end
        
        function obj = getArea(obj,interval)
            % function to measure the response area, e.g., for current
            % clamp recordings
            
            % baseline: baseline value
            % interval: an time interval set to measure response areas;
            % offLength: a time interval set to measure the peak off after
            % stimulus offset
            
            interval = interval * obj.sr;
           
            % get on/off response area using trapz
            for i = 1: length(obj.stim.startpoint)
                % on
                x1 = obj.seg.si(1,i):obj.seg.si(1,i) + interval;
                y1 = obj.seg.d(x1);
                obj.resp.area(1,i) = trapz(x1,y1);
                % off
                x2 = obj.seg.si(2,i):obj.seg.si(2,i) + interval;
                y2 = obj.seg.d(x2);
                obj.resp.area(2,i) = trapz(x2,y2);

            end
        end
        
        function obj = detectSpike(obj,threshold,polarity,option)
            % function to detect spikes
            
            % threshold: threshold to detect spikes
            % polarity:  'positive',above baseline; 'negative',below
            % baseline
            % option: 1, defaut, detection is performed on segmented traces; 
            % 0, detect all spikes in the whole raw data
            
            if option == 0
                
                [~,startpoint,endpoint] = detectEvent(obj.resp.data(:,1), threshold, polarity);
                
                
                obj.resp.data(:,2) = 0;
                
                try
                    if startpoint == 0 || endpoint ==0 % no spikes detected
                        obj.resp.spikerate = 0;
                        return;
                    end
                catch
                end
                
                % correction. due to noise, there are very nearby events
                % detected, but not separate spikes. Define a minmal spike
                % interval for 2.5ms in the case.
                errindx = find(diff(startpoint) < 0.005 * obj.sr);
                startpoint(errindx) =[];
                endpoint(errindx) =[];
                
                %
                
                for i = 1: length(startpoint)
                    [~,index] = min(obj.resp.data(startpoint(i):endpoint(i),1));
                    rawindex  = index + startpoint(i)-1;
                    obj.resp.data(rawindex,2) = 1;
                end
                
                % analysis on average baseline spike rate
                obj.resp.spikerate = length(find(obj.resp.data(:,2) == 1)) / round(length(obj.resp.data)/obj.sr);
                
            else
                
                % get stimulus timing
                 s = obj.seg.si;
                
                % stimulus number
                nsti = length(obj.stim.startpoint);
                
                for i = 1: nsti
                    [~,startpoint,endpoint] = detectEvent(obj.seg.d(:,i), threshold, polarity);
                    
                    % initiation, put spike array after segmented trace data in
                    % the same matrix
                    obj.seg.d(:,i+nsti) = 0;
                    
                    try
                        if startpoint == 0 || endpoint ==0 % no spikes detected
                             obj.seg.baselinespikerate(i) = 0;
                             obj.seg.respspikerate(i)     = 0;
                            continue;
                        end
                    catch
                    end
                    % correction. due to noise, there are very nearby events
                    % detected, but not separate spikes. Define a minmal spike
                    % interval for 2.5ms in the case.
                    
                    errindx = find(diff(startpoint) < 0.01 * obj.sr);
                    startpoint(errindx) =[];
                    endpoint(errindx) =[];
                    
                    
                    for j = 1: length(startpoint)
                        [~,index] = min(obj.seg.d(startpoint(j):endpoint(j),i));
                        rawindex  = index + startpoint(j)-1;
                        obj.seg.d(rawindex,i+nsti) = 1;
                    end
                    
                    % analysis on average baseline spike rate and response
                    % spike rates
                    obj.seg.baselinespikerate(i) = length(find(obj.seg.d(1:s(1,i)-1,i+nsti) == 1)) / round((s(1,i)-1)/obj.sr);
                    obj.seg.respspikerate(i)     = length(find(obj.seg.d(s(1,i):s(2,i),i+nsti) == 1)) / round((s(2,i)-s(1,i))/obj.sr);
                    
                end
                
            end
            
            
        end
        
        function obj = plt(obj,varargin)
            % function to visualize the data
            
            % block, the number of block to visualize, e.g., [1], [1,2]
            % channel, the number of channels to visualize, e.g., [1,2], [1,3]
            % method, "raw", plot all raw data; "average", plot averaged data
            %         by stimulus pattern; or specify some stimulus, e.g, [4]
            
            % to make it simple, just use 1 block, 2 channels every time
            
            p = inputParser;
            
            p.addOptional ('method', '');
%             p.addParameter('tracelength',[]);
                        p.addParameter('sti',[]);
            p.parse(varargin{:});
            
            method= p.Results.method;
%             tracelength = p.Results.tracelength;
            sti = p.Results.sti;
            
            
            
            if isempty(method)
                
                t = (1:1:length(obj.resp.data)) / obj.sr;
                d = obj.resp.data(:,1);
                
                if isfield(obj.stim, 'startpoint')
                    s = obj.stim.data(:,2);
                else
                    s = obj.stim.data(:,1);
                end
                plot(t,d,'b',t,s,'r');
                
                return;
            end
            
   
            if isempty(obj.seg)
                return;
            end
            
            
            
            
            switch method
                case 'fixedlength'
                    if isempty(sti)
                        nsti = length(obj.stim.startpoint);
                        for i = 1:nsti
                            d1 = obj.seg.d (:,i);
                            t1 = obj.seg.t(:,i);
                            s1 = obj.seg.s(:,i)-30;
                            plot(t1,d1,'k','LineWidth',1);hold on;
                            plot(t1,s1,'k','LineWidth',1);hold on;
                            
                        end
                    else
                        tracelength = length(obj.seg.d) / obj.sr;
                        for i = 1:length(sti)
                            d1 = obj.seg.d (:,sti(i));
                            t1 = obj.seg.t(:,sti(i))-(sti(i)-i) * (1+ tracelength);
                            s1 = obj.seg.s(:,sti(i))-30;
                            plot(t1,d1,'k','LineWidth',1);hold on;
                            plot(t1,s1,'k','LineWidth',1);hold on;
                        end
                    end
                    
                case 'average'
                    npat = length (obj.stim.pat);
                    for i = 1:npat
                        nsti = length(obj.stim.pat(i).trailN);
                        t2   = obj.seg.t(:,i);
                        s2   = obj.seg.s(:,obj.stim.pat(i).trailN(1))-30;
                        d2   =[];
                        for j = 1:nsti
                            d2(:,j) = obj.seg.d(:,obj.stim.pat(i).trailN(j));
                            
                            plot(t2,d2(:,j),'Color',[0.827 0.827 0.827],'LineWidth',1);hold on;
                        end
                        ave = mean(d2,2);
                        plot(t2,ave,'r','LineWidth',1);hold on;
                        plot(t2,s2,'k','LineWidth',1);hold on;
                    end
                    
            end
            
        end
        
        
        
    end
end