'use strict';

const DocumentRegister = require('./docs/arv/index.jsx');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'ArveRegister', userData: userData, initData: initData}, 'ArveRegister'
), document.getElementById('doc'));