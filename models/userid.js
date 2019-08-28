// модель для работы с пользователями
// будет искать пользователя, добавлять пользователя, править его данные и создавать (сохранять) в шифрованном виде пароль
'use strict';

module.exports = {
    userId: 0,
    loginName: '',
    login: false, // если прошло проверку на ацтификацию то тру
    encriptedPassword: '',
    userName: '',
    lastLogin: null,
    asutusName: '',
    connectDb: function () {
        const pg = require('pg'),
            config = require('../config/default'),
            db = new pg.Client(config.pg.connection);
        return db;
    },
// возвращает строку пользователя по логину и ид учреждения
    getUserId: function (nimi, rekvId, callback) {
        const db = this.connectDb();

        db.connect(function (err) {
            if (err) {
                callback(err, null);
                return console.error('could not connect to postgres', err);
            }

            db.query(`select * from view_get_users_data v 
                 where (v.rekvid = $2 or $2 is null) 
                 and upper(ltrim(rtrim(v.kasutaja))) = upper($1) 
                 order by v.last_login desc limit 1 `,
                [nimi, rekvId], function (err, result) {
                    db.end();

                    if (err) {
                        return callback(err, null);
//                        return console.error('error in query');
                    }

                    if (result.rows.length == 0) {
                        return callback(null, null);
//                        return console.error('No account for users in this department');
                    }

                    this.userId = result.rows[0].id;
                    this.loginName = result.rows[0].kasutaja;
                    this.userName = result.rows[0].ametnik;
                    this.lastLogin = result.rows[0].last_login;
                    this.encriptedPassword = result.rows[0].parool;

                    db.end();
                    console.log('finish /' + result.rows[0]);
                    callback(null, result.rows[0]);

                });
        });
    },

    //сохраняет шифрованный пароль в таблице, если там его нет
    updateUserPassword: function (userLogin, userPassword, savedPassword, callback) {
        var encryptedPassword = this.createEncryptPassword(userPassword, userLogin.length + '');

        this.loginName = userLogin; // сохраним имя пользователя
        // temparally, only for testing
        if (savedPassword) {
            this.login = encryptedPassword === savedPassword; // проверка пароля
            callback(null, this.login);
        }

        // иначе сохраняем его в таблице
        var db = this.connectDb();

        db.connect(function (err) {
            if (err) {
                return console.error('could not connect to postgres', err);
            }
            db.query("update userid set parool = $2 where upper(kasutaja) = upper($1); ",
                [userLogin, encryptedPassword], function (err, result) {
                    if (err) {
                        callback(err, null);
                        return console.error('error in query');
                    }
                    db.end();
                    callback(null, true);
                });
        });


    },

    // when succesfully logged in, will update last_login field
    updateUseridLastLogin: function (userId, callback) {
        // иначе сохраняем его в таблице
        console.log('last_login' + userId);
        var db = this.connectDb();

        db.connect(function (err) {
            if (err) {
                return console.error('could not connect to postgres', err);
            }
            db.query("update userid set last_login =now()  where id = $1; ",
                [userId], function (err, result) {
                    if (err) {
                        console.log('error in query' + err);
                        next(err);
                    }
                    db.end();
                    console.log('last_login db end');
                    callback(null, true);
                });
        });

    },

    // выбирает всех польователей
    selectAllUsers: function (userId, callback) {
        var db = this.connectDb();

        db.connect(function (err) {
            if (err) {
                return console.error('could not connect to postgres', err);
            }
            db.query("select r.nimetus as asutus, u.* " +
                "           from userid u " +
                "               inner join rekv r on r.id = u.rekvid " +
                "               where $1 = 0 or u.id = $1 " +
                "               order by u.last_login desc, u.id desc;", [userId], function (err, result) {
                if (err) {
                    console.error(err);
                    return callback(err);
                }
                db.end();
                callback(err, result);
            });
        });

    },

// создает криптованный пароль
    createEncryptPassword: function (password, salt, callback) {
        var crypto = require('crypto'),
            hashParool = crypto.createHmac('sha1', salt).update(password).digest('hex');
        console.log(hashParool);
        if (callback) {
//            this.encriptedPassword = hashParool;
            callback(null, hashParool);
        }
        return hashParool;
    },

};
