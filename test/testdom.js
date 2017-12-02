module.exports = function(markup) {
    if (typeof document !== 'undefined') return;
    var jsdom = require('jsdom').jsdom;

    var doc = jsdom(markup);
    var window = doc.defaultView;

    global.document = doc;
    global.window = window;
    global.navigator = {
        userAgent: 'node.js'
    };
};