function varargout = CSS(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @CSS_OpeningFcn, ...
    'gui_OutputFcn',  @CSS_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function CSS_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>

load icons_CSS.mat c jp
handles.createFiles.CData = c{1};
handles.Run.CData         = c{2};
handles.Undock.CData      = c{3};
handles.wand.CData        = c{4};

xlabel(handles.ax2,'T (s)','fontsize',8); ylabel(handles.ax2,'UHS (g)','fontsize',8)
xlabel(handles.ax3,'T (s)','fontsize',8); ylabel(handles.ax3,'CMS (g)','fontsize',8)
xlabel(handles.ax4,'T (s)','fontsize',8); ylabel(handles.ax4,'Sa (g)','fontsize',8)
handles.methodpop.String={'Method 1'};
handles.methodpop.TooltipString='Approximate CS Using Mean M & R and a single GMPM';

if nargin>3
    handles.sys  = varargin{1};
    handles.opt  = varargin{2};
    handles.h    = varargin{3};
    handles      = InitializeCss(handles);
    
    % -------------------------------------------------------------------------
    n=max(handles.sys.branch,[],1);
    if not(strcmp(handles.opt.MagDiscrete{1},'uniform') && handles.opt.MagDiscrete{2}==0.1)
        handles.opt.MagDiscrete = {'uniform',0.1};
        for i=1:n(3)
            handles.sys.mrr2(i) = process_truncexp  (handles.sys.mrr2(i) , handles.opt.MagDiscrete);
            handles.sys.mrr3(i) = process_truncnorm (handles.sys.mrr3(i) , handles.opt.MagDiscrete);
            handles.sys.mrr4(i) = process_yc1985    (handles.sys.mrr4(i) , handles.opt.MagDiscrete);
            handles.sys.mrr6(i) = process_catalog   (handles.sys.mrr6(i) , handles.sys.area1(i),handles.opt.MagDiscrete);
        end
        for i=1:n(1)
            handles.sys.area1(i).rclust=process_rclust(handles.sys,handles.sys.area1(i),i);
        end
    end
    %--------------------------------------------------------------------------
    
    
else
    handles.pop_site.Enable='off';
    handles.pop_branch.Enable='off';
    ch=findall(handles.figure1,'style','pushbutton');
    set(ch,'Enable','inactive');
end
guidata(hObject, handles);
% uiwait(handles.figure1);

function varargout = CSS_OutputFcn(hObject, eventdata, handles)
varargout{1} = [];

function CSS_options_Callback(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>
[handles.param,handles.Tcss,handles.AEP,handles.corrV,handles.flatfile,handles.Npreselect] = ...
    CSS_AlAtik(handles.param,handles.Tcss,handles.AEP,handles.corrV,handles.flatfile);
guidata(hObject,handles)

function createFiles_Callback(hObject, eventdata, handles)

if isempty(handles.flatfile)
    return
end

fig = handles.figure1;
delete(findall(fig,'type','line'));
delete(findall(fig,'tag','patch'));
delete(findall(fig,'tag','legend_ax1'));
set(findall(fig,'type','axes'),'ColorOrderIndex',1);
set(fig, 'WindowButtonMotionFcn', '');
drawnow

site_ptr   = handles.pop_site.Value;
branch_ptr = handles.pop_branch.Value;

h.id    = handles.h.id(site_ptr,:);
h.p     = handles.h.p(site_ptr,:);
h.param = handles.h.param;
h.value = handles.h.value(site_ptr,:);

Tcss       = handles.Tcss;
NTcss      = length(Tcss);
AEP        = handles.AEP;
branch     = handles.sys.branch(branch_ptr,:);
sources    = buildmodelin(handles.sys,branch,handles.opt.ShearModulus);
Nsource    = length(sources);
im1        = repmat(logsp(0.01,3,10)',1,NTcss);
lambda1    = runhazard1(im1,Tcss,h,handles.opt,sources,Nsource,1);
lambda1    = permute(nansum(lambda1,4),[2 3 1]);
im1        = ExtrapHazard(im1,lambda1,AEP);
Nim        = size(im1,1);
lambda1    = runhazard1(im1,Tcss,h,handles.opt,sources,Nsource,1);
lambda1    = permute(nansum(lambda1,4),[2 3 1]);
lambda2    = nan(Nim,NTcss);
patch('parent',handles.ax1,'vertices',[im1([1 end end 1])',AEP([1 1 end end])],'faces',1:4,'edgecolor','none','facecolor',[1 0.97 0.97],'tag','patch','handlevisibility','off');
plot(handles.ax1,im1(:,1),lambda1(:,1),'linewidth',1,'tag','haz1');
plot(handles.ax1,im1(:,1),lambda2(:,1),'linewidth',1,'tag','haz2');
handles.xlabel1.String=sprintf('Sa(T=%g)',Tcss(1));
handles.ylabel1.String=['\lambda Sa',sprintf('(T=%g)',Tcss(1))];

L = legend(handles.ax1,'Analytic','CSS-recovered');
L.Location = 'SouthWest';
L.Box      = 'off';
L.Visible  = 'off';
L.Tag      = 'legend_ax1';
handles.ax1.XLim = [0.01,10];
handles.ax1.YLim = 10.^[log10(min(AEP)) ceil(log10(max(lambda1(:))))];
handles.im1      = im1;
handles.lambda1  = lambda1;
handles.lambda2  = lambda1*nan;
handles.ax1.Layer='top';
drawnow
cols = linspace(0.85,0,NTcss)';
cols = repmat(cols,1,3);
[uhs_spec,cms_spec,sigma_css,rho_css] = deal(zeros(NTcss,length(AEP)));


optCMS           = handles.opt;
optCMS.model_ptr = handles.pop_branch.Value;
optCMS.Tcond     = str2double(handles.param{2});
optCMS.T         = Tcss;
optCMS.Rbin      = handles.Rbin;
optCMS.Mbin      = handles.Mbin;
optCMS.cfun      = handles.corrV;

for i=1:length(AEP)
    optCMS.Tr      = 1/AEP(i);
    %data           = runCMS_m1_CSS(handles,im1,lambda1,Tr,h,sources);
    cmsdata        = runCMS_method1(handles.sys,optCMS,h);
    
    uhs_spec(:,i)  = cmsdata.UHS;
    cms_spec(:,i)  = cmsdata.CMS(:,1);
    sigma_css(:,i) = cmsdata.sigCMS;
    rho_css(:,i)   = cmsdata.RHO;
    plot(handles.ax2,Tcss,uhs_spec(:,i),'color',cols(i,:),'linewidth',1);drawnow
    plot(handles.ax3,Tcss,cms_spec(:,i),'color',cols(i,:),'linewidth',1);drawnow
end

handles.ax2.Layer='top';
handles.ax3.Layer='top';
handles.ax2.XLim=[0.99*Tcss(1),1.01*Tcss(end)];
handles.ax3.XLim=[0.99*Tcss(1),1.01*Tcss(end)];
handles.ax4.XLim=[0.99*Tcss(1),1.01*Tcss(end)];
nameUHS = 'inCSS1';
nameCMS = 'inCSS2';
D = cd;
W=what('platform_css');
cd(W.path)
[~,nameCSV]=fileparts(handles.flatfile);
CreateDRV_CSS(handles.param,nameCSV);
CreateUHS_CSS(Tcss,AEP,uhs_spec,nameUHS);
CreateCMS_CSS(Tcss,AEP,uhs_spec,sigma_css,rho_css,nameCMS);
cd(D)
guidata(hObject,handles)

function Run_Callback(hObject, eventdata, handles)

if isempty(handles.flatfile) || isempty(handles.im1)
    warndlg('No flatfile defined')
    return
end

if handles.Npreselect==0
    warndlg('No ground motions fit the search criterion')
    return
end

if handles.Npreselect>990
    warndlg('More than 990 ground motions candidates found; narrow search')
    return
end

W=what('platform_css');
D=cd;
cd(W.path)
system('Css.exe');
cd(D)

fid = fopen('H.txt');       data = textscan(fid,'%s','delimiter','\n'); data = data{1};fclose(fid); handles.H      = data;
fid = fopen('inCSS1.out3'); data = textscan(fid,'%s','delimiter','\n'); data = data{1};fclose(fid); handles.inCSS1 = data;
fid = fopen('inCSS2.txt');  data = textscan(fid,'%s','delimiter','\n'); data = data{1};fclose(fid); handles.inCSS2 = data;
fid = fopen('inCSS3.sum');  data = textscan(fid,'%s','delimiter','\n'); data = data{1};fclose(fid); handles.inCSS3 = data;
fid = fopen('inCSS4.out1'); data = textscan(fid,'%s','delimiter','\n'); data = data{1};fclose(fid); handles.inCSS4 = data;
fid = fopen('inCSS5.out2'); data = textscan(fid,'%s','delimiter','\n'); data = data{1};fclose(fid); handles.inCSS5 = data;
fid = fopen('inCSS6.out3'); data = textscan(fid,'%s','delimiter','\n'); data = data{1};fclose(fid); handles.inCSS6 = data;
fid = fopen('inCSS7.out4'); data = textscan(fid,'%s','delimiter','\n'); data = data{1};fclose(fid); handles.inCSS7 = data;
fid = fopen('inCSS8.out5'); data = textscan(fid,'%s','delimiter','\n'); data = data{1};fclose(fid); handles.inCSS8 = data;

[T,eq]       = readCSS_Output(handles);
handles.T    = T;
handles.eq   = eq;
SA           = vertcat(eq.SA);

delete(findall(handles.ax4,'type','line'));
handles.ax4.ColorOrderIndex=1;
plot(handles.ax4,handles.T,SA,'color',[1 1 1]*0.7)
handles.ax4.Layer='top';
handles.ax4.YLim = 10.^[floor(log10(min(SA(:)))),ceil(log10(max(SA(:))))];
delete(findall(handles.figure1,'tag','redline'))
dline(1)=plot(handles.ax2,[nan nan],handles.ax2.YLim,'r-','tag','redline');
dline(2)=plot(handles.ax3,[nan nan],handles.ax3.YLim,'r-','tag','redline');
dline(3)=plot(handles.ax4,[nan nan],handles.ax4.YLim,'r-','tag','redline');

%% hazard curve recovery
z = handles.im1(:,1)';
Tcss  = handles.Tcss;
NTcss = length(Tcss);
rate  = vertcat(eq.rate);
for i=1:NTcss
    [~,ind2]= min(abs(handles.T-handles.Tcss(i)));
    handles.lambda2(:,i) = (SA(:,ind2)>z)'*rate;
end

ch=findall(handles.figure1,'tag','legend_ax1');
ch.Visible='on';
haz1 = findall(handles.ax1,'tag','haz1');
haz2 = findall(handles.ax1,'tag','haz2');
set (handles.figure1, 'WindowButtonMotionFcn', {@mouseMove,handles,dline,haz1,haz2});

guidata(hObject,handles)

function mouseMove(hObject,eventdata,handles,dline,haz1,haz2)
tf3     = false;
tf4     = false;
[t1,t2] = getAbsCoords(handles.ax2);
tf2     = coordsWithinXYLimits(handles.ax2, t1,t2);
if ~tf2
    [t1,t2] = getAbsCoords(handles.ax3);
    tf3     = coordsWithinXYLimits(handles.ax3, t1,t2);
end

if ~tf2 && ~tf3
    [t1,t2] = getAbsCoords(handles.ax4);
    tf4     = coordsWithinXYLimits(handles.ax4, t1,t2);
end

if any([tf2 tf3 tf4])
    Tcss=handles.Tcss;
    [~,ind] = min(abs(Tcss-t1));
    set(dline(1:3),'XData',[1 1]*Tcss(ind));
    haz1.YData = handles.lambda1(:,ind);
    haz2.YData = handles.lambda2(:,ind);
    handles.ax2.YLim=dline(1).YData;
    handles.ax3.YLim=dline(2).YData;
    handles.ax4.YLim=dline(3).YData;
    handles.xlabel1.String=sprintf('Sa(T=%g)',Tcss(ind));
    handles.ylabel1.String=['\lambda Sa',sprintf('(T=%g)',Tcss(ind))];
    
    
end

function [x, y] = getAbsCoords(h_ax)
crd = get(h_ax, 'CurrentPoint');
x = crd(2,1);
y = crd(2,2);

function tf = coordsWithinXYLimits(h_ax, x,y)
XLim = h_ax.XLim;
YLim = h_ax.YLim;
tf1 = x>XLim(1) && x<XLim(2);
tf2 = y>YLim(1) && y<YLim(2);
tf  = tf1&tf2;

function pop_site_Callback(hObject, eventdata, handles)

function pop_branch_Callback(hObject, eventdata, handles)

function methodpop_Callback(hObject, eventdata, handles)

hObject.TooltipString=handles.tts{hObject.Value};
if hObject.Value~=1
    handles.pop_branch.Enable='off';
else
    handles.pop_branch.Enable='on';
end
guidata(hObject,handles)

function Undock_Callback(hObject, eventdata, handles)

list = {'Hazard','UHS','CMS','CSS Selection'};
[indx,tf] = listdlg('ListString',list);
if tf==0
    return
end
for i=1:length(indx)
    figure2clipboard_uimenu([],[],handles.(sprintf('ax%i',indx(i))))
end

function wand_Callback(hObject, eventdata, handles)

ch1 = findall(handles.figure1,'tag','redline');
ch2 = findall(handles.figure1,'tag','patch');
switch ch2.Visible
    case 'off'
        set(ch1,'Visible','on');
        set(ch2,'Visible','on');
    case 'on'
        set(ch1,'Visible','off');
        set(ch2,'Visible','off');
end

function ExportRecords_Callback(hObject, eventdata, handles)

[file,path,indx] = uiputfile('*.mat');
if indx==0
    return
end


data =regexprep(handles.inCSS4,' +',' ');
data=data(7:end);
Nth = size(data,1);
eq(1:Nth,1) = struct('Filename',[],'Index',[],'HazLevel',[],'RSN',[],'EqID',[],'Mag',[],'Rrup',[],'Rjb',[],'VS30',[],'scalefactor',[],'rate',[],'T',[],'SA',[],'dt',[],'accH1',[],'accH2',[],'accV',[],'units',[]);
for i=1:Nth
    line                  = regexp(strtrim(data{i}),'\ ','split');
    numline               = str2double(line(1:13));
    eq(i).Index           = numline(1);
    eq(i).HazLevel        = numline(2);
    eq(i).RSN             = numline(3);
    eq(i).EqID            = numline(4);
    eq(i).Mag             = numline(5);
    eq(i).Rrup            = numline(6);
    eq(i).Rjb             = numline(7);
    eq(i).VS30            = numline(8);
    eq(i).scalefactor     = numline(10);
    eq(i).rate            = numline(12);
    eq(i).Filename        = line{14};
    eq(i).T               = handles.T;
    eq(i).SA              = handles.eq(i).SA;
end


for i=1:Nth
    fname = sprintf('%s.mat',eq(i).Filename);
    if eq(i).EqID>=11
        sta   = sprintf('st%g',eq(i).EqID-1);
    else
        sta   = sprintf('st0%g',eq(i).EqID-1);
    end
    OUT=load(fname,sta);
    OUT=OUT.(sta);
    
    eq(i).accH1 = OUT.acc_1 * eq(i).scalefactor;
    eq(i).accH2 = OUT.acc_2 * eq(i).scalefactor;
    eq(i).units = OUT.units;
end

filename = fullfile(path,file);
save(filename,'eq')
msgbox(sprintf('CSS-scaled ground motions saved to %s ',filename));

function File_Callback(hObject, eventdata, handles)

function Reset_Callback(hObject, eventdata, handles)
handles=InitializeCss(handles);
guidata(hObject,handles);

function ImportModel_Callback(hObject, eventdata, handles)

if isfield(handles,'defaultpath_others')
    [filename,pathname,FILTERINDEX]=uigetfile(fullfile(handles.defaultpath_others,'*.txt'),'select file');
else
    [filename,pathname,FILTERINDEX]=uigetfile(fullfile(pwd,'*.txt'),'select file');
end

if FILTERINDEX==0,return;end

% loads hazard curves
handles.defaultpath_others=pathname;
[handles.sys,handles.opt,handles.h]= loadPSHA(fullfile(pathname,filename));
handles   = InitializeCss(handles);

handles.pop_site.Enable='on';
handles.pop_branch.Enable='on';
ch=findall(handles.figure1,'style','pushbutton');
set(ch,'Enable','on');

guidata(hObject,handles)

function ExitMenu_Callback(hObject, eventdata, handles)

function ScalingFactors_Callback(hObject, eventdata, handles)

scale = vertcat(handles.eq.Scalefactor_h);
rate  = vertcat(handles.eq.rate);

figure;
loglog(rate,scale,'o');
xlabel('rate of ocurrence')
ylabel('scale factor')