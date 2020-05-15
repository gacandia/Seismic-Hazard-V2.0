function[eq,IND]=buildGMstruct(handles,component)

data = handles.tabla.Data;
Neq  = size(data,1);

eq(1:Neq,1) = struct(...
    'earthquake',[],...
    'eventID',[],...
    'date',[],...
    'station',[],...
    'component',[],...
    'filename',[],...
    'samples',[],...
    'magnitude',[],...
    'rrup',[],...
    'gps_event',[],...
    'gps_station',[],...
    'Vs30',[],...
    'dt',[],...
    'acc',[],...
    'vel',[],...
    'dis',[],...
    'PGA',[],...
    'PGV',[],...
    'PGD',[],...
    'T',[],...
    'Sa',[],...
    'Sv',[],...
    'Sd',[],...    
    'D595',[],...    
    'D2575',[],...    
    'DBracket',[],...    
    'Tm',[],...
    'Tp',[],...
    'To',[],...
    'aRMS',[],...
    'CAV',[],...
    'Arias',[]);


do_comp = 0;
switch component
    case 'H1',col=10; do_comp = 1; IND=cell2mat(data(:,13));
    case 'H2',col=11; do_comp = 1; IND=cell2mat(data(:,14));
    case 'HZ',col=12; do_comp = 1; IND=cell2mat(data(:,15));
end

for i=1:Neq
    eq(i,1).earthquake= data{i,3};
    eq(i,1).component = component;
    if do_comp
        eq(i,1).filename  = data{i,col};
    end
    eq(i,1).date      = data{i,4};
    eq(i,1).station   = data{i,5};
    eq(i,1).magnitude = data{i,6};
    eq(i,1).rrup      = data{i,7};
    
    ind = data{i,1};
    gps_event = cell2mat(handles.db.raw(ind,8:10));
    eq(i,1).gps_event = gps_event;
    
    if isfield(handles,'station')
        [~,sptr]=intersect({handles.station.label},data{i,5});
        gps_station = handles.station(sptr).gps;
        Vs30        = handles.station(sptr).Vs30;
        eq(i,1).gps_station = gps_station;
        eq(i,1).Vs30        = Vs30;
    end
end

%% computes unique event id
eqnames=unique(handles.db.raw(:,3),'stable');
for i=1:length(eq)
    [~,B]=intersect(eqnames,eq(i).earthquake);
    eq(i).eventID=B;
end
