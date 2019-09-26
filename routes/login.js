'use strict';

const userid = require('../models/userid'),
    async = require('async'),
    HttpError = require('./../error').HttpError,
    errorMessage = '';
const _ = require('lodash');

exports.get = function (req, res) {
    res.render('login', {"title": 'login', "errorMessage": errorMessage});
};


exports.post = function (req, res, next) {

    let username = req.body.username,
        password = req.body.password,
        errorMessage,
        statusCode = 200;


    async.waterfall([
            function (callback) {
                //Loooking for acccount and loading login data
                let rekvId = null;

                userid.getUserId(username, rekvId, function (err, kasutaja) {
                    if (err) return callback(err, null);

                    if (!kasutaja) {
                        const err = new HttpError(403, 'No user');
                        return callback(err, null);
                    }

                    errorMessage = null;

                    if (!req.session.users) {
                        req.session.users = [];
                    }

                    let userIndex =  _.findIndex(req.session.users,{id:kasutaja.id});
                    if (userIndex < 0 ) {
                        // user not loged In before
                        req.session.users.push(kasutaja);
                    }
                    return callback(null, kasutaja);
                });
            },
            // checking for password
            function (kasutaja, callback) {
                userid.updateUserPassword(username, password, kasutaja.parool, function (err, result) {
                    if (err) return callback(err, null, null);
                    let error;

                    if (!result) {
                        error = new HttpError(403, 'Ошибка в пароле');
                        errorMessage = 'Ошибка в пароле';
                        statusCode = 403;
                        console.error('Ошибка в пароле');
                        // return next(err);
                    }
                    return callback(error, result, kasutaja);

                });
            },

            // saving last login timestamp
            function (result, kasutaja, callback) {
                if (result) {
                    userid.updateUseridLastLogin(kasutaja.id, function (err, result) {
                       return callback(err, kasutaja, result);
                    });
                }
            },
            //load allowed asutused
            function (kasutaja, result, callback) {
                userid.loadPermitedAsutused(username, function (err, result) {
                    if (err) {
                        console.error(err);
                        return callback(err, null);
                    }

                    let userIndex =  _.findIndex(req.session.users,{id:kasutaja.id});

                    //will set the list of allowed asutused to session object
                    req.session.users[userIndex].userAllowedAsutused = result;

                    callback(err, result);
                });

            }

        ],


        // finished
        function (err) {
            if (err) return next(err);

            if (errorMessage) {
                //back to login
                res.statusCode = statusCode;
                res.redirect('/login');
            } else {
                // open main page
                res.redirect('/lapsed'); //@todo переделать
            }
        });
};