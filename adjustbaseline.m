function d1 = adjustbaseline(varargin)


% parse input
p = inputParser;

% required argument
p.addRequired('data');
% optional arguments: option, {'whole','pre-stimulus','sliding-window'}
p.addOptional('option','whole');
p.addOptional('prestimlength',0);
p.addOptional('winwidth',0);

% parse varargin
p.parse(varargin{:});
d        = p.Results.data;
option   = p.Results.option;
prestimlength = p.Results.prestimlength;
winwidth = p.Results.winwidth;

switch option
    % Use most frequent value in the whole data as baseline
    case 'whole'
        baseline = mode(d);
        d1       = d - baseline;
    % Use most frequent value in the pre-stimulus period as baseline     
    case 'pre-stimulus'
        baseline = mode(d(1:prestimlength));
        d1       = d - baseline;
    % when baseline is oscilating, cut data into bins and get baseline for each bin
    case 'sliding-window'
        nbin = ceil(length(d) / winwidth);
        for j = 1: nbin-1
            baseline = mode(d((j-1) * winwidth + 1: j*winwidth));
            d1((j-1) * winwidth + 1: j*winwidth) = d((j-1) * winwidth + 1: j*winwidth) - baseline;
        end
        d1((nbin-1) * winwidth + 1: length(d)) = d((nbin-1) * winwidth +1 : end) - mode(d((nbin-1) * winwidth +1 : end));
    otherwise % other fit method

end



end