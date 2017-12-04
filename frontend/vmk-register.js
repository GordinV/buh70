'use strict';

const DocumentRegister = require('./docs/vmk/index.jsx');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'VmkrRegister', userData: userData, initData: initData}, 'VmkRegister'
), document.getElementById('doc'));