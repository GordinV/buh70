'use strict';

const Register = require('../frontend/docs/doc-register/doc-register.jsx');

// данные для хранилища
//localStorage['docsStore'] = storeData;
storeData = JSON.parse(storeData);
userData = JSON.parse(userData);

ReactDOM.hydrate(React.createElement(
    Register,
    { id: 'grid', components: storeData, userData: userData}, 'Тут будут компоненты'
), document.getElementById('grid'));