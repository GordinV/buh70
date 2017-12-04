'use strict';

const DocumentRegister = require('./docs/asutused/index.jsx');

// данные для хранилища
//localStorage['docsStore'] = storeData;
initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'nomenclature-register', userData: userData, initData: initData}, 'asutus-register'
), document.getElementById('doc'));