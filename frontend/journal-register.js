'use strict';

const DocumentRegister = require('./docs/journal/index.jsx');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'JournalRegister', userData: userData, initData: initData}, 'JournalRegister'
), document.getElementById('doc'));