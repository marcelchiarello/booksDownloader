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
%finding book indices from keywords
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



