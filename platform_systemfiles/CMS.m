function varargout = CMS(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @CMS_OpeningFcn, ...
    'gui_OutputFcn',  @CMS_OutputFcn, ...
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

function CMS_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
load icons_CMS.mat c
handles.axLimits.CData =c{1};
handles.Run.CData      =c{2};

handles.output      = hObject;
handles.sys         = varargin{1};
handles.opt         = varargin{2};
handles.h           = varargin{3};
handles.scenarios   = cell(0,9);
handles.tessel      = {[],zeros(0,2)};
handles.opt.SourceDeagg='off';

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

% ------------ REMOVES PCE MODELS (AT LEAST FOR NOW) ----------------------
isREG = handles.sys.isREG;
[~,B]=setdiff(handles.sys.branch(:,2),isREG);
if ~isempty(B)
    handles.sys.branch(B,:)=[];
    handles.sys.weight(B,:)=[];
    handles.sys.weight(:,5)=handles.sys.weight(:,5)/sum(handles.sys.weight(:,5));
    warndlg('PCE Models removed from logic tree. Logic Tree weights were normalized')
    uiwait
end

% -------------------------------------------------------------------------
% Build interface to adjust this piece of code
%--------------------------------------------------------------------------
% rmin  = 0;  rmax  = 120; dr    = 10;
% handles.Rbin      = [(rmin:dr:rmax-dr)',(rmin:dr:rmax-dr)'+dr];
% mmin  = 4; mmax  = 7.6; dm    = 0.2;
% handles.Mbin      = [(mmin:dm:mmax-dm)',(mmin:dm:mmax-dm)'+dm];

rmin  = 0;  rmax  = 300; dr    = 20;
handles.Rbin      = [(rmin:dr:rmax-dr)',(rmin:dr:rmax-dr)'+dr];
mmin  = 5.1;
mmax  = 9.3; dm  = 0.2;
handles.Mbin     = [(mmin:dm:mmax-dm)',(mmin:dm:mmax-dm)'+dm];


%% populate pop menus
Nmodel = size(handles.sys.branch,1);
set(handles.pop_site,'string',handles.h.id);
set(handles.pop_branch,'string',compose('Branch %i',1:Nmodel));
T = UHSperiods(handles);
methods = pshatoolbox_methods(4);
handles.spatial_model.String={methods.label};
handles.spatial_model.Value = 3;

if Nmodel==1
    handles.methodpop.String={'Method 1'};
else
    handles.methodpop.String={'Method 1','Method 2','Method 3'};
end

%% Set up ax1
xlabel(handles.ax1,'Sa(T*)','fontsize',8)
ylabel(handles.ax1,'\lambda Sa(T*)','fontsize',8)

%% Set up ax2
xlabel(handles.ax2,'T (s)','fontsize',8)
ylabel(handles.ax2,'Sa (g)','fontsize',8)

%% set up ax3
set(handles.ax3,'fontsize',8,'visible','off')

%% Set up ax4
plot(handles.ax4,T,nan(size(T)),'.-','tag','rho');
handles.ax4.YLim=[0 1];
xlabel(handles.ax4,'T (s)','fontsize',8)
ylabel(handles.ax4,'\rho (T*,T)','fontsize',8)

%% tooltip strings for CMS
handles.tts{1}='Approximate CS Using Mean M & R and a single GMPM';
handles.tts{2}='Approximate CS Using Mean M & R and GMPMs with Logic-Tree Weights';
handles.tts{3}='Approximate CS Using GMPM-Specific Mean M & R and GMPMs with Deaggregation Weights';
handles.tts{4}='�Exact� CS Using Multiple Causal Earthquake M & R and GMPMs with Deaggregation Weights';
handles.methodpop.TooltipString=handles.tts{1};

guidata(hObject, handles);
% uiwait(handles.figure1);

function varargout = CMS_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

function Ret_Period_Callback(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>

str = hObject.String;
if contains(str,'%')
    str = strrep(str,'year','y');
    str = strrep(str,'yr','y');
    str = strrep(str,'in','');
    str = regexp(str,'\%|\y|\yr','split');
    p   = str2double(str{1});
    t   = str2double(str{2});
    Ret = round(-t/log(1-p/100));
    hObject.String = sprintf('%i',Ret);
end

function Cond_Period_Callback(hObject, eventdata, handles)

function Run_Callback(hObject, eventdata, handles)

site_ptr = handles.pop_site.Value;
h        = handles.h;
h.id     = h.id(site_ptr);
h.p      = h.p(site_ptr,:);
h.value  = h.value(site_ptr,:);

opt           = handles.opt;
opt.model_ptr = handles.pop_branch.Value;
opt.Tcond     = str2double(handles.Cond_Period.String);
includeT      = [opt.IM;opt.Tcond];
opt.T         = UHSperiods(handles,includeT);
opt.im        = createObj('defaultIMrange',opt.T);
opt.Tr        = str2double(handles.Ret_Period.String);
opt.Rbin      = handles.Rbin;
opt.Mbin      = handles.Mbin;
opt.cfun      = handles.spatial_model.Value;


switch handles.methodpop.Value
    case 1, cmsdata=runCMS_method1(handles.sys,opt,h);
    case 2, cmsdata=runCMS_method2(handles.sys,opt,h);
    case 3, cmsdata=runCMS_method3(handles.sys,opt,h);
end

plotCMS(handles.figure1,handles.ax3,opt,cmsdata)

function pop_site_Callback(hObject, eventdata, handles)

function pop_branch_Callback(hObject, eventdata, handles)

function control_R_Callback(hObject, eventdata, handles)

function control_M_Callback(hObject, eventdata, handles)

function spatial_model_Callback(hObject, eventdata, handles)

function axLimits_Callback(hObject, eventdata, handles)

list = {'Hazard Curve','Conditional Mean Spectra','Correlation Model'};
[indx,tf] = listdlg('ListString',list,'SelectionMode','single','ListSize',[160 100]);
if tf==0
    return
end
switch indx
    case 1, handles.ax1=ax2Control(handles.ax1);
    case 2, handles.ax2=ax2Control(handles.ax2);
    case 3, handles.ax4=ax2Control(handles.ax4);
end
guidata(hObject,handles)

function methodpop_Callback(hObject, eventdata, handles)

hObject.TooltipString=handles.tts{hObject.Value};
if hObject.Value~=1
    handles.pop_branch.Enable='off';
else
    handles.pop_branch.Enable='on';
end
guidata(hObject,handles)

function Edit_Callback(hObject, eventdata, handles)

function defineMRbins_Callback(hObject, eventdata, handles)

[handles.Rbin,handles.Mbin]=setMRebins(handles.Rbin,handles.Mbin);
guidata(hObject,handles)