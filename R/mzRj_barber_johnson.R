# Host-side calculations only; the shared mzGraphics renderer owns drawing.
# Standalone so the same function can be serialized to System R.
.mzRj_barberJohnsonPrepare <- function(dataset, view='toi_alos', input_mode='raw',
    unit='unit', period='period', period_days='period_days', beds='beds',
    available_bed_days=NULL, occupied_bed_days='occupied_bed_days', discharges='discharges',
    toi='toi', alos='alos', bor='bor', order=NULL, facet=NULL, group=NULL,
    turnover_days=365, occupancy_lines=c(.5,.7,.8,.85,.9), turnover_lines=c(15,25,35,50),
    alos_lines=c(3,5,7,10,14), scenarios=NULL, size_by_beds=FALSE,
    max_toi=NULL, max_alos=NULL, max_bto=NULL, point_labels=FALSE, title=NULL,
    translate=function(text)text) {
    . <- translate
    error <- function(text)stop(text,call.=FALSE)
    text <- function(template,...) {
        value<-.(template);args<-list(...)
        for(key in names(args))value<-gsub(paste0('{',key,'}'),as.character(args[[key]]),value,fixed=TRUE)
        value
    }
    number <- function(x,label,positive=FALSE) {
        if(!is.numeric(x)||length(x)!=1L||!is.finite(x)||x<0||(positive&&x==0))
            error(sprintf(.('%s must be a finite %s number.'),label,if(positive).('positive')else .('non-negative')))
        as.double(x)
    }
    scalar <- function(x)is.character(x)&&length(x)==1L&&!is.na(x)&&nzchar(x)
    boolean <- function(x)is.logical(x)&&length(x)==1L&&!is.na(x)
    if(!scalar(view)||!view %in% c('toi_alos','toi_bto','trajectory','faceted'))
        error(.('view must be toi_alos, toi_bto, trajectory or faceted.'))
    if(!scalar(input_mode)||!input_mode %in% c('raw','toi_alos','alos_bor'))
        error(.('input_mode must be raw, toi_alos or alos_bor.'))
    if(!boolean(size_by_beds)||!boolean(point_labels))error(.('size_by_beds and point_labels must be logical values.'))
    turnover_days<-number(turnover_days,'turnover_days',TRUE)
    if(view=='trajectory'&&is.null(order))error(.('trajectory requires an explicit numeric order column.'))
    cols<-c(unit,period,order,facet,group)
    if(is.character(period_days))cols<-c(cols,period_days)else number(period_days,'period_days',TRUE)
    if(input_mode=='raw')cols<-c(cols,occupied_bed_days,discharges,if(is.null(available_bed_days))beds else available_bed_days)
    else cols<-c(cols,alos,if(input_mode=='toi_alos')toi else bor,if(size_by_beds)beds)
    cols<-unique(cols)
    if(!is.list(dataset)||is.null(names(dataset))||anyDuplicated(names(dataset))||
       !scalar(unit)||!scalar(period)||any(!vapply(as.list(cols),scalar,logical(1)))||
       any(!cols %in% names(dataset)))error(.('Use a data frame or named column list containing all requested columns.'))
    lengths<-vapply(dataset[cols],length,integer(1))
    if(!length(lengths)||length(unique(lengths))!=1L)error(.('Requested columns must have equal lengths.'))
    n<-lengths[1];points<-list();excluded<-integer();keys<-character()
    missing <- function(x)length(x)!=1L||is.na(x)||(is.numeric(x)&&!is.finite(x))||
        (is.character(x)&&!nzchar(trimws(x)))
    for(i in seq_len(n)) {
        if(any(vapply(dataset[cols],function(column)missing(column[[i]]),logical(1)))) {excluded<-c(excluded,i);next}
        u<-as.character(dataset[[unit]][[i]]);label<-as.character(dataset[[period]][[i]])
        key<-paste0(nchar(u,type='bytes'),':',u,label)
        if(key %in% keys)error(sprintf(.('Duplicate unit/period at row %s; aggregate or correct the source data first.'),i))
        keys<-c(keys,key)
        days<-number(if(is.character(period_days))dataset[[period_days]][[i]]else period_days,'period_days',TRUE)
        b<-NULL
        if(input_mode=='raw') {
            capacity<-if(is.null(available_bed_days))number(dataset[[beds]][[i]],'beds',TRUE)*days else number(dataset[[available_bed_days]][[i]],'available_bed_days',TRUE)
            occupied<-number(dataset[[occupied_bed_days]][[i]],'occupied_bed_days')
            exits<-number(dataset[[discharges]][[i]],'discharges',TRUE)
            if(exits!=floor(exits))error(.('Discharges must be whole counts.'))
            if(occupied>capacity)error(.('Occupied bed-days exceed available bed-days; check the capacity definition.'))
            a<-occupied/exits;t<-(capacity-occupied)/exits;p<-occupied/capacity;b<-capacity/days;actual<-exits/b
        } else {
            a<-number(dataset[[alos]][[i]],'alos',TRUE)
            if(input_mode=='toi_alos'){t<-number(dataset[[toi]][[i]],'toi');p<-a/(a+t)}
            else {
                p<-number(dataset[[bor]][[i]],'bor',TRUE)
                if(p>1)error(.('BOR must be a proportion in (0, 1], not a percentage.'))
                t<-a*(1/p-1)
            }
            actual<-days/(a+t)
            if(size_by_beds)b<-number(dataset[[beds]][[i]],'beds',TRUE)
        }
        reference<-turnover_days/(a+t)
        if(any(!is.finite(c(a,t,p,actual,reference,b))))error(.('Indicators exceed the supported finite numeric range.'))
        points[[length(points)+1L]]<-list(row=i,unit=u,period=label,days=days,alos=a,toi=t,bor=p,
            bto=actual,btoStandard=reference,beds=b,
            group=if(is.null(group))u else as.character(dataset[[group]][[i]]),
            facet=if(is.null(facet))u else as.character(dataset[[facet]][[i]]),
            order=if(is.null(order))i-1L else number(dataset[[order]][[i]],'order'))
        if(length(points)>2000L)error(.('Use at most 2000 complete unit-period observations per result.'))
    }
    if(!length(points))error(.('No complete observations are available.'))
    if(view=='trajectory'&&anyDuplicated(data.frame(unit=vapply(points,`[[`,'','unit'),order=vapply(points,`[[`,0,'order'))))
        error(.('Each unit must have a unique numeric order in trajectory view.'))
    if(view=='faceted'&&length(unique(vapply(points,`[[`,'','facet')))>12L)error(.('Use at most 12 facets per result; filter or split the dataset.'))
    levels <- function(values,label,proportion=FALSE) {
        if(!is.numeric(values)&&length(values))error(.('Reference lines must be numeric vectors.'))
        values<-sort(unique(vapply(as.list(values),number,numeric(1),label=label,positive=TRUE)))
        if(length(values)>12L||(proportion&&any(values>=1)))error(.('Use at most 12 reference lines; occupancy proportions must be strictly between 0 and 1.'))
        unname(as.list(values))
    }
    references<-list()
    if(!is.null(scenarios)) {
        if(!is.list(scenarios)||is.data.frame(scenarios))error(.('scenarios must be a list of named lists.'))
        for(scenario in scenarios) {
            if(!is.list(scenario)||!scalar(scenario$label)||!nzchar(trimws(scenario$label))||
               any(!names(scenario) %in% c('label','bor','toi','alos'))||anyDuplicated(names(scenario)))
                error(.('Each scenario needs a non-empty label and BOR bounds; fields are label, bor, toi and alos.'))
            values<-scenario$bor
            if(!is.numeric(values)||!length(values)%in%c(1L,2L))error(.('Scenario BOR must be a proportion or two-value interval.'))
            if(length(values)==1L)values<-rep(values,2)
            values<-vapply(as.list(values),number,numeric(1),label='scenario bor',positive=TRUE)
            if(values[1]>values[2]||values[2]>=1)error(.('Scenario BOR must satisfy 0 < lower <= upper < 1.'))
            ref<-list(label=scenario$label,bor=unname(as.list(values)))
            for(key in c('toi','alos'))if(!is.null(scenario[[key]])) {
                bounds<-scenario[[key]]
                if(!is.numeric(bounds)||length(bounds)!=2L)error(.('Scenario TOI/ALOS requires two ordered non-negative bounds.'))
                bounds<-vapply(as.list(bounds),number,numeric(1),label=key)
                if(bounds[1]>bounds[2])error(.('Scenario TOI/ALOS requires two ordered non-negative bounds.'))
                ref[[key]]<-unname(as.list(bounds))
            }
            references[[length(references)+1L]]<-ref
        }
        if(length(references)>6L||anyDuplicated(vapply(references,`[[`,'','label')))error(.('Use at most six scenarios with distinct labels.'))
    }
    limit<-function(value,key,column)if(is.null(value))max(1,1.25*max(vapply(points,`[[`,0,column)))else number(value,key,TRUE)
    xmax<-limit(max_toi,'max_toi','toi');ymax<-limit(max_alos,'max_alos','alos');rmax<-limit(max_bto,'max_bto','btoStandard')
    outside<-sum(vapply(points,function(p)p$toi>xmax||if(view=='toi_bto')p$btoStandard>rmax else p$alos>ymax,logical(1)))
    note<-text('N = {n} unit-periods; {excluded} incomplete rows excluded; {outside} observations outside the displayed limits. BTO reference period: {days} days.',
        n=length(points),excluded=length(excluded),outside=outside,days=format(turnover_days,trim=TRUE))
    note<-paste(note,.('BTO on this basis is a rate rescaling, not a forecast. Reference scenarios are user-selected, not quality or efficiency classifications.'))
    if(length(references))note<-paste(note,.('References:'),paste(vapply(references,function(r)paste0(r$label,': BOR ',
        paste(paste0(format(100*unique(unlist(r$bor)),trim=TRUE),'%'),collapse='–'),
        if(!is.null(r$toi))paste0('; TOI ',paste(unlist(r$toi),collapse='–'),' d'),
        if(!is.null(r$alos))paste0('; ALOS ',paste(unlist(r$alos),collapse='–'),' d')),''),collapse='; '))
    if(length(references))note<-paste0(note,'.')
    ui<-list(xLabel=.('Turnover interval (TOI, days)'),yLabel=.('ALOS (bed-days / discharges, days)'),
        btoLabel=.('BTO per {days} days'),
        status=.('Hover or focus a point to read its indicators. Click or press Enter to pin; Escape clears the selection.'),
        detail=.('{unit} / {period} · {days} days · ALOS {alos} d · TOI {toi} d · BOR {bor}% · BTO {bto} per observed period; {reference} per {basis} d'),beds=.('mean beds'))
    list(kind='barberJohnson',view=view,title=if(is.null(title)).('Barber–Johnson: hospital bed utilisation')else title,ui=ui,
        points=points,turnoverDays=turnover_days,occupancyLines=levels(occupancy_lines,'occupancy_lines',TRUE),
        turnoverLines=levels(turnover_lines,'turnover_lines'),alosLines=levels(alos_lines,'alos_lines'),
        scenarios=references,sizeByBeds=size_by_beds,pointLabels=point_labels,xMax=xmax,yMax=ymax,btoMax=rmax,
        note=note,excludedRows=unname(as.list(excluded)),outside=outside)
}
