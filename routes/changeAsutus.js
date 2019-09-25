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

            // will save last login
            userid.updateUseridLastLogin(userData.id, (err, result)=>{
                console.log('success');
            });

            res.send({result: 'Ok'}); //пока нет новых данных
        }
    })
};