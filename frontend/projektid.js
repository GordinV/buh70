'use strict';

const DocumentRegister = require('./docs/project/index.jsx');

// данные для хранилища
//localStorage['docsStore'] = storeData;
initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'tunnused', userData: userData, initData: initData}, 'Projektid'
), document.getElementById('doc'));