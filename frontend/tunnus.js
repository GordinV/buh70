
const ReactDOM = require('react-dom');

// данные для хранилища
userData = JSON.parse(userData);
docId = Number(docId);
initData = JSON.parse(initData);


// запросим компонент документа по его типу
const Doc = require('../frontend/docs/tunnus/tunnus.jsx');

ReactDOM.hydrate(
    <Doc userData={userData} docId = {docId} initData = {initData}/>
    , document.getElementById('doc')
);

