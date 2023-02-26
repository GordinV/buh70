const _ = require('lodash');
const Userid = require('../models/userid');
const log = require('./../libs/log');
const UserContext = require('./../frontend/user-context');
const DocContext = require('./../frontend/doc-context');


const userData = async function (req, _uuid) {
    let userId = req.body.userId,
        uuid = _uuid ? _uuid : req.body.uuid;

    let userIndex =-1;

    if (!UserContext.users || UserContext.users.length == 0) {
        // logs
        //let message = `userData, !UserContext.users userId -> ${userId},uuid -> ${uuid}, ${UserContext}`;
        //log(message,'Error');

        //return null;
        userIndex - 1;
    } else {
        userIndex = _.findIndex(UserContext.users, {uuid: uuid});
    }


    if (!uuid && UserContext.users) {
        // for get
        userIndex = 0;
    }


    let sqlUser = {
        userId: null,
        asutusId: null,
        kasutaja: null,
        asutus: null,
        asutus_tais: null,
        regkood: null,
        user_data: {},
        users: []
    };

    if (userIndex < 0) {
        // потеряли хеш
        let uuidUser = await Userid.getUserByUuid(uuid);
        if (uuidUser && uuidUser.data && uuidUser.data.length) {
            sqlUser.userId = uuidUser.data[0].userid;
            sqlUser.asutusId = uuidUser.data[0].asutusid;
            sqlUser.kasutaja = uuidUser.data[0].kasutaja;
            sqlUser.asutus = uuidUser.data[0].asutus;
            sqlUser.asutus_tais = uuidUser.data[0].taisnimetus;
            sqlUser.regkood = uuidUser.data[0].regkood;
            sqlUser.user_data = uuidUser.data[0].user_data;
            sqlUser.users = uuidUser.data[0].users;

            if (!DocContext.getUuid) {
                DocContext.userData = uuidUser.data[0].user_data;
            }
            // вернем пользователей
            if (sqlUser.users) {
                UserContext.users = sqlUser.users;
            }
        }

        // logs
        let message = `userData, userIndex < 0 userId -> ${sqlUser.userId},asutusId -> ${sqlUser.asutusId}`;
        log(message, 'info');
    }


    const user = Object.assign({
        userId: userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex].id : sqlUser.userId,
        userName: userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex].ametnik : sqlUser.kasutaja,
        asutus: userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex].asutus : sqlUser.asutus,
        asutusTais: userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex].asutus_tais : sqlUser.asutus_tais,
        regkood: userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex].regkood : sqlUser.regkood,
        asutusId: userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex].rekvid : sqlUser.asutusId,
        lastLogin: userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex].last_login : sqlUser.user_data.last_login,
        userAccessList: userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex].userAllowedAsutused : sqlUser.user_data.allowed_access,
        userLibraryList: [],
        parentid: userIndex > -1 && UserContext.users && UserContext.users.length && UserContext.users[userIndex].parentid ? UserContext.users[userIndex].parentid : sqlUser.user_data.parentid,
        parent_asutus: userIndex > -1 && UserContext.users && UserContext.users.length && UserContext.users[userIndex].parent_asutus ? UserContext.users[userIndex].parent_asutus: sqlUser.user_data.parent_asutus,
        login: userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex].kasutaja : sqlUser.kasutaja,
        roles: userIndex > -1 && UserContext.users && UserContext.users.length && UserContext.users[userIndex].roles ? UserContext.users[userIndex].roles: sqlUser.user_data.roles
    }, userIndex > -1 ? UserContext.users && UserContext.users.length && UserContext.users[userIndex] : {});

    return user;
};

module.exports = userData;