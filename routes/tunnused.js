'use strict';


const React = require('react');

const ReactServer = require('react-dom/server'),
    async = require('async');


exports.get = async (req, res) => {
    // рендер грида на сервере при первой загрузке странице
    const Tunnused = require('../frontend/docs/tunnus/tunnused.jsx');

    let results = [], // {}
        user = require('../middleware/userData')(req),  // check for userid in session
        sortBy,
        sqlWhere,
        docId;


    const Doc = require('./../classes/DocumentTemplate');
    const Tunnus = new Doc('TUNNUS', null, user.userId, user.asutusId);

    // делаем запрос , получаем первоначальные данные
    let gridConfig = Tunnus.config.grid.gridConfiguration;
    // вызвать метод
    let data = {
        result: await Tunnus.selectDocs(),
        gridConfig: gridConfig
    };

    const Component = React.createElement(
        Tunnused,
        {id: 'doc', initData: data, userData: user}, 'Тут будут компоненты');

    try {
        let html = ReactServer.renderToString(Component);

        // передатим в хранилище данные
        let storeInitialData = JSON.stringify(data);
        let userData = JSON.stringify(user);

        res.render('tunnused', {
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