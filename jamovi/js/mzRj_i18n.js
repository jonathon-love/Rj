// Mark literal calls with _() so jamovi-compiler can extract the catalog.
module.exports = function _(text, formats) {
    if (typeof window._ === 'function') return window._(text, formats);
    // Standalone UI tests have no jamovi translation context.
    if (!formats) return text;
    return text.replace(/\{(\w+)\}/g, (match, key) =>
        Object.prototype.hasOwnProperty.call(formats, key) ? String(formats[key]) : match);
};
