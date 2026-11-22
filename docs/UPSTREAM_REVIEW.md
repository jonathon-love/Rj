# Rj/Rjp update proposal: review scope

This branch modernizes the existing R editors while retaining the Embedded/System R choices and analysis identifiers. It is intended for upstream review; it has not been merged into the distributed Rj module. The module version remains 2.7.18 so the upstream maintainer can choose the release number and baseline.

## Editor and lifecycle

- Shared toolbar with passive Load/Save/Clear, filename/draft state, Service script and keyboard Run.
- Sliding/draggable Settings, interpreter selector, global figure size, version badge and consistent Rj/Rjp styling.
- External OMV Read/preview/Save through jmvReadWrite, using separate `dataext`; the current jamovi dataset is preserved.
- Native Image/Svg sizing and resize persistence, without rerunning the script for display-only changes.
- Source-aware syntax/runtime/Service diagnostics, multiline/Unicode messages and recoverable errors. Successful script loading is silent; operational failures use an editor-owned toast.
- System R uses an owned processx tree, file-backed UTF-8 input, drained output and active checkpoints. Dataset/result transport uses RDS rather than jmvconnect shared-memory acquisition. The child still needs jmvcore/evaluate. Existing R discovery and the Windows cli shutdown workaround are retained.

## Graphics block

Shared offline D3/Plotly bundles plus Chart.js are adapted to R lists/data frames; no Python or R plotly dependency is introduced. Guided scatter, line, bars, boxplots, histograms and heatmaps complement explicit Plotly/Chart configurations. See [helper contracts, examples and limitations](GRAPHICS.md).

Html retains interaction and optional line/bordered accordion. Svg/Image are native results without Html zoom wrappers; browser PNG capture is acknowledged without rerunning user code. Plotly/Chart Svg exports are raster-backed. Explicit per-result dimensions override the settings popup. Unchanged Chart canvases survive complete script reruns. No backend-service API or R-script toast API is added.

New functions use the `mzrj` prefix. User-facing R/JS text uses extractable translation markers with a remote message catalog. There are no automatic user package installations. Existing copyright and GPL licensing are preserved; vendor licenses and the shared bundle manifest accompany the resources.

## Dependencies and packaging

Imports include the existing jmvReadWrite/jsonlite workflow, processx/rappdirs runner support, and png/grid for native browser images. The existing jmvReadWrite Remotes declaration is retained. The Windows and Linux JMOs include their png dependency. The source repository retains tests/docs/examples and versioned UI dependencies; tests/docs/examples are excluded from the installable JMO.

Build through jmvtools; `tools/update_version.R` stamps the badge from DESCRIPTION. Do not edit the generated badge. Use platform-native R/Node and the target jamovi runtime. Windows/Linux builds are local; Apple Intel/ARM64 use native GitHub Actions jobs at the planned review stage. Older jamovi versions are not certified; native Svg requires a core exposing that result class.

## Validation and limits

The editor/lifecycle, processx and diagnostics blocks passed maintainer desktop acceptance on Windows and Ubuntu-26.04 WSL2 with both R interpreters (examples 05/06, including interruption/recovery). Tests distinguish draft edits from submitted code and keep the editor usable after errors.

The graphics block was built and installed on Windows and Ubuntu-26.04 WSL2. Automated checks cover both R evaluators, offline Chromium rendering under CSP, Html/Svg/Image, dimensions, input escaping, no RNG consumption, Chart canvas reuse, acknowledgement without rerun, native save/reload and the external OMV round-trip. Windows examples 07/08/09 passed maintainer visual acceptance. In WSL2 the maintainer accepted example 09 with both R modes and the external OMV preview/save workflow. Examples 07/08 were not separately reported as manual Linux checks in this round; automated Linux helper/dimension/capture tests passed. No macOS GUI acceptance is claimed.

The known Ubuntu lower-left resize grip belongs to jamovi and is also visible with official Rj/other modules; this proposal does not claim to fix it. CI success is distinct from manual desktop acceptance.

## Running the checks

R integration scripts take the source root first and use a compiled Rj. Engine checks use jamovi R; `MZRJ_TEST_LIBS` may select the dependency library. Set `MZRJ_SYSTEM_RSCRIPT` for real child transport tests; `MZRJ_SYSTEM_TEST_LIBS` optionally confines child dependencies to a test-only directory.

`tests/shared_graphics.R SOURCE OUTPUT` creates fixtures from the actual R evaluator. `tests/shared_graphics.cjs SOURCE OUTPUT_PARENT` checks the two evaluator fixture directories using Playwright (`MZRJ_PLAYWRIGHT`, `MZRJ_CHROME` optional). `tests/graphics_capture.R SOURCE OUTPUT_PARENT` exercises actual Analysis save/load/PNG acknowledgement for Rj/Rjp and both R modes. Existing lifecycle/diagnostic/OMV/native-resize tests remain applicable.

The author will submit the proposal toward upstream for Core Team review. No automatic merge into the fork's main, upstream merge or public release is part of this graphics preview.
