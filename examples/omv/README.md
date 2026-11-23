# External OMV example

`02_external_omv.omv` is a **synthetic, data-only** example with 24 participants, Control/Training groups, baseline/follow-up scores, attendance counts and a few missing values. It contains no saved analyses and is not added automatically to the jamovi Data Library.

1. Open an Rj or Rjp analysis and Load `../02_external_omv.R`.
2. In the sliding settings panel, use **External OMV files > Read...** to select this OMV. Do not open it as the current document for this workflow.
3. Run the script. The separate `dataext` receives `Rj_row` and `score_change` (follow-up minus baseline); the current jamovi dataset stays unchanged.
4. Enable **Show preview in Results** to inspect it. Save exports all rows and columns, including the new columns and missing values.
5. Use **Save...** with a new filename, such as `02_external_omv_modified.omv`, outside this example folder. Reopen the saved copy to inspect the modifications. Keep the original supplied example unchanged.

The displayed changes are descriptive teaching data, not a treatment-effect estimate or causal result. Without Read, the script falls back to the current/selected data or iris; that fallback does not test reading this OMV.

The input can be regenerated with `tools/create_external_omv_example.R` and jmvReadWrite. Examples and tools belong to the source repository and are excluded from the installable JMO.
