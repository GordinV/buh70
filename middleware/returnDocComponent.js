module.exports = function(docTypeId) {
    // взависимости от типа документа вернет компонент документа

    console.log('returnDocComponent:' +docTypeId );
    var component = {};

    switch(docTypeId) {
        case 'PALK':
            component = require('../frontend/docs/palk_oper.jsx');
            break;
        default:
            component = require('../frontend/docs/arve/arve.jsx');
    }
    return component;

}
