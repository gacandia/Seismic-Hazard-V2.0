function[obj]=createObj(tag)

switch tag
    % seismic source objects
    case 'model'
        obj  = struct('id',[],'source',[]);
        
    case 'source'
        obj  = struct(...
            'txt'      , [],...
            'adp'      , [],...
            'num'      , [],...
            'vptr'     , [],...
            'mptr'     , [],...
            'vert'     , [],...
            'center'   , [],...
            'xyzm'     , [],...
            'conn'     , [],...
            'aream'    , [],...
            'hypm'     , [],...
            'strike'   , [],...
            'normal'   , [],...
            'p'        , [],...
            'dsv'      , [],...
            'dip'      , [],...
            'mred'     , []);
        
    case 'sourceDSHA'
        obj  = struct(...
            'branch',[],...
            'txt'      , [],...
            'adp'      , [],...
            'num'      , [],...
            'vptr'     , [],...
            'mptr'     , [],...
            'vert'     , [],...
            'xyzm'     , [],...
            'conn'     , [],...
            'aream'    , [],...
            'hypm'     , [],...
            'strike'   , [],...
            'normal'   , [],...
            'p'        , [],...
            'dsv'      , [],...
            'dip'      , [],...
            'mred'     , []);
        
    case 'gmmlib'
        obj = struct('label',[],'txt',[],'type',[],'handle',[],'T',[],'usp',[],'Rmetric',[],'Residuals',[],'cond',[],'var',[]);
        
    case 'mscl'
        obj = struct('source',[],'adp',[],'num',[],'mptr',[],'mdata',[],'meanMo',[]);
        
    case 'site'
        obj.id        = cell(0,1);
        obj.p         = zeros(0,3);
        obj.VS30      = zeros(0,1);
        obj.t         = cell(0,2);
        obj.shape     = [];
        
    case 'opt'
        load pshatoolbox_RealValues opt
        obj=opt;
        
    case 'hazoptions'
        obj=struct('mod',1,'avg',[1 0 0 50 0],'sbh',[1 0 0 1],'dbt',[1 0 0 50],'map',[475 1],'pce',[0 1 50],'rnd',1);
        
    case 'Rbin'
        rmin  = 0;   rmax    = 360; dr    = 40;   obj  = [(rmin:dr:rmax-dr)',(rmin:dr:rmax-dr)'+dr];
        
    case 'Mbin'
        mmin  = 5;   mmax    = 9.6; dm    = 0.2;  obj  = [(mmin:dm:mmax-dm)',(mmin:dm:mmax-dm)'+dm];
        
    case 'Ebin'
        emin  = 0;   emax    = 2;   de    = 0.5;  obj  = [[-inf emin];(emin:de:emax-de)',(emin:de:emax-de)'+de;[emax,inf]];
        
    case 'returnperiods'
        obj=[144;250;475;949;1462;1950;2475;4975;10000];
    case 'LIBSsite'
        obj = struct('B',[],'L',[],'Df',[],'Q',[],'type',[],'wt',[],'LPC',[],'th1',[],'th2',[],'N1',[],'N2',[],'meth',[],'N160',[],'qc1N',[],'thick',[],'d2mat',[],'CPT',[]);

end