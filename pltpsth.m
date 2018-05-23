function pltpsth(t, binwidth, tracen, axislimit)

% function to plot the PSTH given an object t, containing spiking and
% stimulus info
figure;
% No segmentation, plot the whole data, usually for detecting baseline
% spike rate
if isempty(t.seg)
    
    b   = ceil(length(t.resp.data) / binwidth);
    % calculate spike rate
    
    for i = 1:b-1
        s(i) = length(find(t.resp.data(binwidth*(i-1)+1:binwidth*i,2) == 1));
    end
    s(b) = length(find(t.resp.data(binwidth*(b-1)+1:end,2) == 1));
    
    % spike index & value
    ind = find(t.resp.data(:,2) == 1);
    val = t.resp.data(ind,1);
    
    % plot;
    subplot(2,1,1), t.plt;
    text (ind /4000, val, '*', 'Color', 'red');
    %     axis(axislimit(1,:))
    subplot(2,1,2),area((1:b) * binwidth / 4000, s /(binwidth / 4000));
    %     axis(axislimit(2,:))
    return;
end


% bin number
b = ceil(length(t.seg.d) / binwidth);

% number of stimulus
nsti   = length(t.stim.startpoint);

if isempty(tracen)
    n = nsti;
    tracen = 1:n;
else
    n=length(tracen);
end

for i = 1: n
    
    % trace number
    m = tracen(i);
    
    % create a spike array
    for j = 1: b-1
        s(j) = length(find(t.seg.d(binwidth*(j-1)+1:binwidth*j,m+nsti) == 1));
    end
    s(b) = length(find(t.seg.d(binwidth*(b-1)+1:end,m+nsti) == 1));
    
    % spike index & value
    ind = find(t.seg.d(:,m+nsti) == 1);
    val = t.seg.d(ind,m);
    
    % plot
    subplot(2,n,i), t.plt('method','fixedlength','sti',m);
    text (ind /4000, val, '*', 'Color', 'red');
    axis(axislimit(1,:));
%     axis off;
    subplot(2,n,i+n),area((1:b) * binwidth / 4000, s /(binwidth / 4000),'FaceColor','black');
    axis(axislimit(2,:));
%     axis off;
    
end


end