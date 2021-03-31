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
    let keys = Object.keys(model);
    let oXml = {
        '?xml version = "1.0" encoding="Windows-1252" standalone="yes"?': null,
        'VFPData': {
            grid: {
                sql: (_.indexOf(keys, 'grid')> -1  ? model.grid.sqlString : ''),
                alias: model.grid.alias
            },
            select: _.indexOf(keys, 'select')> -1 ? model.select : '',
            selectAsLibs: {
                sql: _.indexOf(keys, 'selectAsLibs')> -1 ? model.selectAsLibs: '',
                alias: 'selectAsLibs'
            },
            saveDoc: {
                sql: _.indexOf(keys, 'saveDoc')> -1 ? model.saveDoc : '',
                alias: 'saveDoc'
            },
            deleteDoc: {
                sql: _.indexOf(keys, 'deleteDoc')> -1 ? model.deleteDoc : '',
                alias: 'deleteDoc'
            },
            requiredFields:  {
                validate: _.map(model.requiredFields,'name').join(',')
            },
            executeSql: {
                    sql: _.indexOf(keys, 'executeSql')> -1 ? model.executeSql.sqlString : '',
                    alias: _.indexOf(keys, 'executeSql')> -1 ? model.executeSql.alias: ''
            },
            executeCommand: {
                sql: _.indexOf(keys, 'executeCommand')> -1 ? model.executeCommand.command: '',
                alias: _.indexOf(keys, 'executeCommand')> -1 ? model.executeCommand.alias: ''
            },
            register: {
                sql: _.indexOf(keys, 'register')> -1 ? model.register.command : '',
                alias: _.indexOf(keys, 'register')> -1 ? model.register.alias : ''
            },
            endProcess: {
                sql:  _.indexOf(keys, 'endProcess')> -1 ? model.endProcess.command : null,
                alias: _.indexOf(keys, 'endProcess')> -1 ? model.endProcess.alias : null
            },
            generateJournal: {
                sql:  _.indexOf(keys, 'generateJournal')> -1 ? model.generateJournal.command : null,
                alias: _.indexOf(keys, 'generateJournal')> -1 ? model.generateJournal.alias : null
            },
            print:  _.indexOf(keys, 'print')> -1 ? model.print : '',
            getLog: {
                sql:  _.indexOf(keys, 'getLog')> -1 ? model.getLog.command : null,
                alias: _.indexOf(keys, 'getLog')> -1 ? model.getLog.alias : null
            }
        }
    };

//пишем XML

    let lcXml = o2x(oXml);

    fs.writeFile(xmlFile, lcXml, (err) => {
        if (err) return (callback (err, null));
        callback(null,xmlFile);
    });
}

module.exports = createXMLmodel;
