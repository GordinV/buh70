'use strict';
const o2x = require('object-to-xml');
const fs = require('fs');
const path = require('path');
const _ = require('lodash');

/**
 * Функция генерирует XML модель на основе JS модели.
 * @param modelForExport наменование модели и папка где находится, пример 'raamatupidamine/arv'
 * @param callback
 */
function createXMLmodel(modelForExport, callback) {
    let modelPath =  path.resolve(path.join('./models/', modelForExport));
    let xmlFile =  modelPath +'.xml';
    let model = require(modelPath);
    let oXml = {
        '?xml version = "1.0" encoding="Windows-1252" standalone="yes"?': null,
        'VFPData': {
            selectAsLibs: {
                sql: model.selectAsLibs,
                alias: 'selectAsLibs'
            },
            select: model.select,
            saveDoc: {
                sql: model.saveDoc,
                alias: 'saveDoc'
            },
            deleteDoc: {
                sql: model.deleteDoc,
                alias: 'deleteDoc'
            },
            grid: {
                sql: model.grid.sqlString,
                alias: model.grid.alias
            },
            requiredFields:  {
                validate: _.map(model.requiredFields,'name').join(',')
            }

        }
    };

//пишем XML

    let lcXml = o2x(oXml);

    fs.writeFile(xmlFile, lcXml, (err) => {
        if (err) return (callback (err, null));
        console.log('The file has been saved!');
        callback(null,xmlFile);
    });
}

module.exports = createXMLmodel;
