const _ = require('./mzRj_i18n');
// Variable selector and accordion, matching Pjp presentation.
function hasValue(val) {
    return Array.isArray(val) && val.length > 0 && val[0] !== '';
}

function styleVariableSupplier(ui) {
    let field = ui.vars;
    if (field && field.el) {
        let filled = hasValue(field.value());
        field.el.classList.add('rj-vs-target');
        field.el.classList.toggle('rj-vs-filled', filled);
        field.el.classList.toggle('rj-vs-empty', ! filled);
    }

    let sourceList = document.querySelector('jmv-selectgrid.silky-variable-supplier');
    if (sourceList)
        sourceList.classList.add('rj-vs-source');

    document.querySelectorAll('button.jmv-variable-transfer').forEach((btn) => {
        btn.classList.add('rj-vs-transfer-btn');
    });
}

// ────────────────────────────────────────────────────────────────────
// ACCORDION "Variables" (solo Pjp): CustomControl al posto del
// CollapseBox nativo (rjpAccordion in pjp.a.yaml/pjp.u.yaml). Lo stato
// aperto/chiuso e' l'opzione Bool nascosta rjpAccordion, quindi viene
// persistito con l'analisi. Su Pj (senza questo CustomControl)
// ui.rjpAccordion e' undefined, quindi tutto qui sotto e' un no-op.
// ────────────────────────────────────────────────────────────────────
function findAccordionContent(ui) {
    let header = ui.rjpAccordion && ui.rjpAccordion.el;
    let target = ui.vars && ui.vars.el;
    if ( ! header || ! target)
        return null;

    // Trova l'antenato comune tra header e target (approccio robusto,
    // indipendente da quanti livelli di wrapper jamovi frappone tra un
    // controllo dichiarato in yaml e il suo nodo DOM effettivo): risale
    // da target finche' non incontra un nodo che e' anche antenato
    // dell'header. Il nodo immediatamente precedente su quel ramo e' il
    // contenitore "fratello" da mostrare/nascondere.
    let headerAncestors = new Set();
    for (let node = header; node; node = node.parentElement)
        headerAncestors.add(node);

    let node = target;
    let prev = null;
    while (node && ! headerAncestors.has(node)) {
        prev = node;
        node = node.parentElement;
    }

    return prev;
}

function applyAccordionState(ui) {
    let header = ui.rjpAccordion && ui.rjpAccordion.el;
    if ( ! header)
        return;

    let expanded = header._rjExpanded !== false;
    header.classList.toggle('rj-accordion-expanded', expanded);
    header.setAttribute('aria-expanded', String(expanded));

    let content = findAccordionContent(ui);
    if (content) {
        content.classList.add('rj-accordion-content');
        content.inert = !expanded;
        content.classList.toggle('rj-accordion-expanded', expanded);
    }
}

function initAccordionHeader(ui) {
    let header = ui.rjpAccordion && ui.rjpAccordion.el;
    // guard: non ricostruire il markup se gia' inizializzato (puo' essere
    // chiamata sia da 'creating' che da 'loaded'/'update' come ridondanza,
    // visto che il binding per naming-convention (rjpAccordion_creating) su
    // alcune installazioni jamovi Desktop locali risulta inaffidabile)
    if ( ! header || header.dataset.rjInit)
        return;
    header.dataset.rjInit = '1';
    header._rjExpanded = true; // stato iniziale: aperto (CustomControl non
    // e' associato ad alcuna opzione - vedi customcontrol.ts - quindi lo
    // stato si tiene qui, non su un'opzione persistita)

    header.classList.add('rj-accordion-header');
    header.setAttribute('role', 'button');
    header.tabIndex = 0;

    header.innerHTML = `
        <span class="rj-accordion-icon-container">
            <svg class="rj-plus-minus-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2">
                <line class="horizontal" x1="4" y1="8" x2="12" y2="8"></line>
                <line class="vertical" x1="8" y1="4" x2="8" y2="12"></line>
            </svg>
        </span>
        <span class="rj-accordion-title">${_('Variables')}</span>`;

    let toggle = () => {
        header._rjExpanded = ! header._rjExpanded;
        applyAccordionState(ui);
    };

    header.addEventListener('click', toggle);
    header.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            toggle();
        }
    });

    applyAccordionState(ui);
}

module.exports = function(ui) {
    styleVariableSupplier(ui);
    initAccordionHeader(ui);
    applyAccordionState(ui);
};
