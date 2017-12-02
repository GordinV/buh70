'use strict';

const ReactDOM = require('react-dom');

// данные для хранилища
localStorage['docStore'] = storeData;
storeData = JSON.parse(storeData);
userData = JSON.parse(userData);

// создаем обработчик события на изменение даннх


// запросим компонент документа по его типу
const Doc = require('../middleware/returnDocComponent')(storeData.docTypeId);

ReactDOM.hydrate(
    <Doc data={storeData.data} bpm = {storeData.bpm} userData={userData}/>
    , document.getElementById('doc')
);

