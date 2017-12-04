'use strict';

const DocumentRegister = require('./docs/dok/index.jsx');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'DocsRegister', userData: userData, initData: initData}, 'DocsRegister'
), document.getElementById('doc'));