function modulenames = MiscWriter
    % =====================================================================
    % check towrite m-files
    % =====================================================================
    files_struct = dir(pwd);
    files_name = {files_struct.name}';
    [~,filenames,exts] = cellfun(@fileparts,files_name,'UniformOutput',0);
    ext_dbc_bool = strcmp(exts,'.dbc');
    ext_dbc_idx = find(ext_dbc_bool);
    
    modulenamepart = filenames(ext_dbc_bool);
    modulenames = strcat('module_', modulenamepart, '.m');
    
    module_exist_idx = ismember(modulenames,files_name);
    dbc_towrite_idx = ext_dbc_idx(~module_exist_idx);
    dbc_towrite_file = files_name(dbc_towrite_idx);
    identify_towrite_file = filenames(dbc_towrite_idx);
    
    % =====================================================================
    % call sub-functions
    % =====================================================================
    if ~isempty(ext_dbc_idx)
    % write can_module_ext.m
    % ---------------------------------------------------------------------    
        WriteModuleExt(modulenamepart);
    end
    
    if ~isempty(dbc_towrite_file)
        for i=1:numel(dbc_towrite_file)
    % write module_(xxx).m
    % ---------------------------------------------------------------------
            DBC_O = DbcExtractor(dbc_towrite_file{i});
    % write identify_(xxx).m
    % ---------------------------------------------------------------------
            WriteIdentify(DBC_O, identify_towrite_file{i});
        end 
    end
end

% #########################################################################
% =========================================================================
% sub-function definitions
% =========================================================================
% #########################################################################

% =========================================================================
% Write can_module_ext.m
% =========================================================================
function WriteModuleExt(module)
    filetowrite = 'can_module_ext';
    fid = fopen([filetowrite '.m'], 'w');
    
    str = ['function can = ' filetowrite '(b,msg,chan,tm)'];
    fprintf(fid, '%s\n\n\n', str);
    
    loopnum = size(module,1);
    for i=1:loopnum
        str = ['if exist(''module_' module{i} ''',''file'')'];
        fprintf(fid, '%s\n', str);
        
        str = ['if exist(''identify_' module{i} '_can_chan'',''file'')'];
        fprintf(fid, '\t%s\n', str);
        
        str = ['CHAN_NUMBER = identify_' module{i} '_can_chan(msg,chan);'];
        fprintf(fid, '\t\t%s\n', str);
        
        str = ['fprintf(''module_' module{i} ' is on CAN %d\n'',CHAN_NUMBER);'];
        fprintf(fid, '\t\t%s\n', str);
        
        str = 'else';
        fprintf(fid, '\t%s\n', str);
        
        str = 'CHAN_NUMBER = 1;';
        fprintf(fid, '\t\t%s\n', str);
        
        str = 'end';
        fprintf(fid, '\t%s\n', str);
        
        str = ['can_tmp = module_' module{i} '(b,msg,chan,tm,CHAN_NUMBER);'];
        fprintf(fid, '\t%s\n\n', str);
        
        str = 'if isstruct(can_tmp)';
        fprintf(fid, '\t%s\n', str);
        
        str = 'fields = fieldnames(can_tmp);';
        fprintf(fid, '\t\t%s\n', str);
        
        str = 'for k=1:length(fields)';
        fprintf(fid, '\t\t%s\n', str);
        
        str = 'can.(fields{k}) = can_tmp.(fields{k});';
        fprintf(fid, '\t\t\t%s\n', str);
        
        str = 'end';
        fprintf(fid, '\t\t%s\n', str);
        
        str = 'end';
        fprintf(fid, '\t%s\n', str);
        
        str = 'end';
        fprintf(fid, '%s\n', str);
        
        fprintf(fid, '\n\n');
        
    end
    
    fclose(fid);
    
    pcode([filetowrite '.m'],'-inplace');
    delete([filetowrite '.m']);
end

% =========================================================================
% WriteIdentify
% =========================================================================
function WriteIdentify(DBC_I, dbcfilename)
    filetowrite = ['identify_' dbcfilename '_can_chan'];
    fid = fopen([filetowrite '.m'], 'w');
    
    % header
    % ---------------------------------------------------------------------
    str = ['function CHAN_NUMBER = ' filetowrite '(msg,canchannel)'];
    fprintf(fid, '%s\n\n\n', str);
    
    str = {'chan1_count = 0;','chan2_count = 0;','chan3_count = 0;','chan4_count = 0;'};
    fprintf(fid, '%s\n',str{:});
    
    fprintf(fid, '\n');
    
    % loop
    % ---------------------------------------------------------------------
    loopnum = size(DBC_I,1);
    for i=1:loopnum
        iddec = num2str(DBC_I{i,2});
        for j=1:4
            chan = num2str(j);
            str = ['if ~isempty(find(msg == ' iddec ' & canchannel == ' chan ',1))'];
            fprintf(fid, '%s\n', str);
            str = ['chan' chan '_count = chan' chan '_count+1;'];
            fprintf(fid, '%s\n', str);
            str = 'end';
            fprintf(fid, '%s\n', str);
        end 
    end
    % tail
    % ---------------------------------------------------------------------
    fprintf(fid, '\n');
    str = 'CHAN_NUMBER = find([chan1_count chan2_count chan3_count chan4_count]==max([chan1_count chan2_count chan3_count chan4_count]));';
    fprintf(fid, '%s\n', str);
    str = 'CHAN_NUMBER = CHAN_NUMBER(1);';
    fprintf(fid, '%s\n', str);

    fclose(fid);
    
    pcode([filetowrite '.m'],'-inplace');
    delete([filetowrite '.m']);
end

