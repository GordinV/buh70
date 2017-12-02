'use strict';

const Tunnused = require('./docs/tunnus/tunnused.jsx');

// данные для хранилища
//localStorage['docsStore'] = storeData;
initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    Tunnused,
    {id: 'tunnused', userData: userData, initData: initData}, 'Tunnused'
), document.getElementById('doc'));