const _ = require('lodash');
const Userid = require('../models/userid');
const log = require('./../libs/log');
const UserContext = require('./../frontend/user-context');


const userData = async function (req, _uuid) {
    let userId = req.body.userId,
        uuid = _uuid ? _uuid : req.body.uuid;

    let userIndex;

    if (!UserContext.users) {
        // logs
        //let message = `userData, !UserContext.users userId -> ${userId},uuid -> ${uuid}, ${UserContext}`;
        //log(message,'Error');

        //return null;
        userIndex -1;
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
        regkood: null
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
        }

        // logs
        let message = `userData, userIndex < 0 userId -> ${sqlUser.userId},asutusId -> ${sqlUser.asutusId}`;
        log(message,'info');

    }

    const user = Object.assign({
        userId: userIndex > -1 ? UserContext.users && UserContext.users[userIndex].id : sqlUser.userId,
        userName: userIndex > -1 ? UserContext.users && UserContext.users[userIndex].ametnik : sqlUser.kasutaja,
        asutus: userIndex > -1 ? UserContext.users && UserContext.users[userIndex].asutus : sqlUser.asutus,
        asutusTais: userIndex > -1 ? UserContext.users && UserContext.users[userIndex].asutus_tais : sqlUser.asutus_tais,
        regkood: userIndex > -1 ? UserContext.users && UserContext.users[userIndex].regkood : sqlUser.regkood,
        asutusId: userIndex > -1 ? UserContext.users && UserContext.users[userIndex].rekvid : sqlUser.asutusId,
        lastLogin: userIndex > -1 ? UserContext.users && UserContext.users[userIndex].last_login : null,
        userAccessList: userIndex > -1 ? UserContext.users && UserContext.users[userIndex].userAllowedAsutused : [],
        userLibraryList: [],
        parentid: userIndex > -1 && UserContext.users && UserContext.users[userIndex].parentid ? UserContext.users[userIndex].parentid : 0,
        parent_asutus: userIndex > -1 && UserContext.users && UserContext.users[userIndex].parent_asutus,
        login: userIndex > -1 ? UserContext.users && UserContext.users[userIndex].kasutaja : sqlUser.kasutaja,
        roles: userIndex > -1 && UserContext.users && UserContext.users[userIndex].roles
    }, userIndex > -1 ? UserContext.users && UserContext.users[userIndex] : {});

    return user;
};

module.exports = userData;