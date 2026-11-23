# Additional guided examples: no external dataset or R plotting package.
# Change RESULT_TYPE, then try both Embedded R and System R.
RESULT_TYPE <- "html" # "html", "svg", "image"

mzrjShowHistogram(iris,"Sepal.Length",bins=10,name="length_histogram",
    title="Sepal length: observed histogram",width=640,height=380,result_type=RESULT_TYPE)

profiles<-data.frame(month=rep(c(0,3,6,9),2),score=c(50,54,61,64,49,52,55,58),
    group=rep(c("A","B"),each=4))
mzrjShowPlotlyLine(profiles,"month","score",group="group",name="guided_profiles",
    title="Illustrative observed profiles: no model fitted",width=640,height=380,
    result_type=RESULT_TYPE,x_label="Month",y_label="Illustrative score")

counts<-data.frame(activity=c("Reading","Practice","Discussion"),responses=c(12,19,8))
mzrjShowPlotlyBar(counts,"activity","responses",stat="identity",name="guided_counts",
    title="Illustrative response counts",width=640,height=380,result_type=RESULT_TYPE)

# Each cell is the Pearson correlation between its row and column measurements.
# The diagonal is 1; values near 0 indicate little linear association.
# The default diverging palette uses muted blue, neutral ivory and sage green.
# Read the sign and magnitude from the printed coefficients and the color bar.
# R computes the correlations; Plotly only displays them.
# These pooled correlations include between-species differences: they are not causal
# effects or correlations estimated separately within each species.
correlations<-cor(iris[1:4],use="complete.obs")
mzrjShowPlotlyHeatmap(correlations,name="correlation_heatmap",
    title="Iris: correlations between four measurements",width=680,height=480,
    zmin=-1,zmax=1,zmid=0,show_values=TRUE,value_label="Pearson r",
    result_type=RESULT_TYPE)
