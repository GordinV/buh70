'use strict';

const ReactDOM = require('react-dom');
const {BrowserRouter} = require('react-router-dom');

const Doc = require('../frontend/modules/raama.jsx');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

ReactDOM.hydrate(
    <BrowserRouter>
        <Doc initData={initData}  userData={userData}/>
    </BrowserRouter>
    , document.getElementById('doc')
);

