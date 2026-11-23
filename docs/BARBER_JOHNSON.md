# Hospital Barber–Johnson nomograms

Available in the Rj/Rjp development branch. No optional R package or Python installation is required. This helper describes hospital bed use, not clinical quality, case-mix-adjusted efficiency or future bed requirements.

## Observation and dataset structure

**One row is one ward/facility in one defined observation period.** The pair
`unit` + `period` must be unique. Aggregate source records explicitly before
calling the helper. Use comparable ward types and service definitions. Separate
overnight inpatient activity from day cases. Define whether transfers count as
ward exits and keep that definition consistent with the capacity and bed-days.

The supplied synthetic CSV is `examples/data/10_barber_johnson_hospital.csv`:
three wards, four actual calendar quarters in 2025, with a capacity change.
Script `10_barber_johnson.R` also contains those data and runs without a file.
In Rjp select every column named in the call when using the current dataset.
Column arguments map your names: no renaming of the source dataset is required.

| Argument / example column | Meaning and units | Requirements |
| --- | --- | --- |
| `unit='unit'` | Ward or facility identifier | Required, non-missing |
| `period='period'` | Period label, e.g. 2025 Q1 | Required; unique within unit |
| `period_days='period_days'` | Actual period length in days | Required positive numeric column; alternatively a positive scalar applying to every row |
| `beds='beds'` | Mean actually available beds during the period | Positive; used for raw input if available_bed_days is not supplied |
| `available_bed_days=NULL` | Column with sum of daily available beds, in bed-days | Preferred when capacity changes; positive; replaces beds × days, not an additional quantity |
| `occupied_bed_days='occupied_bed_days'` | Occupied inpatient bed-days in the same period | Raw input; non-negative and no greater than available bed-days |
| `discharges='discharges'` | Completed exits in the same period, including deaths under the chosen definition | Raw input; positive whole counts |
| `order='period_order'` | Numeric chronological position | Required for trajectories; unique within each unit |
| `facet='unit'` | Panel grouping | Optional; defaults to unit; at most 12 panels |
| `group='clinical_area'` | Colour/legend grouping | Optional; defaults to unit; use unit for independently selectable ward trajectories |
| `toi='toi'`, `alos='alos'` | Precomputed TOI and bed-day/discharge ALOS in days | Used with input_mode='toi_alos'; TOI ≥ 0, ALOS > 0 |
| `bor='bor'` | Precomputed occupancy proportion | Used with input_mode='alos_bor'; 0 < BOR ≤ 1, not 0–100 |

`input_mode='raw'` is the default and takes capacity, occupied bed-days and
discharges. It does not silently switch between routes when other columns are
present. `input_mode='toi_alos'` and `'alos_bor'` are explicit alternatives;
their derived identities assume consistent indicator definitions. Mean bed
capacity cannot be recovered from those two indicators alone. For precomputed
input, `size_by_beds=TRUE` requires a real beds column; no capacity is invented.

Rows missing any requested input are excluded and their 1-based row numbers
are returned. Invalid finite values cause an error. Duplicate keys and
inconsistent capacity cause an error. A maximum of 2,000 complete rows is
supported per result. Data and dataext are never modified.

## Formulas and period basis

Let T be period days, C available bed-days, O occupied bed-days, D discharges,
and B = C/T mean available beds. With constant capacity, C = B × T.

| Indicator | Formula | Units |
| --- | --- | --- |
| ALOS used by the nomogram, L | O / D | days |
| Turnover interval, I | (C − O) / D | days |
| Occupancy proportion, p | O / C = L / (L + I) | proportion; displayed as 100p% |
| Observed-period turnover, R | D / B = T / (L + I) | exits per mean bed over T days |
| Turnover on reference period T₀, R₀ | R × T₀/T = T₀ / (L + I) | exits per bed on the selected time basis |

Example: 10 mean beds over 90 days, C=900, O=720 and D=90 give L=8 days,
I=2 days, occupancy=80%, R=9 per quarter and R₀=36.5 per 365 days.
Annualisation rescales a rate; it does not predict future admissions/exits.
The table and point details retain both observed and reference-period turnover.
Use actual days, including leap years. A pooled occupancy is sum(O)/sum(C),
not the unweighted mean of ward percentages; aggregate raw totals deliberately.

**ALOS here is period bed-days divided by period exits.** This can differ from
the mean completed stay of patients discharged in the period because of stays
crossing its boundaries. Do not mix the two definitions and expect the
nomogram identities to hold exactly. TOI is an aggregate capacity indicator,
not a direct measurement of bed cleaning or preparation time.

The graphical reference equations are:

- TOI–ALOS occupancy rays: L = p I / (1 − p).
- TOI–ALOS turnover lines: L = T₀/R₀ − I.
- TOI–BTO occupancy curves: R₀ = T₀(1 − p)/I, for I > 0.
- TOI–BTO constant-ALOS curves: R₀ = T₀/(L + I).

At I=0, a fully occupied observation is plotted using its finite calculated
turnover; the singular reference curve is not evaluated at zero. The helper
does not replace the real period with a fixed 365-day quarter.

## Four presentations

- `view='toi_alos'`: the classic nomogram with occupancy rays and turnover lines.
- `view='toi_bto'`: TOI against reference-period BTO with occupancy and ALOS curves.
- `view='trajectory'`: TOI–ALOS positions joined in explicit numeric order for
  each unit. Arrows indicate sequence, not causality. Missing requested rows
  are excluded; a connection can therefore span a missing period.
