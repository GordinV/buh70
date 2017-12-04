'use strict';

const DocumentRegister = require('./docs/kontod/index.jsx');

// данные для хранилища
//localStorage['docsStore'] = storeData;
initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'tunnused', userData: userData, initData: initData}, 'Kontod'
), document.getElementById('doc'));