function BlfExtractorBuilder

    % path1 = ['-I' 'c:\program files (x86)\microsoft sdks\windows\v7.0a\include'];
    % path2 = ['-I' 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\include'];
    % path3 = ['-I' 'C:\Users\Public\Documents\Vector\CANoe\Sample Configurations 11.0.42\Programming\BLF_Logging\Include'];

    % mex('-v',path1,path2,path3,srcFile,'binlog.lib')
    % mex('-v',path3,srcFile,'binlog.lib')
    % mex('-v',path3,srcFile,'binlog.lib','-g')
    
	% ��ע����뻹����ͨ����˵��path1 �� paht2��·������������vs2010��·����
    
    srcFile = 'BlfExtractor.c';
    libFile = 'binlog.lib';
    
    mex('-v', '-g', srcFile, libFile)

end