- `view='faceted'`: separate, vertically stacked panels by facet, using the
  same limits in all panels. Height is per panel, not total figure height.

## Call and options

```r
report <- mzrjShowBarberJohnson(
    data, view='trajectory', input_mode='raw',
    unit='ward', period='quarter', period_days='days',
    available_bed_days='capacity_bed_days',
    occupied_bed_days='occupied_days', discharges='exits',
    order='quarter_order', group='ward', turnover_days=365,
    scenarios=list(
        list(label='Locally selected range', bor=c(.75,.85), toi=c(1,3)),
        list(label='Comparison threshold', bor=.90)),
    width=800, height=400, result_type='html', name='hospital_nomogram')
```

`turnover_days=365` defines the reference time basis. Reference families are
configured with `occupancy_lines` (proportions), `turnover_lines` (BTO on that
basis) and `alos_lines` (days); numeric(0) hides a family, at most 12 per family.
`max_toi`, `max_alos`, `max_bto` set axis limits, otherwise calculated from data.
Observations outside explicit limits are clipped and counted in the report.
`size_by_beds=FALSE` enables optional square-root-scaled bed-capacity markers
when TRUE; a minimum readable marker radius is retained. `point_labels=FALSE`
avoids clutter; TRUE adds unit or period labels, which can overlap in dense data.
All values remain available on focus/selection without labels.

`scenarios=NULL` shows no target area by default. Supply up to six named R lists
with distinct `label`, `bor` as a single threshold or c(lower, upper) interval,
and optional `toi`/`alos` bounds in days. Single thresholds draw lines;
intervals draw lightly shaded intersections. BOR bounds must be within (0,1).
References are user-selected scenarios, never automatic efficiency categories.
The legend toggles each ward/group and scenario without recalculating data.
Their values appear in notes; native SVG export also includes legend visibility.

Hover/focus a point for all indicators; click/Enter pins its projection lines,
Escape clears selection. The existing figure-size slider enlarges the figure
and its Results area. Reset restores size and clears selection, retaining legend
visibility. It does not change the axes or the underlying indicators.

`width=NULL`, `height=NULL` use popup values, then Rj defaults (400 × 300 pixels). Explicit
arguments take precedence. In faceted view total plot height is panel height ×
panel count. `result_type` supports html, vector svg and captured image. Native
Svg/Image have no Html accordion/size slider and keep jamovi resizing. Releasing
an Image resize handle updates only that figure's dimensions and raster: it
does not execute R or restart captures, and preserves the other figures
and the table. Base dimensions remain unchanged across repeated drags. Html uses
`accordion=TRUE`, `expanded=TRUE`, `accordion_type='line'` (or 'bordered').
`tables=TRUE` adds a native indicator table. The invisible returned list contains `indicators` (an R data frame),
`excluded_rows` (1-based row numbers), `outside`, `turnover_days` and `scenarios`.

## Evidence and interpretation

The classic construction is retained while interpretation follows current
capacity-management concerns: available beds must be operationally available,
case mix and service type matter, and an average occupancy hides daily peaks.
OECD 2025 explicitly notes no consensus on one optimal occupancy rate. Do not
turn a familiar 85% reference into a universal clinical standard. Local targets
need their own rationale. The chart alone cannot estimate latent reserve,
staffing adequacy, avoidable bed-days or future bed requirements.

References (dates refer to publication, not necessarily observation years):

1. Barber B, Johnson D. *The Presentation of Acute Hospital In-patient Statistics*.
   Hospital and Health Services Review, 1973. Historical construction; full
   original text not reviewed.
2. Pulgar Perera VA, Paniagua Tejo MT, Sañudo García S. *Barber and Johnson diagram
   and latent reserve as tools to optimise the management of hospital beds*.
   J Healthc Qual Res. 2019;34(3):124–130.
   https://doi.org/10.1016/j.jhqr.2019.02.001 — abstract reviewed; no latent-reserve
   estimator is implemented by this helper.
3. OECD. *Health at a Glance 2025*, Hospital beds and occupancy.
   https://www.oecd.org/content/dam/oecd/en/publications/reports/2025/11/health-at-a-glance-2025_a894f72e/8f9e3f98-en.pdf
4. WHO Europe. *Bed occupancy rate (%), acute care hospitals only*.
   https://gateway.euro.who.int/en/indicators/hfa_542-6210-bed-occupancy-rate-acute-care-hospitals-only/
5. Tamarina FA, Suswojo H, Absor S. *Efficiency of Inpatient Care Services at
   Surabaya Islamic Hospital in 2022–2023 Using the Barber-Johnson Approach*.
   Qanun Medika. 2026;10(1). https://doi.org/10.3651/jqm.v10i01.27393
   Recent local descriptive application, not universal validation of targets.

The Raffaele (2014) port-activity paper was consulted for the
mathematical analogy; port-specific definitions and targets are not transferred
to this hospital helper. All supplied hospital data are synthetic.


### Dimensions and Linux compatibility

On some Linux installations the native Svg/Image resize handle appears at the lower left and may be unresponsive. Use the function’s `width` and `height`, or global Popup dimensions when those arguments are omitted. Explicit arguments take precedence. Example 10 already supplies dimensions; omit them to test global values. Image resizing preserves other figures and tables without executing R again.

The maintainer also observed the blocked lower-left Image grip in graphics from third-party modules on the same Ubuntu environment. This addition does not claim to correct that shared native behaviour.
