'use strict';

const userid = require('../models/userid'),
    async = require('async'),
    HttpError = require('./../error').HttpError,
    uuid = require('uuid/v1'),
    errorMessage = '';
const _ = require('lodash');
const log = require('./../libs/log');
const UserContext = require('./../frontend/user-context');


exports.get = function (req, res) {
    res.render('login', {"title": 'login', "errorMessage": errorMessage});
};


exports.post = function (req, res, next) {

    let username = req.body.username,
        password = req.body.password,
        errorMessage,
        statusCode = 200;

    let user = {};

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

                    if (!UserContext.users) {
                        UserContext.users = [];
                    }

                    // user not loged In before
                    const newUser = Object.assign({
                        uuid: uuid(),
                        userId: kasutaja.id,
                        userName: kasutaja.ametnik,
                        asutusId: kasutaja.rekvid,
                        lastLogin: kasutaja.last_login,
                        userAccessList: kasutaja.allowed_access,
                        login: kasutaja.kasutaja,
                        parentid: kasutaja.parentid,
                        parent_asutus: kasutaja.parent_asutus,
                        roles: kasutaja.roles
                    }, kasutaja);

                    UserContext.users.push(newUser);
                    user = newUser;

// save user uuid
                    const params = {userId: newUser.userId, asutusId: newUser.asutusId, uuid: newUser.uuid, user_data: newUser, users: UserContext.users};
                    userid.storeUserUuid(params);

                    return callback(null, newUser);
                });
            },
            // checking for password
            function (kasutaja, callback) {
                userid.updateUserPassword(username, password, kasutaja.parool, function (err, result) {
                    if (err) return callback(err, null, null);
                    let error;

                    if (!result) {
                        error = new HttpError(403, 'Vale parool või kasutaja nimi');
                        errorMessage = 'Vale parool või kasutaja nimi';
                        statusCode = 403;
                        console.error('Vale parool või kasutaja nimi');
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
                        let message = `login, error ${err}`;
                        log(message, 'error');
                        return callback(err, null);
                    }

                    let userIndex = _.findIndex(UserContext.users, {id: kasutaja.id});

                    //will set the list of allowed asutused to session object
                    UserContext.users[userIndex].userAllowedAsutused = result;

                    callback(err, result);
                });

            },

        ],


        // finished
        function (err) {
            if (err) {
                // log
                let message = `login, error ${err}`;
                log(message, 'error');

                return next(err);
            }

            if (errorMessage) {
                // log
                let message = `login, error ${errorMessage}`;
                log(message, 'error');

                //back to login

                res.statusCode = statusCode;
                res.redirect('/login');
            } else {
                // log
                let message = `login, username-> ${username}`;
                log(message, 'info');

                // open main page
                req.app.locals.user = user;
                res.redirect('/lapsed'); //@todo переделать
            }
        });
};