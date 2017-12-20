
const ReactDOM = require('react-dom');

// данные для хранилища
initData = JSON.parse(initData);
userData = JSON.parse(userData);


// запросим компонент документа по его типу
const Doc = require('../frontend/docs/kontod/kontod.jsx');

ReactDOM.hydrate(
    <Doc initData={initData} userData={userData} docId = {docId}/>
    , document.getElementById('doc')
);

