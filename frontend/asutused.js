
const ReactDOM = require('react-dom');

// данные для хранилища
localStorage['docStore'] = storeData;
storeData = JSON.parse(storeData);
userData = JSON.parse(userData);


// запросим компонент документа по его типу
const Doc = require('../frontend/docs/asutused/asutused.jsx');

ReactDOM.hydrate(
    <Doc data={storeData.data} userData={userData}/>
    , document.getElementById('doc')
);

