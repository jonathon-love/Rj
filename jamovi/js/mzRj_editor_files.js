const _ = require('./mzRj_i18n');
// Bozza, file e Service sono separati dal Run e condivisi da Rj/Rjp.
module.exports = function(ui, root) {
    if (this.disposeServiceHeader) this.disposeServiceHeader();
    const serviceBar = root.querySelector('#service-bar');
    const serviceName = root.querySelector('#service-name');
    const removeService = root.querySelector('#remove-service');
    let headerObserver = null;
    this.disposeServiceHeader = () => {
        if (headerObserver) headerObserver.disconnect();
        if (!root.contains(serviceBar)) serviceBar.remove();
    };
    this.placeServiceHeader = () => {
        const block = root.closest('.jmv-options-block');
        const header = (block && block.querySelector('.silky-options-header')) ||
            root.ownerDocument.querySelector('.silky-options-header');
        if (!header || header.contains(serviceBar)) return;
        const back = header.querySelector('.silky-sp-back-button');
        header.insertBefore(serviceBar, back && back.parentElement === header ? back : null);
        header.classList.add('mzrj-editor-header');
        const title = header.querySelector('.silky-options-title');
        if (title && window.name === 'Rj-Rjp' && !title.querySelector('.mzrj-editor-plus')) {
            title.textContent = _('Rj Editor');
            title.setAttribute('aria-label', _('Rj Editor plus'));
            const plus = root.ownerDocument.createElement('sub');
            plus.className = 'mzrj-editor-plus';
            plus.textContent = _('plus');
            title.appendChild(plus);
        }
        serviceBar.classList.add('mzrj-service-header');
        headerObserver = new MutationObserver(() => {
            if (!root.isConnected) this.disposeServiceHeader();
        });
        headerObserver.observe(block || header.parentElement, {childList:true,subtree:true});
    };
    const name = root.querySelector('#editor-filename');
    const message = root.querySelector('#editor-message');
    const replace = root.querySelector('#editor-replace');
    this.pendingFile = null;
    this.showMessage = text => { message.hidden = true; this.showToast(text, {kind:'warning'}); };
    this.refreshFiles = () => {
        if (!this.currentSession) return;
        const state = this.currentSession.rjState;
        name.textContent = (state.filename || _('Untitled')) + (this.currentSession.getValue() !== state.baseline ? ' *' : '');
        name.title = state.filename || _('Untitled');
        serviceName.textContent = state.serviceName || '';
        removeService.hidden = !state.serviceName;
    };
    this.persistEditor = () => {
        const session = this.currentSession;
        if (!session) return;
        session.rjState.draft = session.getValue();
        session.rjState.hasDraft = true;
        ui.editorState.setValue(Object.assign({}, session.rjState));
        this.refreshFiles();
    };
    const applyPending = () => {
        const pending = this.pendingFile; this.pendingFile = null; replace.hidden = true;
        if (!pending || pending.session !== this.currentSession) return;
        const state = this.currentSession.rjState;
        if (pending.service) { state.serviceName = pending.filename; state.serviceCode = pending.code; }
        else { state.filename = pending.filename; state.baseline = pending.code; this.currentSession.setValue(pending.code); }
        this.persistEditor(); this.editor.focus();
    };
    for (const [button, input, service] of [['load-script','editor-file',false],['load-service','service-file',true]]) {
        const chooser = root.querySelector('#' + input);
        root.querySelector('#' + button).addEventListener('click', () => { this.showMessage(''); chooser.click(); });
        chooser.addEventListener('change', () => {
            const file = chooser.files[0]; chooser.value = '';
            if (!file || !this.currentSession) return;
            if (!/\.r$/i.test(file.name)) { this.showMessage(_('Choose an R script (.R).')); return; }
            const session = this.currentSession;
            const request = this.fileRequest = (this.fileRequest || 0) + 1;
            const reader = new FileReader();
            reader.onerror = () => { if (session === this.currentSession && request === this.fileRequest) this.showMessage(_('Unable to read the selected R script.')); };
            reader.onload = () => {
                if (session !== this.currentSession || request !== this.fileRequest) return;
                this.pendingFile = {session, service, filename:file.name, code:String(reader.result).replace(/^\uFEFF/,'').replace(/\r\n?/g,'\n')};
                if (service ? session.rjState.serviceCode : session.getValue().trim()) {
                    root.querySelector('#replace-message').textContent = service ? _('Replace the current Service script?') : _('Replace the current editor code?');
                    replace.hidden = false; root.querySelector('#cancel-script').focus();
                } else applyPending();
            };
            reader.readAsText(file, 'UTF-8');
        });
    }
    root.querySelector('#replace-script').addEventListener('click', applyPending);
    root.querySelector('#cancel-script').addEventListener('click', () => { this.pendingFile = null; replace.hidden = true; this.editor.focus(); });
    root.querySelector('#remove-service').addEventListener('click', () => {
        if (!this.currentSession) return;
        this.currentSession.rjState.serviceName = ''; this.currentSession.rjState.serviceCode = ''; this.persistEditor();
    });
    root.querySelector('#save-script').addEventListener('click', () => {
        if (!this.currentSession) return;
        ui.view.model.options.beginEdit();
        try { this.persistEditor(); ui.saveEditorScript.setValue(true); }
        finally { ui.view.model.options.endEdit(); }
    });
    root.querySelector('#clear-script').addEventListener('click', () => {
        if (!this.currentSession) return;
        this.runRequest = (this.runRequest || 0) + 1; this.fileRequest = (this.fileRequest || 0) + 1;
        this.pendingFile = null; replace.hidden = true; this.showMessage('');
        ui.view.model.options.beginEdit();
        try {
            const previous = this.currentSession.rjState;
            this.currentSession.rjState = {draft:'',hasDraft:true,filename:'',baseline:'',serviceCode:previous.serviceCode,serviceName:previous.serviceName};
            this.currentSession.allColumns = false; this.currentSession.setValue(''); this.persistEditor();
            ui.code.setValue(''); ui.editorCleared.setValue(true); ui.toggle.setValue(!ui.toggle.value());
        } finally { ui.view.model.options.endEdit(); }
        this.editor.focus();
    });
    this.placeServiceHeader();
};
