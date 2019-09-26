'use strict';

const userid = require('../models/userid'),
    HttpError = require('./../error').HttpError;


exports.post = (req, res) => {

    let rekvId;
    if (req.params.rekvId) {
        rekvId = req.params.rekvId;
    }

    let user = require('./../middleware/userData')(req);  // check for userid in session

    // load new User data
    const userName = user.login;

    userid.getUserId(userName, rekvId, function (err, userData) {

        if (!userData) {
            const err = new HttpError(403, 'No user');
            res.send({status: 403, result: 'error'});
        } else {
            let users  = req.session.users;
            req.session.users = users.map((userRow) => {
                if (user.id !== userRow.id) {
                    return user;
                } else {
                    return {
                        id: userData.id,
                        userId: userData.id,
                        login: userData.kasutaja,
                        asutus: userData.asutus,
                        asutusId: userData.rekvid,
                        userName: userData.ametnik,
                        userAsutus: userData.asutus,
                        userAsutusId: userData.rekvid,
                        userLastLogin: userData.last_login,
                        userAccessList: userData.allowed_access,
                        userLibraryList: userData.allowed_libs
                    }
                }

            });

            // will save last login
            userid.updateUseridLastLogin(userData.id, (err, result) => {
            });
            res.send({result: 'Ok'}); //пока нет новых данных
        }
    })
};