
const ace = require('brace');

require('brace/mode/r');
require('brace/ext/language_tools');

require('./css');
const funcs = require('./funcs');

const events = {
	loaded(ui) {

	    this.editSessions = { };

	    let $contents = ui.view.$el;
	    $contents.css('display', 'flex');
	    $contents.css('flex-direction', 'column');

		$contents.prepend(`
		    <div id="editor-box">
		        <div id="toolbar">
		            <div id="config"></div>
		            <div id="run"></div>
		        </div>
		        <div id="editor"></div>
                <div id="info">Ctrl + Shift + Enter to run</div>
            </div>`);

        let $config = $contents.find('#config');
        $config.append(`
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
            </div>`);

		this.$editor = $contents.find('#editor');
		this.$run = $contents.find('#run');
		this.$menu = $contents.find('#menu');

		this.$run.on('click', () => this.run(ui));

		this.$output = $config.find('#output');
		this.$output.on('change', (event) => {
		    ui.output.setValue(this.$output.val());
		});

		this.$r = $config.find('#r-version');
		this.$r.on('change', (event) => {
		    ui.R.setValue(this.$r.val());
		});

		this.$figWidth = $config.find('#figure-width');
		this.$figHeight = $config.find('#figure-height');

		this.$menu.find('input').on('keyup', (event) => {
		    if (event.keyCode == 13)
		        this.run(ui);
		});

		$config.on('click', (event) => {
		    if (event.target === $config[0])
		        this.toggleMenu(ui);
		});

		this.$editor.on('click', () => {
            this.hideMenu(ui);
		});

		if (navigator.platform === 'MacIntel') {
		    let $info = $contents.find('#info');
		    $info.text('\u2318 + Shift + Enter to run');
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
            if (event.command.name == "insertstring") {
                let position = editor.getCursorPosition();
                let line = editor.getSession().getDocument().getLine(position.row);
                let before = line.substring(0, position.column);
                if (/^[\w.]$/.test(event.args) && /[A-Za-z0-9_\.\$]{3}\:?$/.test(before))
                    editor.execCommand('startAutocomplete');
                else if (event.args == ':' && /[A-Za-z0-9]\:\:\:?$/.test(before))
                    editor.execCommand('startAutocomplete');
            }

            if (event.command.name == 'backspace' &&
                editor.completer &&
                editor.completer.activated)
                    editor.execCommand("startAutocomplete");
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
        });

        let self = this; // haven't had to do this in a while
        this.editor.completers.splice(0, this.editor.completers.length);
        this.editor.completers.push({
            identifierRegexps: [/[A-Za-z0-9_\.\$]/],
            getCompletions: function(editor, session, pos, prefix, callback) {

                let row = pos.row;
                let col = pos.column;
                let line = editor.getSession().getDocument().getLine(row);
                let before = line.substring(0, col - prefix.length);

                let entries = funcs;

                let match = before.match(/([A-Za-z][A-Za-z0-9]*)(\:\:\:?)$/);
                if (match) {  // if package
                    let ns = match[1];
                    let dots = match[2];
                    entries = entries.filter(entry => entry.ns === ns);
                }
                else {

                    let vars1 = self.columns.map(col => {
                        return {
                            name: 'data$' + col,
                            value: 'data$' + col,
                            meta: 'variable' }});
                    let vars2 = self.columns.map(col => {
                        return {
                            name: "'" + col + "'",
                            value: "'" + col + "'",
                            meta: 'variable' }});
                    entries = entries.concat(vars1).concat(vars2);
                }

                entries = entries.filter((entry) => {
                    return entry.value.toLowerCase().startsWith(prefix.toLowerCase());
                });

                let index = 0;

                entries = entries.map((entry) => {
                    // custom completer
                    entry.completer = this;
                    // provide scores so it retains alphabetic sort
                    let score = entries.length - index++;
                    if (entry.value.startsWith(prefix))
                        score += 1000;
                    entry.score = score;
                    return entry;
                });

                callback(null, entries);
            },
            insertMatch: (editor, entry) => {
                if (entry.type === 'func') {
                    editor.completer.insertMatch({value: entry.name + '()'});
                    let pos = editor.getCursorPosition();
                    if (pos.column > 0) {
                        pos.column -= 1;
                        editor.moveCursorToPosition(pos);
                    }
                }
                else if (entry.type === 'ns') {
                    editor.completer.insertMatch({value: entry.name});
                    setTimeout(() => editor.execCommand("startAutocomplete"), 0);
                }
                else {
                    editor.completer.insertMatch({value: entry.name});
                }
            },
        });

        this.toggleMenu = (ui) => {
            if ( ! this.$menu.hasClass('visible'))
		        this.showMenu(ui);
		    else
		        this.hideMenu(ui);
        };

        this.showMenu = (ui) => {
		    this.$menu.addClass('visible');
        };

        this.hideMenu = (ui) => {
	        this.$menu.removeClass('visible')

	        ui.view.model.options.beginEdit();
	        ui.figWidth.setValue(this.$figWidth.val());
	        ui.figHeight.setValue(this.$figHeight.val());
	        ui.output.setValue(this.$output.val());
	        ui.R.setValue(this.$r.val());
	        ui.view.model.options.endEdit();
        };

        this.run = (ui) => {

            let script = this.currentSession.getDocument().getValue();

            this.requestData('columns').then((data) => {

                let allVars = data.columns.map(col => col.name);

                ui.view.model.options.beginEdit();

                ui.figWidth.setValue(this.$figWidth.val());
	            ui.figHeight.setValue(this.$figHeight.val());
	            ui.output.setValue(this.$output.val());
	            ui.R.setValue(this.$r.val());

                let match = script.match(/^\s*\#\s*\((.*)\)/);
                if (match !== null) {
                    let content = match[1];
                    let vars = content.split(',');
                    vars = vars.map(s => s.trim());
                    vars = vars.filter(v => allVars.includes(v));
                    ui.vars.setValue(vars);
                    ui.code.setValue(script);
                }
                else {
                    ui.vars.setValue(allVars);
                    ui.code.setValue(script);
                }

                // toggle toggle so the analysis *always* reruns
                // even if nothing has changed
                ui.toggle.setValue( ! ui.toggle.value());

                ui.view.model.options.endEdit();

                this.editor.focus();
            });
    	};

        this.$editor.on('keydown', (event) => {
            if (event.keyCode === 13 && (event.metaKey || event.ctrlKey) && event.shiftKey) {
                this.run(ui);
                event.stopPropagation();
            }
            else if (event.keyCode === 65 && event.metaKey) {
                this.$editor.select();
            }
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

        this.$figWidth.val(ui.figWidth.value());
        this.$figHeight.val(ui.figHeight.value());
        this.$output.val(ui.output.value());
        this.$r.val(ui.R.value());

        this.requestData('columns').then((data) => {
            this.columns = data.columns.map(col => col.name);
        });
    },
};


module.exports = events;
