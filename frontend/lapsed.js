'use strict';
const ReactDOM = require('react-dom');
const {BrowserRouter} = require('react-router-dom');

const Doc = require('../frontend/modules/lapsed.jsx');
import DocContext from './doc-context.js';

initData = JSON.parse(initData);
userData = JSON.parse(userData);

// сохраним базовые данные в памети

DocContext.setInitData = initData;
DocContext.setUserData = userData;
DocContext.setModule = 'lapsed';
DocContext.setPageName = 'Laste register';

ReactDOM.hydrate(
    <BrowserRouter>
        <Doc initData={initData}
             userData={userData}
             module={'lapsed'}
        />
    </BrowserRouter>
    , document.getElementById('doc')
);

