'use strict';

const DocumentRegister = require('./docs/sorder/index.jsx');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'SorderRegister', userData: userData, initData: initData}, 'SorderRegister'
), document.getElementById('doc'));