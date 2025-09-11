
const ace = require('brace');

require('brace/mode/r');
require('brace/ext/language_tools');

require('./css');
const Suggest = require('./suggest');
const SuggestIcons = require('./suggesticons');

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

        $contents.insertAdjacentHTML('beforeend', `
            <div id="editor-box">
                <div id="toolbar">
                    <div id="config" title="Configuration"></div>
                    <div id="run" title="Run"></div>
                </div>
                <div id="editor"></div>
                <div id="info">Ctrl + Shift + Enter to run</div>
            </div>`);

        let $config = $contents.querySelector('#config');
        $config.innerHTML = `
            <div id="menu">
                <label id="r-label">R Version</label>
                <select id="r-version">
                    <option value="bundled">jamovi R</option>
                    <option value="external">System R</option>
                </select>
                <label id="output-label">Output</label>
                <select id="output">
                    <option value="noEcho">Show output only</option>
                    <option value="echo">Show code and output</option>
                </select>
                <div id="figure-size">
                    <div id="figure-size-title">Figure size (px)</div>
                    <label>Width</label>
                    <input id="figure-width" placeholder="Default">
                    <label>Height</label>
                    <input id="figure-height" placeholder="Default">
                </div>
            </div>`;

        this.$editor = $contents.querySelector('#editor');
        this.$run = $contents.querySelector('#run');
        this.$menu = $contents.querySelector('#menu');

        this.$run.addEventListener('click', () => this.run(ui));

        this.$output = $config.querySelector('#output');
        this.$output.addEventListener('change', (event) => {
            ui.output.setValue(this.$output.value);
        });

        this.$r = $config.querySelector('#r-version');
        this.$r.addEventListener('change', (event) => {
            ui.R.setValue(this.$r.value);
        });

        this.$figWidth = $config.querySelector('#figure-width');
        this.$figHeight = $config.querySelector('#figure-height');

        this.$menu.querySelectorAll('input').forEach(el => el.addEventListener('keyup', (event) => {
            if (event.keyCode == 13)
                this.run(ui);
        }));

        $config.addEventListener('click', (event) => {
            if (event.target === $config)
                this.toggleMenu(ui);
        });

        this.$editor.addEventListener('click', () => {
            this.hideMenu(ui);
        });

        if (navigator.platform === 'MacIntel') {
            let $info = $contents.querySelector('#info');
            $info.textContent = '\u2318 + Shift + Enter to run';
        }

        this.editor = ace.edit('editor');

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
                event.args.text = event.args.text.replace(/[\r\u200B-\u200D\uFEFF]/g, '');
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

        this.toggleMenu = (ui) => {
            if ( ! this.$menu.classList.contains('visible'))
                this.showMenu(ui);
            else
                this.hideMenu(ui);
        };

        this.showMenu = (ui) => {
            this.$menu.classList.add('visible');
        };

        this.hideMenu = (ui) => {
            this.$menu.classList.remove('visible');

            ui.view.model.options.beginEdit();
            ui.figWidth.setValue(this.$figWidth.value);
            ui.figHeight.setValue(this.$figHeight.value);
            ui.output.setValue(this.$output.value);
            ui.R.setValue(this.$r.value);
            ui.view.model.options.endEdit();
        };

        this.run = async(ui) => {

            let script = this.currentSession.getDocument().getValue();
            script = script.replace(/[\r\u200B-\u200D\uFEFF]/g, '');

            let columns = [ ];
            if (window.name === 'Rj-Rj')
                columns = await this.getColumnNames();

            ui.view.model.options.beginEdit();

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
        if ( ! this.currentSession.allColumns)
            return;
        if (event.dataType !== 'columns')
            return;
        this.getColumnNames().then((columns) => {
            let old = ui.vars.value();
            if ( ! arrayEquals(old, columns))
                ui.vars.setValue(columns);
        });
    },

    update(ui, event) {

        let id = event.id;
        this.currentSession = this.editSessions[id];

        if (this.currentSession === undefined) {

            let code = ui.code.value();
            this.currentSession = ace.createEditSession(code, 'ace/mode/r');
            this.editSessions[id] = this.currentSession;
        }

        this.editor.setSession(this.currentSession);

        this.$figWidth.value = ui.figWidth.value();
        this.$figHeight.value = ui.figHeight.value();
        this.$output.value = ui.output.value();
        this.$r.value = ui.R.value();
    },
};


module.exports = events;
