
const css = `
/* Stessi margini sopra la toolbar di Pj/Pjp, limitati a questi editor. */
.silky-options-content.mzrj-plain-editor { padding-top: 7.5px; }
.silky-options-content.mzrj-editor-content > .top-level { margin-bottom: 10px; }
/* Dimensioni CSS coerenti con Pj: jamovi applica gia lo zoom dell'interfaccia. */
#editor-box { margin-bottom: 6px; flex: 1; display: flex; flex-direction: column; position: relative; min-height: 0; font-size: 12px; }
#toolbar { display: flex; align-items: center; justify-content: space-between; gap: 6px 12px; padding: 2px 0 8px; flex-wrap: wrap; position: relative; z-index: 10; }
#editor-heading, #editor-actions { display: flex; align-items: center; gap: 8px; min-width: 0; }
#editor-heading { flex: 1 1 130px; color: #3e6da9; }
#editor-heading > span { white-space: nowrap; }
#editor-filename { max-width: 180px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #64748b; font-size: 11px; }
#editor-actions { margin-left: auto; }
#toolbar button, #service-bar button, #editor-replace button { font-family: inherit; font-size: 12px; color: #3e6da9; background: #fff; border: 1px solid #b6cce8; border-radius: 4px; padding: 5px 8px; cursor: pointer; white-space: nowrap; }
#toolbar button:hover, #service-bar button:hover { background: #eef4fa; }
#toolbar #clear-script { font-size: 10px; padding: 0; }
#clear-script, #script-actions > button, #editor-actions #config, #editor-actions #run { box-sizing: border-box; display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; min-width: 32px; flex-shrink: 0; padding: 0; line-height: 1; vertical-align: middle; }
#script-actions > button { font-size: 10px; }
#script-actions { position: relative; display: flex; align-items: center; gap: 8px; padding: 8px; border: 1px solid #c1d1e5; border-radius: 7px; flex-shrink: 0; }
#scripts-label { position: absolute; top: 0; left: 8px; transform: translateY(-50%); padding: 0 5px; font-size: 11px; font-weight: 500; line-height: 1.2; color: #64748b; background-color: var(--main-background-color, #e6e6e6); }
#config-container { position: relative; }
#toolbar #run, #toolbar #config { display: inline-flex; align-items: center; justify-content: center; box-sizing: border-box; width: 32px; height: 32px; padding: 5px; border: 1px solid #3e6da9; border-radius: 5px; flex-shrink: 0; }
#toolbar #run { background: #3e6da9; color: #fff; }
#toolbar #run:hover { background: #315b91; }
#config[aria-expanded="true"] { box-shadow: 0 0 0 1px #d4e3f5; }
#toolbar #config, #toolbar #run { padding: 0; }
#run svg, #config svg { width: 20px; height: 20px; pointer-events: none; }
#editor { border: 1.5px solid #a4bfdf; border-radius: 8px; overflow: hidden; flex: 1; min-height: 0; }
#info { margin: 4px 2px 0; align-self: flex-end; color: #52647d; font-size: 10px; pointer-events: none; }
.silky-options-header.mzrj-editor-header { justify-content: flex-start; gap: 8px; }
.mzrj-editor-header > .silky-options-title { flex: 0 0 auto; white-space: nowrap; }
.mzrj-editor-header > .silky-sp-back-button { flex-shrink: 0; margin-inline-start: auto; }
.mzrj-editor-plus { margin-inline-start: 4px; color: #3e6da9; font-size: .55em; font-weight: 600; }
#service-bar.mzrj-service-header { margin: 0 0 0 4px; min-width: 0; flex: 0 1 auto; }
#service-bar { display: flex; align-items: center; gap: 6px; margin: 0 0 16px; font-size: 12px; }
#service-name { color: #52647d; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 220px; }
#remove-service[hidden] { display: none; }
#editor-message, #editor-replace { font-size: 12px; margin: 0 0 8px; padding: 8px; background: #eef4fa; color: #334155; }
#editor-replace:not([hidden]) { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
#menu-position { pointer-events: none; position: absolute; top: calc(100% + 6px); right: 0; width: max-content; z-index: 100; }
#menu {
    visibility: hidden;
    opacity: 0;
    pointer-events: none;
    transform: translateX(110%);
    transition: transform 0.28s ease-out, opacity 0.28s ease-out, visibility 0s linear 0.28s;
}
#menu.visible {
    visibility: visible;
    transition-delay: 0s;
    opacity: 1;
    pointer-events: auto;
    transform: translateX(0);
}
#menu { box-sizing: border-box; position: relative; top: 0; right: auto; z-index: 100; width: 280px; font-family: Arial, "Liberation Sans", sans-serif; max-width: calc(100vw - 24px); max-height: calc(100vh - 24px); overflow-y: auto; overscroll-behavior: contain; padding: 14px; color: #333; background: #fff; border: 1.5px solid #3e6da9; border-radius: 8px; box-shadow: 0 4px 14px #3e6da938; font-size: 12px; line-height: 1.4; cursor: move; }
#omv-files { border-top: 1px solid #dbe5f1; margin-top: 12px; padding-top: 10px; color: #52647d; }
.mzrj-omv-heading { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; color: #3e6da9; }
#omv-files button { font: inherit; padding: 5px 8px; background: #f5f8fc; border: 1px solid #b6cce8; border-radius: 4px; color: #3e6da9; cursor: pointer; }
#omv-files button:disabled { opacity: .5; cursor: default; }
#omv-files .jmv-file-selector-list { display: none; }
#omv-files p { font-size: 11px; line-height: 1.4; margin: 10px 0; }
#omv-files p:last-child { font-size: 10px; line-height: 1.5; margin: 8px 0 0; }
#dataext-dimensions { display: block; font-size: 10px; margin: 3px 0 0 42px; }
#dataext-dimensions:empty { display: none; }
#omv-files .mzrj-preview { display: flex; align-items: center; gap: 6px; font-size: 11px; }
.mzrj-omv-input { display: inline-flex; min-width: 0; }
#omv-files .jmv-file-selector { display: flex; min-width: 0; }
#menu #preview-dataext { width: 14px; height: 14px; accent-color: #3e6da9; }
#menu::-webkit-scrollbar { width: 8px; }
#menu::-webkit-scrollbar-thumb { background: #b7c7dd; border-radius: 6px; }
#menu-drag { display: flex; align-items: center; justify-content: space-between; color: #3e6da9; font-weight: 600; margin-bottom: 6px; cursor: grab; }
#menu-drag button { border: 0; background: transparent; color: #3e6da9; cursor: pointer; font: inherit; padding: 0 3px; font-size: 16px; }
#menu .mzrj-setting-row { display: flex; align-items: center; gap: 8px; cursor: default; }
#menu select { box-sizing: border-box; min-width: 0; flex: 1; font: inherit; color: #222; background: #fff; border: 1px solid #bbb; border-radius: 4px; padding: 6px; }
#figure-size { margin: 12px 0; }
#figure-size-title { color: #3e6da9; font-weight: 600; text-transform: uppercase; letter-spacing: .04em; padding-bottom: 4px; border-bottom: 1px solid #b8cce5; margin-bottom: 8px; }
#menu .mzrj-figure-inputs { display: grid; grid-template-columns: auto minmax(0, 1fr) auto minmax(0, 1fr); gap: 6px; align-items: center; }
#menu input:not([type="radio"]):not([type="checkbox"]) { box-sizing: border-box; min-width: 0; width: 100%; font: inherit; color: #222; padding: 4px 6px; border: 1px solid #bbb; border-radius: 4px; }
#code-label { display: flex; align-items: center; gap: 8px; color: #444; margin-bottom: 6px; }
#rj-module-version { color: #64748b; background: #f0f5fa; border-radius: 4px; padding: 1px 6px; font-size: 11px; font-weight: 400; }
#menu .mzrj-interpreter-row { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; cursor: default; }
#r-interpreter { display: flex; align-items: center; gap: 10px; }
#r-interpreter label { display: inline-flex; align-items: center; gap: 4px; cursor: pointer; white-space: nowrap; }
#r-interpreter input { width: 14px; height: 14px; margin: 0; accent-color: #3e6da9; }
#menu input, #menu select, #menu label { cursor: default; }
#menu :focus-visible, #toolbar button:focus-visible, #service-bar button:focus-visible { outline: 2px solid #3e6da9; outline-offset: 2px; }

.rj-vs-source {
    border-radius: 8px ;
    border: 2px solid #3e6da9 ;
    background-color: #ffffff ;
    box-shadow: none ;
}

.rj-vs-transfer-btn {
    border-radius: 6px ;
    border: 1px solid rgba(62, 109, 169, 0.45) ;
    background: #f5f8fc ;
    box-shadow: 0 1px 3px rgba(62, 109, 169, 0.15) ;
    transition: all 0.2s ease-in-out ;
}

.rj-vs-transfer-btn:hover {
    background: #eef4fb ;
    border-color: #3e6da9 ;
}

.rj-vs-target {
    border-radius: 8px ;
    transition: background-color 0.25s ease, border-color 0.25s ease, box-shadow 0.25s ease ;
}

/* Vuoto: bordo tratteggiato, invita a trascinare le variabili */
.rj-vs-target.rj-vs-empty {
    border: 2px dashed rgba(62, 109, 169, 0.55) ;
    background: rgba(62, 109, 169, 0.06) ;
}

/* Compilato: bordo pieno, sfondo e ombra piu' marcati */
.rj-vs-target.rj-vs-filled {
    border: 2px solid #3e6da9 ;
    background: rgba(62, 109, 169, 0.14) ;
    box-shadow: 0 2px 6px rgba(62, 109, 169, 0.20) ;
}

/* Ghost-label (placeholder nativo jamovi) quando il box e' vuoto */
.rj-vs-target.rj-vs-empty .column-ghost-label {
    color: rgba(62, 109, 169, 0.7) ;
    font-weight: 400 ;
    font-style: italic ;
}

/* Freccia a doppio chevron al posto di quella di default */
.jmv-toolbar .jmv-toolbar-button.jmv-variable-transfer > .jmv-toolbar-button-icon {
    width: 22px ;
    height: 22px ;
    background-position: center ;
    background-repeat: no-repeat ;
    opacity: 0.65 ;
    transition: opacity 0.2s ease, transform 0.1s ease ;
}

.rj-vs-transfer-btn:hover > .jmv-toolbar-button-icon {
    opacity: 1 ;
}

.rj-vs-transfer-btn:active > .jmv-toolbar-button-icon {
    transform: scale(0.85) ;
}

.jmv-toolbar.arrow-right .jmv-toolbar-button.jmv-variable-transfer > .jmv-toolbar-button-icon {
    background-image: url("data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2024%2024'%20fill='none'%3E%3Cpath%20d='M11%206.3%2016.7%2012%2011%2017.7'%20stroke='%233E6DA9'%20stroke-width='3.75'%20stroke-linecap='round'%20stroke-linejoin='round'/%3E%3Cpath%20d='M5.3%206.3%2011%2012%205.3%2017.7'%20stroke='%23ECA038'%20stroke-width='3.75'%20stroke-linecap='round'%20stroke-linejoin='round'/%3E%3C/svg%3E") ;
}

.jmv-toolbar.arrow-left .jmv-toolbar-button.jmv-variable-transfer > .jmv-toolbar-button-icon {
    background-image: url("data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2024%2024'%20fill='none'%3E%3Cpath%20d='M11%206.3%205.3%2012%2011%2017.7'%20stroke='%23ECA038'%20stroke-width='3.75'%20stroke-linecap='round'%20stroke-linejoin='round'/%3E%3Cpath%20d='M18.7%206.3%2013%2012%2018.7%2017.7'%20stroke='%233E6DA9'%20stroke-width='3.75'%20stroke-linecap='round'%20stroke-linejoin='round'/%3E%3C/svg%3E") ;
}

/* =====================================================
   ACCORDION "Variables" (Pjp) - CustomControl al posto del
   CollapseBox nativo, stesso stile "Info & Notes" gia' in uso
   in Metafora (icona +/- animata via SVG, titolo con separatori).
   Classi applicate da main.js::pjpAccordion_creating/applyAccordionState().
   ===================================================== */

.rj-accordion-header {
    font-size: 12px ;
    font-weight: 500 ;
    border: none ;
    background-color: transparent ;
    padding: 4px 0 ;
    color: #3e6da9 ;
    width: 100% ;
    text-align: left ;
    cursor: pointer ;
    display: flex ;
    align-items: center ;
    transition: all 0.3s ease ;
    border-radius: 0 ;
}

.rj-accordion-header:hover {
    color: #1565c0 ;
    background-color: transparent ;
}

.rj-accordion-header.rj-accordion-expanded {
    font-weight: 700 ;
}

.rj-accordion-icon-container {
    width: 18px ;
    height: 18px ;
    display: flex ;
    align-items: center ;
    justify-content: center ;
    margin-right: 6px ;
    flex-shrink: 0 ;
    border-right: 1px solid rgba(62, 109, 169, 0.50) ;
    padding-right: 6px ;
}

.rj-plus-minus-icon {
    width: 12px ;
    height: 12px ;
}

.rj-plus-minus-icon .horizontal,
.rj-plus-minus-icon .vertical {
    transition: transform 0.3s ease, opacity 0.3s ease ;
    transform-origin: center ;
}

.rj-accordion-header.rj-accordion-expanded .rj-plus-minus-icon .vertical {
    transform: rotate(90deg) ;
    opacity: 0 ;
}

.rj-accordion-title {
    margin-left: 0px ;
    display: flex ;
    align-items: center ;
    flex-grow: 1 ;
}

.rj-accordion-title::before,
.rj-accordion-title::after {
    content: '' ;
    height: 1px ;
    background-color: rgba(62, 109, 169, 0.50) ;
    transition: all 0.3s ease ;
}

.rj-accordion-title::before {
    flex-basis: 30px ;
    margin: 0 8px ;
}

.rj-accordion-title::after {
    flex-basis: 30px ;
    margin-left: 8px ;
}

.rj-accordion-header.rj-accordion-expanded .rj-accordion-title::before,
.rj-accordion-header.rj-accordion-expanded .rj-accordion-title::after {
    height: 2px ;
    background-color: rgba(62, 109, 169, 0.70) ;
}

.rj-accordion-header.rj-accordion-expanded .rj-accordion-title::after {
    flex-grow: 1 ;
}

.rj-accordion-content {
    max-height: 0 ;
    overflow: hidden ;
    transition: max-height 0.3s ease-out ;
}

.rj-accordion-content.rj-accordion-expanded {
    max-height: 2000px ;
    transition: max-height 0.4s ease-in ;
}


.ace_editor.ace_autocomplete .ace_completion-highlight {
    color: inherit ;
    text-shadow: none ;
}

.ace_editor.ace_autocomplete .ace_line {
    line-height: 20px ;
}

.ace_icon_data,
.ace_icon_func,
.ace_icon_var,
.ace_icon_ns {
    display: inline-block ;
    width: 24px ;
    background-repeat: no-repeat ;
    background-size: 12px ;
    background-position: center ;
}

.ace_icon_data {
    background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAQklEQVR42mOImrXnPy0wA4jYeu8jVfGowZgG0yTy2jqn/8cFLly4SpYcyMwhajBIETXxEA6K0TAeDePRMMZjMC0wAFMtrQuuiigOAAAAAElFTkSuQmCC');
}

.ace_icon_func {
    background-image: url('data:image/svg+xml;base64,PHN2ZyBpZD0ic3ZnMiIgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGhlaWdodD0iMjQiIHdpZHRoPSIyNCIgdmVyc2lvbj0iMS4xIiB4bWxuczpjYz0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHZpZXdCb3g9IjAgMCAyNCAyNCI+PG1ldGFkYXRhIGlkPSJtZXRhZGF0YTEwIj48cmRmOlJERj48Y2M6V29yayByZGY6YWJvdXQ9IiI+PGRjOmZvcm1hdD5pbWFnZS9zdmcreG1sPC9kYzpmb3JtYXQ+PGRjOnR5cGUgcmRmOnJlc291cmNlPSJodHRwOi8vcHVybC5vcmcvZGMvZGNtaXR5cGUvU3RpbGxJbWFnZSIvPjxkYzp0aXRsZS8+PC9jYzpXb3JrPjwvcmRmOlJERj48L21ldGFkYXRhPjxyZWN0IGlkPSJyZWN0NDE1NiIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIgdHJhbnNmb3JtPSJtYXRyaXgoLjY4ODgxIC43MjQ5NCAtLjcxNjU4IC42OTc1MSAwIDApIiBoZWlnaHQ9IjIxLjYxMSIgd2lkdGg9IjExLjIxNSIgc3Ryb2tlPSIjM2M2Y2E1IiB5PSItMTEuMjQiIHg9IjExLjM2MiIgc3Ryb2tlLXdpZHRoPSIuNzk0NjEiIGZpbGw9IiM3NzlmY2UiLz48L3N2Zz4=');
}

.ace_icon_ns {
    background-image: url('data:image/svg+xml;base64,PHN2ZyBpZD0ic3ZnMiIgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGhlaWdodD0iMjQiIHdpZHRoPSIyNCIgdmVyc2lvbj0iMS4xIiB4bWxuczpjYz0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHZpZXdCb3g9IjAgMCAyNCAyNCI+PG1ldGFkYXRhIGlkPSJtZXRhZGF0YTEwIj48cmRmOlJERj48Y2M6V29yayByZGY6YWJvdXQ9IiI+PGRjOmZvcm1hdD5pbWFnZS9zdmcreG1sPC9kYzpmb3JtYXQ+PGRjOnR5cGUgcmRmOnJlc291cmNlPSJodHRwOi8vcHVybC5vcmcvZGMvZGNtaXR5cGUvU3RpbGxJbWFnZSIvPjxkYzp0aXRsZS8+PC9jYzpXb3JrPjwvcmRmOlJERj48L21ldGFkYXRhPjxwYXRoIGlkPSJwYXRoNDE1NCIgZD0ibTExLjk5OCAwLjYwOTM4LTEwLjQ2MyA1LjcwN3YxMS40OTRsMTAuNDY1IDUuNTg1IDEwLjQ2NS01LjU4NHYtMTEuNDNsLTEwLjQ2Ny01Ljc3MTZ6bS0wLjAwMzkgMS4xMzY3YTAuNTM0NCAwLjUzNDQgMCAwIDEgMC4yNTggMC4wNjY0bDcuOTE2IDQuMzY1MmEwLjUzNDQgMC41MzQ0IDAgMCAxIC0wLjAwNTkgMC45Mzk0NWwtNy45MDQgNC4yMTY4YTAuNTM0NCAwLjUzNDQgMCAwIDEgLTAuNTA4IC0wLjAwMmwtNy44NzMtNC4yOTI5YTAuNTM0NCAwLjUzNDQgMCAwIDEgMCAtMC45Mzc1bDcuODYxLTQuMjg5MWEwLjUzNDQgMC41MzQ0IDAgMCAxIDAuMjU1ODYgLTAuMDY2NDA2em05LjAxMTcgNi4wNDg4YTAuNTM0NCAwLjUzNDQgMCAwIDEgMC41MjkzIDAuNTM1MTZ2OC42MDE2YTAuNTM0NCAwLjUzNDQgMCAwIDEgLTAuMjgzMiAwLjQ3MDdsLTggNC4yNjc2YTAuNTM0NCAwLjUzNDQgMCAwIDEgLTAuNzg3MTEgLTAuNDcwN3YtOC41OTk2YTAuNTM0NCAwLjUzNDQgMCAwIDEgMC4yODMyIC0wLjQ3MDdsOC00LjI2OTVhMC41MzQ0IDAuNTM0NCAwIDAgMSAwLjI1NzgxIC0wLjA2NDQ1M3oiIHRyYW5zZm9ybT0ibWF0cml4KDEuMDU3MyAwIDAgMS4wNTI3IC0uNjg4MjAgLS42MjY0NikiIGZpbGw9IiM4OTViYTgiLz48L3N2Zz4=');
}

`;

let node = document.createElement('style');
node.innerHTML = css;
document.body.appendChild(node);

module.exports = undefined;
