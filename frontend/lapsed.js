'use strict';
const ReactDOM = require('react-dom');
const {BrowserRouter} = require('react-router-dom');

const Doc = require('../frontend/modules/lapsed.jsx');
import DocContext from './doc-context.js';

initData = JSON.parse(initData);
userData = JSON.parse(userData);

// сохраним базовые данные в памети

DocContext.initData = initData;
DocContext.userData = userData;
DocContext.module = 'lapsed';
DocContext.pageName = 'Laste register';
DocContext.gridConfig = initData.docConfig;


ReactDOM.hydrate(
    <BrowserRouter>
        <Doc initData={initData}
             userData={userData}
             module={'lapsed'}
        />
    </BrowserRouter>
    , document.getElementById('doc')
);

