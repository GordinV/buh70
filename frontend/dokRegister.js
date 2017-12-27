'use strict';

const DocumentRegister = require('./docs/dok/index.jsx');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'dokrRegister', userData: userData, initData: initData}, 'dokRegister'
), document.getElementById('doc'));