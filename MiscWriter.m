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
            [moduletowrite, DBC_O] = DbcExtractor(dbc_towrite_file{i});
            WriteModule(moduletowrite, DBC_O);
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
    fprintf(fid, '%s\n\n', str);
    
    str = 'uniquemsgid = msgidproc(msg,chan);';
    fprintf(fid, '\t%s\n\n', str);
    
    loopnum = size(module,1);
    for i=1:loopnum
        str = ['if exist(''module_' module{i} ''',''file'')'];
        fprintf(fid, '\t%s\n', str);
        
        str = ['if exist(''identify_' module{i} '_can_chan'',''file'')'];
        fprintf(fid, '\t\t%s\n', str);
        
        str = ['CHAN_NUMBER = identify_' module{i} '_can_chan(uniquemsgid);'];
        fprintf(fid, '\t\t\t%s\n', str);
        
        str = ['fprintf(''module_' module{i} ' is on CAN %d\n'',CHAN_NUMBER);'];
        fprintf(fid, '\t\t\t%s\n', str);
        
        str = 'else';
        fprintf(fid, '\t\t%s\n', str);
        
        str = 'CHAN_NUMBER = 1;';
        fprintf(fid, '\t\t\t%s\n', str);
        
        str = 'end';
        fprintf(fid, '\t%s\n', str);
        
        str = ['can_tmp = module_' module{i} '(b,msg,chan,tm,CHAN_NUMBER);'];
        fprintf(fid, '\t\t%s\n\n', str);
        
        str = 'if isstruct(can_tmp)';
        fprintf(fid, '\t\t%s\n', str);
        
        str = 'fields = fieldnames(can_tmp);';
        fprintf(fid, '\t\t\t%s\n', str);
        
        str = 'for k=1:length(fields)';
        fprintf(fid, '\t\t\t%s\n', str);
        
        str = 'can.(fields{k}) = can_tmp.(fields{k});';
        fprintf(fid, '\t\t\t\t%s\n', str);
        
        str = 'end';
        fprintf(fid, '\t\t\t%s\n', str);
        
        str = 'end';
        fprintf(fid, '\t\t%s\n', str);
        
        str = 'end';
        fprintf(fid, '\t%s\n\n\n', str);
        
    end
    
    str = 'end';
    fprintf(fid, '%s\n\n\n', str);
    
    str = 'function uniquemsgid = msgidproc(msg,chan)';
    fprintf(fid, '%s\n', str);
    str = 'uniquemsgid = cell(1,4);';
    fprintf(fid, '\t%s\n', str);
    str = 'uniquemsgid{1} = unique(msg(chan==1));';
    fprintf(fid, '\t%s\n', str);
    str = 'uniquemsgid{2} = unique(msg(chan==2));';
    fprintf(fid, '\t%s\n', str);
    str = 'uniquemsgid{3} = unique(msg(chan==3));';
    fprintf(fid, '\t%s\n', str);
    str = 'uniquemsgid{4} = unique(msg(chan==4));';
    fprintf(fid, '\t%s\n', str);
    str = 'end';
    fprintf(fid, '%s\n', str);
    
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
    str = ['function CHAN_NUMBER = ' filetowrite '(uniquemsgid)'];
    fprintf(fid, '%s\n\n\n', str);
    
    str = 'dbcid = [ ...';
    fprintf(fid, '%s\n', str);
    str = DBC_I(:,2);
    fprintf(fid, '\t\t%u,...\n',str{:});
    str = '0];';
    fprintf(fid, '\t\t%s\n',str);
    
    fprintf(fid, '\n');
    
    % loop
    % ---------------------------------------------------------------------

    for i=1:4
       str = ['chan' num2str(i) '_count = numel(intersect(uniquemsgid{1,'...
           num2str(i) '}, dbcid));'];
       fprintf(fid, '%s\n', str);
    end 
    % tail
    % ---------------------------------------------------------------------
    fprintf(fid, '\n');
    str = '[~, CHAN_NUMBER] = max([chan1_count chan2_count chan3_count chan4_count]);';
    fprintf(fid, '%s\n', str);

    fclose(fid);
    
    pcode([filetowrite '.m'],'-inplace');
    delete([filetowrite '.m']);
end


% =========================================================================
% WriteModule
% =========================================================================
function WriteModule(filetowrite, DBC_I)
    fid = fopen(filetowrite, 'w');
    
    [~,funcname,~] = fileparts(filetowrite);
    
    str = ['function can = ' funcname '(b,msg,chan,tm,CHANNUM)'];
    fprintf(fid, '%s\n\n\n', str);
    str = 'can=[];';
    fprintf(fid, '%s\n\n', str);
    str = 'ix = (chan == CHANNUM);';
    fprintf(fid, '%s\n', str);
    str = 'if isempty(ix)';
    fprintf(fid, '%s\n', str);
    str = 'return;';
    fprintf(fid, '\t%s\n', str);
    str = 'end';
    fprintf(fid, '%s\n', str);
    str = 'b  = b(:,ix);';
    fprintf(fid, '%s\n', str);
    str = 'tm  = tm(:,ix);';
    fprintf(fid, '%s\n', str);
    str = 'msg  = msg(:,ix);';
    fprintf(fid, '%s\n\n\n', str);
    
    loopnum = size(DBC_I, 1);
    
    for i=1:loopnum
    % msg struct frame
    % ---------------------------------------------------------------------
        str = ['% ' repmat('=',1, 73)];
        fprintf(fid, '%s\n', str);
        
        msg = ['MSG_' dec2hex(DBC_I{i,2})];
        str = [msg ' = ' num2str(DBC_I{i,2}) ';'];
        fprintf(fid, '%s\n\n', str);
        
        str = ['ix=(msg == ' msg ');'];
        fprintf(fid, '%s\n', str);
        
        str = 'if ~isempty(ix)';
        fprintf(fid, '%s\n', str);
        
        str = ['can.' DBC_I{i,1} ...
            ' = struct(''ID_hex'', '''', ''ID_dec'', [], ''nsamples'', 0, ''ctime'', []);'];
        fprintf(fid, '\t%s\n\n', str);
        
        str = 'bb  = b(:,ix);';
        fprintf(fid, '\t%s\n\n', str);
        
        str = ['can.' DBC_I{i,1} '.ID_hex = ''' dec2hex(DBC_I{i,2}) ''';'];
        fprintf(fid, '\t%s\n', str);
        
        str = ['can.' DBC_I{i,1} '.ID_dec = ' num2str(DBC_I{i,2}) ';'];
        fprintf(fid, '\t%s\n', str);
        
        str = ['can.' DBC_I{i,1} '.nsample = length(ix);'];
        fprintf(fid, '\t%s\n', str);
        
        str = ['can.' DBC_I{i,1} '.ctime = tm(ix);'];
        fprintf(fid, '\t%s\n\n', str);
        
    
    % signals
    % ---------------------------------------------------------------------
        for j=1:size(DBC_I{i,3},1)
            str = ['can.' DBC_I{i,1} '.units.' DBC_I{i,3}{j,1} ' = ''' DBC_I{i,3}{j,3} ''';'];
            fprintf(fid, '\t%s\n', str);
            
            str = ['can.' DBC_I{i,1} '.' DBC_I{i,3}{j,1} ' = ' DBC_I{i,3}{j,2}];
            fprintf(fid, '\t%s\n', str);
        end
        
        str = 'end';
        fprintf(fid, '%s\n\n\n', str);
        
    end
    
    fclose(fid);
    
    pcode(filetowrite,'-inplace');
    delete(filetowrite);
    
end
