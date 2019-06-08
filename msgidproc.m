function uniquemsgid = msgidproc(msg,chan)
    uniquemsgid = cell(1,4);
    uniquemsgid{1} = unique(msg(chan==1));
    uniquemsgid{2} = unique(msg(chan==2));
    uniquemsgid{3} = unique(msg(chan==3));
    uniquemsgid{4} = unique(msg(chan==4));
end