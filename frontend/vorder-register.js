'use strict';

const DocumentRegister = require('./docs/vorder/index.jsx');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'VorderRegister', userData: userData, initData: initData}, 'VorderRegister'
), document.getElementById('doc'));