
const ReactDOM = require('react-dom');

// данные для хранилища
userData = JSON.parse(userData);
docId = Number(docId);
initData = JSON.parse(initData);


// запросим компонент документа по его типу 1
const Doc = require('./docs/dok/dok.jsx');

ReactDOM.hydrate(
    <Doc userData={userData} docId = {docId} initData = {initData}/>
    , document.getElementById('doc')
);

