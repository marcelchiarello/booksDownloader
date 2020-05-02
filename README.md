# booksDownloader - Automatic Springer Books Downlaoder, based on keywords
booksDownloader(folderName,method,keywords,epubFlag)

Usage example:
booksDownloader('Data Science','fromKeywords',{'data','statistics','artificial','machine learning'},1)

Last input is the epub flag
epubFlag = 1 -- > Download epub format if available

method = 'fromList' or 'fromKeywords' -- fromList -- > completed list is displayed and no keyword is considered
