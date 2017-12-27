'use strict';

const DocumentRegister = require('./docs/documents/documents.jsx');

// данные для хранилища
//localStorage['docsStore'] = storeData;
initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'documents', userData: userData, initData: initData}, 'Documents'
), document.getElementById('doc'));