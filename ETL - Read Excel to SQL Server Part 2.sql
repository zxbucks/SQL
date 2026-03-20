--Read Excel from file system (or network shared drive) to SQL Server
--Part 2:

--Before start,
--1. Make sure you completed the required permission provision part in "Read Excel to SQL Server Part 1.sql"
--2. Create an Excel file as C:\SQL\Test.xlsx (with data and column header) to test below script:


Declare 
@SourceFullPathFileName NVARCHAR(255)='C:\SQL\', 
@FileName NVARCHAR(255)='Test.xlsx',
@SheetName NVARCHAR(255)='Sheet1$',
@TableName NVARCHAR(255)='dbo.Test'
;

BEGIN

DECLARE @SQLStrIntialize nvarchar(max)=
'
IF (OBJECT_ID('''+@TableName+''') IS NOT NULL)
    DROP TABLE '+@TableName+';
'
;
PRINT '----------------------------------------';
PRINT 'Initialize Table to be Load into:';
PRINT(@SQLStrIntialize);
PRINT '';
PRINT '';
EXECUTE(@SQLStrIntialize);

DECLARE @SQLStr nvarchar(max)=
          'SELECT * INTO '+@TableName+' FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                         ''Excel 12.0;Database='+@SourceFullPathFileName+@FileName+';HDR=YES;IMEX=1'',
                         ''SELECT * FROM ['+@SheetName+']'');
'
;
PRINT '----------------------------------------';
PRINT 'Load Excel into'+ @TableName;
PRINT(@SQLStr);
PRINT '';
PRINT '';		  
EXECUTE(@SQLStr);

END



