function BlfLoad(varargin)
    % =====================================================================
    % input file check
    % =====================================================================
    fileready = 0;
    
    if ~isempty(varargin)
        filetoread = varargin{1,1};
        [~,~,ext] = fileparts(filetoread);
        
        if strcmpi(ext, '.blf') && exist(filetoread,'file') == 2
            fileready = 1;
            filetoread = which(filetoread);
        end
    end
    
    if ~fileready
        [filename, pathname] = uigetfile( ...
            {'*.blf', 'Canoe/Canalyzer Files (*.blf)';}, 'Pick a blf file');
        if filename==0
            return;
        end
        filetoread = fullfile(pathname, filename); 
    end
    
    tic
    % =====================================================================
    % call DbcExtractor
    % =====================================================================
    [~] = MiscWriter;

    % =====================================================================
    % call mex function BlfExtractor
    % =====================================================================
    [b,msg,chan,tm]=BlfExtractor(filetoread, 789456.0);
    
    % =====================================================================
    % call can_module_ext
    % =====================================================================
    can = can_module_ext(b,msg,chan,tm);
    
    assignin('base', 'can', can)
    toc
end
