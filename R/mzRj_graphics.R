# The host prepares data; mzGraphics owns D3/Plotly rendering in both editors.
.mzRj_graphicsAssets <- function() {
    names <- c(accordion='mzrj_accordion.css', d3='mzD3.min.js', d3css='mzD3.min.css',
        plotly='mzPlotly.min.js', plotlycss='mzPlotly.min.css',
        capture='mzrj_image_capture.js', chart='mzrj_chart.js',
        chartcss='mzrj_chart.css', chartstatic='mzrj_chart_static.js', chartvendor='chart.umd.js')
    lapply(names,function(name) paste(readLines(
        system.file('extdata',name,package='Rj',mustWork=TRUE),
        encoding='UTF-8',warn=FALSE),collapse='\n'))
}

# Self-contained for serialization to System R. No dependency on Python or Pj.
.mzRj_graphicsFactory <- function(root, options, env, assets, translate, messages=list()) {
    . <- translate
    error <- function(message) stop(message,call.=FALSE)
    scalar <- function(x) is.character(x) && length(x)==1L && !is.na(x)
    boolean <- function(x) is.logical(x) && length(x)==1L && !is.na(x)
    escape <- function(x) {
        if(!scalar(x)) error(.('Labels and titles must be single strings.'))
        x<-gsub('&','&amp;',x,fixed=TRUE);x<-gsub('<','&lt;',x,fixed=TRUE)
        x<-gsub('>','&gt;',x,fixed=TRUE);gsub('"','&quot;',x,fixed=TRUE)
    }
    json <- function(value) {
        check <- function(x) {
            if(is.function(x)||is.environment(x)||is.language(x)||is.raw(x))
                error(.('Graphic configuration must contain JSON values, without callbacks.'))
            if(is.numeric(x)&&any(is.infinite(x)))
                error(.('Graphic configuration contains an infinite value.'))
            if(is.list(x)) {
                if(any(names(x) %in% c('__proto__','prototype','constructor')))
                    error(.('Graphic configuration contains a reserved JavaScript key.'))
                invisible(lapply(x,check))
            }
        }
        check(value)
        text<-as.character(jsonlite::toJSON(value,auto_unbox=TRUE,na='null',null='null',
            dataframe='rows',digits=16,force=TRUE))
        for(pair in list(c('&','\\u0026'),c('<','\\u003c'),c('>','\\u003e'),
                         c('\u2028','\\u2028'),c('\u2029','\\u2029')))
            text<-gsub(pair[1],pair[2],text,fixed=TRUE)
        text
    }
    hash <- function(text) {
        path<-tempfile();on.exit(unlink(path))
        writeBin(charToRaw(enc2utf8(text)),path)
        unname(tools::md5sum(path))
    }
    newId <- function() hash(tempfile())
    dimension <- function(value, fallback) {
        if(is.null(value)) value<-fallback
        if(!is.numeric(value)||length(value)!=1L||!is.finite(value)||
           value!=floor(value)||value<1||value>2000)
            error(.('Graphic dimensions must be whole numbers from 1 to 2000 pixels.'))
        as.integer(value)
    }
    size <- function(width,height) {
        value<-c(dimension(width,env$figWidth),dimension(height,env$figHeight))
        if(value[1]<320L||value[2]<240L)
            error(.('Graphics require a width of at least 320 and a height of at least 240 pixels.'))
        value
    }
    resultName <- function(name) {
        if(is.null(name)) {
            repeat {
                name<-paste0('graphic_',env$count);env$count<-env$count+1L
                if(is.null(root$get(name))) break
            }
        }
        if(!scalar(name)||!grepl('^[A-Za-z][A-Za-z0-9_]*$',name)||
           name %in% c('omvExport','dataextPreview')||!is.null(root$get(name)))
            error(.('Use a unique result name starting with a letter and containing only letters, digits or underscores.'))
        name
    }
    wrap <- function(content,title,accordion,expanded,accordion_type) {
        if(!boolean(accordion)||!boolean(expanded)||!accordion_type %in% c('line','bordered'))
            error(.('Use logical accordion/expanded values and line or bordered accordion_type.'))
        if(!accordion&&!expanded) error(.('expanded=FALSE requires accordion=TRUE.'))
        if(!accordion) return(content)
        icon<-if(accordion_type=='line')
            '<svg class="mzrj-accordion-plus-minus" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path class="horizontal" d="M2 8h12"/><path class="vertical" d="M8 2v12"/></svg>'
        else '<svg class="mzrj-accordion-arrow" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M5 2l6 6-6 6"/></svg>'
        paste0('<style>',assets$accordion,'</style><details data-mzrj-motion="svg" class="mzrj-accordion mzrj-accordion-',
            accordion_type,'"',if(expanded)' open' else '','><summary><span class="mzrj-accordion-icon" aria-hidden="true">',
            icon,'</span><span class="mzrj-accordion-title"><span class="mzrj-accordion-label">',
            escape(title),'</span></span></summary><div class="mzrj-accordion-content">',content,'</div></details>')
    }
    emit <- function(content,name,title,mode,scripts,accordion,expanded,accordion_type) {
        if(!scalar(mode)||!mode %in% c('html','svg','image'))
            error(.('result_type must be html, svg or image.'))
        name<-resultName(name);escape(title)
        if(mode=='html') content<-wrap(content,title,accordion,expanded,accordion_type)
        state<-NULL
        if(mode=='image') {
            token<-newId();id<-paste0('mzrj_image_',token)
            request<-json(list(root=id,name=name,token=token,title=title))
            bridge<-gsub('__MESSAGES__',json(messages),assets$capture,fixed=TRUE)
            bridge<-gsub('__REQUEST__',request,bridge,fixed=TRUE)
            content<-paste0('<style>.jmv-results-html:has([data-mzrj-image-capture="pending"]){position:fixed!important;left:-100000px!important;top:0!important;margin:0!important;pointer-events:none!important}</style>',
                '<div id="',id,'" data-mzrj-image-capture="pending" aria-busy="true">',
                '<strong data-image-error-title hidden></strong><p data-image-status role="status" hidden></p>',
                '<div class="ignore-html" aria-hidden="true" style="position:absolute;left:-100000px;top:0;pointer-events:none">',
                content,'</div></div><script>',bridge,'</script>')
            state<-list(image_capture_token=token,image_capture_title=title)
        }
        constructor<-if(mode=='svg') jmvcore::Svg else jmvcore::Html
        item<-constructor$new(options,name=name,title=if(mode=='image'||(mode=='html'&&accordion))'' else title)
        item$setContent(content)
        if(length(scripts)) item$setScripts(scripts)
        if(!is.null(state)) item$setState(state)
        root$add(item)
        invisible(NULL)
    }
    d3 <- function(payload,name=NULL,title=NULL,width=NULL,height=NULL,result_type='html',
                   accordion=TRUE,expanded=TRUE,accordion_type='line',color='#3e6da9') {
        if(!is.list(payload)||!scalar(payload$kind)||!payload$kind %in%
           c('scatter','line','bar','boxplot','histogram','intervals','correlation','paired','distribution','test_distribution','interaction','barberJohnson'))
            error(.('Use a supported D3 payload kind.'))
        if(!scalar(color)||!grepl('^#[0-9a-fA-F]{6}$',color))
            error(.('Use a six-digit hexadecimal graphic color.'))
        dims<-size(width,height);id<-paste0('mzrj_d3_',newId())
        if(is.null(title)) title<-if(is.null(payload$title)) .('D3 graphic') else payload$title
        payload$title<-title;payload$width<-dims[1];payload$height<-dims[2]
        payload$accordion<-FALSE;payload$hideHeading<-isTRUE(accordion)&&result_type=='html'
        payload$expanded<-TRUE;payload$color<-color
        if(result_type!='html') {
            payload$resultType<-'svg';payload$hideHeading<-TRUE
            payload$exportStyle<-paste0(gsub('.mz-d3','.mz-d3-export',assets$d3css,fixed=TRUE),'.mz-d3-export{margin:0}')
        }
        content<-paste0('<style>',assets$d3css,'</style><div id="',id,'"></div><script>',
            assets$d3,'</script><script>(function(){const p=',json(payload),
            ';window.mzD3[p.kind](document.getElementById(',json(id),'),p);})();</script>')
        emit(content,name,title,result_type,'extdata/d3.min.js',accordion,expanded,accordion_type)
    }
    plotly <- function(figure,name=NULL,title=.('Plotly graphic'),width=NULL,height=NULL,
                       config=list(),result_type='html',accordion=TRUE,expanded=TRUE,accordion_type='line') {
        if(!is.list(figure)||!is.list(figure$data)||!is.list(config))
            error(.('Plotly requires a figure with a data list and a configuration list.'))
        dims<-size(width,height);id<-paste0('mzrj_plotly_',newId())
        if(is.null(figure$layout)) figure$layout<-list()
        if(!is.list(figure$layout)) error(.('The Plotly layout must be a list.'))
        figure$layout$width<-dims[1];figure$layout$height<-dims[2]
        figure$layout$autosize<-FALSE
        # A one-element R vector must remain a Plotly array.
        for(i in seq_along(figure$data)) for(axis in c('x','y','z','text','labels','values','customdata')) {
            value<-figure$data[[i]][[axis]]
            if(!is.null(value)&&!is.list(value)&&!is.matrix(value))
                figure$data[[i]][[axis]]<-unname(as.list(value))
            if(axis=='z'&&is.list(value))
                figure$data[[i]][[axis]]<-unname(lapply(value,function(row)unname(as.list(row))))
        }
        settings<-utils::modifyList(list(displayModeBar=FALSE,displaylogo=FALSE,scrollZoom=FALSE),config)
        static<-result_type!='html'
        if(static) settings<-utils::modifyList(settings,list(staticPlot=TRUE,responsive=FALSE,displayModeBar=FALSE))
        options<-list(figure=figure,config=settings,static=static,width=dims[1],height=dims[2],libraryName='mzPjPlotly411')
        if(static) content<-paste0('<div id="',id,'" class="mz-plotly"><p class="mz-plotly-status ignore-html" role="status"></p>',
            '<svg xmlns="http://www.w3.org/2000/svg" class="jmv-results-svg-content jmv-results-svg-selection" width="',dims[1],
            '" height="',dims[2],'" viewBox="0 0 ',dims[1],' ',dims[2],'"><title>',escape(title),
            '</title><image width="',dims[1],'" height="',dims[2],'"/></svg></div>')
        else content<-paste0('<style>.jmv-results-html:has(#',id,':not([data-mz-size-zoom])){width:',dims[1],
            'px;min-width:0;max-width:100%}</style><div id="',id,'" class="mz-plotly" style="width:',dims[1],
            'px;max-width:100%;height:',dims[2],'px"></div>')
        content<-paste0('<style>',assets$plotlycss,'</style>',content,'<script>',assets$plotly,
            '</script><script>window.mzPlotly.render(document.getElementById(',json(id),'),',json(options),
            ').catch(()=>{});</script>')
        emit(content,name,title,result_type,'extdata/plotly.min.js',accordion,expanded,accordion_type)
    }
    chart <- function(chart_type,datasets,labels=NULL,name=NULL,title=.('Chart.js graphic'),
                      options=list(),width=NULL,height=NULL,result_type='html',
                      accordion=TRUE,expanded=TRUE,accordion_type='line') {
        if(!scalar(chart_type)||!chart_type %in% c('bar','line','scatter','bubble','pie','doughnut','radar','polarArea')||
           !is.list(datasets)||!length(datasets)||!is.list(options))
            error(.('Use a supported Chart.js type, non-empty dataset list and options list.'))
        for(i in seq_along(datasets)) {
            if(!is.list(datasets[[i]])||is.null(datasets[[i]]$data))
                error(.('Each Chart.js dataset requires a data array.'))
            datasets[[i]]$data<-unname(as.list(datasets[[i]]$data))
            if(!is.null(labels)&&!chart_type %in% c('scatter','bubble')&&
               length(labels)!=length(datasets[[i]]$data))
                error(.('Chart.js labels and categorical data must have the same length.'))
        }
        dims<-size(width,height);id<-paste0('mzrj_chart_',newId())
        payload<-list(type=chart_type,data=list(datasets=datasets),options=options)
        if(!is.null(labels)) payload$data$labels<-unname(as.list(labels))
        if(!length(options)) payload$options<-jsonlite::fromJSON('{}',simplifyVector=FALSE)
        # force an object for empty options, rather than JSON [].
        encoded<-json(payload);encoded<-sub('"options":[]','"options":{}',encoded,fixed=TRUE)
        if(result_type=='html') {
            content<-paste0('<style>',assets$chartcss,'</style><style>.jmv-results-html:has(#',id,'){width:',dims[1],
                'px;min-width:0;max-width:100%}</style><div id="',id,'" class="mzrj-chartjs"><div class="mzrj-cj-body">',
                '<div class="mzrj-cj-surface" style="width:',dims[1],'px;height:',dims[2],
                'px" role="img" aria-label="',escape(title),'"><canvas role="img" aria-label="',escape(title),
                '"></canvas></div><p class="mzrj-cj-error" hidden></p></div></div>')
            signature<-hash(paste(encoded,paste(dims,collapse=':'),title,accordion,expanded,accordion_type,assets$chart))
            renderer<-gsub('__SIGNATURE__',signature,assets$chart,fixed=TRUE)
        } else {
            content<-paste0('<div id="',id,'"><svg xmlns="http://www.w3.org/2000/svg" class="jmv-results-svg-content jmv-results-svg-selection" width="',
                dims[1],'" height="',dims[2],'" viewBox="0 0 ',dims[1],' ',dims[2],
                '"><title>',escape(title),'</title><image width="',dims[1],'" height="',dims[2],
                '"/></svg><p class="mzrj-cj-error" hidden></p></div>')
            renderer<-gsub('__WIDTH__',dims[1],assets$chartstatic,fixed=TRUE)
            renderer<-gsub('__HEIGHT__',dims[2],renderer,fixed=TRUE)
        }
        renderer<-gsub('__MESSAGES__',json(messages),renderer,fixed=TRUE)
        renderer<-gsub('__ROOT__',id,renderer,fixed=TRUE)
        renderer<-gsub('__PAYLOAD__',encoded,renderer,fixed=TRUE)
        # The vendor global is loaded once; retain it for subsequent Rj results.
        content<-paste0(content,'<script>(function(){if(window.mzRjChart461)return;const previous=window.Chart;const module=undefined,exports=undefined,define=undefined;',assets$chartvendor,'\nwindow.mzRjChart461=window.Chart;window.Chart=previous;})();</script><script>',renderer,'</script>')
        emit(content,name,title,result_type,character(),accordion,expanded,accordion_type)
    }
    columns <- function(data,required,numeric=character()) {
        if(!is.data.frame(data)||any(!required %in% names(data)))
            error(.('Use a data frame containing all requested columns.'))
        if(any(!vapply(data[numeric],function(x)is.numeric(x)&&!is.factor(x),logical(1))))
            error(.('The requested measurement columns must be numeric.'))
        invisible(TRUE)
    }
    groups <- function(data,group) if(is.null(group)) rep(.('All observations'),nrow(data)) else as.character(data[[group]])
    prepareXY <- function(data,x,y,group=NULL,labels=NULL,line=FALSE,sort_x=TRUE,connect_gaps=FALSE,show_points=TRUE) {
        columns(data,c(x,y,group,labels),c(x,y))
        g<-groups(data,group);label<-if(is.null(labels))as.character(seq_len(nrow(data))) else as.character(data[[labels]])
        valid<-is.finite(data[[x]])&is.finite(data[[y]])&!is.na(g)
        if(!any(valid)) error(.('No complete finite observations are available for this graphic.'))
        points<-lapply(which(if(line&&!connect_gaps)!is.na(g) else valid),function(i)
            list(x=if(is.finite(data[[x]][i]))data[[x]][i] else NULL,
                 y=if(is.finite(data[[y]][i]))data[[y]][i] else NULL,
                 label=if(is.na(label[i]))as.character(i) else label[i],group=g[i],row=i))
        level<-unique(g[valid]);p<-list(kind=if(line)'line' else 'scatter',groups=as.list(level),
            grouped=!is.null(group),xLabel=x,yLabel=y,n=sum(valid),excluded=sum(!valid),
            note=paste0(.('Complete observations:'),' ',sum(valid),'; ',.('Rows excluded:'),' ',sum(!valid),'.'))
        if(line) {
            p$series<-lapply(level,function(level) {
                part<-Filter(function(z)identical(z$group,level),points)
                if(sort_x) part<-part[order(vapply(part,function(z)if(is.null(z$x))Inf else z$x,numeric(1)))]
                list(group=level,points=part)
            })
            p$showPoints<-show_points
        } else p$points<-points
        p
    }
    prepareBar <- function(data,category,value=NULL,stat='count',orientation='horizontal') {
        columns(data,c(category,value),if(is.null(value))character() else value)
        if(!stat %in% c('count','sum','mean','identity')||!orientation %in% c('horizontal','vertical')||
           (stat!='count'&&is.null(value))) error(.('Use count, sum, mean or identity with the required numeric value column.'))
        cat<-as.character(data[[category]]);valid<-!is.na(cat)
        if(stat!='count') valid<-valid&is.finite(data[[value]])
        if(!any(valid)) error(.('No complete finite observations are available for this graphic.'))
        level<-sort(unique(cat[valid]))
        bars<-lapply(level,function(key) {
            v<-if(stat=='count') rep(1,sum(valid&cat==key,na.rm=TRUE)) else data[[value]][which(valid&cat==key)]
            if(stat=='identity'&&length(v)!=1L) error(.('Identity bars require exactly one observation per category.'))
            list(category=key,value=switch(stat,count=length(v),sum=sum(v),mean=mean(v),identity=v[1]),n=length(v))
        })
        measure<-if(stat=='count').('Count') else value
        list(kind='bar',bars=bars,stat=stat,orientation=orientation,
            xLabel=if(orientation=='horizontal')measure else category,
            yLabel=if(orientation=='horizontal')category else measure,
            n=sum(valid),excluded=sum(!valid),note=paste(.('Descriptive statistic:'),stat))
    }
    prepareBox <- function(data,variable,group=NULL,show_points=TRUE) {
        columns(data,c(variable,group),variable)
        g<-groups(data,group);valid<-is.finite(data[[variable]])&!is.na(g)
        if(!any(valid)) error(.('No complete finite observations are available for this graphic.'))
        level<-unique(g[valid])
        boxes<-lapply(level,function(key) {
            v<-data[[variable]][which(valid&g==key)];q<-stats::quantile(v,c(.25,.5,.75),names=FALSE,type=7)
            inlier<-v[v>=q[1]-1.5*(q[3]-q[1])&v<=q[3]+1.5*(q[3]-q[1])]
            list(kind='summary',group=key,q1=q[1],median=q[2],q3=q[3],lower=min(inlier),upper=max(inlier),n=length(v))
        })
        points<-lapply(which(valid),function(i) {
            b<-boxes[[match(g[i],level)]];v<-data[[variable]][i];outlier<-v<b$lower||v>b$upper
            if(!show_points&&!outlier)return(NULL)
            list(kind='observation',value=v,group=g[i],row=i,label=as.character(i),outlier=outlier)
        })
        list(kind='boxplot',boxes=boxes,points=Filter(Negate(is.null),points),groups=as.list(level),
            grouped=!is.null(group),xLabel=if(is.null(group))'' else group,yLabel=variable,n=sum(valid),excluded=sum(!valid),
            note=.('Quartiles use R type 7; whiskers extend to observations within 1.5 IQR.'))
    }
    guided <- function(payload,renderer='d3',name=NULL,title=NULL,width=NULL,height=NULL,result_type='html',
                       accordion=TRUE,expanded=TRUE,accordion_type='line',color='#3e6da9',config=list(),
                       x_label=NULL,y_label=NULL) {
        if(!is.null(x_label)) {escape(x_label);payload$xLabel<-x_label}
        if(!is.null(y_label)) {escape(y_label);payload$yLabel<-y_label}
        if(renderer=='d3') return(d3(payload,name,title,width,height,result_type,accordion,expanded,accordion_type,color))
        if(renderer!='plotly') error(.('renderer must be d3 or plotly.'))
        if(is.null(title))title<-paste('Plotly',payload$kind)
        recipe<-list(protocol=1,kind=payload$kind,payload=payload,
            options=list(palette=as.list(c(color,'#d28118','#218578','#a580b7','#d66a70')),
                showLegend=TRUE,hoverMode='closest',dragMode='zoom',markerSize=7,opacity=.8))
        if(payload$kind=='bar') {
            recipe$payload$categories<-as.list(vapply(payload$bars,function(b)b$category,character(1)))
            recipe$payload$series<-list(list(name=if(is.null(payload$yLabel))'' else payload$yLabel,bars=payload$bars))
            recipe$options$barMode<-'group'
        }
        plotly(list(data=list(),layout=list(),mzGraphics=recipe),name,title,width,height,config,result_type,accordion,expanded,accordion_type)
    }
    scatter <- function(data,x,y,group=NULL,labels=NULL,renderer='d3',...) guided(prepareXY(data,x,y,group,labels),renderer,...)
    line <- function(data,x,y,group=NULL,labels=NULL,sort_x=TRUE,connect_gaps=FALSE,show_points=TRUE,renderer='d3',...)
        guided(prepareXY(data,x,y,group,labels,TRUE,sort_x,connect_gaps,show_points),renderer,...)
    bar <- function(data,category,value=NULL,stat='count',orientation='horizontal',renderer='d3',...)
        guided(prepareBar(data,category,value,stat,orientation),renderer,...)
    box <- function(data,variable,group=NULL,show_points=TRUE,renderer='d3',...)
        guided(prepareBox(data,variable,group,show_points),renderer,...)
    histogram <- function(data,variable,bins='FD',density=FALSE,...) {
        columns(data,variable,variable);v<-data[[variable]];v<-v[is.finite(v)]
        if(!length(v)||!boolean(density)) error(.('A histogram requires finite observations and a logical density argument.'))
        h<-graphics::hist(v,breaks=bins,plot=FALSE)
        bars<-lapply(seq_along(h$counts),function(i)list(lower=h$breaks[i],upper=h$breaks[i+1],
            value=if(density)h$density[i] else h$counts[i],count=h$counts[i],last=i==length(h$counts)))
        # Shared renderer describes left-closed bins; prepare counts with that convention.
        index<-findInterval(v,h$breaks,rightmost.closed=TRUE,all.inside=TRUE)
        counts<-tabulate(index,nbins=length(bars))
        for(i in seq_along(bars)) {bars[[i]]$count<-counts[i];bars[[i]]$value<-if(density)counts[i]/length(v)/diff(h$breaks)[i] else counts[i]}
        d3(list(kind='histogram',bars=bars,density=density,xLabel=variable,
            yLabel=if(density).('Density') else .('Count'),n=length(v),excluded=nrow(data)-length(v),
            note=.('Bins are left-closed; the last bin also includes its upper boundary.')),...)
    }
    heatmap <- function(matrix,name=NULL,title=.('Heatmap'),color_scale=NULL,
                        zmin=NULL,zmax=NULL,zmid=NULL,show_values=TRUE,value_label=.('Value'),...) {
        if(!is.matrix(matrix)||!is.numeric(matrix)||!length(matrix)||any(!is.finite(matrix)))
            error(.('A heatmap requires a finite numeric matrix.'))
        if(!boolean(show_values))
            error(.('show_values must be TRUE or FALSE.'))
        bound<-function(x)is.numeric(x)&&length(x)==1L&&is.finite(x)
        if((!is.null(zmin)||!is.null(zmax))&&
           (!bound(zmin)||!bound(zmax)||zmin>=zmax))
            error(.('Provide finite zmin and zmax values with zmin less than zmax.'))
        if(!is.null(zmid)&&(!bound(zmid)||
           (!is.null(zmin)&&(zmid<zmin||zmid>zmax))))
            error(.('zmid must be finite and within the selected color range.'))
        if(is.null(color_scale)) {
            limits<-if(is.null(zmin))range(matrix) else c(zmin,zmax)
            color_scale<-if(!is.null(zmid)||(limits[1]<0&&limits[2]>0))
                list(list(0,'#587295'),list(.25,'#b7c5d6'),list(.5,'#f5f3ee'),
                     list(.75,'#b9cec5'),list(1,'#54786d'))
            else list(list(0,'#edf1f5'),list(.5,'#b7c5d6'),list(1,'#587295'))
        }
        if(is.list(color_scale)) {
            stopValid<-function(stop)is.list(stop)&&length(stop)==2L&&
                bound(stop[[1]])&&stop[[1]]>=0&&stop[[1]]<=1&&
                scalar(stop[[2]])&&grepl('^#[0-9a-fA-F]{6}$',stop[[2]])
            if(length(color_scale)<2L||!all(vapply(color_scale,stopValid,logical(1))))
                error(.('A custom color scale requires position/color pairs with positions from 0 to 1 and six-digit hexadecimal colors.'))
            positions<-vapply(color_scale,function(stop)stop[[1]],numeric(1))
            if(positions[1]!=0||tail(positions,1)!=1||any(diff(positions)<0))
                error(.('Custom color scale positions must increase from 0 to 1.'))
            color_scale<-unname(lapply(color_scale,unname))
        } else if(!scalar(color_scale))
            error(.('Use a supported Plotly color scale name or a list of position/color pairs.'))
        escape(value_label)
        x<-colnames(matrix);if(is.null(x))x<-as.character(seq_len(ncol(matrix)))
        y<-rownames(matrix);if(is.null(y))y<-as.character(seq_len(nrow(matrix)))
        trace<-list(type='heatmap',x=unname(as.list(x)),y=unname(as.list(y)),
            # Matrix column names belong on the axes, never on numeric z arrays.
            z=lapply(seq_len(nrow(matrix)),function(i)unname(as.list(matrix[i,]))),
            colorscale=color_scale,hoverongaps=FALSE,
            colorbar=list(title=list(text=value_label)),
            hovertemplate=paste0('%{y} / %{x}<br>',escape(value_label),
                ': %{z:.3f}<extra></extra>'))
        if(!is.null(zmin)) {trace$zmin<-zmin;trace$zmax<-zmax}
        if(!is.null(zmid)) trace$zmid<-zmid
        if(show_values) {trace$texttemplate<-'%{z:.2f}';trace$textfont<-list(size=12)}
        plotly(list(data=list(trace),layout=list(margin=list(l=115,r=55,t=30,b=100),
            xaxis=list(type='category',automargin=TRUE),
            yaxis=list(type='category',autorange='reversed',automargin=TRUE))),name,title,...)
    }
    html <- function(content,name=NULL,title=.('R content'),accordion=TRUE,expanded=TRUE,accordion_type='line') {
        if(!scalar(content)) error(.('HTML content must be a single string.'))
        emit(content,name,title,'html',character(),accordion,expanded,accordion_type)
    }
    barberJohnson <- function(dataset,...,name=NULL,title=NULL,width=NULL,height=NULL,
        result_type='html',accordion=TRUE,expanded=TRUE,accordion_type='line',tables=TRUE) {
        if(!boolean(tables))error(.('tables must be a logical value.'))
        payload<-.mzRj_barberJohnsonPrepare(dataset,...,title=title,translate=.)
        base<-resultName(name);tableName<-paste0(base,'_indicators')
        if(tables&&!is.null(root$get(tableName)))error(.('The indicator table name already exists; choose a different name.'))
        rows<-lapply(payload$points,function(p)list(Unit=p$unit,Period=p$period,Days=p$days,
            ALOS=p$alos,TOI=p$toi,BOR_percent=100*p$bor,BTO_period=p$bto,
            BTO_reference=p$btoStandard,Mean_beds=if(is.null(p$beds))NA_real_ else p$beds))
        d3(payload,base,payload$title,width,height,result_type,accordion,expanded,accordion_type,color='#587295')
        if(tables) {
            item<-jmvcore::Table$new(options,name=tableName,title=.('Hospital bed utilisation indicators'),notes=list(payload$note))
            headings<-c(Unit=.('Unit'),Period=.('Period'),Days=.('Period days'),ALOS=.('ALOS (days)'),
                TOI=.('TOI (days)'),BOR_percent=.('BOR (%)'),BTO_period=.('BTO observed period'),
                BTO_reference=.('BTO reference period'),Mean_beds=.('Mean available beds'))
            for(key in names(headings))item$addColumn(name=key,title=headings[[key]],
                type=if(key %in% c('Unit','Period'))'text'else'number')
            for(i in seq_along(rows))item$addRow(rowKey=i,values=rows[[i]])
            root$add(item)
        }
        invisible(list(indicators=do.call(rbind,lapply(rows,as.data.frame)),
            excluded_rows=unlist(payload$excludedRows,use.names=FALSE),outside=payload$outside,
            turnover_days=payload$turnoverDays,scenarios=payload$scenarios))
    }
    list(mzrjShowBarberJohnson=barberJohnson,
         mzrjShowD3=d3,mzrjShowPlotly=plotly,mzrjShowChart=chart,mzrjShowHtml=html,
         mzrjShowScatter=scatter,mzrjShowLine=line,mzrjShowBar=bar,mzrjShowBoxplot=box,
         mzrjShowHistogram=histogram,mzrjShowHeatmap=heatmap,
         mzrjShowPlotlyScatter=function(...)scatter(...,renderer='plotly'),
         mzrjShowPlotlyLine=function(...)line(...,renderer='plotly'),
         mzrjShowPlotlyBar=function(...)bar(...,renderer='plotly'),
         mzrjShowPlotlyBoxplot=function(...)box(...,renderer='plotly'),
         mzrjShowPlotlyHeatmap=heatmap)
}
