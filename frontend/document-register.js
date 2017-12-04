'use strict';

const DocumentRegister = require('./docs/document/index.jsx');

// данные для хранилища
//localStorage['docsStore'] = storeData;
initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'tunnused', userData: userData, initData: initData}, 'Documents'
), document.getElementById('doc'));