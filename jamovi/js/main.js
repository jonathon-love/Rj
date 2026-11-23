const _ = require('./mzRj_i18n');
const moduleVersion = require('./mzRj_version');

const ace = require('brace');

require('brace/mode/r');
require('brace/ext/language_tools');

require('./css');
const Suggest = require('./suggest');
const SuggestIcons = require('./suggesticons');
const initSettings = require('./mzRj_settings');
const initFiles = require('./mzRj_editor_files');
const createToast = require('./mzRj_toast');
const styleVariables = require('./mzRj_variables');
const initOmvFiles = require('./mzRj_omv_files');

// const SNIPPETS = require('./snippets');
// const snippetManager = ace.acequire('ace/snippets').snippetManager;
// const snippets = snippetManager.parseSnippetFile(SNIPPETS);
// snippetManager.register(snippets, 'r');


function arrayEquals(a, b) {
    return Array.isArray(a) &&
        Array.isArray(b) &&
        a.length === b.length &&
        a.every((val, index) => val === b[index]);
}


const events = {
    loaded(ui) {

        this.editSessions = { };

        let $contents = ui.view.el;
        $contents.style.display = 'flex';
        $contents.style.flexDirection = 'column';
        $contents.classList.add('mzrj-editor-content');
        $contents.classList.toggle('mzrj-plain-editor', !ui.rjpAccordion);

        $contents.insertAdjacentHTML('beforeend', `
            <div id="editor-box" class="mzrj-editor">
                <div id="service-bar"><button type="button" id="load-service" title="${_('Run a preparatory R script before the editor')}">${_('Service…')}</button><span id="service-name"></span><button type="button" id="remove-service" title="${_('Remove Service script')}" aria-label="${_('Remove Service script')}" hidden>×</button></div>
                <div id="toolbar">
                    <div id="editor-heading"><button type="button" id="clear-script">${_('Clear')}</button><span>${_('R editor')}</span><span id="editor-filename"></span></div>
                    <div id="editor-actions">
                        <div id="script-actions" role="group" aria-label="${_('Scripts')}"><span id="scripts-label">${_('Scripts')}</span><button type="button" id="load-script">${_('Load')}</button><button type="button" id="save-script">${_('Save')}</button></div>
                        <div id="config-container">
                        <button type="button" id="config" title="${_('Settings')}" aria-label="${_('Settings')}" aria-expanded="false" aria-controls="menu">
                            <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 6h16M4 12h16M4 18h16"/><circle cx="9" cy="6" r="2.2"/><circle cx="16" cy="12" r="2.2"/><circle cx="8" cy="18" r="2.2"/></svg>
                        </button>
                <div id="menu" role="region" aria-label="${_('R editor settings')}" aria-hidden="true" hidden>
                    <div class="mzrj-setting-row"><label for="output">${_('Output')}</label>
                        <select id="output"><option value="noEcho">${_('Show output only')}</option><option value="echo">${_('Show code and output')}</option></select>
                    </div>
                    <section id="figure-size" aria-labelledby="figure-size-title">
                        <div id="figure-size-title">${_('Figure size (px)')}</div>
                        <div class="mzrj-figure-inputs"><label for="figure-width">${_('Width')}</label><input id="figure-width" placeholder="${_('Default')}" inputmode="numeric">
                            <label for="figure-height">${_('Height')}</label><input id="figure-height" placeholder="${_('Default')}" inputmode="numeric"></div>
                    </section>
                    <div id="code-label"><span>${_('R Code')}</span><span id="rj-module-version"></span></div>
                    <div class="mzrj-interpreter-row"><span id="r-label">${_('R interpreter:')}</span>
                        <div id="r-interpreter" role="radiogroup" aria-labelledby="r-label">
                            <label title="${_('R included with jamovi.')}"><input type="radio" name="r-interpreter" value="bundled"><span>${_('Embedded')}</span></label>
                            <label title="${_('R installed on your computer, using its own libraries.')}"><input type="radio" name="r-interpreter" value="external"><span>${_('System')}</span></label>
                        </div>
                    </div>
                    <section id="omv-files"><div class="mzrj-omv-heading"><strong>${_('External OMV files')}</strong><span class="mzrj-omv-input"></span><button type="button" id="save-omv" disabled>${_('Save…')}</button></div>
                    <p>dataext: <span id="dataext-name">${_('Empty')}</span><span id="dataext-dimensions"></span></p>
                    <label class="mzrj-preview"><input type="checkbox" id="preview-dataext">${_('Show preview in Results')}</label><p>${_('Separate from the current jamovi dataset.')}</p></section>
                </div>
                        </div><button type="button" id="run" title="${_('Run')}" aria-label="${_('Run')}">
                            <svg viewBox="0 0 24 24" aria-hidden="true" fill="currentColor"><path d="M8 5.5a1 1 0 0 1 1.5-.86l10 6a1 1 0 0 1 0 1.72l-10 6A1 1 0 0 1 8 17.5Z"/></svg>
                        </button>
                    </div>
                </div>
                <input type="file" id="editor-file" accept=".R,.r" hidden><input type="file" id="service-file" accept=".R,.r" hidden>
                <div id="editor-message" role="status" hidden></div>
                <div id="editor-replace" hidden><span id="replace-message"></span><button type="button" id="replace-script">${_('Replace')}</button><button type="button" id="cancel-script">${_('Cancel')}</button></div>
                <div id="editor"></div>
                <div id="info">${_('Ctrl + Shift + Enter to run')}</div>
            </div>`);

        $contents.querySelector('#rj-module-version').textContent = 'Rj v' + moduleVersion;
        this.$editor = $contents.querySelector('#editor');
        this.$run = $contents.querySelector('#run');
        this.$menu = $contents.querySelector('#menu');
        this.$run.addEventListener('click', () => this.run(ui));
        if (this.settings)
            this.settings.dispose();
        this.settings = initSettings(ui, $contents, () => this.run(ui));
        this.$output = $contents.querySelector('#output');
        this.$r = this.settings.selection;
        this.$figWidth = $contents.querySelector('#figure-width');
        this.$figHeight = $contents.querySelector('#figure-height');
        this.$editor.addEventListener('click', () => this.hideMenu(ui));

        if (navigator.platform === 'MacIntel') {
            let $info = $contents.querySelector('#info');
            $info.textContent = _('\u2318 + Shift + Enter to run');
        }

        this.editor = ace.edit(this.$editor);
        if (this.notifications) this.notifications.dispose();
        this.notifications = createToast($contents);
        this.showToast = (text, options) => this.notifications.show(text, options);
        initFiles.call(this, ui, $contents);
        styleVariables(ui);
        initOmvFiles(ui, this.$menu);

        this.editor.$blockScrolling = Infinity; // disable a warning
        this.editor.setShowPrintMargin(false);
        this.editor.setHighlightActiveLine(false);
        this.editor.focus();

        this.editor.setOptions({
            enableBasicAutocompletion: true,
        });

        this.editor.commands.on('afterExec', (event) => {
            let editor = event.editor;
            if (event.command.name == 'insertstring') {
                let position = editor.getCursorPosition();
                let line = editor.getSession().getDocument().getLine(position.row);
                let before = line.substring(0, position.column);
                if (/^[\w.]$/.test(event.args) && /[A-Za-z0-9_\.\$]{3}\:?$/.test(before))
                    editor.execCommand('startAutocomplete');
                else if (event.args == ':' && /[A-Za-z0-9]\:\:\:?$/.test(before))
                    editor.execCommand('startAutocomplete');
            }
            else if (event.command.name == 'backspace' &&
                editor.completer &&
                editor.completer.activated)
                    editor.execCommand('startAutocomplete');
            else if (event.command.name === 'startAutocomplete')
                SuggestIcons.add(event.editor);
        });

        this.editor.commands.on('exec', (event) => {
            if (event.command.name === 'indent') {
                let editor = event.editor;
                let position = editor.getCursorPosition();
                let line = editor.getSession().getDocument().getLine(position.row);
                let before = line.substring(0, position.column);
                if (/[A-Za-z0-9_\.\$\:]$/.test(before)) {
                    editor.execCommand('startAutocomplete');
                    event.preventDefault();
                }
            }
            else if (event.command.name === 'paste') {
                // some times these extra kookie characters show up
                event.args.text = event.args.text.replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n');
            }
        });

        // clear the default completers
        this.editor.completers.splice(0, this.editor.completers.length);

        // add the new one
        this.editor.completers.push(new Suggest(() => {
            return this.getColumnNames();
        }));

        this.getColumnNames = () => {
            return this.requestData('columns', {  })
                .then((data) => {
                    return data.columns.map(col => col.name);
                }).then((names) => {
                    // exclude filters
                    let index = 0;
                    for (;index < names.length; index++) {
                        let name = names[index];
                        if (/^Filter [1-9][0-9]*$/.exec(name) ||
                            /^F[1-9][0-9]* \([1-9][0-9]*\)$/.exec(name))
                                continue; // a filter
                        else
                            break; // not a filter
                    }
                    return names.slice(index);
                });
        };

        this.showMenu = () => this.settings.show();
        this.hideMenu = (ui, apply = true) => this.settings.hide(apply);

        this.run = async(ui) => {
            if (!this.currentSession)
                return;
            this.hideMenu(ui, false);
            const session = this.currentSession;
            const request = this.runRequest = (this.runRequest || 0) + 1;

            let script = this.currentSession.getDocument().getValue();
            script = script.replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n');

            let columns = [ ];
            try {
                if (window.name === 'Rj-Rj') columns = await this.getColumnNames();
            } catch (error) {
                if (session === this.currentSession && request === this.runRequest)
                    this.showToast(_('Unable to read dataset columns. Please try again.'), {kind:'error', duration:10000});
                return;
            }
            if (session !== this.currentSession || request !== this.runRequest)
                return;

            ui.view.model.options.beginEdit();

            ui.editorCleared.setValue(false);
            ui.figWidth.setValue(this.$figWidth.value);
            ui.figHeight.setValue(this.$figHeight.value);
            ui.output.setValue(this.$output.value);
            ui.R.setValue(this.$r.value);

            if (window.name === 'Rj-Rj') {
                let match = script.match(/^\s*\#\s*\((.*)\)/);
                if (match !== null) {
                    let content = match[1];
                    let vars = content.split(',');
                    vars = vars.map(s => s.trim());
                    vars = vars.filter(v => columns.includes(v));
                    ui.vars.setValue(vars);
                    ui.code.setValue(script);
                    this.currentSession.allColumns = false;
                }
                else {
                    ui.vars.setValue(columns);
                    ui.code.setValue(script);
                    this.currentSession.allColumns = true;
                }
            }
            else {
                ui.code.setValue(script);
            }

            // toggle toggle so the analysis *always* reruns
            // even if nothing has changed
            ui.toggle.setValue( ! ui.toggle.value());

            ui.view.model.options.endEdit();

            this.editor.focus();
        };

        this.$editor.addEventListener('keydown', (event) => {

            if (event.keyCode === 13 && (event.metaKey || event.ctrlKey) && event.shiftKey) {
                // ctrl+shift+enter
                this.run(ui);
                event.stopPropagation();
            }
            else if (event.keyCode === 65 && event.metaKey) {
                // ctrl+a
                this.$editor.select();
            }
            else if (event.keyCode === 67 && (event.metaKey || event.ctrlKey) && event.shiftKey)             {
                // ctrl+shift+c
                this.editor.toggleCommentLines();
            }
            else if (event.keyCode === 191 && (event.metaKey || event.ctrlKey)) {
                // ctrl+/
                this.editor.toggleCommentLines();
            }
        });


    },

    onDataChanged(ui, event) {
        if ( ! this.currentSession || ! this.currentSession.allColumns)
            return;
        if (event.dataType !== 'columns')
            return;
        const session = this.currentSession;
        this.getColumnNames().then((columns) => {
            if (session !== this.currentSession)
                return;
            let old = ui.vars.value();
            if ( ! arrayEquals(old, columns))
                ui.vars.setValue(columns);
        });
    },

    onChange_vars(ui) { styleVariables(ui); },

    update(ui, event) {
        styleVariables(ui);

        let id = event.id;
        const previous = this.currentSession;
        this.currentSession = this.editSessions[id];

        if (this.currentSession === undefined) {

            const stored = ui.editorState.value() || {};
            const code = stored.hasDraft ? stored.draft : ui.code.value();
            const session = ace.createEditSession(code, 'ace/mode/r');
            session.rjState = {draft:code,hasDraft:!!stored.hasDraft,filename:stored.filename||'',baseline:stored.hasDraft ? stored.baseline : code,serviceCode:stored.serviceCode||'',serviceName:stored.serviceName||''};
            this.currentSession = session;
            this.editSessions[id] = session;
            session.on('change', () => { if (session === this.currentSession) this.persistEditor(); });
        }
        if (previous && previous !== this.currentSession) {
            this.settings.hide(false);
            this.notifications.clear();
            this.fileRequest = (this.fileRequest || 0) + 1;
            this.runRequest = (this.runRequest || 0) + 1;
            this.pendingFile = null;
            ui.view.el.querySelector('#editor-replace').hidden = true;
        }

        this.editor.setSession(this.currentSession);
        this.refreshFiles();
        this.placeServiceHeader();
        initOmvFiles(ui, this.$menu);

        this.$figWidth.value = ui.figWidth.value();
        this.$figHeight.value = ui.figHeight.value();
        this.$output.value = ui.output.value();
        this.$r.value = ui.R.value();
    },
};


module.exports = events;
