# Rj/Rjp editor and native result improvements

This branch is a proposal for upstream review. It preserves the Embedded/System R option values and existing Rj/Rjp analyses. No D3, Chart.js or additional graphics library is bundled. The module version is unchanged; the upstream maintainer can select the release number and supported jamovi baseline.

## Changes

- Shared editor toolbar: passive script Load, Save, Clear, filename/draft state, Service script loaded before the editor, keyboard Run and a sliding/draggable Settings panel.
- Settings retain output mode and global figure size, expose Embedded/System R, and keep the module-version badge in the panel rather than duplicating the editor label.
- External OMV Read, preview and Save through jmvReadWrite, using a separate `dataext` data frame. The current jamovi dataset is not replaced. The existing Remotes entry is retained; jmvReadWrite and jsonlite are declared Imports because they are called at runtime.
- Native Image results bind to the analysis options. Restoring/resizing a result preserves other output and does not rerun the user's R script. Svg width/height changes receive the same treatment.
- `rjShowImage(function() { ... }, width=NULL, height=NULL, name=NULL, title='')` and `rjShowSvg(...)` are available inside the evaluator, including the serialized System R evaluator. They create native results with their own dimensions. No arguments uses the global figure defaults; one dimension preserves their aspect ratio; both set the individual size. Drawing occurs on a separate device to avoid duplicate automatic plots. Ordinary `plot()` remains supported.
- English user-facing text uses the existing translation mechanism (`.` in R; translation wrapper in JS). Examples contain English instructions. No dependency is installed into the user's System R by these helpers.

The follow-up replaces the System R `system2()` launch with an owned `processx` process tree. File-backed UTF-8 input avoids blocking on large scripts; merged output is drained while jamovi checkpoints remain active. Restart/error cleanup terminates owned descendants. Nonzero exit statuses and missing result handshakes are reported explicitly. Environment overrides apply only to the child, leaving the engine environment unchanged. Windows retains the existing System R user-library policy and `cli` shutdown workaround. `processx` and the already-used `rappdirs` are declared Imports. Embedded evaluation and R discovery are unchanged.

## Validation and limits

The maintainer has visually accepted the editor, slide animation, file operations, OMV workflow, Image resizing and per-figure Image/Svg examples. Windows and Ubuntu 26.04 WSL2 packages were built and installed with jamovi 28.18.0.0. Embedded and System R evaluator checks passed on Windows and WSL2; WSL System tests supplied the existing evaluate dependency in an isolated test library. Native Svg resize save/restore was checked without rerunning the script. Browser tests use real Ace and cover both Rj and Rjp, toolbar geometry, draft isolation, focus, keyboard behavior and slide reversal.

The processx follow-up has passed automated checks on Windows and Ubuntu 26.04 WSL2; the maintainer has also accepted example 05 with Embedded and System R on both platforms. Process tests cover UTF-8, long output, nonzero status, timeout, checkpoint restart, recovery and descendant cleanup. Analysis lifecycle tests use the actual Rj/Rjp classes and subprocess transport, replacing only live shared-memory dataset acquisition with a fixture. Linux tests distinguish host System R from the R executable inside Flatpak; isolated test dependencies are not installed into user libraries. Existing R discovery inside Flatpak may resolve its bundled R; this change does not introduce a host-R bridge.

No macOS build or GUI acceptance is claimed. Older jamovi/jmvcore versions have not been certified; the Svg helper requires a core exposing the native Svg result class. On Ubuntu the native resize grip is displayed at the lower left in Pj, official Rj and MetaJam as well; this branch does not claim to fix that jamovi positioning issue. The official Rj resize behavior and the grip's placement are separate issues.

## Build and tests

Build using the standard jmvtools workflow. Before building run `Rscript tools/update_version.R .` to synchronize the UI version badge. Do not edit the generated badge manually. Tests/docs/examples are repository resources, excluded from the runtime R/JMO payload.

R integration scripts accept the source/build root as their first argument and need a compiled/installed Rj. Use jamovi's R for engine tests; optional library paths can be provided with `MZRJ_TEST_LIBS`. For System R transport tests set `MZRJ_SYSTEM_RSCRIPT` to its executable. Examples 01/02 exercise editor/OMV features; example 04 compares ordinary plotting with per-result Image/Svg sizes. Example 05 checks the processx preview and includes an optional interruption probe. `tests/process_runner.R`, `tests/system_omv.R` and `tests/system_lifecycle.R` exercise the subprocess runner and remote transport. An isolated child dependency library can be supplied to the latter two using `MZRJ_SYSTEM_TEST_LIBS`.

Run `tests/ui/ui_preview.test.js` with Node and Playwright. Optional environment variables: `MZRJ_PLAYWRIGHT`, `MZRJ_CHROME`, `MZRJ_UI_OUTPUT`. It reads the current source and does not patch jamovi or install a module.

The working branch is intentionally separate from master. No upstream merge, release or graphics-library expansion is part of this proposal.
