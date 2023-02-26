'use strict';

const Userid = require('../models/userid'),
    HttpError = require('./../error').HttpError;
const log = require('./../libs/log');


exports.post = async (req, res) => {
    const UserContext = require('./../frontend/user-context');

    let rekvId;
    if (req.params.rekvId) {
        rekvId = req.params.rekvId;
    }
    let userUuid = req.body.uuid;

    let user = await require('./../middleware/userData')(req, userUuid);  // check for userid in session

    if (!user || !userUuid) {
        //send result and wait for reload

        console.error('User puudub või uuid puudub', userUuid, user);
        return res.send({status: 401, result: 'Logout'}); //пока нет новых данных

    }

    // load new User data
    const userName = user.login;

    Userid.getUserId(userName, rekvId, async function (err, userData) {
        if (!userData || !UserContext.users || UserContext.users.length == 0) {
            // logs
            let message = `changeAsutus, tekkis viga !userData,userName-> ${userName} , rekvId-> ${rekvId}`;
            log(message, 'error');

            const err = new HttpError(403, 'No user');
            res.send({status: 403, result: 'error'});
        } else {

            let users = UserContext.users;
            // меняем данные пользователя. все кроме индентификатора
            UserContext.users = users.map((userRow) => {
                if (userUuid !== userRow.uuid) {
                    return userRow;
                } else {
                    return {
                        uuid: userRow.uuid,
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
                        userLibraryList: userData.allowed_libs,
                        roles: userData.roles

                    }
                }
            });

            // will save last login
            await Userid.updateUseridLastLogin(userData.id, (err, result) => {
            });


            // save user uuid
            const params = {userId: userData.id, asutusId: userData.rekvid, uuid: userUuid, user_data: userData, users: UserContext.users};

            await Userid.storeUserUuid(params);

            //will load new userdata
            let newUser = await require('../middleware/userData')(req, userUuid); // данные пользователя

            //save in locals
            req.app.locals.user = newUser;

            let message = `changeAsutus, userId-> ${JSON.stringify(userData.id)}, userData.rekvid-> ${userData.rekvid}, rekvId-> ${rekvId}`;
            log(message, 'info');

            //send result and wait for reload
            res.send({result: 'Ok', asutusId: userData.rekvid}); //пока нет новых данных
        }
    })
};