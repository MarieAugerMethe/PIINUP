%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Narwhal matching program: uses the location of features of the notchess
% found on the dorsal ridge of the narwhals to identify the individuals.
%
% Author: Marie Auger-Methe & Hal Whitehead
% Date: July 2009
% Please cite: Auger-Methe, M. M. Marcoux, H. Whitehead (2011). Computer-assisted photo-identification of narwhals. Arctic 64:342-352
%
% This program is based on the matching program that Hal Whitehead wrote to
% help the identification of sperm whales. See Whitehead (1990) Computer
% assisted individual identification of sperm whale flukes. Report of the
% International Whaling Commission (Special Issue 12): 71-77
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function piinup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function piinup is the function to be called in
% the command window omatchf MATLAB to start the matching program. It creates
% 'Figure 1: Main control' which asks the information regarding the location
% of the pictures and databases, and other basic info. Piinup 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

infopl='infopl.txt';% place where info is stored
infoname={'Catalog table','Catalog database','Match table','Match database','New Id #''s greater (Yes/No)?','Areas (separate with commas)','Match area # (which of below?)','Number of potential matches','Location of pictures'}; %Description of the different option. The last description appears on top.
infovar={'cdbtable','cdb','dbtable','dbs','startnum','catname','dcat','noval','picloc'}; % contains the tags/name of these variable
% cdbtable      --> catalog table (Catalogtable)
% cdb           --> catalog db(Narwhalcatalog)
% dbtable       --> match table (KB_2006)
% dbs           --> match db (KBnarwhals)
% startnum      --> New id numbers greater (Yes)
% catname       --> area (Koluktoo Bay)
% dcat          --> area # from which the match are (1)
% noval         --> number of potential matches (60)
% picloc        --> location of picture (C:\Documents and Settings\Marie\My Documents\Narwhals\PhotoId\)
infodef={'Catalogtable','Catalog','KB_2006','Photos','Yes','Koluktoo Bay','1','1','C:\Documents and Settings\Marie\My Documents\NarwhalPhotoId\Catalogue'}; %default values
infotype=[2 1 2 1 2 6 3 3 5];%type of variable: 1 = database; 2 = string; 3 = number; 4 = file; 5 = path; 6 = set of strings

% Deals with the information saved in the infopl.txt file which has the
% info entered last time in figure 1.: Main control was open
fid=fopen(infopl,'r'); %fid = fopen(FILENAME, PERMISSION) opens the file infopl (which has the info peiously stored) for read access. PERMISSION can be: 'r' --> read, 'r+' read and write, ...
if fid>0
    for j=1:length(infoname)
        infod=fgetl(fid); % tline = fgtel(fid) returns the next line of a file associated with file idetifier fid as a MATLAB string
        [uv,uq]=strtok(infod,',');
        var=find(strcmp(uv,infovar));
        if ~isempty(var)
            uq=uq(2:end);
            if infotype(var)==3;% Deals with variables that are numbers (i.e.: 'Match area # (which of below?)','Number of potential matches')
                uq=str2num(uq);
            end
            infodef{var}=uq;
        end
    end
    fclose(fid);
end
logintimeout(25);

tfig=0.1;%no info. fig.
umaino=figure; % open the 1st figure
topval=40*length(infoname)+30;
set(umaino,'Position',[200 200 600 topval],'Menubar','none','Name', 'Main control');
umaint=uicontrol(umaino,'Style','text','position',[130 topval-50 360 30],'string','RIDGE MATCHING: MAIN CONTROLS','fontsize',15);
for j=1:length(infoname)
    utct(j)=uicontrol(umaino,'Style','text','tag',['t' infovar{j}],'position',[20 20+30*(j-1) 180 20],'string',[infoname{j} ':']);
    utc(j)=uicontrol(umaino,'Style','edit','tag',infovar{j},'position',[220 20+30*(j-1) 320 20],'string',infodef{j});
    if (infotype(j)==4)|(infotype(j)==5)
        ufst(j)=uicontrol(umaino,'Style','pushbutton','tag',['q' infovar{j}],'position',[550 20+30*(j-1) 30 20],'string','...','callback',{@getpl,infotype(j)});
    end        
end
umaingo=uicontrol(umaino,'Style','pushbutton','position',[500 topval-50 80 30],'string','OK','callback',{@flukeprsetup,infopl,infovar,infotype},'fontsize',15);
umainstop=uicontrol(umaino,'Style','pushbutton','position',[20 topval-50 80 30],'string','Quit','callback','close(gcf);','fontsize',15);


function getpl(obj,eventdata,infot)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function getpl gets the file path using a second window when you
% use the push button '...' It gets called in 'Figure 1: Main control' when
% the user chooses the location for the photographs.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
taggdat=get(obj,'tag');
taggdat=taggdat(2:end);
ufl=findobj('tag',taggdat);
uflt=findobj('tag',['t' taggdat]);
targstr=get(uflt,'string');
if infot==5;pn=[targstr '*.*'];end
[fn,pn]=uigetfile('*.*',targstr,get(ufl,'string'));
if infot==4;pn=[pn fn];end
set(ufl,'string',pn)


