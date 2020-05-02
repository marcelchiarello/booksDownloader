function booksDownloader(folderName,method,keywords,epubFlag)
% MChiarello
% Free Springer Books downloader
%
% Usage example:
% booksDownloader('Data Science','fromKeywords',{'data','statistics','artificial','machine learning'},1)
%
% Last input is the epub flag
% epubFlag = 1 -- > Download epub format if available

% method = 'fromList' or 'fromKeywords' -- fromList -- > completed list is displayed and no keyword is considered

%% START
mkdir(folderName)

% Reading csv file
bookData = importBooksData('SpringerTable.csv');

% Checking book data
bookData = checkBookData(bookData);


%Finding book indices
switch method
    case 'fromList'
        %Book UI list
        UIlist = strcat(bookData.BookName,' -- ',string(1:size(bookData,1))');
        bookIdx = listdlg('PromptString','Select the books to download:','ListString',UIlist,'ListSize',[400 800]);
        
    case 'fromKeywords'
        foundIdx = findIdxFromKeywords(bookData,keywords);
        if isempty(foundIdx)
            msgbox('No book contains the indicated keywords!')
            return
        end
        UIlist = strcat(bookData.BookName(foundIdx),' -- ',string(foundIdx)');
        selIdx = listdlg('PromptString','Select the books to download:','ListString',UIlist,'ListSize',[400 400]);
        bookIdx = foundIdx(selIdx);
        
    otherwise
        disp('Unknown Method!')
        return
end

for n = bookIdx
    
    bookName = bookData.BookName{n};
    disp(['Downlaoding - ' num2str(n) ' - ' bookName ' ...']);
    
    %If the book title contains / --> change with -
    if contains(bookName, '/')
        bookName = strrep(bookName,'/','-');
    end
    
    %Check if already downlaoded
    if exist([folderName '/' bookName '.pdf'],'file')
        disp('The book is already present!')
        disp(' ')
    else
        
        link = bookData.Link{n};
        
        %Reading web content
        websave('urlContentTemp',link);
        fid = fopen('urlContentTemp');
        lines = textscan(fid,'%s','delimiter','\n');
        fclose(fid);
        lines = lines{1};
        
        %Finding download url
        for i = 1:length(lines)
            if ~isempty(strfind(lines{i},'.pdf'))
                sLine = lines{i};
                idxEnd = strfind(sLine,'.pdf') - 1;
                idxStart = strfind(sLine,'pdf/') + 4;
                
                %Download
                PDFdownloadUrl = ['https://link.springer.com/content/pdf/' sLine(idxStart:idxEnd) '.pdf'];
                websave([folderName '/' bookName], PDFdownloadUrl);
                
                if epubFlag
                    EPUBdownloadUrl = ['https://link.springer.com/download/epub/' sLine(idxStart:idxEnd) '.epub'];
                    try
                        websave([folderName '/' bookName], EPUBdownloadUrl);
                    catch
                        delete([folderName '/' bookName '.epub'])
                        disp('EPUB NOT FOUND!')
                    end
                end
                
                break
                
            end
        end
    end
end

%Deleting temp file
delete('urlContentTemp')
disp('done!')

end

%% Functions definition
function bookIdx = findIdxFromKeywords(bookData,keywords)
%Check book data
cnt = 0; bookIdx = NaN*[];
for i = 1:size(bookData,1)
    for j = 1:size(keywords,2)
        if contains(lower(bookData.BookName{i}),lower(keywords{j}))
            cnt = cnt + 1;
            bookIdx(cnt) = i;
            break
        end
    end
end
end

function bookData = checkBookData(bookData)
% Checking books data
cnt = 0; toDel = NaN*[];
for i = 1:size(bookData,1)
    if  isempty(bookData.BookName{i}) || strcmp(bookData.BookName{i},'Book Title')
        cnt = cnt + 1;
        toDel(cnt) = i;
    end
end
bookData(toDel,:) = [];
end

function SpringersTable = importBooksData(filename)
%Generated automatically

delimiter = ';';

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2]
    % Converts text in the input cell array to numbers. Replaced non-numeric
    % text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end


%% Split data into numeric and string columns.
rawNumericColumns = raw(:, [1,2]);
rawStringColumns = string(raw(:, [3,4,5,6]));


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Make sure any text containing <undefined> is properly converted to an <undefined> categorical
idx = (rawStringColumns(:, 3) == "<undefined>");
rawStringColumns(idx, 3) = "";

%% Create output variable
SpringersTable = table;
SpringersTable.Tabella1 = cell2mat(rawNumericColumns(:, 1));
SpringersTable.VarName2 = cell2mat(rawNumericColumns(:, 2));
SpringersTable.BookName = rawStringColumns(:, 1);
SpringersTable.Author = rawStringColumns(:, 2);
SpringersTable.VarName5 = categorical(rawStringColumns(:, 3));
SpringersTable.Link = rawStringColumns(:, 4);

end


