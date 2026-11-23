# Hospital Barber–Johnson: four views, shared D3, no optional R packages.
# SYNTHETIC teaching data; reference scenarios are user choices, not clinical standards.
# Run in a NEW Rj or Rjp analysis. No selected variables or Data Library example required.
# For hospital data set USE_JAMOVI_DATA <- TRUE; in Rjp select every named column.
# One row = one ward and observation period; unit + period must be unique.
# See docs/BARBER_JOHNSON.md and docs/BARBER_JOHNSON_IT.md for variables and formulas.
# The same synthetic records are also supplied in examples/data/10_barber_johnson_hospital.csv.
USE_JAMOVI_DATA <- FALSE
RESULT_TYPE <- "html"  # "html", "svg", "image"; native outputs have no Html accordion.
VIEW <- "all"          # "all", "toi_alos", "toi_bto", "trajectory", "faceted"
SHOW_TABLE <- TRUE

example <- data.frame(
    unit=rep(c("Medicine","Surgery","Rehabilitation"),each=4),
    period=rep(paste("2025 Q",1:4,sep=""),3), period_order=rep(1:4,3),
    period_days=rep(c(90,91,92,92),3),
    beds=c(32,32,28,28,rep(24,4),rep(20,4)),
    clinical_area=rep(c("Medical","Surgical","Rehabilitation"),each=4))
occupancy <- c(.89,.86,.78,.84,.76,.81,.72,.79,.91,.88,.85,.90)
stay <- c(8.5,8.0,7.6,7.8,5.8,5.2,5.6,5.0,18,17,16,16.5)
example$occupied_bed_days <- round(example$beds*example$period_days*occupancy)
example$discharges <- round(example$occupied_bed_days/stay)
dataset <- if(USE_JAMOVI_DATA)data else example

# BOR uses proportions, not percentages. Change/add/remove local references (up to six).
references <- list(
    list(label="Comparison band 75–85%",bor=c(.75,.85),toi=c(.5,3)),
    list(label="Occupancy reference 90%",bor=.90))
titles <- c(toi_alos="Hospital bed utilisation: TOI and ALOS",
    toi_bto="Hospital bed utilisation: TOI and annualised BTO",
    trajectory="Ward trajectories: 2025 Q1 to Q4",
    faceted="Ward profiles on common scales")
views <- if(VIEW=="all")names(titles) else VIEW
for(index in seq_along(views)) {
    view <- views[[index]]
    report <- mzrjShowBarberJohnson(dataset, view=view, input_mode="raw",
        unit="unit",period="period",period_days="period_days",
        beds="beds",occupied_bed_days="occupied_bed_days",discharges="discharges",
        order="period_order",facet="unit",group="unit",turnover_days=365,
        occupancy_lines=c(.5,.7,.8,.85,.9),turnover_lines=c(10,20,30,40,60),
        alos_lines=c(3,5,7,10,14,21),scenarios=references,size_by_beds=TRUE,
        max_toi=5,max_alos=24,max_bto=90,title=titles[[view]],
        name=paste0("hospital_",view),width=800,height=380,
        result_type=RESULT_TYPE,tables=SHOW_TABLE&&index==1)
}
# Html: focus/hover points for indicators; click/Enter pins, Escape clears.
# Legend buttons toggle wards and reference scenarios; no model is fitted.
# Native Svg/Image: use jamovi's handle or width/height; no Html zoom wrapper.
# Width/height here are explicit: omit them to follow global Settings dimensions.
# Faceted height is PER PANEL; all wards share the same axes.
# BTO uses turnover_days as a comparison basis, not a forecast.
# ALOS is period bed-days/discharges, not a completed-discharge-cohort mean stay.