function flukeprsetup(obj,eventdata,infopl,infovar,infotype)
global proce vv dd ddu numwig minMPnum noot num sizecat urtt xlt catqual cataside picloc fgc noval startnum fileToBeM qualPicTBM fg dcat connd cdbtable conn dbtable catname compQVal % needs to include all of the variables save in infopl.txt file which will be used in other functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function flukeprsetup gets the information from the catalogue table of
% the MS access db and place it in a matrix called fgc. It also gets the
% info for the individual that will be processed from the matching table of
% the MS access db and place it the matrix fg.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% the following set of lines gets the info from the textfile infopl.txt
fid=fopen(infopl,'w');
for j=1:length(infovar)
    uu=get(findobj('tag',infovar{j}),'string');
    fprintf(fid,'%s,%s\n',infovar{j},uu);
    switch infotype(j)
        case 3
            eval([infovar{j} '=' uu ';']);
        case 6
            q=0;
            while 1
                q=q+1;
                [ak{q},uu]=strtok(uu,',');
                if isempty(uu);break;end
            end
            eval([infovar{j} '=strvcat(ak);']);
        otherwise
            eval([infovar{j} '=''' uu ''';']);
    end
end

% Set of variables that have been optimized for the program
vv=[1 0 0; 0 1 0; 0 0 0;]; % the value of two MPs compared: up deep
% In this version you can only compare up with up and deep with
% deep. But you could change this vv=[1 0.5 0; 0.5 1 0; 0 0 0;]; would give
% compare up with deep and give a match between the two half the value than
% for a match between two ups or two deeps MPs. If you want to do such a
% change you need to change also the dd matrix.
ddu=0.04; % size of extra bit added when using the wiggles. This helps to
% account for the misplacement of the ends of the ridge by the user (in the
% version that uses the ends of the ridge) or the possible addition of a
% mark point with time or missing of a point by the user (in the version
% that does not use the ends of the ridge). This value (0.04) should be
% about the average distance between 2 MP for now it's the old optimize ddu
% value from the original piinup (inputridge) program.  
dd=[0.003 0 0; 0 0.002 0; 0 0 0;]; % sd of the normal distribution used to
% calculate the probability that two MPs are same.  This helps account for
% the errors in the location of the MPS and of the ridge ends. 
numwig=1; % number of wiggle used. numwig=1 will result 9 possible
% placements of the ends see fig. 3.3 (Auger-Methe 2008).  
minMPnum=9; % minimum number of MPs a photo needs to be adequate for
% matching. This minimum number is based on the minimun 3 deep MPs but is
% now more for the benefit of the program than a limitation for the
% distinctiveness of the ridge. 9 MPs allow the comparison of photographs
% using the matching routine that does not use the ends of the ridge to
% compare two photographs that have visible limits and use the wiggles.
compQVal=[1 1 1]; % value to which lujnddu luknddu is multiply depending on
% the quality of the photos compared for quality [3 4 5]. Since changing
% these values did not significantly increase the matching efficiency, we
% left them as 1. But this is something that could be investigated more.

fclose(fid);
close(gcf);


% Gets the data found in the catalog and place it in a matrix called fgc
% and then form the matrices urtt and xlt which contains the MP information
% of the catalogue.
connd = database(cdb,'','');%input catalog database (Narwhalcatalog)
cursc=exec(connd,['SELECT * from ' cdbtable]); %select all columns from the catalog table (Catalogtable) in connd, the catalog database (Narwhalscatalog)
cursc=fetch(cursc); % fetch data and import data into MATLAB cell array. Import data from the catalog table into an array called cursc
fgc=cursc.Data; % that actually makes a matrix(?) fgc that has the data from the catalog table
sizecat=size(fgc); 
sizecat=sizecat(1); % gets the number of rows in the catalogue table
num=zeros(10000,1); %does it put a limit of 10000?
%  converts to variables
for i=1:sizecat %For all rows of the catalog table
    noot(i)=fgc{i,2};%IDN ()
    num(noot(i))=i;
    urtt{i}=str2num(fgc{i,3}); % urtt has the Marpoints type information found in the 3rd column of the catalog table (Maktype)
    xlt{i}=str2num(fgc{i,4}); % xlt has the Markpoints position information found in the 4th column of the catalog table (Markpos)
    catqual{i}=fgc{i,11}; % gets the quality of the photos from the catalogue found in the 11th column of the catalog table (Quality) 
    cataside{i}=fgc{i,12}; % gets the side of the narwhal in the photograph
end
proce=1; % proceed down the list

% These lines (including the loop) are use to go get the data in the match
% table and place it in a matrix called fg one row at the time. fg only has
% the information found in one of the rows of the match table.
conn = database(dbs,'','');%input match database (KBnarwhals)
%curs=exec(conn,['SELECT * from ' dbtable ]); % Original!! cursor = exec(connect, SQLquerry). It selects all columns from the match table in conn, the match database
curs=exec(conn,['SELECT * from ' dbtable ' ORDER BY ' dbtable '.Encounter']);% Changed so it uses the random numbers I entered, in the final program should change so it with dat time?
while proce
    curs=fetch(curs,1); % Fetch data and import data into MATLAB cell array, it returns only 1 row
    fg=curs.Data; % Puts the data of one row in fg
    while isempty(strmatch(fg{1},'No Data')) && (~strcmp(fg{9},'null') || fg{7}== 0) % if you are not at the end of the table (isempty(strmatch(fg{1},'No Data'))) and the row already has an IDN (~strcmp(fg{9},'null')) or it's not the best photo for that individual (fg{7} == 0), skip the row
        curs=fetch(curs,1); % Fetch data and import data into MATLAB cell array, it returns only 1 row
        fg=curs.Data; % Puts the data of one row in fg
    end
    
    % Display a message box saying 'End of file' if the table is empty or
    % if there is no more rows of the match table to go through.
    if strmatch(fg{1},'No Data'); 
        uiwait(msgbox('All of the ID have been assigned to this match table. The program only consider ridges for which the BestEncPhoto column contains a 1 and IDN column is empty.','End of file','modal'));
        break;
    end
    
    fileToBeM=fg{1}; % fileToBeM is the information from the 1st column of match table (e.g.: KC072501.JPG). It's the picture you want to match
    qualPicTBM=fg{5}; % quality of the picture to be matched
    
    % to make sure that the location of the picture has a final '\', if not it
    % cannot find the picture
    if isempty(strmatch(picloc(length(picloc)), '\'));
        picloc = [picloc '\'];
    end
    ifile=[picloc fileToBeM];
    if exist(ifile)
        umain=figure; % open the 2nd figure: File processed (the one that gives you the name of the file you could  process)
        qqq=0;
        set(umain,'Position',[600 60 400 100],'Menubar','none','tag','umain','Name','File processed');
        umaingo=uicontrol(umain,'Style','pushbutton','position',[275 60 100 30],'string','PROCESS','callback',{@processfluke,ifile},'fontsize',15);
        umainquit=uicontrol(umain,'Style','pushbutton','position',[160 60 60 30],'string','QUIT','callback',{@quitfig1},'fontsize',15);
        umainno=uicontrol(umain,'Style','pushbutton','position',[25 60 70 30],'string','SKIP','callback','close(gcf);','fontsize',15);
        ufitt=uicontrol(umain,'Style','text','position',[10 10 380 40],'string',ifile);
        uiwait(umain) %wait the figure umain figure is close
    else
        umain=msgbox(['No image for ' ifile]);
        pq=get(umain,'Position'); 
        set(umain,'Position',[520 60 pq(3:4)]);
        uiwait(umain);
    end
end
close(curs)
close(cursc)
close all
clear all


function quitfig1(obj,event)
global proce
proce=0;
close all;

function processfluke(obj,eventdata,ifile)
global xq numshown ife fg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function processfluke opens 'Figure 2: Ridge to be matched' which allows 
% you to crop the photograph before starting to enter the MPs.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numshown=1;%number photographs shown
hr=figure; % open 3rd figure which has the ridge you want to match. This figure gives you the option of cropping,  ...
set(gcf,'Name','Ridge to be matched','tag','primef');
[dum,ftype]=strtok(ifile,'.');
x=imread(ifile,ftype(2:end));
qq=image(x); % Truecolor image since m-by-n-by-3, changing colormap should not have effect on the colored displayed
axis equal; %sets the aspect ratio so that the data units are the same in every direction; so image not stuck in a square
axis tight;showaxes('off');

set(gcf,'Position',[10 380 1005 360],'Menubar','none');
set(gca,'Position',[0 0 1 1]); %change the position of the picture in the window (gca: get current axes handle)
hs(numshown)=hr;
xq{numshown}=x;

% displays the position of the whale if there is more than 1 individual in
% the photo
if ~strcmp(fg{2},'Null')
    uposition=uicontrol(hs(numshown),'Style','text','fontsize',10, ...
        'position',[0 343 180 17],'string',...
        ['Whale position in photo: ' fg{2}]);
end

% push buttons of the first figure with the narwhal photo
umarkin=uicontrol(hs(numshown),'String','GO','tag','ggo','Position',[960 15 40 20],...
    'callback',{@markpoints,hs,numshown});
uscrop=uicontrol(hs(numshown),'String','Crop?','tag','ggo','Position',[860 15 40 20],...
    'callback','ww=imcrop;qq=image(ww);axis equal;axis tight;showaxes(''off'');set(gcf,''Menubar'',''none'',''tag'',''primef'');');


function markpoints(obj,eventdata,hr,numshown)
global minMPnum sideE sideEntered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function markpoints allows the input of the markpoints (ridge ends, up,
% down, visible limits) for the photograph from the match table that the
% user is trying to match to the catalogue. The inputed MPs are stored in
% two vectors. urttx is a list of the entered mark type (1 2 3) means: up, 
% deep, visible limits. xltx stores the position of the MPs other than the
% ends using the distance from the start of the ridge till its end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

delete(findobj('tag','okn'));
delete(findobj('tag','ggo'));
delete(findobj('tag','sidePopUp'));
sideEntered=[];

% This makes the figure with the information
if isempty(findobj('tag','procinstr'))% only creates a new figure if the figure with the information is not already open    
    % Describe the MP and diplay the descriptions in figure called
    % Instruction. Can add types of MP between R and I but should not play
    % with the other types of MP (R, I, O) and don't add MP after O. If you
    % add MP types you need to add to the lines below which defines marcode
    % and teststring.
    tit=strvcat('Put in points from front to back of the narwhal, starting with front of the ridge,',...
        'input ends with end of ridge',...
        'Precede each point with code',...
        '   R=Ridge: (front to back), if one part of the ridge is masked place the ridge mark point',...
        '           where you think the ridge would begin.',...
        '   U=Up: upper limits of deep notches, it should be the highest point next to a deep notch.',...
        '           If there is only one high point between 2 deep notches only insert one up mark point',...
        '   D=Deep: deepest point of deep notch. Deep notches are only the notches that reaches the',...
        '           bottom of the dorsal ridge. If it is a triangular or narrow rounded notch, place',...
        '           one deep mark point at the deepest point. If it is a square or wide rouded notch place',...
        '           two deep mark points at the deepest points of the ends of the notch.',...
        '   I=Visible limits: if either of the ends of the ridge is masked. Place I where the ridge disapear.',...
        '           Do not include in the catalogue ridges that would have more than 1 visible limit', ...
        '   O=Oops, undo the last point');
    tfig=figure;
    tt=text(0.1,0.1,tit);
    axis tight;showaxes('off');
    set(tt,'Fontsize',7,'Verticalalignment','bottom');
    set(tfig,'Position',[20 60 500 280],'tag','procinstr','Menubar','none','Name','Instructions');%#
    set(gca,'Position',[0 0 1 1]);
end

marcode=[0 1 2 3 4];%# Code for the markpoints
figure(hr);
unumt=uicontrol(hr,'Style','text','position',[20 15 330 20],'String','You cannot quit before all of the MPs are entered!'); % writes ID on the left corner
teststring='RUDIO';%# Letters that will be entered in the image when you place a MP on the picture
OK=0;
while ~OK
    nummark=zeros(1,length(marcode)-1);% will serve to count the number of mark of each type; should be the length of the number of mark points (-1 since don't count the oops)
    p=0;
    OK=0;
    delete(findobj('tag','points'));% make sure the points entered from previous photographs are deleted
    clear tu xx yy typu
    while nummark(1)<2 % nummark(1) counts the number of ridge points counted, when two point entered the loop stopped
        k=waitforbuttonpress;
        if k
            cch=upper(get(gcf,'CurrentCharacter')); %get the character entered in the figure (I think)
            iss=findstr(cch,teststring);% finds the position of cch (character just entered) in the teststring, so r=0, u=1,... 
            if ~isempty(iss)% make sure that the letter entered on the key board is from the teststring
                figure(hr);
                if cch == 'O' %for oops, undo the last point
                    nummark(typu(p)+1)=nummark(typu(p)+1)-1; % takes out the 1 from the count of each types
                    typu(p)=[]; % to take out the type just enterd from the list (typu)
                    xx(p)=[]; % take out the x-position just entered
                    delete(pu(p)); % delete the red dot just entered
                    delete(tu(p)); % delete the letter just entered
                    p=p-1; % reset the p, so the next value has the appropriate index
                else
                    p=p+1;% to give a new point for each point entered
                    [xx(p),yy(p)]=ginput(1); %Input 1 point using the mouse, the xx is used for the position of the MP               
                    pu(p)=line(xx(p),yy(p),'tag','points','marker','.','markerfacecolor',[1 0 0],'markeredgecolor',[1 0 0],'linestyle','none');% adds the red dot
                    tu(p)=text(xx(p),yy(p),cch); % sets the letter
                    set(tu(p),'tag','points','HorizontalAlignment','center','verticalalignment','bottom','color',[0.3 0.3 0.3]);% adds the letter       
                    nummark(iss)=nummark(iss)+1;% this array with the counts the number of mark points of each type
                    typu(p)=marcode(iss);% typu for: r --> 0, u --> 1, d --> 2, i --> 3
                end
            end
        end
    end
    OK=1;
    if nummark(length(marcode)-1)>1 % verify if you have entered more than 1 visible limit
        OK=0;
        uiwait(msgbox('You cannot have more than 1 visible limit on a photo. If it is a typo re-enter the mark points. If the two ends of this photo are not visible, quit the program and remove this photo from your matching table.','ERROR','modal')); % error message
    elseif sum(nummark(2:end-1))<minMPnum | sum(nummark(3))<3% verify whether you the min number of MP (9 total MPs up or deep) and a minimum of 3 deep MP 
        OK=0;
        uiwait(msgbox(['You have entered less than ' num2str(minMPnum) ' mark points (up or deep) or less than 3 deep mark points, which is the minimum number required. If it is a typo re-enter the mark points. If this photo has not the required number of mark points, quit the program and remove this photo from your matching table.'],'ERROR','modal')); % error message
    end
end
urttx=typu(find(typu)); % k = find(X) returns the indices of the array X that point to nonzero elements. If none is found, find returns an empty matrix. In this case returns the indices of the matrix that is not the ridge, since marcode of the ridge (R) is 0.
%so urttx is a list of the entered mark type (1 2 3) means: up, deep,
%visible limit
xltx=(xx(find(typu))-xx(1))/(xx(end)-xx(1)); % Gives position to the MP other than the ends using the distance from the start of the ridge till its end. The ends of the ridge are removed in the function rvalue.

% Entering the side of the narwhal
sideN=uicontrol(hr,'Style','text','tag','sidePopUp','position',[380 15 90 20],'String','Side of narwhal'); % writes ID on the left corner
sideE=uicontrol(hr,'Style', 'popup','tag','sidePopUp','String', 'Enter side|Rigth|Left','Position', [470 15 75 20],'Callback',{@enterside,hr,1});
while isempty(sideEntered) || sideEntered ==1
    uiwait(hr)
end
delete(findobj('tag','sidePopUp'));
if sideEntered == 2
    sideN=uicontrol(hr,'Style','text','tag','sidePopUp','position',[380 15 90 20],'String','Side of narwhal'); % writes ID on the left corner
    sideE=uicontrol(hr,'Style', 'popup','tag','sidePopUp','String', 'Rigth|Left','Position', [470 15 75 20],'Callback',{@enterside,hr,2});
elseif sideEntered == 3
    sideN=uicontrol(hr,'Style','text','tag','sidePopUp','position',[380 15 90 20],'String','Side of narwhal'); % writes ID on the left corner
    sideE=uicontrol(hr,'Style', 'popup','tag','sidePopUp','String', 'Left|Rigth','Position', [470 15 75 20],'Callback',{@enterside,hr,3});
end

% Are the markpoints ok
okname=uicontrol(hr,'Style','text','tag','okn','position',[580 15 230 20],'String','Are you Ok with the mark points you entered?'); % writes ID on the left corner
oky=uicontrol(hr,'String','OK','tag','okn','Position',[815 15 30 20],'callback',{@startmatchloop,urttx,xltx});
okn=uicontrol(hr,'String','Not OK','tag','okn','Position',[850 15 50 20],'callback',{@markpoints,hr,numshown});



function enterside(obj,event,hr,firstpop)
global sideE sideEntered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function enterside gets the side from the pop-up menu of 'Figure 2: Ridge
% to be matched'. 1=not entered, 2=rigth, 3=left. The variable firstpop
% allow to make sure that no errors is created by the user (e.g. cannot
% click on 'Enter side' after entering either side.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if firstpop == 1
    sideEntered=get(sideE,'Value');
    uiresume(hr);
elseif firstpop ==2
    sideEntered=get(sideE,'Value')+1;
    uiresume(hr);    
else
    if get(sideE,'Value')==1
        sideEntered=get(sideE,'Value')+2;
    else
        sideEntered=get(sideE,'Value');
    end
    uiresume(hr);        
end



function startmatchloop(obj,event,urttx,xltx,sideEntered) % you need to have obj and event as argument of a callback function
global urtt xlt vv dd ddu numwig minMPnum noval fgc picloc noot catname ptx numdisp catqual qualPicTBM compQVal sideEntered cataside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function startmatchloop starts the match loop, get the r-values which
% represents the comparision between the ridge being matched and the ridges
% from the catalog. The loop allows the program to compare the ridge to be
% matched to all the photos of the catalogue. This function also open the
% 'Figure 4: List of potential matches' which displays the information of
% different ridges found in the catalogue. The r-value is in the second
% column and it represent the similarity value between the ridge you are
% trying to match and the ridge of the catalague.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sideEntered==2
    sidecat='R';
elseif sideEntered==3
    sidecat='L';
end
sideEntered=[];
    
lurtt = length(urtt); % number of individuals in the catalogue
h = waitbar(0,'Please wait ...');

for k=1:lurtt
    [rm(1,k)]=rvaluew(urttx,urtt{k},xltx,xlt{k},vv,dd,ddu,numwig,minMPnum,qualPicTBM,catqual{k},compQVal); %rm is the r value of the match, mmt reporesent whether the match is to a reverse photo
    waitbar(k/lurtt) 
end


close(h)
[rm,I]=sort(-rm);rm=-rm;% sorts the r-values comparing the photo to the catalog in decreasing order
ispicw=['Pic';' - ']; % picture available on the files of the computer to view

m=noval; % noval is the number of potential match indicated in 'Figure 1: Main control' and represent the maximum number of photograph shown in the list.
if lurtt<noval
    m=lurtt;
end

for kkp=1:m % for all individuals of the catalogue (or for the number of potential matches)
    ifork{kkp}=[picloc fgc{I(kkp),8}];
    ispic(kkp)=exist(ifork{kkp})>0;
    datell=fgc{I(kkp),7}(1:(end-2));
    if ~strcmp(fgc{I(kkp),10},'Null')
        position = fgc{I(kkp),10};
    else
        position = ' ';
    end
    selpos{kkp}=sprintf('%2.0f %2.4f %3.0f%1s %1s %12s  %19s %12s %5s %3s',kkp,rm(kkp),noot(I(kkp)),fgc{I(kkp),12},position,fgc{I(kkp),8},datell,catname(fgc{I(kkp),6},:),fgc{I(kkp),9},ispicw(2-ispic(kkp),:));
end
ptx=length(urttx); % value of ridge = number of notches
numdisp=m; % number of photos displayed as potential match

usel=figure; % open 4th figure of the program
set(usel,'tag','usel','Position',[25 25 800 360],'Menubar','none','Name','List of potential matches');
uc=uicontrol(usel,'Style','listbox','tag','ulist','string',selpos,'position',[20 50 760 280],'Fontname','courier','callback',...
    {@dopic,noot,I,ispic,ifork,I,sidecat}); % writes the list of info of the potential match, if you click on one of the photographs the function dopic which opens the appropriate photo is called 
unumt=uicontrol(usel,'Style','text','position',[20 20 40 20],'String','ID='); % writes ID on the left corner
unum=uicontrol(usel,'Style','edit','tag','unum','position',[60 20 60 20],'callback',{@newnum,ispicw,sidecat}); % makes the ID box
umatch=uicontrol(usel,'Style','pushbutton','position',[140 20 60 20],'string','MATCH!','callback',{@matchrun,xltx,urttx,sidecat});
unew=uicontrol(usel,'Style','pushbutton','position',[220 20 90 20],'string','NEW WHALE!','callback',{@newwhale,xltx,urttx,sidecat});
uquit=uicontrol(usel,'Style','pushbutton','position',[330 20 60 20],'string','QUIT!','callback',@uiquit);
disp('   ');


function [r]=rvaluew(ujE,ukE,xjE,xkE,vv,dd,ddu,numwig,minMPnum,qualPicTBM,catqual,compQVal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function rvaluew compares the photo you just entered with one of the
% photo from the catalogue. This function comes up with highest rvalue
% (similarity value) for this comparison. This function calculates the
% rvalue with both the 'with ends' and 'without ends' version and chooses
% the highest r-value. See Auger-Methe (2008) for details. 
% This function is called from startmatchloop. The loop in function
% startmatchloop allows to have a rvalue for the comparison of all of the
% photos from the catalogue.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nn=0; %


ukr=ukE; % uk is urt{k} --> 1 or 2 for up or down mark points of the photo from the catalog
xkr=xkE; % xj is xlt{k} --> the proportional distance of the mark points of the photo from the catalog
mc=length(vv(1,:));%in this case mc=3, represent the value for the visible limit ends
[vvl,dum]=size(vv); %so vv1=3
vv=vv(:);
vals=diag(vv);

for s=1:2 % this allow to also match the flip side of the photograph to be matched
    if s==1
        xjr=xjE; % xj is xlt{j} --> the proportional distance of the mark points of the photo your are trying to match
        ujr=ujE; % uj is urt{j} --> 1 or 2 for up or down mark points of the photo your are trying to match
    else
        xjr=1-fliplr(xjE); % flip the photograph to be matched
        ujr=fliplr(ujE); % flip the photograph to be matched
        ukr=ukE; % reset the original values for the photograph of the catalogue
        xkr=xkE; % reset the original values for the photograph of the catalogue
    end

    % this is the basic idea behind the wiggle. It gets complicated when you
    % are dealing with visible limit ends.
    % For 1st photo of the comparison the 2 loops (i1 and i2) should give 9
    % options of wiggle if numwig=1:
    % |ddu*-*-*--*-*ddu|--> * represent the MP
    % |ddu*-*-*--*      --> i1=-1 & i2=-1 proportional length= xjr+ddu-lastMP
    % |ddu*-*-*--*-*    --> i1=-1 & i2= 0 proportional length= xjr+ddu
    % |ddu*-*-*--*-*ddu|--> i1=-1 & i2=+1 proportional length= xjr+ddu+ddu
    %     *-*-*--*      --> i1= 0 & i2=-1 proportional length= xjr-lastMP
    %     *-*-*--*-*    --> i1= 0 & i2= 0 proportional length= xjr
    %     *-*-*--*-*ddu|--> i1= 0 & i2=+1 proportional length= xjr+ddu
    %       *-*--*      --> i1=+1 & i2=-1 proportional length= xjr-1stMP-lastMP
    %       *-*--*-*    --> i1=+1 & i2= 0 proportional length= xjr-1stMP
    %       *-*--*-*ddu|--> i1=+1 & i2=+1 proportional length= xjr-1stMP+ddu
    p1=1+(ujr(1)==mc); %verifying whether the ridge of 1st photo starts with an visible limit mark point, --> p1 will be 2 if starts with an visible limit (uj(1) should be 4)
    p2=1+(ujr(end)==mc); %verifying whether the ridge of 1st photo ends with an visible limit mark point, --> p2 will be 2 if ends with an visible limit (uj(end) should be 4)
    p3=1+(ukr(1)==mc); %verifying whether the ridge of 2nd photo starts with an visible limit mark point, --> p3 will be 2 if starts with an visible limit (uk(1) should be 4)
    p4=1+(ukr(end)==mc); %verifying whether the ridge of 2nd photo ends with an visible limit mark point, --> p4 will be 2 if endsts with an visible limit (uk(end) should be 4)

    %%%%%%%%%%%%%%%%%%
    % section with ends
    for i1=-numwig:numwig %-1 0 1 --> for the front of the dorsal ridge
        for i2=-numwig:numwig %-1 0 1 --> for the back of the dorsal ridge
            xj=(xjr-i1*ddu)/(1-(i1*ddu-i2*ddu)); % adjusted proportional distance of the mark points of the photo your are trying to match
            uj=ujr;
            % for 2nd photo of the comparison pair
            for i3=-numwig:numwig %-1 0 1
                for i4=-numwig:numwig %-1 0 1
                    xk=(xkr-i3*ddu)/(1-(i3*ddu-i4*ddu));
                    uk=ukr;
                    % so mc=length(vv(1,:))+1;-->mc=3 so uk>=mc will find the visible limit(startI=3, endI=4)
                    % if reversed the start will become the end so if reversed uk=3 is the end not the start
                    mvj1=find(uj==mc); %finds the start of an visible limit (uj=3 for startI), 1st photo
                    missj=[]; % sets a missing section, which is empty be default, so section in k not visible in j
                    mvk1=find(uk==mc); %finds the start of an visible limit (uk=3 for startI), 2nd photo
                    missk=[]; % sets a missing section, which is empty be default
                    for i=1:length(mvj1)%deal with missing values
                        if p1>1
                            missk=find(xk<=xj(mvj1)); %finds the area of the ridge in the 2nd photo(xk) that is missing in 1st photo (xj)
                        else
                            missk=find(xk>=xj(mvj1));
                        end
                    end
                    for i=1:length(mvk1)
                        if p3>1
                            missj=find(xj<=xk(mvk1)); %finds the area of the ridge in the 1st photo(xj) that is missing in 1st photo (xk)
                        else
                            missj=find(xj>=xk(mvk1)); %finds the area of the ridge in the 1st photo(xj) that is missing in 1st photo (xk)
                        end
                    end
                    ujj=uj;
                    ujj(missj)=[]; %gives an null value to all the mark points in the 1st photo that are in an visible limit area in the 2nd photo
                    xjj=xj;
                    xjj(missj)=[]; %gives an null value to all the distances of the mark points in the 1st photo that are in an visible limit area in the 2nd photo
                    ukk=uk;
                    ukk(missk)=[]; %gives an null value to all the mark points in the 2nd photo that are in an visible limit area in the 1st photo
                    xkk=xk;
                    xkk(missk)=[]; %gives an null value to all the distances of the mark points in the 2nd photo that are in an visible limit area in the 1st photo

                    % removes visible limit ends from the ridge that still have
                    % them some might have been removed if both ridge had an
                    % visible limit end
                    xjj(find(ujj==mc))=[];
                    ujj(find(ujj==mc))=[];
                    xkk(find(ukk==mc))=[];
                    ukk(find(ukk==mc))=[];

                    luj=length(ujj); %the length has been decreased by the number of missing points (missj)
                    luk=length(ukk); %the length has been decreased by the number of missing points (missj)
                    co1=ones(luj,1)*ukk; % makes a matrix with luj numbers of row, each row has the ukk data (markpoint type)
                    co2=(ones(luk,1)*ujj)'; % makes a matrix with luk number of columns, each column has ujj data (markpoint type)
                    vvp=vv(co1(:)+vvl*(co2(:)-1)); % so vv is a column with the values of matching two mark points u to u -->1, u to d--> 0, d to s--> 0,5; vv1=3
                    vvp=reshape(vvp,luj,luk); % makes a matrix with 1 if the mark points in both photos have the same mark point category (up or down)
                    ddp=dd(co1(:)+vvl*(co2(:)-1));
                    ddp=reshape(ddp,luj,luk);
                    rmat=vvp.*exp(-((ones(luj,1)*xkk-(ones(luk,1)*xjj)').^2)./(2*((0.001+ddp).^2))); % for each of the mark points of the same type compares the position and gives a r value that represent whether they error distribution overlap
                    if luk>luj;rmat=rmat';end
                    rr=sum(max(rmat))/(((luj*compQVal(catqual-2))+ (luk*compQVal(qualPicTBM-2)))/(compQVal(catqual-2)+compQVal(qualPicTBM-2)));  % adds all of the maximum r value for each possible combination and divides it by the greatest number of mark point and divide it so by the number of MP from the the ridge with the highest does count the extra bits as MP
                    nn=nn+1;
                    rq(nn)=rr;
                end
            end
        end
    end

    %%%%%%%%%%%%%%%
    % This whole following section of 100s of line is the no ends program!
    % this section removes the ends of the ridges compared
    xjr=(xjr-xjr(1))/(xjr(end)-xjr(1));% distance from the first point to last point proportional to the distance from the first to last point exclude the ends of ridge
    xkr=(xkr-xkr(1))/(xkr(end)-xkr(1));% distance from the first point to last point proportional to the distance from the first to last point exclude the ends of ridge

    if (p1+p2+p3+p4)==4 % for no visible limit
        for i=1:numwig
            xjrt=[(-ddu*i) xjr (1+ddu*i)]; % adding the extra ends (ddu), 1st photo
            xkrt=[(-ddu*i) xkr (1+ddu*i)]; % adding the extra ends (ddu), 2nd photo
            ujrt=[mc ujr mc]; % adding points for the extra bits they have the same value as visible limit ends, 1st photo
            ukrt=[mc ukr mc]; % adding points for the extra bits they have the same value as visible limit ends, 2nd photo
        end
        for i1=1:numwig*2+1 % for 1st photo of the comparison pair
            for i2=1:numwig*2+1
                xj=(xjrt(i1:end-i2+1)-xjrt(i1))/(xjrt(end-i2+1)-xjrt(i1));
                uj=(ujrt(i1:end-i2+1));
                for i3=1:numwig*2+1 % for 2nd photo of the comparison pair
                    for i4=1:numwig*2+1
                        xk=(xkrt(i3:end-i4+1)-xkrt(i3))/(xkrt(end-i4+1)-xkrt(i3));
                        uk=(ukrt(i3:end-i4+1));
                        luj=length(uj);
                        luk=length(uk);
                        lujnddu=length(find(uj<4)); % counts the number of MP used without counting the extra bits
                        luknddu=length(find(uk<4)); % counts the number of MP used without counting the extra bits
                        co1=ones(luj,1)*uk; % makes a matrix with luj numbers of row, each row has the ukk data (markpoint type)
                        co2=(ones(luk,1)*uj)'; % makes a matrix with luk number of columns, each column has ujj data (markpoint type)
                        vvp=vv(co1(:)+vvl*(co2(:)-1)); % so vv is a column with the values of matching two mark points u to u -->1, u to d--> 0, d to s--> 0.5; vv1=3
                        vvp=reshape(vvp,luj,luk); % makes a matrix with 1 if the mark points in both photos have the same mark point category (up or down)
                        ddp=dd(co1(:)+vvl*(co2(:)-1));
                        ddp=reshape(ddp,luj,luk);
                        rmat=vvp.*exp(-((ones(luj,1)*xk-(ones(luk,1)*xj)').^2)./(2*((0.001+ddp).^2))); % for each of the mark points of the same type compares the position and gives a r value that represent whether they error distribution overlap
                        if luk>luj
                            rmat=rmat';
                        end
                        rr=sum(max(rmat))/(((lujnddu*compQVal(catqual-2))+ (luknddu*compQVal(qualPicTBM-2)))/(compQVal(catqual-2)+compQVal(qualPicTBM-2)));  % adds all of the maximum r value for each possible combination and divides it by the greatest number of mark point and divide it so by the number of MP from the the ridge with the highest does count the extra bits as MP
                        nn=nn+1;
                        rq(nn)=rr;
                    end
                end
            end
        end

    elseif (p1==2 & p2==1 & p3==1 & p4==1) || (p1==1 & p2==2 & p3==1 & p4==1) % if (the 1st ridge starts with an visible limit) OR (the 1st ridge ends with an visible limit)
        if (length(ujr)-1)<=(length(ukr)+2*numwig) % only do the comparison if the ridge with the visible limit end (the 1st ridge) has at the maximum the same ammount of MP than the second ridge + 2x the amount of wiggle
            numMPxjexI=length(xjr)-1; % number of MP from the original 1st ridge before adding the extra bits(ddu) it does not include the visible limit MP

            % this removes the visible limit ends and flip both ridge if the
            % visible limit end is at the end of the ridge (p2=2)
            if p1==2 % if the 1st ridge start with an visible limit
                xjrt=(xjr(2:end)-xjr(2))/(xjr(end)-xjr(2)); % remove the visible limit point
                ujrt=ujr(2:end); % remove the visible limit point
                xjrt=1-fliplr(xjrt);
                ujrt=fliplr(ujrt);
                xkrt=1-fliplr(xkr); % for no reverse flip since the xjr is flipped
                ukrt=fliplr(ukr);
            elseif p2==2 % if the 1st ridge ends with an visible limit
                xjrt=(xjr(1:(end-1))-xjr(1))/(xjr(end-1)-xjr(1)); % remove the visible limit point
                ujrt=ujr(1:(end-1)); % remove the visible limit point
                xkrt=xkr; % for no reverse since xjr in this case in not flipped
                ukrt=ukr;
            end

            % dealing with the wiggles of the ridge WITH the visible limit end
            for i=1:numwig % just adding the normal ddu wiggles like for when there is no visible limit for the 1st photo
                xjrt=[(-ddu*i) xjrt (1+ddu*i)]; % adding the extra ends (ddu), 1st photo
                ujrt=[mc ujrt mc]; % adding points for the extra bits they have the same value as visible limit ends, 1st photo
            end

            % dealing with wiggles of the ridge WITHOUT the visible limit end
            if length(xkrt)>=(numMPxjexI+numwig) % If the 2nd photo has at least the the same amount of MP than the number MP of the photo with visible limit + 2x the amount numwig
                xkrt=(xkrt(1:(numMPxjexI+numwig))-xkrt(1))/(xkrt(numMPxjexI+numwig)-xkrt(1)); % using the MPs of the ridge as wiggle for the appropriate side
                ukrt=ukrt(1:(numMPxjexI+numwig));
                for i=1:numwig
                    xkrt=[(-ddu*i) xkrt]; %just adding normal wiggle on the other side
                    ukrt=[mc ukrt];
                end
            elseif length(xkrt)<=numMPxjexI % If the 2nd photo has at the same number or a bit less (see fisrt if of this section) MP than the photo with the visible limit start
                for i=1:numwig
                    xkrt=[(-ddu*i) xkrt (1+ddu*i)]; % just adding normal wiggle on each side
                    ukrt=[mc ukrt mc];
                end
            else % If the 2nd photo an amount of MP in between the amount the photo with the visible limit start has and that amount plus 2*numwig
                for i=1:(numMPxjexI+numwig-length(xkrt))
                    xkrt=[xkrt (1+ddu*i)]; % adding extra wiggles (in addition to the additional MP) on the appropriate side
                    ukrt=[ukrt mc];
                end
                for i=1:numwig
                    xkrt=[(-ddu*i) xkrt]; % adding the normal amount of wiggle on the other side
                    ukrt=[mc ukrt];
                end
            end

            % removes wiggle or extra MPs as the loop increases
            for i1=1:numwig*2+1 % for 1st photo of the comparison pair
                for i2=1:numwig*2+1
                    xj=(xjrt(i1:end-i2+1)-xjrt(i1))/(xjrt(end-i2+1)-xjrt(i1));
                    uj=(ujrt(i1:end-i2+1));
                    for i3=1:numwig*2+1% for 2nd photo of the comparison pair
                        for i4=1:numwig*2+1
                            xk=(xkrt(i3:end-i4+1)-xkrt(i3))/(xkrt(end-i4+1)-xkrt(i3));
                            uk=ukrt(i3:end-i4+1);
                            luj=length(uj); % length for the comparison matrices
                            luk=length(uk); % length for the comparison matrices
                            lujnddu=length(find(uj<4)); % counts the number of MP used without counting the extra bits
                            luknddu=length(find(uk<4)); % counts the number of MP used without counting the extra bits
                            co1=ones(luj,1)*uk; % makes a matrix with luj numbers of row, each row has the ukk data (markpoint type)
                            co2=(ones(luk,1)*uj)'; % makes a matrix with luk number of columns, each column has ujj data (markpoint type)
                            vvp=vv(co1(:)+vvl*(co2(:)-1)); % so vv is a column with the values of matching two mark points u to u -->1, u to d--> 0, d to s--> 0,5; vv1=3
                            vvp=reshape(vvp,luj,luk); % makes a matrix with 1 if the mark points in both photos have the same mark point category (up or down)
                            ddp=dd(co1(:)+vvl*(co2(:)-1));
                            ddp=reshape(ddp,luj,luk);
                            rmat=vvp.*exp(-((ones(luj,1)*xk-(ones(luk,1)*xj)').^2)./(2*((0.001+ddp).^2))); % for each of the mark points of the same type compares the position and gives a r value that represent whether they error distribution overlap
                            if luk>luj
                                rmat=rmat';
                            end
                            rr=sum(max(rmat))/(((lujnddu*compQVal(catqual-2))+ (luknddu*compQVal(qualPicTBM-2)))/(compQVal(catqual-2)+compQVal(qualPicTBM-2))); % adds all of the maximum r value for each possible combination and divides it by the greatest number of mark point
                            nn=nn+1;
                            rq(nn)=rr;
                        end
                    end
                end
            end
        else % if the amount of MP of the ridge with an visible limit is much more than the amount of MP than the ridge without the visible limit
            if p1==2 % if the 1st ridge start with an visible limit
                xjrt=(xjr(2:end)-xjr(2))/(xjr(end)-xjr(2)); % remove the visible limit point
                ujrt=ujr(2:end); % remove the visible limit point
            elseif p2==2 % if the 1st ridge ends with an visible limit
                xjrt=(xjr(1:(end-1))-xjr(1))/(xjr(end-1)-xjr(1)); % remove the visible limit point
                ujrt=ujr(1:(end-1)); % remove the visible limit point
            end
            for i=1:numwig
                xjr=[(-ddu*i) xjr (1+ddu*i)]; % adding the extra ends (ddu), 1st photo
                xkr=[(-ddu*i) xkr (1+ddu*i)]; % adding the extra ends (ddu), 2nd photo
                ujr=[mc ujr mc]; % adding points for the extra bits they have the same value as visible limit ends, 1st photo
                ukr=[mc ukr mc]; % adding points for the extra bits they have the same value as visible limit ends, 2nd photo
            end
            for i1=1:numwig*2+1 % for 1st photo of the comparison pair
                for i2=1:numwig*2+1
                    xj=(xjr(i1:end-i2+1)-xjr(i1))/(xjr(end-i2+1)-xjr(i1));
                    uj=(ujr(i1:end-i2+1));
                    for i3=1:numwig*2+1 % for 2nd photo of the comparison pair
                        for i4=1:numwig*2+1
                            xk=(xkr(i3:end-i4+1)-xkr(i3))/(xkr(end-i4+1)-xkr(i3));
                            uk=(ukr(i3:end-i4+1));
                            luj=length(uj);
                            luk=length(uk);
                            lujnddu=length(find(uj<4)); % counts the number of MP used without counting the extra bits
                            luknddu=length(find(uk<4)); % counts the number of MP used without counting the extra bits
                            co1=ones(luj,1)*uk; % makes a matrix with luj numbers of row, each row has the ukk data (markpoint type)
                            co2=(ones(luk,1)*uj)'; % makes a matrix with luk number of columns, each column has ujj data (markpoint type)
                            vvp=vv(co1(:)+vvl*(co2(:)-1)); % so vv is a column with the values of matching two mark points u to u -->1, u to d--> 0, d to s--> 0,5; vv1=3
                            vvp=reshape(vvp,luj,luk); % makes a matrix with 1 if the mark points in both photos have the same mark point category (up or down)
                            ddp=dd(co1(:)+vvl*(co2(:)-1));
                            ddp=reshape(ddp,luj,luk);
                            rmat=vvp.*exp(-((ones(luj,1)*xk-(ones(luk,1)*xj)').^2)./(2*((0.001+ddp).^2))); % for each of the mark points of the same type compares the position and gives a r value that represent whether they error distribution overlap
                            if luk>luj
                                rmat=rmat';
                            end
                            rr=sum(max(rmat))/(((lujnddu*compQVal(catqual-2))+ (luknddu*compQVal(qualPicTBM-2)))/(compQVal(catqual-2)+compQVal(qualPicTBM-2))); % adds all of the maximum r value for each possible combination and divides it by the greatest number of mark point and divide it so by the number of MP from the the ridge with the highest does count the extra bits as MP
                            nn=nn+1;
                            rq(nn)=rr;
                        end
                    end
                end
            end
        end
    elseif (p1==1 & p2==1 & p3==2 & p4==1) || (p1==1 & p2==1 & p3==1 & p4==2) % if (the 2nd ridge starts with an visible limit) OR (the 2nd ridge ends with an visible limit)
        if (length(ukr)-1)<=(length(ujr)+2*numwig) % only do the comparison if the ridge with the visible limit start or end (the second ridge) has at the maximum the same ammount of MP than the 1st ridge plus twice the amount of wiggle
            numMPxkexI=length(xkr)-1; % number of MP from the original 2nd ridge before adding the extra bits(ddu) it does not include the visible limit MP
            if p3==2 % if the 2nd ridge starts with an visible limit
                xkrt=(xkr(2:end)-xkr(2))/(xkr(end)-xkr(2)); % remove the visible limit point
                ukrt=ukr(2:end); % remove the visible limit point
                xkrt=1-fliplr(xkrt);
                ukrt=fliplr(ukrt);
                xjrt=1-fliplr(xjr); % for no reverse flip since the xkr is flipped
                ujrt=fliplr(ujr);
            elseif p4==2 % if the 2nd ridge ends with an visible limit
                xkrt=(xkr(1:(end-1))-xkr(1))/(xkr(end-1)-xkr(1)); % remove the visible limit point
                ukrt=ukr(1:(end-1)); % remove the visible limit point
                xjrt=xjr; % for no reverse not flipped since the xkr is not flipped
                ujrt=ujr;
            end

            for i=1:numwig % just adding the normal ddu wiggles like for when there is no visible limit
                xkrt=[(-ddu*i) xkrt (1+ddu*i)]; % adding the extra ends (ddu), 2nd photo
                ukrt=[mc ukrt mc]; % adding points for the extra bits they have the same value as visible limit ends, 2nd photo
            end

            if length(xjrt)>=(numMPxkexI+numwig) % If the 1st photo has at least the the same amount of MP than the number MP of the photo with visible limit + the amount numwig
                xjrt=(xjrt(1:(numMPxkexI+numwig))-xjrt(1))/(xjrt(numMPxkexI+numwig)-xjrt(1));
                ujrt=ujrt(1:(numMPxkexI+numwig));
                for i=1:numwig
                    xjrt=[(-ddu*i) xjrt];
                    ujrt=[mc ujrt];
                end

            elseif length(xjrt)<=numMPxkexI % If the 2nd photo has at the same number or a bit less (see fisrt if of this section) MP than the photo with the visible limit start
                for i=1:numwig
                    xjrt=[(-ddu*i) xjrt (1+ddu*i)];
                    ujrt=[mc ujrt mc];
                end

            else % If the 2nd photo an amount of MP in between the amount the photo with the visible limit start has and that amount plus 2*numwig
                for i=1:(numMPxkexI+numwig-length(xjrt))
                    xjrt=[xjrt (1+ddu*i)];
                    ujrt=[ujrt mc];
                end
                for i=1:numwig
                    xjrt=[(-ddu*i) xjrt];
                    ujrt=[mc ujrt];
                end
            end

            for i1=1:numwig*2+1 % for 1st photo of the comparison pair % might put this part before the for rev=1:2
                for i2=1:numwig*2+1
                    xj=(xjrt(i1:end-i2+1)-xjrt(i1))/(xjrt(end-i2+1)-xjrt(i1));
                    uj=(ujrt(i1:end-i2+1));
                    for i3=1:numwig*2+1% for 2nd photo of the comparison pair
                        for i4=1:numwig*2+1
                            xk=(xkrt(i3:end-i4+1)-xkrt(i3))/(xkrt(end-i4+1)-xkrt(i3));
                            uk=ukrt(i3:end-i4+1);
                            luj=length(uj);
                            luk=length(uk);
                            lujnddu=length(find(uj<4)); % counts the number of MP used without counting the extra bits
                            luknddu=length(find(uk<4)); % counts the number of MP used without counting the extra bits
                            co1=ones(luj,1)*uk; % makes a matrix with luj numbers of row, each row has the ukk data (markpoint type)
                            co2=(ones(luk,1)*uj)'; % makes a matrix with luk number of columns, each column has ujj data (markpoint type)
                            vvp=vv(co1(:)+vvl*(co2(:)-1)); % so vv is a column with the values of matching two mark points u to u -->1, u to d--> 0, d to s--> 0,5; vv1=3
                            vvp=reshape(vvp,luj,luk); % makes a matrix with 1 if the mark points in both photos have the same mark point category (up or down)
                            ddp=dd(co1(:)+vvl*(co2(:)-1));
                            ddp=reshape(ddp,luj,luk);
                            rmat=vvp.*exp(-((ones(luj,1)*xk-(ones(luk,1)*xj)').^2)./(2*((0.001+ddp).^2))); % for each of the mark points of the same type compares the position and gives a r value that represent whether they error distribution overlap
                            if luk>luj
                                rmat=rmat';
                            end
                            rr=sum(max(rmat))/(((lujnddu*compQVal(catqual-2))+ (luknddu*compQVal(qualPicTBM-2)))/(compQVal(catqual-2)+compQVal(qualPicTBM-2))); % adds all of the maximum r value for each possible combination and divides it by the greatest number of mark point
                            nn=nn+1;
                            rq(nn)=rr;
                        end
                    end
                end
            end

        else % if the amount of MP of the ridge with an visible limit is much more than the amount of MP than the ridge without the visible limit the match between these two ridges is unlikely and we give a rvalue of 0
            if p3==2 % if the 2nd ridge starts with an visible limit
                xkrt=(xkr(2:end)-xkr(2))/(xkr(end)-xkr(2)); % remove the visible limit point
                ukrt=ukr(2:end); % remove the visible limit point
            elseif p4==2 % if the 2nd ridge ends with an visible limit
                xkrt=(xkr(1:(end-1))-xkr(1))/(xkr(end-1)-xkr(1)); % remove the visible limit point
                ukrt=ukr(1:(end-1)); % remove the visible limit point
            end
            for i=1:numwig
                xjr=[(-ddu*i) xjr (1+ddu*i)]; % adding the extra ends (ddu), 1st photo
                xkr=[(-ddu*i) xkr (1+ddu*i)]; % adding the extra ends (ddu), 2nd photo
                ujr=[mc ujr mc]; % adding points for the extra bits they have the same value as visible limit ends, 1st photo
                ukr=[mc ukr mc]; % adding points for the extra bits they have the same value as visible limit ends, 2nd photo
            end
            for i1=1:numwig*2+1 % for 1st photo of the comparison pair
                for i2=1:numwig*2+1
                    xj=(xjr(i1:end-i2+1)-xjr(i1))/(xjr(end-i2+1)-xjr(i1));
                    uj=(ujr(i1:end-i2+1));
                    for i3=1:numwig*2+1 % for 2nd photo of the comparison pair
                        for i4=1:numwig*2+1
                            xk=(xkr(i3:end-i4+1)-xkr(i3))/(xkr(end-i4+1)-xkr(i3));
                            uk=(ukr(i3:end-i4+1));
                            luj=length(uj);
                            luk=length(uk);
                            lujnddu=length(find(uj<4)); % counts the number of MP used without counting the extra bits
                            luknddu=length(find(uk<4)); % counts the number of MP used without counting the extra bits
                            co1=ones(luj,1)*uk; % makes a matrix with luj numbers of row, each row has the ukk data (markpoint type)
                            co2=(ones(luk,1)*uj)'; % makes a matrix with luk number of columns, each column has ujj data (markpoint type)
                            vvp=vv(co1(:)+vvl*(co2(:)-1)); % so vv is a column with the values of matching two mark points u to u -->1, u to d--> 0, d to s--> 0,5; vv1=3
                            vvp=reshape(vvp,luj,luk); % makes a matrix with 1 if the mark points in both photos have the same mark point category (up or down)
                            ddp=dd(co1(:)+vvl*(co2(:)-1));
                            ddp=reshape(ddp,luj,luk);
                            rmat=vvp.*exp(-((ones(luj,1)*xk-(ones(luk,1)*xj)').^2)./(2*((0.001+ddp).^2))); % for each of the mark points of the same type compares the position and gives a r value that represent whether they error distribution overlap
                            if luk>luj
                                rmat=rmat';
                            end
                            rr=sum(max(rmat))/(((lujnddu*compQVal(catqual-2))+ (luknddu*compQVal(qualPicTBM-2)))/(compQVal(catqual-2)+compQVal(qualPicTBM-2))); % adds all of the maximum r value for each possible combination and divides it by the greatest number of mark point and divide it so by the number of MP from the the ridge with the highest does count the extra bits as MP
                            nn=nn+1;
                            rq(nn)=rr;
                        end
                    end
                end
            end
        end

    elseif (p1==2 & p2==1 & p3==2 & p4==1) || (p1==1 & p2==2 & p3==1 & p4==2) % if each of the ridges have an visible limit on the same section, remember ridge cannot have two visible limits!
        numMPxjexI=length(xjr)-1; % number of MP from the original 1st ridge before adding the extra bits(ddu) it does not include the visible limit MP
        numMPxkexI=length(xkr)-1; % number of MP from the original 2nd ridge before adding the extra bits(ddu) it does not include the visible limit MP
        compnumMP= [numMPxjexI numMPxkexI]; % to find which ridge has the smallest amount of point visible
        [minval posmin]=min(compnumMP); % to find which ridge has the smallest amount of point visible

        if p1==2 & p3==2 % if the 1st ridge start with an visible limit
            xjrt=(xjr(2:end)-xjr(2))/(xjr(end)-xjr(2)); % remove the visible limit point
            ujrt=ujr(2:end); % remove the visible limit point
            xjrt=1-fliplr(xjrt);
            ujrt=fliplr(ujrt);
            xkrt=(xkr(2:end)-xkr(2))/(xkr(end)-xkr(2)); % remove the visible limit point
            ukrt=ukr(2:end); % remove the visible limit point
            xkrt=1-fliplr(xkrt); % for no reverse flip since the xjr is flipped
            ukrt=fliplr(ukrt);
        elseif p2==2 & p4==2 % if the 1st ridge ends with an visible limit
            xjrt=(xjr(1:(end-1))-xjr(1))/(xjr(end-1)-xjr(1)); % remove the visible limit point
            ujrt=ujr(1:(end-1)); % remove the visible limit point
            xkrt=(xkr(1:(end-1))-xkr(1))/(xkr(end-1)-xkr(1)); % remove the visible limit point
            ukrt=ukr(1:(end-1)); % remove the visible limit point
        end

        % same number of MPs on the two ridges --> just add normal wiggles on
        % both sides
        if numMPxjexI == numMPxkexI
            for i=1:numwig % just adding the normal ddu wiggles like for when there is no visible limit
                xjrt=[(-ddu*i) xjrt (1+ddu*i)]; % adding the extra ends (ddu), 1st photo
                ujrt=[mc ujrt mc]; % adding points for the extra bits they have the same value as visible limit ends, 1st photo
                xkrt=[(-ddu*i) xkrt (1+ddu*i)]; % adding the extra ends (ddu), 2nd photo
                ukrt=[mc ukrt mc]; % adding points for the extra bits they have the same value as visible limit ends, 2nd phototo, reverse
            end

        elseif posmin==1 % if it's the 1st ridge (xj) that has the smallest amount of MP
            for i=1:numwig % just adding the normal ddu wiggles like for when there is no visible limit
                xjrt=[(-ddu*i) xjrt (1+ddu*i)]; % adding the extra ends (ddu), 1st photo
                ujrt=[mc ujrt mc]; % adding points for the extra bits they have the same value as visible limit ends, 1st photo
            end
            if length(xkrt)>=(numMPxjexI+numwig) % If the 2nd photo has at least the the same amount of MP than the number MP of the photo with visible limit + two times the amount numwig
                xkrt=(xkrt(1:(numMPxjexI+numwig))-xkrt(1))/(xkrt(numMPxjexI+numwig)-xkrt(1));
                ukrt=ukrt(1:(numMPxjexI+numwig));
                for i=1:numwig
                    xkrt=[(-ddu*i) xkrt];
                    ukrt=[mc ukrt];
                end
            else % If the 2nd photo an amount of MP in between the amount the photo with the visible limit start has and that amount plus 2*numwig
                for i=1:(numMPxjexI+numwig-length(xkrt))
                    xkrt=[xkrt (1+ddu*i)];
                    ukrt=[ukrt mc];
                end
                for i=1:numwig
                    xkrt=[(-ddu*i) xkrt];
                    ukrt=[mc ukrt];
                end
            end
        elseif posmin==2 % if it's the 2nd ridge that has the smallest amount of MP (if they both have the same amount of MP the 1st ridge comes as default)
            for i=1:numwig % just adding the normal ddu wiggles like for when there is no visible limit
                xkrt=[(-ddu*i) xkrt (1+ddu*i)]; % adding the extra ends (ddu), 2nd photo
                ukrt=[mc ukrt mc]; % adding points for the extra bits they have the same value as visible limit ends, 2nd photo
            end
            if length(xjrt)>=(numMPxkexI+numwig) % If the 2nd photo has at least the the same amount of MP than the number MP of the photo with visible limit + two times the amount numwig
                xjrt=(xjrt(1:(numMPxkexI+numwig))-xjrt(1))/(xjrt(numMPxkexI+numwig)-xjrt(1));
                ujrt=ujrt(1:(numMPxkexI+numwig));
                for i=1:numwig
                    xjrt=[(-ddu*i) xjrt];
                    ujrt=[mc ujrt];
                end
            else % If the 2nd photo an amount of MP in between the amount the photo with the visible limit start has and that amount plus 2*numwig
                for i=1:(numMPxkexI+numwig-length(xjrt))
                    xjrt=[xjrt (1+ddu*i)];
                    ujrt=[ujrt mc];
                end
                for i=1:numwig
                    xjrt=[(-ddu*i) xjrt];
                    ujrt=[mc ujrt];
                end
            end
        end
        for i1=1:numwig*2+1 % for 1st photo of the comparison pair
            for i2=1:numwig*2+1
                xj=(xjrt(i1:end-i2+1)-xjrt(i1))/(xjrt(end-i2+1)-xjrt(i1));
                uj=(ujrt(i1:end-i2+1));
                for i3=1:numwig*2+1 % for 2nd photo of the comparison pair
                    for i4=1:numwig*2+1
                        xk=(xkrt(i3:end-i4+1)-xkrt(i3))/(xkrt(end-i4+1)-xkrt(i3));
                        uk=ukrt(i3:end-i4+1);
                        luj=length(uj);
                        luk=length(uk);
                        lujnddu=length(find(uj<4)); % counts the number of MP used without counting the extra bits
                        luknddu=length(find(uk<4)); % counts the number of MP used without counting the extra bits
                        co1=ones(luj,1)*uk; % makes a matrix with luj numbers of row, each row has the ukk data (markpoint type)
                        co2=(ones(luk,1)*uj)'; % makes a matrix with luk number of columns, each column has ujj data (markpoint type)
                        vvp=vv(co1(:)+vvl*(co2(:)-1)); % so vv is a column with the values of matching two mark points u to u -->1, u to d--> 0, d to s--> 0,5; vv1=3
                        vvp=reshape(vvp,luj,luk); % makes a matrix with 1 if the mark points in both photos have the same mark point category (up or down)
                        ddp=dd(co1(:)+vvl*(co2(:)-1));
                        ddp=reshape(ddp,luj,luk);
                        rmat=vvp.*exp(-((ones(luj,1)*xk-(ones(luk,1)*xj)').^2)./(2*((0.001+ddp).^2))); % for each of the mark points of the same type compares the position and gives a r value that represent whether they error distribution overlap
                        if luk>luj
                            rmat=rmat';
                        end
                        rr=sum(max(rmat))/(((lujnddu*compQVal(catqual-2))+ (luknddu*compQVal(qualPicTBM-2)))/(compQVal(catqual-2)+compQVal(qualPicTBM-2))); % adds all of the maximum r value for each possible combination and divides it by the greatest number of mark point
                        nn=nn+1;
                        rq(nn)=rr;
                    end
                end
            end
        end
    elseif (p1==2 & p2==1 & p3==1 & p4==2) || (p1==1 & p2==2 & p3==2 & p4==1)
        numMPxjexI=length(xjr)-1; % number of MP from the original 1st ridge before adding the extra bits(ddu) it does not include the visible limit MP
        numMPxkexI=length(xkr)-1; % number of MP from the original 2nd ridge before adding the extra bits(ddu) it does not include the visible limit MP
        compnumMP= [numMPxjexI numMPxkexI]; % to find which ridge has the smallest amount of point visible
        [minval posmin]=min(compnumMP); % to find which ridge has the smallest amount of point visible

        if p1==2 & p4==2
            xjrt=(xjr(2:end)-xjr(2))/(xjr(end)-xjr(2)); % remove the visible limit point
            ujrt=ujr(2:end); % remove the visible limit point

            xkrt=(xkr(1:(end-1))-xkr(1))/(xkr(end-1)-xkr(1)); % remove the visible limit point
            ukrt=ukr(1:(end-1)); % remove the visible limit point

        elseif p2==2 & p3==2 % if the 1st ridge ends with an visible limit
            xjrt=(xjr(1:(end-1))-xjr(1))/(xjr(end-1)-xjr(1)); % remove the visible limit point
            ujrt=ujr(1:(end-1)); % remove the visible limit point
            xjrt=1-fliplr(xjrt);
            ujrt=fliplr(ujrt);

            xkrt=(xkr(2:end)-xkr(2))/(xkr(end)-xkr(2)); % remove the visible limit point
            ukrt=ukr(2:end); % remove the visible limit point
            xkrt=1-fliplr(xkrt);
            ukrt=fliplr(ukrt);
        end
        for i=minMPnum:compnumMP(posmin)
            xj=(xjrt(1:i)-xjrt(1))/(xjrt(i)-xjrt(1));%take the first MPs since the visible limit is at the beginning (p1=2)
            uj=ujrt(1:i);
            xk=(xkrt(end-i+1:end)-xkrt(end-i+1))/(xkrt(end)-xkrt(end-i+1));%take the last MP since the visible limit now is at the end  (since original ridge flipped)
            uk=ukrt(end-i+1:end);
            luj=length(uj); %the length has been decreased by the number of missing points (missj)
            luk=length(uk); %the length has been decreased by the number of missing points (missj)
            lujnddu=length(find(uj<4)); % counts the number of MP used without counting the extra bits
            luknddu=length(find(uk<4)); % counts the number of MP used without counting the extra bits
            co1=ones(luj,1)*uk; % makes a matrix with luj numbers of row, each row has the ukk data (markpoint type)
            co2=(ones(luk,1)*uj)'; % makes a matrix with luk number of columns, each column has ujj data (markpoint type)
            vvp=vv(co1(:)+vvl*(co2(:)-1)); % so vv is a column with the values of matching two mark points u to u -->1, u to d--> 0, d to s--> 0,5; vv1=3
            vvp=reshape(vvp,luj,luk); % makes a matrix with 1 if the mark points in both photos have the same mark point category (up or down)
            ddp=dd(co1(:)+vvl*(co2(:)-1));
            ddp=reshape(ddp,luj,luk);
            rmat=vvp.*exp(-((ones(luj,1)*xk-(ones(luk,1)*xj)').^2)./(2*((0.001+ddp).^2))); % for each of the mark points of the same type compares the position and gives a r value that represent whether they error distribution overlap
            if luk>luj
                rmat=rmat';
            end
            rr=sum(max(rmat))/(((lujnddu*compQVal(catqual-2))+ (luknddu*compQVal(qualPicTBM-2)))/(compQVal(catqual-2)+compQVal(qualPicTBM-2)));
            nn=nn+1;
            rq(nn)=rr;
        end
    end
end
r=max(rq);



function uiquit(obj,eventdata)
delete(findobj('tag','usel'));
delete(findobj('tag','primef'));
delete(findobj('tag','figx'));



function newwhale(obj,eventdata,xltx,urttx,sidecat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function newwhale gets called when you push on the button 'New Whale' in
% 'Figure 4: List of potential matches'. This function opens 'Figure 5: Are
% you sure that it is a new whale?', which ask you to confirm whether you
% want the photo you have processed to become a new whale in the catalogue.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
umatch1=figure; % open a 5th figure
set(umatch1,'Position',[45 45 600 300],'Menubar','none','tag','umatch','name','Are you sure that it is a new whale?');
umatchy=uicontrol(umatch1,'Style','pushbutton','position',[20 20 260 260],'string','NEW WHALE-YES','callback',{@matchgo,xltx,urttx,sidecat},'fontsize',20);
umatchn=uicontrol(umatch1,'Style','pushbutton','position',[320 20 260 260],'string','NEW WHALE-NO','callback','delete(gcf);','fontsize',20);

function matchgo(obj,eventdata,xltx,urttx,sidecat)
global num sizecat urtt xlt fileToBeM fgc noval catname startnum fg dcat ptx catqual cataside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function matchgo is called when you confirm that you want to give the
% ridge a new IDN (new whale) in the 'Figure 5: Are you sure that it is a
% new whale?'. This function replaces the info in fgc, urtt, and xlt for
% the ID matched and opens Figure 4: Info for new whale'.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% replaces the info in fgc, urtt, xlt, sidecat for the ID matched. The updated
% fgc, urtt, xlt, and catqual will be used for the next photo processed and fgc will
% eventually be loaded in the MS access tables.  
sizecat=sizecat+1; % sizecat is the number of rows in the cataloge, so it's adding a new row
fgc{sizecat,3}=num2str(urttx); % add MP types in a new row of fgc (Marktype column)
urtt{sizecat}=urttx; % add a new row to urtt which contains the MP types of the new whale
fgc{sizecat,4}=num2str(xltx); % add MP positions in the new row of fgc (Markpos column)
xlt{sizecat}=xltx; % enters a new row to xlt which contains the MP positions of the new whale
fgc{sizecat,5}=ptx; % add the value of the ridge the new row of fgc (Val column)
fgc{sizecat,6}=dcat; % add the area code in the new row of fgc (Area column)
fgc{sizecat,8}=fileToBeM; % add the filename of the new ridge in the new row of fgc (Filename column)
fgc{sizecat,10}=fg{2}; % add the position of the new ridge in the new row of fgc (Position column)
fgc{sizecat,11}=fg{5}; % add the quality of the new ridge in the new row of fgc (Quality column)
catqual{sizecat}=fg{5}; % enters a new row to catqual which contains the quality of the new whale
fgc{sizecat,12}=sidecat; % add the side of the photograph
cataside{sizecat}=sidecat; % enters a new row to cataside which contains the side of the new whale

delete(findobj('tag','umatch')); % deletes the previous figure (the figure asking NEW whale yes New whale no)
delete(findobj('tag','usel')); % deletes the figure: List of potential matches
umatch2=figure; % open a new figure
set(umatch2,'Position',[20 45 300 300],'Menubar','none','tag','umatch2','Name','Info for new whale');
umatcht=uicontrol(umatch2,'Style','text','position',[20 230 260 60],'string','Choose number, replace date and other inf.','fontsize',15);
timn=fg{4}; % date and time of the ridge matched
timnt={'Date & time'};
umatchdt=uicontrol(umatch2,'Style','text','position',[20 200 60 20],'string',timnt); % diplay in fig 4: Info for new whale the heading Date & time
umatchd=uicontrol(umatch2,'Style','edit','tag','umatchd','position',[90 200 180 20],'string',timn); % diplay in fig 4: Info for new whale the the date and time of the photos you are matching in the box
if strcmp(startnum,'Yes') % new ID number greater
    newnumber=find(num);
    newnumber=newnumber(end)+1;
else
    newnumber=find((~num)');
    newnumber=newnumber(1);
end
umatchet=uicontrol(umatch2,'Style','text','position',[60 75 180 20],'string','Extra info.:');
umatche=uicontrol(umatch2,'Style','edit','tag','extrainf','position',[20 50 260 20],'string',' '); % allows you to enter extra information
umatchg=uicontrol(umatch2,'Style','pushbutton','position',[170 110 100 80],'string','DONE','fontsize',15,'callback',{@donecat,xltx,urttx});
unewnumt=uicontrol(umatch2,'Style','text','position',[20 20 100 20],'string','New number');        
unewnum=uicontrol(umatch2,'Style','edit','tag','nummmw','position',[125 20 60 20],'string',num2str(newnumber),'callback',{@checknum,newnumber});


function donecat(obj,eventdata,xltx,urttx)
global noot num sizecat urtt xlt fgc noval catname startnum fg  connd cdbtable conn dbtable dcat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function donecat uploads the information in the MS access catalogue
% table. It gets call when you push on the button DONE from the 'Figure 4:
% Info for new whale' in function matchgo and function newrow.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

catalog(sizecat)=dcat; % area
noot(sizecat)=str2num(get(findobj('tag','nummmw'),'string')); % Places the new IDN in the noot array which has the IDN already in the catalog table
num(noot(sizecat))=sizecat;

fgc{sizecat,7}=get(findobj('tag','umatchd'),'string'); % adds the date and time from the fig 4: Info for new whale (either from the photo you are matching or that you entered manually)
fgc{sizecat,9}=get(findobj('tag','extrainf'),'string'); % In Extrainf column of the new row of the catalog table (fr extra information)
delete(findobj('tag','umatch2')); % delete figure: Info for new whale
fgc{sizecat,2}=noot(sizecat);
fgc{sizecat,1}=max([fgc{:,1}])+1; %this is calculating which autonumber in the first column (ID) of table of the MS access catalague table. This migth not work if you just delted row in this catalogue tabe and did not reset the ID column.


% This section actually updates the information in the MS access catalogue
% table. This section migth cause problem with earlier version of MATLAB. I
% think the error in earlier version is caused by the creation of the to
% field Marktype and Markpos, which are memo fields in MS Access. Memo
% field seem to be a problem when you export a field that has more than 255
% char. You can use the update function (which is used below for the match
% table) to fix this. 
colnames={'IDN','Marktype','Markpos','Val','Area','Datel','Filename','Extrainf','Position','Quality','Side'};
insert(connd,cdbtable,colnames,{fgc{sizecat,2:12}}); % Exports MATLAB cell array data into MS Access catalogue table. INSERT(CONNECT,TABLENAME,FIELDNAMES,DATA).
 
% This section updates the MS access match table. It enters the IDN for the
% photo you just matched.
colnames={'IDN'};
newid(1,1)={noot(sizecat)};
wherestr=['where EncounterID= ''' fg{8} ''' AND Encounter= ''' fg{3} '''']; % SQL statement: where the column EncounterID is equal to the ridge matched and in the same encounter
update(conn,dbtable,colnames,newid,wherestr);

uiquit;
delete(findobj('tag','umain'));



function dopic(obj,eventadat,noot,ind,ispic,ifork,I,sidecat) 
global numshown xq fgc picloc catIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function dopic opens 'Figure 5: Potential match --> ID: ' which is the
% figure that has photos (1 or 2) of the potential match the user chose
% from the lis by clicking on the ID.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lisn=get(obj,'value');%returns the number in the list of the photo
catIndex=fgc(ind(lisn));%catalogue index (ID column in MS access Catalogue Table). This is a way to store the exact row for which you match a photograph. It is used by other functions.
IDN=noot(ind(lisn));% the IDN of the photo from the list of potential matches to be looked at
idnInCat=find([fgc{:,2}]==IDN); %gives the index from fgc for all rows with with the ID chosen from the list
set(findobj('tag','unum'),'string',num2str(IDN)); %tag unum is how the ID number to be matched to is stored, it adds the value in the ID boc in 'Figure 4: List of potential matches'
sideOfChosenP=fgc{ind(lisn),12};% Side of the picture you chose in the list
if strcmp(sideOfChosenP,'R')% finnds what is the other side of the picture chosen
    otherSideP='L';
else
    otherSideP='R';
end
locOtherS=[];
if length(idnInCat==IDN)>1 % checking if more than one row with the same individual in the catalogue
    if ~isempty(find(strcmp(fgc(idnInCat,12),otherSideP)))% checking there is a photo from the other side of the individual in the catalogue
        indexOtherS=fgc{idnInCat(find(strcmp(fgc(idnInCat,12),otherSideP),1)),1};
        sideOfOtherP=otherSideP;
        fileOtherS=fgc{find([fgc{:,1}]==indexOtherS),8}; % getting the file name for the other side of the narwhal
        locOtherS=[picloc fileOtherS];
    end
end
if ispic(lisn) ||  exist(locOtherS)>0 % only opens figures if the one of the images are available
    numshown=numshown+1;
    cc=ind(lisn); 
    if ispic(lisn) &&  exist(locOtherS)>0 % only opens figures if the images are available there is a photo of the other side in the catalogue     
            [dum,ftype]=strtok(ifork{lisn},'.'); % ifork is the name of the file in the list of potential matches
            xq{numshown}=imread(ifork{lisn},ftype(2:end)); 
            xqSide=sideOfChosenP;
            [dum,ftype]=strtok(locOtherS,'.'); % getting the file type for this file
            otherSim=imread(locOtherS,ftype(2:end)); % need to add it somewhere
            osiSide=sideOfOtherP;
    elseif ispic(lisn) %if only the photograph you chose is on the computer
            [dum,ftype]=strtok(ifork{lisn},'.'); % ifork is the name of the file in the list of potential matches
            xq{numshown}=imread(ifork{lisn},ftype(2:end)); 
            xqSide=sideOfChosenP;
            for k=1:3
                flipPhoto(:,:,k)=fliplr(xq{numshown}(:,:,k));
            end
    elseif exist(locOtherS)>0 %if only the photograph of the other side is on the computer
        [dum,ftype]=strtok(locOtherS,'.'); % getting the file type for this file
        xq{numshown}=imread(locOtherS,ftype(2:end)); % need to add it somewhere
        xqSide=sideOfOtherP;                    
        for k=1:3
            flipPhoto(:,:,k)=fliplr(xq{numshown}(:,:,k));
        end
    end
    
    % part that actually opens the 'Figure 5: Potential match --> ID: #'
    hs(numshown)=figure;
    iiid(numshown)=str2num(get(findobj('tag','unum'),'String')); %gets the ID number
    set(hs(numshown),'Position',[15 40 1000 400],'Name', ['Potential match --> ID: ' num2str(iiid(numshown))]); %sets the window, its size and position
    retxt={'',' REVERSED!'};
    idaxes = axes('Position',[0 0 0.06 1],'Visible','off');
    text(0.01,0.9,['ID: ' num2str(iiid(numshown))],'FontSize',15);
    if ispic(lisn) &&  exist(locOtherS)>0
        subplot(2,1,1), image(xq{numshown},'CDatamap','scaled');
        axis equal;
        axis tight;
        showaxes('off');
        set(gca,'Position',[0.06 0.5 0.94 0.5]);
        tqq=text (20,40,[xqSide]); % place the text
        set(tqq,'fontsize',14,'tag','numb');
        subplot(2,1,2), image(otherSim,'CDatamap','scaled');
        axis equal;
        axis tight;
        showaxes('off');
        set(gca,'Position',[0.06 0 0.94 0.5]);         
        tqq=text (20,40,[osiSide]); % place the text
        set(tqq,'fontsize',14,'tag','numb');
    else
        subplot(2,1,1), image(xq{numshown},'CDatamap','scaled');
        axis equal;
        axis tight;
        showaxes('off');
        set(gca,'Position',[0.06 0.5 0.94 0.5]); %change the position of the picture in the window (gca: get current axes handle)
        tqq=text(20,40,[xqSide]); % place the text
        set(tqq,'fontsize',14,'tag','numb');
        subplot(2,1,2), image(flipPhoto,'CDatamap','scaled');
        axis equal;
        axis tight;
        showaxes('off');
        set(gca,'Position',[0.06 0 0.94 0.5]); %change the position of the picture in the window (gca: get current axes handle)
        tqq=text(20,40,[xqSide ' Reverse']); % place the text
        set(tqq,'fontsize',14,'tag','numb');
    end
    if ~strcmp(fgc{I(lisn),10},'Null')% If more than one narwhal in the photograph you chose
        uposition=uicontrol(hs(numshown),'Style','text','fontsize',12,'position',[10 280 100 30],'string',['Position: ' fgc{I(lisn),10}]);    
    end
    if  exist(locOtherS)>0 
        if ~strcmp(fgc{find([fgc{:,1}]==indexOtherS),10},'Null')% If there is a photo of the other side and there is more than one narwhal
            uposition=uicontrol(hs(numshown),'Style','text','fontsize',12,'position',[10 80 100 30],'string',['Position: ' fgc{find([fgc{:,1}]==indexOtherS),10}]);    
        end
    end
end


function newnum(obj,evendata,ispicw,sidecat)
global fgc catIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function newnum verifies whether the ID number that is typed (not
% automatically entered) in the ID box of 'Figure 4: List of potential
% matches' is one of the ID number in the catalogue.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
boxCatIndex=find([fgc{:,2}]==str2num(get(obj,'String'))); % its not the ID column it's just the order in fgc
boxSideIndex=find([fgc{boxCatIndex,12}]==sidecat);% check whether the sides of that indvidual in the catalogue matches with the side of the narwhal to match
if isempty(boxCatIndex) % check if there is the ID number that was entered in the ID box in 'Figure 4: List of potential matches'
    nott=uicontrol(gcf,'Style','text','position',[140 7 400 37],'String',['The ID ' get(obj,'String') ' is not in the catalogue database. Choose another ID number or make a new ID by pressing on New Whale!']);
    pause(6);
    delete(nott);
elseif ~isempty(boxSideIndex) % if this ID is in the catalogue check whether the side is in the catalogue also
        catIndex = fgc(boxCatIndex(boxSideIndex(1)),1); % choose the 1st row in the catalogue that has the good side
else % if ID is in the catalogue but there is not the good side
    catIndex = fgc(boxCatIndex(1),1); % Choose the 1st individual in the catalogue with the good ID
end


function checknum(obj,eventdata,newnumber)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function checknum verifies whether the ID number is already used in
% the catalogue.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global num
if num(str2num(get(obj,'string')))
    set(obj,'string','Used number');
    pause(2);
    set(obj,'string',num2str(newnumber));
end


function matchrun(obj,eventdata,xltx,urttx,sidecat)
global fgc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function matchrun makes a figure which ask you whether you are sure you
% want to match the whale to that individual of the catalogue.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
iidn=str2num(get(findobj('tag','unum'),'String'));
if ~isempty(iidn)% Make sure there is a number in ID box in 'Figure 4: List of potential matches' 
    boxCatIndex=find([fgc{:,2}]==iidn);
    if isempty(boxCatIndex); % Make sure that this ID is in the catalogue
        uiwait(msgbox(['The ID ' num2str(iidn) ' is not in the catalogue.'],'ERROR','modal'));
    else
        umatch1=figure;
        set(umatch1,'Position',[45 45 600 300],'Menubar','none','tag','umatch1');
        umatchy=uicontrol(umatch1,'Style','pushbutton','position',[20 20 260 260],'string','MATCH-YES','callback',{@matchit,xltx,urttx,sidecat},'fontsize',20);
        umatchn=uicontrol(umatch1,'Style','pushbutton','position',[320 20 260 260],'string','MATCH-NO','callback','delete(findobj(''tag'',''umatch1''));','fontsize',20);
    end
else %if no number in the id box
    uiwait(msgbox(['You did not specified an ID.'],'ERROR','modal'));
end

function matchit(obj,eventdata,xltx,urttx,sidecat)
global fgc catIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function matchit either add call the function new row if the photograph
% to be matched and the photogarh in the catalogue are of the same side or
% opens 'Figure 5: Add this new side of # to the catalogue?'. Which ask you
% whether there migth be an error in side assignment.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
delete(findobj('tag','umatch1')); % delete the figure that ask you if you are sure you want to match this photo

iidn=str2num(get(findobj('tag','unum'),'String')); % get the id from the id box in 'Figure 4: List of potential matches'
rowWithID=find([fgc{:,1}]==catIndex{:}); % get the actual line in the MS catalogue table
if length(rowWithID)==1 & ~strcmp(fgc{rowWithID(1),12},sidecat)
    umatch2=figure;
    sideInCatNS=fgc{rowWithID(1),12};
    set(umatch2,'Position',[45 45 600 300],'tag','umatch2', 'Menubar','none','name',['Add this new side of ' num2str(iidn) ' to the catalogue?']);
    umatchr=uicontrol(umatch2,'Style','pushbutton','position',[20 20 260 260],'tag','1','string','ADD NEW SIDE','callback',{@newrow,xltx,urttx,sidecat},'fontsize',15);
    umatchk=uicontrol(umatch2,'Style','pushbutton','position',[320 20 260 260],'tag','0','string','SIDE ASSIGNMENT ERROR','callback',{@sideass,xltx,urttx,sidecat,iidn,sideInCatNS},'fontsize',15);    
else
    newrow(obj,eventdata,xltx,urttx,sidecat);
end



function newrow(obj,eventdata,xltx,urttx,sidecat)
global sizecat urtt xlt fileToBeM fgc noval catname startnum fg dcat ptx catqual cataside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function newrow is called when you confirm that the narwhal you want to
% match is found in the catalogue. This function replaces the info in fgc,
% urtt, and xlt for the  ID matched to form a new row in the catalogue and
% deals with fig.5:Info for new side. It is call from function matchit.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iidn=str2num(get(findobj('tag','unum'),'String')); %gets the ID (new or from catalogue) to which you match the photo 

% replaces the info in fgc, urtt, xlt, sidecat for the ID matched. The updated
% fgc, urtt, xlt, and catqual will be used for the next photo processed and fgc will
% eventually be loaded in the MS access tables.  
sizecat=sizecat+1; % sizecat is the number of rows in the cataloge, so it's adding a new row
fgc{sizecat,2}=iidn;
fgc{sizecat,3}=num2str(urttx); % add MP types in a new row of fgc (Marktype column)
urtt{sizecat}=urttx; % add a new row to urtt which contains the MP types of the new whale
fgc{sizecat,4}=num2str(xltx); % add MP positions in the new row of fgc (Markpos column)
xlt{sizecat}=xltx; % enters a new row to xlt which contains the MP positions of the new whale
fgc{sizecat,5}=ptx; % add the value of the ridge the new row of fgc (Val column)
fgc{sizecat,6}=dcat; % add the area code in the new row of fgc (Area column)
fgc{sizecat,8}=fileToBeM; % add the filename of the new ridge in the new row of fgc (Filename column)
fgc{sizecat,10}=fg{2}; % add the position of the new ridge in the new row of fgc (Position column)
fgc{sizecat,11}=fg{5}; % add the quality of the new ridge in the new row of fgc (Quality column)
catqual{sizecat}=fg{5}; % enters a new row to catqual which contains the quality of the new whale
fgc{sizecat,12}=sidecat; % add the side of the photograph
cataside{sizecat}=sidecat; % enters a new row to cataside which contains the side of the new whale

delete(findobj('tag','umatch1')); % deletes fig Assigment error
delete(findobj('tag','umatch2')); % deletes the previous figure Fig 5. : ADD...
delete(findobj('tag','usel')); % deletes the figure: List of potential matches
umatch2=figure; % open a new figure
set(umatch2,'Position',[20 45 300 300],'Menubar','none','tag','umatch2','Name','Info for new whale');
umatcht=uicontrol(umatch2,'Style','text','position',[20 230 260 60],'string','Replace date and other inf.','fontsize',15);
timn=fg{4}; % date and time of the ridge matched
timnt={'Date & time'};
umatchdt=uicontrol(umatch2,'Style','text','position',[20 200 60 20],'string',timnt); % diplay in fig 4: Info for new whale the heading Date & time
umatchd=uicontrol(umatch2,'Style','edit','tag','umatchd','position',[90 200 180 20],'string',timn); % diplay in fig 4: Info for new whale the the date and time of the photos you are matching in the box

umatchet=uicontrol(umatch2,'Style','text','position',[60 75 180 20],'string','Extra info.:');
umatche=uicontrol(umatch2,'Style','edit','tag','extrainf','position',[20 50 260 20],'string',' '); % allows you to enter extra information
umatchg=uicontrol(umatch2,'Style','pushbutton','position',[170 110 100 80],'string','DONE','fontsize',15,'callback',{@donecat,xltx,urttx});
unewnumt=uicontrol(umatch2,'Style','text','position',[20 20 100 20],'string','ID: ');        
unewnum=uicontrol(umatch2,'Style','text','tag','nummmw','position',[125 20 60 20],'string',num2str(iidn));

function sideass(obj,eventdata,xltx,urttx,sidecat,iidn,sideInCatNS)
global fgc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function sideass is called if the user feels that there is error in
% either the side assignement of the individual in the catalogue or for the
% narwhal to be matched. It opens 'Figure 5: Side assignment problems'. It
% is called in function matchit if you press on button 'SIDE ASSIGNMENT
% ERROR' in 'Figure 5: Add this new side of # to the catalogue?' 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
delete(findobj('tag','umatch2'));
umatch1=figure; % open a new figure
set(umatch1,'Position',[20 45 340 300],'Menubar','none','tag','umatch1','Name','Side assignment problems');

ttss=uicontrol(umatch1,'Style','text','position',[20 280 300 15],'string',['The side you chose for ID ' num2str(iidn) ' in the catalogue is: ' sideInCatNS]);
ttss=uicontrol(umatch1,'Style','text','position',[20 265 300 15],'string',['The side of the narwhal to be matched is: ' sidecat]);        
ttss=uicontrol(umatch1,'Style','text','position',[20 235 260 20],'string',['Are these two photos of the same side?'],'fontsize',12);
ttss=uicontrol(umatch1,'Style','text','position',[25 205 50 20],'string',['If yes:'],'fontsize',12);
ttss=uicontrol(umatch1,'Style','text','position',[30 175 240 20],'string',['Which one has the good side assigned?'],'fontsize',12);
uissycat=uicontrol(umatch1,'Style','pushbutton','position',[40 150 220 20],'string',['Catalogue has the good side'],'callback',{@matchit,1-fliplr(xltx),fliplr(urttx),sideInCatNS}); % so changes the value of sidecat with the value from sideInCatNS
uissyntbm=uicontrol(umatch1,'Style','pushbutton','position',[40 125 220 20],'string',['Narwhal to be matched has the good side'],'callback',{@sideerror,xltx,urttx,sidecat,iidn,sideInCatNS,1});
ttss=uicontrol(umatch1,'Style','text','position',[25 95 50 20],'string',['If no:'],'fontsize',12);
ttss=uicontrol(umatch1,'Style','text','position',[30 65 240 20],'string',['Are they well assigned?'],'fontsize',12);
uissnnotrev=uicontrol(umatch1,'Style','pushbutton','position',[40 40 220 20],'string',['Yes, they are well assigned'],'callback',{@newrow,xltx,urttx,sidecat});
uissnrev=uicontrol(umatch1,'Style','pushbutton','position',[40 15 220 20],'string',['No, they are reverse'],'callback',{@sideerror,xltx,urttx,sidecat,iidn,sideInCatNS,2});

function sideerror(obj,eventdata,xltx,urttx,sidecat,iidn,sideInCatNS,typeSideError)
global fgc connd cdbtable catIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function sideerror is called if the user decides that there is an error
% in the catalogue and press on either 'Narwhal to be matched has the good
% side' or 'No, they are reverse' in Figure : Side assigiment problems'. It
% changes the side in the MS access table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fgcIndex=find([fgc{:,1}]==catIndex{:});
catMPvalO=fgc{fgcIndex,3}; %finding the Marktyp cell value in catalogue
catMPvalN=fliplr(catMPvalO); % fliping the values
fgc{fgcIndex,3}=catMPvalN;
catMPPosO=str2num(fgc{fgcIndex,4}); % finding the Markpos cell value in catalogue
catMPPosN=num2str(1-fliplr(catMPPosO)); % changing so the distance is from the good front end of the ridge
fgc{fgcIndex,4}=catMPPosN;
fgc{fgcIndex,12}=sidecat;

wherestr=['where ID= ' num2str(catIndex{:}) ]; 
colnames={'Marktype'};
update(connd,cdbtable,colnames,{catMPvalN},wherestr);
colnames={'Markpos'};
update(connd,cdbtable,colnames,{catMPPosN},wherestr);
colnames={'Side'};
update(connd,cdbtable,colnames,{sidecat},wherestr);
if typeSideError==2 % if both the narwhal to be matches and the catalogue have side errors
    sidecat=sideInCatNS;
    xltx=1-fliplr(xltx);
    urttx=fliplr(urttx);
    newrow(obj,eventdata,xltx,urttx,sidecat)
else %if only the catalogue has a side error
    matchit(obj,eventdata,xltx,urttx,sidecat);
end