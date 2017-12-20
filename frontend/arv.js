
const ReactDOM = require('react-dom');

initData = JSON.parse(initData);
userData = JSON.parse(userData);

// запросим компонент документа по его типу
const Doc = require('../frontend/docs/arv/arv.jsx');

ReactDOM.hydrate(
    <Doc initData={initData} userData={userData} docId = {docId}/>
    , document.getElementById('doc')
);

