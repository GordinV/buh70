'use strict';

const userid = require('../models/userid'),
    HttpError = require('./../error').HttpError;


exports.post = async (req, res) => {
    let rekvId;
    if (req.params.rekvId) {
        rekvId = req.params.rekvId;
    }

    // load new User data
    const userName = req.session.user.login;

    userid.getUserId(userName, rekvId, function (err, userData) {

        if (!userData) {
            const err = new HttpError(403, 'No user');
            res.send({result: 'error'});
        } else {
            req.session.user = {
                id: userData.id,
                login: userData.kasutaja,
                userName: userData.ametnik,
                userAsutus: userData.asutus,
                userAsutusId: userData.rekvid,
                userLastLogin: userData.last_login,
                userAccessList: userData.allowed_access,
                userLibraryList: userData.allowed_libs,
            };
            global.userId = userData.id;
            global.rekvId = userData.rekvid;

            res.send({result: 'Ok'}); //пока нет новых данных
        }


        /*
            let user = require('../middleware/userData')(req); // данные пользователя
            let documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа

            if (!user) {
                user = {
                    userId: 1,
                    asutusId: 1
                }
            }

            const Doc = require('./../classes/DocumentTemplate');
            const Document = new Doc(documentType, null, user.userId, user.asutusId);

            let result = {result: await Document.selectLibs()};
        */


    })
};