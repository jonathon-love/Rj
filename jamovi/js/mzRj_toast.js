const _ = require('./mzRj_i18n');

// One owned notification per editor; no document-wide queue or HTML interpolation.
module.exports = function createToast(root) {
    const doc = root.ownerDocument;
    let node = null, timer = null, remaining = 0, started = 0, hovered = false, focused = false;
    const clear = () => {
        clearTimeout(timer); timer = null;
        if (node) node.remove();
        node = null; hovered = false; focused = false;
        doc.removeEventListener('keydown', onKey);
    };
    const onKey = event => { if (event.key === 'Escape') clear(); };
    const resume = () => { if (!hovered && !focused && !timer && remaining > 0) { started = Date.now(); timer = setTimeout(clear, remaining); } };
    const pause = () => { if (timer) { clearTimeout(timer); timer = null; remaining = Math.max(1, remaining - (Date.now() - started)); } };
    const show = (text, {kind='info', duration=6000} = {}) => {
        clear();
        if (!text || !root.isConnected) return;
        node = doc.createElement('div');
        node.className = 'mzrj-toast';
        node.dataset.kind = kind === 'error' ? 'error' : kind === 'warning' ? 'warning' : 'info';
        node.setAttribute('role', kind === 'error' ? 'alert' : 'status');
        node.setAttribute('aria-atomic', 'true');
        const message = doc.createElement('span');
        message.className = 'mzrj-toast-message'; message.textContent = String(text);
        const close = doc.createElement('button');
        close.type = 'button'; close.textContent = _('Close');
        close.setAttribute('aria-label', _('Close notification'));
        close.addEventListener('click', clear);
        node.append(message, close); root.appendChild(node);
        doc.addEventListener('keydown', onKey);
        node.addEventListener('mouseenter', () => { hovered = true; pause(); });
        node.addEventListener('mouseleave', () => { hovered = false; resume(); });
        node.addEventListener('focusin', () => { focused = true; pause(); });
        node.addEventListener('focusout', event => { if (node && !node.contains(event.relatedTarget)) { focused = false; resume(); } });
        remaining = Number.isFinite(duration) ? Math.max(0, duration) : 6000;
        resume();
    };
    // Analysis roots are replaced without a separate unload callback.
    const observer = new MutationObserver(() => { if (!root.isConnected) dispose(); });
    observer.observe(doc.documentElement, {childList:true, subtree:true});
    const dispose = () => { clear(); observer.disconnect(); };
    return {show, clear, dispose};
};
