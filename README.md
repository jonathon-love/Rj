# Rj / Rjp editor update proposal

This branch modernizes the existing R editors while retaining Embedded/System R operation. It adds script file controls and draft state, a sliding Settings panel, a separate external OMV workflow, native graphic resize persistence, and per-figure Image/Svg dimensions.

No D3 or other graphics library is bundled in this proposal. See [upstream review notes](docs/UPSTREAM_REVIEW.md) for scope, dependencies, examples, tests and platform limitations. Windows and Ubuntu 26.04 WSL2 builds were tested with jamovi 28.18.0.0; macOS acceptance is not claimed.

The branch is intended for review by the upstream maintainers. It has not been merged into the distributed Rj module. Existing copyright and GPL licensing remain in effect.
