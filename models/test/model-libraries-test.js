'use strict';
require('babel-polyfill');

describe('Libraries test', function () {
    it('Nomenklatuur select', function (done) {
        var DocDataObject = require('../documents');
        DocDataObject.selectDoc('nomenclature', null, function (err, data) {
            if (err) throw new Error('Error in  selectDoc');
            if (data.length < 1) throw new Error('Result < 1');
            done();
        });
    });

    it('Nomenklatuur select promise', function (done) {
        const DocDataObject = require('../documents'),
            co = require('co');


        co(function *() {
            var data = DocDataObject.selectDocPromise('nomenclature', null);
            done();
        }).catch((err) => {
            throw new Error('Error in  selectDocPromise')
        });

    });

    it('Asutused select', function (done) {
        var DocDataObject = require('../documents');
        DocDataObject.selectDoc('asutused', null, function (err, data) {
            if (err) throw new Error('Ошибка метода  selectDoc');
            if (data.length < 1) throw new Error('Result < 1');
            done();
        });
    });

});
