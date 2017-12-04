'use strict';

const DocumentRegister = require('./docs/smk/index.jsx');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    DocumentRegister,
    {id: 'SmkrRegister', userData: userData, initData: initData}, 'SmkRegister'
), document.getElementById('doc'));