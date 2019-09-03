// модель для работы с пользователями
// будет искать пользователя, добавлять пользователя, править его данные и создавать (сохранять) в шифрованном виде пароль
'use strict';

const _ = require('underscore');

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

            db.query(`SELECT *
                      FROM view_get_users_data v
                      WHERE (v.rekvid = $2 OR $2 IS NULL)
                        AND upper(ltrim(rtrim(v.kasutaja))) = upper(ltrim(rtrim($1)))
                      ORDER BY v.last_login DESC
                      LIMIT 1 `,
                [nimi, rekvId], function (err, result) {
                    db.end();

                    if (err) {
                        return callback(err, null);
                    }

                    if (result.rows.length == 0) {
                        return callback(null, null);
                    }

                    this.userId = result.rows[0].id;
                    this.loginName = result.rows[0].kasutaja;
                    this.userName = result.rows[0].ametnik;
                    this.lastLogin = result.rows[0].last_login;
                    this.encriptedPassword = result.rows[0].parool;

                    db.end();
                    callback(null, result.rows[0]);

                });
        });
    },

    //сохраняет шифрованный пароль в таблице, если там его нет
    updateUserPassword: function (userLogin, userPassword, savedPassword, callback) {

        let encryptedPassword = this.createEncryptPassword(userPassword, userLogin.length + '');

        this.loginName = userLogin; // сохраним имя пользователя
        // temparally, only for testing
        if (savedPassword) {
            this.login = encryptedPassword === savedPassword; // проверка пароля
            callback(null, this.login);
        } else {

            //first should connect to pg, using connection, username and password. If success, then get hash and update userInformation
            const pg = require('pg');
            const local_config = require('../config/default');

            const local_db = new pg.Client({
                host: local_config.pg.host,
                port: local_config.pg.port,
                database: local_config.pg.database,
                user: userLogin,
                password: userPassword
            });


            local_db.connect((err, result) => {

                if (err) {
                    callback(err, null);
                }

                // иначе сохраняем его в таблице
                const db = this.connectDb();

                db.connect(function (err) {
                    if (err) {
                        return console.error('could not connect to postgres', err);
                    }
                    db.query("UPDATE ou.userid SET parool = $2 WHERE upper(kasutaja) = upper($1); ",
                        [userLogin, encryptedPassword], function (err, result) {
                            if (err) {
                                callback(err, null);
                                return console.error('error in query');
                            }
                            db.end();
                            callback(null, true);
                        });

                callback(err, true);

                });

                // close connection
                local_db.end();

            });

        }

    },

    // when succesfully logged in, will update last_login field
    updateUseridLastLogin: function (userId, callback) {
        // иначе сохраняем его в таблице
        const db = this.connectDb();

        db.connect(function (err) {
            if (err) {
                return console.error('could not connect to postgres', err);
            }
            db.query("UPDATE ou.userid SET last_login =now()  WHERE id = $1; ",
                [userId], function (err, result) {
                    if (err) {
                        console.error('error in query', err);
                        next(err);
                    }

                    db.end();
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
                "           from ou.userid u " +
                "               inner join ou.rekv r on r.id = u.rekvid " +
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
        const crypto = require('crypto'),
            hashParool = crypto.createHmac('sha1', salt).update(password).digest('hex');
        if (callback) {
//            this.encriptedPassword = hashParool;
            callback(null, hashParool);
        }
        return hashParool;
    },

    //грузим доступные учреждения
    loadPermitedAsutused: function (kasutajaNimi, callback) {
        //model
        const useridModel = require('./ou/userid');
        const sql = _.findWhere(useridModel.select, {alias: 'com_user_rekv'}).sql;

        const db = this.connectDb();

        db.connect(function (err) {
            if (err) {
                return console.error('could not connect to postgres', err);
            }
            db.query(sql, [kasutajaNimi], function (err, result) {
                if (err) {
                    console.error(err);
                    callback(err, null);
                }
                db.end();
                callback(err, result.rows);
            });
        });


    }

};
