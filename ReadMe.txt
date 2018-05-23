1.	Read LabChart file,  function d = readLabChart (filename),  d is a cell structure, each cell represents data from a block in LabChart, and each cell has a struct includes data from all channels;
2.	A function t = segmentLabChart(filename, block, channels, interval), to get a TS object from data in the block, channels within specific interval
3.	A TS class to create an object, to read timeseries data, including response data and stimulus data. Then plot data easily with different methods, for example, ‘raw’: plot all data; ‘fixedlength’: plot each trace with a fixed length; ‘average’, plot averaged data based stimulus pattern. 




Detect spikes and analyze spike rate 
1.	Read file.  (an interval of interest)
2.	In most of cases, select some traces with fixed length
3.	Detect spikes in these traces, analyze baseline, response spike rate 
4.	Plot.
