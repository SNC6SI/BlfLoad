function BlfLoad(varargin)

    fileready = 0;
    
    if ~isempty(varargin)
        filetoread = varargin{1,1};
        [~,~,ext] = fileparts(filetoread);
        
        if strcmpi(ext, '.blf') && exist(filetoread) == 2
            fileready = 1;
            filetoread = which(filetoread);
        end
    end
    
    if ~fileready
        [filename, pathname] = uigetfile( ...
            {'*.blf', 'Canoe/Canalyzer Files (*.blf)';}, 'Pick a blf file');
        filetoread = fullfile(pathname, filename);
    end
    tic
    [candata,canmsgid,canchannel,cantime]=BlfExtractor(filetoread);
    toc
    tic
    assignin('base', 'candata', candata')
    assignin('base', 'canmsgid', canmsgid')
    assignin('base', 'canchannel', canchannel')
    assignin('base', 'cantime', cantime')
    toc
    
end