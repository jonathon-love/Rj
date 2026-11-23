# Source-aware diagnostics and operational notifications

The development preview validates the syntax of the editor and Service script before executing either one. Syntax and runtime errors remain in jamovi Results. The report identifies the loaded filename (or R editor / Service script), the source line and the relevant instruction. Calls between user functions and between the editor and Service script are included when R supplies source references. Package internals are omitted. Dynamically generated or external code without a matching source reference falls back to its calling instruction; the formatter does not invent an internal line number.

The evaluator keeps parser references in a private dispatcher while retaining evaluate's output/graphics handling. Service and editor share the user environment and graphics device. Echo displays user code, not dispatcher instructions. The serialized System R evaluator uses the same formatter. The selected dataset is transferred as RDS, preserving its R types and attributes; jmvconnect is not required to reread jamovi shared memory. System R still needs jmvcore and evaluate, already used by the original evaluator. Error records use the existing result file so multiline messages and Unicode survive transport. After a complete error record has been written, the worker flushes an error marker. The runner terminates the owned process tree rather than waiting indefinitely for R shutdown/finalizers. Ordinary successful or long-running scripts retain their existing execution policy.

Operational notices use a shared editor-owned toast, separate from Results. Successful Load and Service operations are silent, matching Pj. File-selection/read failures and dataset-column lookup failures produce notices without executing R code. Notifications use plain text, have a Close button and Escape dismissal, pause while hovered or focused, and are removed when switching analyses or disposing the editor. They do not take keyboard focus. JavaScript editor controls can reuse `this.showToast(text, {kind: 'info', duration: 6000})`; use the existing translation wrapper at the call site. There is no new public background-service API or R-script toast API.

## Manual check

Restart jamovi after installing the preview. Use Rj or Rjp and repeat with Embedded and System R:

1. Load `examples/06_diagnostics.R`. Confirm that loading is silent and text/Image/Svg output succeeds with `CASE <- "success"`.
2. Set CASE to `runtime`: check the filename, source line, instruction and both lines of the message.
3. Set CASE to `nested`: check the inner-function error and calling lines.
4. Load `examples/06_service.R` with Service, then set CASE to `service`. The report must name the Service file and the calling editor line.
5. Restore a valid CASE and uncomment the final syntax-probe line. The syntax report must point at that line. Comment it again before subsequent checks.
6. After the error, edit CASE back to `success` in the same editor and Run again. The editor, Load/Service buttons and Settings must remain usable, and the same analysis must complete. Close a notification with its button or Escape. Native figure resize and the Settings panel must still work.

Automated checks cover parser locations, multiline/runtime errors, Service calls, caught errors, validation before Service side effects, shared plotting, Echo, notifications, process restart/recovery, OMV and native figure sizing. Desktop acceptance PASSED on 20 November 2026: Windows and Ubuntu 26.04 WSL2, Embedded and System R, scripts 05 and 06 (diagnostics and Service). Windows and Ubuntu 26.04 WSL2 were built/tested with jamovi 28.18.0.0; no macOS acceptance is claimed.

## Windows build and test locale

Use a valid Windows UTF-8 locale for compilation subprocesses and for cold-load tests, matching jamovi's embedded R. A POSIX value such as `LC_ALL=C.UTF-8` inherited by a Windows build worker is not valid there. In this environment, a package produced under that failed locale loaded in the CLI fallback locale but failed when its evaluator was loaded under the desktop UTF-8 locale, with `embedded nul in string`. Rebuilding under `.UTF-8` passed the same cold-load test. Do not change the user's jamovi language or Windows regional settings to work around this.

For a Windows build session, before calling jmvtools:

```r
Sys.setenv(LC_ALL=".UTF-8", LANG=".UTF-8")
Sys.setlocale("LC_ALL", ".UTF-8")
```

The environment variables cover compiler subprocesses; setting only the parent R locale is insufficient. The startup regression checks empty/comment-only Rj and Rjp analyses after cold namespace loading in the GUI locale.

The canonical new helper names are `mzrjShowImage()` and `mzrjShowSvg()`. Earlier unreleased preview examples using `rjShowImage()`/`rjShowSvg()` must be updated. `openNew()` is an existing Rj function and retains its original name.
