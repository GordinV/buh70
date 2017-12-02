
var user = {
    nimi: 'testUser',
    kasutaja: 'vlad',
    rekvId: 1,
    userId: 0,
    parool: 'Vlad490710',
    cryptParool: null,
    savePassword: true,
    login: false // будет тру если аутификация успешная
};

var kasutaja = require('../models/userid'),
    async = require('async');

// 1. получить ид пользователя по логину
// 2. если надо, до добавить его в таблицу (для теста)
// 3. проверить пароль, а если его нет, то установить соединение с ПГ, и если успешно, то обновить пароль в таблице юзеров
// 4. закрыть соединение

async.series([
    getUserId,
    cryptParool,
    updatePassword
//    uusKasutaja,
//    checkParool
], function(err, results) {
    console.log('finished');
})


// сохранение криптованого пароля
function updatePassword (callback) {
    console.log('updateParool');
    kasutaja.updateUserPassword(user.kasutaja, user.parool, user.cryptParool)
    callback(null,user.cryptParool);
}

// проверка пароля
function checkParool (callback) {
    console.log('checkParool');
    cryptParool(function(err, parool) {
        user.login = user.cryptParool == cryptParool();
        callback(null,'3');
    })
}

// получить криптованный пароль
function  cryptParool (callback) {
    console.log('cryptParool');
    var salt =  user.kasutaja.length + '',
        hashParool = kasutaja.createEncryptPassword(user.parool, salt, function(err, result) {
            user.cryptParool =  result;
            callback(null,result);
        });
}

// ищем пользователя по лигону и ид организации
function getUserId(callback) {
    console.log('getUser 1');
    var row = kasutaja.getUserId(user.nimi, user.rekvId, function(err, data) {
        if (err) {
            console.error('viga');
            callback(err,null);
            return console.error('error in query');
        }
        user.userId = data.id;
        if (data.parool) {
            user.savePassword = false;
        }
        callback(null,user.userId);
    });
    console.log('getUser finish');
/*
        console.log(data)
        if (data.id) {
            user.userId = data.id;
            user.cryptParool = data.parool;
            console.log('data inserted');
        } else {
            // обнулим ид пользователя
            user.userId = 0;
        }
*/
      //  callback(null,'1');

}

//Добавление нового пользователя
function uusKasutaja(callback) {
    console.log('uusKasutaja');
    if (!user.userId) {
        kasutaja().addUser(user.nimi, user.nimi, user.rekvId).then(function(data) {
            user.userId = data.id;
            console.log(data);

        });
/*
            .then(function (err,data) {
                user.userId = data.id;
                console.log(data);
                callback(err,data);
            })
            */
    } else {
        console.log('kasutaja juba olemas')
    }
    callback(null,'2');
}
