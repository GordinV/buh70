'use strict';

exports.get = (req, res) => {

// will offer departments, if exists
// 1. render template with departments
// 2. get departments list

    let departmentId = null,
        async = require('async'),
        userid = require('../models/userid'),
        user = require('middleware/userData')(req);

    if (req.params.id) {
        departmentId = req.params.id;
        async.series([
            (callback) => {
                // loading new user's data
                let login = req.session.user.login.trim();

                userid.getUserId(login, departmentId, (err, kasutaja) => {
                    if (err) return callback(err, null);
                    //errorMessage = null;

                    if (kasutaja) {
                        // has access, updating user data
                        req.session.user = {
                            id: kasutaja.id,
                            login: kasutaja.kasutaja,
                            userName: kasutaja.ametnik,
                            userAsutus: kasutaja.asutus,
                            userAsutusId: kasutaja.rekvid,
                            userLastLogin: kasutaja.last_login,
                            userAccessList: kasutaja.allowed_access,
                            userLibraryList: kasutaja.allowed_libs
                        };
                        global.rekvId = kasutaja.rekvid;

                    }
                    callback(err, kasutaja);
                });
            },
            (callback) => {
                // saving last login
                userid.updateUseridLastLogin(req.session.user.id, (err, result) => {
                    if (err) return callback(err, null);
                    callback(null, null);
                });
            },
        ],  (err) => {
            if (err) {
                res.render('error', {"message": err.message});
                return null;
            };
            // redirect to main page
            user = require('middleware/userData')(req);
            res.redirect('/documents');
        });
    } else {
        // return dep. list
        res.render('changeDepartment', {"user": user, departmentId: departmentId});
    }
};
