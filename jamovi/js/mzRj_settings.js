// Impostazioni condivise: conserva i valori bundled/external salvati negli OMV.
module.exports = function(ui, root, onRun) {
    const button = root.querySelector('#config');
    const menu = root.querySelector('#menu');
    const output = root.querySelector('#output');
    const width = root.querySelector('#figure-width');
    const height = root.querySelector('#figure-height');
    const radios = Array.from(menu.querySelectorAll('input[name="r-interpreter"]'));
    const controller = new AbortController();
    const listen = (node, event, callback) => node.addEventListener(event, callback, {signal: controller.signal});
    const selection = {
        get value() { return (radios.find(input => input.checked) || {}).value || ui.R.value(); },
        set value(value) { radios.forEach(input => { input.checked = input.value === value; }); }
    };
    selection.value = ui.R.value();
    output.value = ui.output.value();
    width.value = ui.figWidth.value();
    height.value = ui.figHeight.value();
    const commit = () => {
        const settings = [[ui.figWidth, width.value], [ui.figHeight, height.value],
            [ui.output, output.value], [ui.R, selection.value]];
        const changed = settings.filter(([option, value]) => option.value() !== value);
        if (!changed.length)
            return;
        ui.view.model.options.beginEdit();
        try { changed.forEach(([option, value]) => option.setValue(value)); }
        finally { ui.view.model.options.endEdit(); }
    };
    // The positioning wrapper handles dragging; #menu uses Pj's CSS transition.
    const anchor = root.ownerDocument.createElement('div');
    anchor.id = 'menu-position';
    menu.before(anchor);
    anchor.appendChild(menu);
    menu.hidden = false;
    menu.inert = true;
    let open = false;
    let shift = {x:0,y:0};
    let drag = null;
    const position = () => {
        anchor.style.transform = 'none';
        const initial = anchor.getBoundingClientRect();
        const scaleX = initial.width / anchor.offsetWidth || 1;
        const scaleY = initial.height / anchor.offsetHeight || scaleX;
        menu.style.maxWidth = Math.max(100, (window.innerWidth - 24) / scaleX) + 'px';
        menu.style.maxHeight = Math.max(60, (window.innerHeight - 24) / scaleY) + 'px';
        const size = anchor.getBoundingClientRect();
        const left = Math.max(12, Math.min(size.left, window.innerWidth - size.width - 12));
        const top = Math.max(12, Math.min(size.top, window.innerHeight - size.height - 12));
        shift = {x:(left-size.left)/scaleX,y:(top-size.top)/scaleY};
        anchor.style.transform = `translate(${shift.x}px, ${shift.y}px)`;
    };
    const hide = (apply = true, focus = false) => {
        if (!open) return;
        if (apply) commit();
        open = false;
        drag = null;
        if (focus || menu.contains(root.ownerDocument.activeElement)) button.focus();
        menu.inert = true;
        menu.setAttribute('aria-hidden', 'true');
        button.setAttribute('aria-expanded', 'false');
        menu.classList.remove('visible');
    };
    const show = () => {
        position();
        open = true;
        menu.inert = false;
        menu.setAttribute('aria-hidden', 'false');
        button.setAttribute('aria-expanded', 'true');
        // Establish the closed CSS state before the first opening, as in Pj.
        menu.getBoundingClientRect();
        menu.classList.add('visible');
    };
    listen(button, 'click', () => open ? hide() : show());
    listen(root.querySelector('#close-settings'), 'click', () => hide(true, true));
    listen(menu, 'pointerdown', event => {
        if (!open || event.button !== 0 || event.target.closest('button,input,select,label,option')) return;
        const bounds = menu.getBoundingClientRect();
        drag = {x:event.clientX,y:event.clientY,bounds,shift:{...shift},
            sx:bounds.width/menu.offsetWidth || 1,sy:bounds.height/menu.offsetHeight || 1};
        event.preventDefault();
    });
    listen(root.ownerDocument, 'pointermove', event => {
        if (!drag) return;
        const left = Math.max(8, Math.min(drag.bounds.left+event.clientX-drag.x,window.innerWidth-drag.bounds.width-8));
        const top = Math.max(8, Math.min(drag.bounds.top+event.clientY-drag.y,window.innerHeight-drag.bounds.height-8));
        shift = {x:drag.shift.x+(left-drag.bounds.left)/drag.sx,y:drag.shift.y+(top-drag.bounds.top)/drag.sy};
        anchor.style.transform = `translate(${shift.x}px, ${shift.y}px)`;
    });
    listen(root.ownerDocument, 'pointerup', () => { drag = null; });
    listen(root.ownerDocument, 'pointercancel', () => { drag = null; });
    listen(root.ownerDocument, 'keydown', event => {
        if (event.key === 'Escape' && open) { event.preventDefault(); hide(true,true); }
    });
    listen(menu, 'keydown', event => {
        if (event.key === 'Escape') {
            event.preventDefault();
            event.stopPropagation();
            hide(true, true);
        } else if (event.key === 'Enter' && (event.target === width || event.target === height)) {
            event.preventDefault();
            onRun();
        }
    });
    listen(output, 'change', () => {
        if (ui.output.value() !== output.value)
            ui.output.setValue(output.value);
    });
    radios.forEach(input => listen(input, 'change', () => {
        if (input.checked && ui.R.value() !== input.value)
            ui.R.setValue(input.value);
    }));
    listen(root.ownerDocument, 'pointerdown', event => {
        // Run applica impostazioni e codice in una sola transazione.
        if (open && !menu.contains(event.target) && !button.contains(event.target) &&
                !root.querySelector('#run').contains(event.target))
            hide();
    });
    listen(root, 'transitionend', event => { if (open && event.target !== menu) position(); });
    listen(window, 'resize', position);
    listen(root.ownerDocument, 'scroll', position);
    return {selection, show, hide, commit, dispose: () => controller.abort()};
};
