# Rj / Rjp editor update proposal

This branch modernizes the existing R editors while retaining Embedded/System R operation. It adds script file controls and draft state, a sliding Settings panel, a separate external OMV workflow, native graphic resize persistence, per-figure Image/Svg dimensions, and a cancellable System R processx runner.

This graphics block adds shared offline D3/Plotly resources and Chart.js, with R-native helper adapters. See [graphics helpers](docs/GRAPHICS.md) and examples 07–10. See [upstream review notes](docs/UPSTREAM_REVIEW.md) for scope, dependencies, examples, tests and platform limitations. Windows and Ubuntu 26.04 WSL2 builds were tested with jamovi 28.18.0.0; macOS acceptance is not claimed.

The branch is intended for review by the upstream maintainers. It has not been merged into the distributed Rj module. Existing copyright and GPL licensing remain in effect.

The diagnostics block adds source-aware editor/Service errors and operational notifications; see [diagnostics checks](docs/DIAGNOSTICS.md). The diagnostics block was accepted on Windows and Ubuntu WSL2 with both R interpreters. The graphics examples passed Windows visual acceptance with both R interpreters. Linux builds and automated checks passed; example 09 and the external OMV preview/save workflow also passed maintainer checks with both R modes in WSL2.

The development branch also includes hospital Barber–Johnson nomograms, with [English](docs/BARBER_JOHNSON.md) and [Italian](docs/BARBER_JOHNSON_IT.md) guides, synthetic example 10 and native graphic capture/resize fixes. Platform acceptance for this addition is recorded separately from the earlier graphics block.
