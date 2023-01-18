// модель для работы с пользователями
// будет искать пользователя, добавлять пользователя, править его данные и создавать (сохранять) в шифрованном виде пароль
'use strict';

const _ = require('underscore');

//model
const useridModel = require('./ou/userid');
const Db = require('./../libs/db');
const fs = require('fs');

const path = require('path');

const pathToSSLCa = path.join(global.__base, 'config', 'client.crt');
const pathToSSLKey = path.join(global.__base, 'config', 'server.key');
const pathToSSLcert = path.join(global.__base, 'config', 'client.crt');


module.exports = {
    userId: 0,
    loginName: '',
    login: false, // если прошло проверку на ацтификацию то тру
    encriptedPassword: '',
    userName: '',
    lastLogin: null,
    asutusName: '',
    app_port: 3000,

    getUserByUuid: async function (uuid) {
        const sql = _.findWhere(useridModel.select, {alias: 'get_user_by_uuid'}).sql;
        return await Db.queryDb(sql, [uuid], null, null, null);
    },
    storeUserUuid: async function (params) {
        const sql = _.findWhere(useridModel.select, {alias: 'store_user_uuid'}).sql;
        return await Db.queryDb(sql, [params]);
    },
    deleteUserUuid: function (params) {
        const sql = _.findWhere(useridModel.select, {alias: 'delete_user_uuid'}).sql;
        if (sql) {
            Db.queryDb(sql, [params]);
        }
    },


// возвращает строку пользователя по логину и ид учреждения
    getUserId: async function (nimi, rekvId, callback) {

        const sql = _.findWhere(useridModel.select, {alias: 'get_last_login'}).sql;

        const result = await Db.queryDb(sql, [nimi, rekvId]);

        if (!result || !result.data || !result.data.length) {
            console.error ('Viga', sql,nimi, rekvId, result );
            return callback('Viga', null);
        }

        this.userId = result.data[0].id;
        this.loginName = result.data[0].kasutaja;
        this.userName = result.data[0].ametnik;
        this.lastLogin = result.data[0].last_login;
        this.encriptedPassword = result.data[0].parool;

        const userData = Object.assign({}, result.data[0]);

        return callback(null, userData);

    },

    //сохраняет шифрованный пароль в таблице, если там его нет
    updateUserPassword: async function (userLogin, userPassword, savedPassword, callback) {
        let encryptedPassword = this.createEncryptPassword(userPassword, userLogin.length + '');

        this.loginName = userLogin; // сохраним имя пользователя
        // temparally, only for testing
        if (savedPassword) {
            this.login = encryptedPassword === savedPassword; // проверка пароля
            callback(null, this.login);
        } else {
            // get hash and update userInformation
            const sql = _.findWhere(useridModel.executeSql, {alias: 'update_hash'}).sql;

            await Db.queryDb(sql, [userLogin, encryptedPassword]);
            callback(null, this.login);
        }
    },

    // when succesfully logged in, will update last_login field
    updateUseridLastLogin: async function (userId, callback) {
        const sql = _.findWhere(useridModel.executeSql, {alias: 'update_last_login'}).sql;

        await Db.queryDb(sql, [userId]);
        callback(null, true);
    },

    // выбирает всех польователей
    selectAllUsers: async function (userId, callback) {
        const sql = _.findWhere(useridModel.select, {alias: 'get_all_users'}).sql;

        const result = await Db.queryDb(sql, [userId]);
        callback(null, result);
    },

// создает криптованный пароль
    createEncryptPassword: function (password, salt, callback) {
        const crypto = require('crypto'),
            hashParool = crypto.createHmac('sha1', salt).update(password).digest('hex');
        if (callback) {
            callback(null, hashParool);
        }
        return hashParool;
    },

    //грузим доступные учреждения
    loadPermitedAsutused: async function (kasutajaNimi, callback) {
        const sql = _.findWhere(useridModel.select, {alias: 'com_user_rekv'}).sql;

        const result = await Db.queryDb(sql, [kasutajaNimi]);
        let data = result.data.map((row) => {
            return JSON.stringify(row);
        });
        callback(null, data);
    }

};
