'use strict';

const React = require('react');
const ReactServer = require('react-dom/server');

exports.get = async (req, res) => {
    // рендер грида на сервере при первой загрузке странице
    // берем тип документа из параметра в адресе
    const documentType = req.params.documentType.toLowerCase(),
        docId = Number(req.params.id);

    const DocumentView = require(`../frontend/docs/${documentType}/${documentType}.jsx`);
    let user = require('../middleware/userData')(req);  // check for userid in session

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, docId, user.userId, user.asutusId);

    // делаем запрос , получаем первоначальные данные
    // вызвать метод
    let data = {};
    if (docId) {
        data = await Document.select();
    } else {
        data = await Document.createNew();
    }

    const requiredFields = Document.requiredFields ? Document.requiredFields : [];

    const prepairedData = Object.assign({}, data.row[0],
        {gridData: data.details},
        {relations: data.relations},
        {gridConfig: data.gridConfig},
        {requiredFields: requiredFields}
    );


    const Component = React.createElement(
        DocumentView,
        {id: 'doc', initData: prepairedData, userData: user, docId: docId}, 'Тут будут компоненты');

    try {
        let html = ReactServer.renderToString(Component);

        // передатим в хранилище данные
        let storeInitialData = JSON.stringify(prepairedData);
        let userData = JSON.stringify(user);

        res.render(documentType, {
            "user": user,
            "userData": userData,
            "initData": storeInitialData,
            "docId": docId
            , react: html
        });

    } catch (e) {
        console.error('error:', e);
        res.statusCode = 500;
    }

};
