'use strict';


const React = require('react');
const ReactServer = require('react-dom/server');

exports.get = async (req, res) => {
    // рендер грида на сервере при первой загрузке странице
    // берем тип документа из параметра в адресе
    const documentType = req.params.id.toLowerCase();

    const DocumentRegister = require(`../frontend/docs/${documentType}/index.jsx`);
    let user = require('../middleware/userData')(req);  // check for userid in session

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, null, user.userId, user.asutusId);

    // делаем запрос , получаем первоначальные данные
    let gridConfig = Document.config.grid.gridConfiguration;
    // вызвать метод
    let data = {
        result: await Document.selectDocs(),
        gridConfig: gridConfig
    };

    const Component = React.createElement(
        DocumentRegister,
        {id: 'doc', initData: data, userData: user}, 'Тут будут компоненты');

    try {
        let html = ReactServer.renderToString(Component);

        // передатим в хранилище данные
        let storeInitialData = JSON.stringify(data);
        let userData = JSON.stringify(user);

        res.render(documentType, {
            "user": user,
            "userData": userData,
            "store": storeInitialData
            , react: html
        });

    } catch (e) {
        console.error('error:', e);
        res.statusCode = 500;
    }

};