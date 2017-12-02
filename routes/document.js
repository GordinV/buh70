'use strict';
exports.get = function(req, res, params) {
    const React = require('react'),
        ReactServer = require('react-dom/server');

    // check for userid in session
    let user = require('../middleware/userData')(req),
        parameter = req.params.id,
        docTypePattern = /[0-9]/gi,
        docIdPattern = /[^0-9]/gi,
        docId = parameter.replace(docIdPattern, '').trim(),
        docTypeId = parameter.replace( docTypePattern, '').trim(),
        docComponent = {},
        results = [] , // {} сюда будем писать результат выборки
        DocDataObject = require('../models/documents'), // погружаем модель
        docTemplate = 'document', // шаблон для документа
        docName = 'Document',
        moduleSource = "/javascripts/doc.js", // линк с указанием модуля, передадим параметром
        docInitData = {
            docTypeId: docTypeId.toUpperCase(),
            data: [],
            bpm:[]
        };
//@todo заменить

    switch (docTypeId) {
        case 'ARV':
            docComponent = require('../frontend/docs/arve/arve.jsx');
            moduleSource = "/javascripts/arv.js";
            docName = 'Arve';
            break;

        case 'JOURNAL':
            docComponent = require('../frontend/docs/journal/journal.jsx');
            moduleSource = "/javascripts/journal.js";
            docName = 'Lausend';
            break;
        case 'SORDER':
            docComponent = require('../frontend/docs/sorder/sorder.jsx');
            moduleSource = "/javascripts/sorder.js";
            docName = 'Kassa sissetuliku order';
            break;
        case 'VORDER':
            docComponent = require('../frontend/docs/vorder/vorder.jsx');
            docName = 'Kassa väljamakse order';
            moduleSource = "/javascripts/vorder.js";
            break;
        case 'SMK':
            docComponent = require('../frontend/docs/smk/smk.jsx');
            docName = 'Sissemakse korraldus';
            moduleSource = "/javascripts/smk.js";
            break;
        case 'VMK':
            docComponent = require('../frontend/docs/vmk/vmk.jsx');
            docName = 'Väljamakse korraldus';
            moduleSource = "/javascripts/vmk.js";
            break;
        case 'ASUTUSED':
            docComponent = require('../frontend/docs/asutused/asutused.jsx');
            docName = 'Asutused';
            moduleSource = "/javascripts/asutused.js";
            break;
        case 'KONTOD':
            docComponent = require('../frontend/docs/kontod/kontod.jsx');
            docName = 'Kontod';
            moduleSource = "/javascripts/kontod.js";
            break;
        case 'NOMENCLATURE':
            docComponent = require('../frontend/docs/nomenclature/nomenclature.jsx');
            docName = 'Nomenclature';
            moduleSource = "/javascripts/nomenclature.js";
            break;
        case 'DOCUMENT':
            docComponent = require('../frontend/docs/document/document.jsx');
            docName = 'Document';
            moduleSource = "/javascripts/documentLib.js";
            break;
        case 'PROJECT':
            docComponent = require('../frontend/docs/project/project.jsx');
            docName = 'Projekt';
            moduleSource = "/javascripts/project.js";
            break;
        case 'TUNNUS':
            docComponent = require('../frontend/docs/tunnus/tunnus.jsx');
            docName = 'Tunnus';
            moduleSource = "/javascripts/tunnus.js";
            break;
        default:
            docComponent = require('../middleware/returnDocComponent')(docTypeId); // вернет компонент по типу тип документа
    }


    // пишем в сессию выбранный документ
    if (req.session.docs) {
//        console.log('routes documents session docs found', req.session.docs);
        // ищем в сессии наш компонент
        for (let i = 0; i < req.session.docs.length; i++) {
            if (req.session.docs[i]['component'] == docTypeId) {
                // нашли, сохраняем выбор
                req.session.docs[i].docId = docId;
                break;
            }
        }

    }

    try {
        DocDataObject.selectDoc(docTypeId, [Number(docId), user.userId], (err, data, bpm)=> {

            if (err) {
                console.error(err);
                res.render('error', {message: 'Error in document', status:500} );
                return;
            }

            docInitData = {
                data:data,
                userData: user
            };

            if (data.row) {
                if (bpm) {
                    docInitData.bpm = bpm;
                }

                let Component = React.createElement(
                    docComponent,
                    docInitData
                );

                try {
                    let html = ReactServer.renderToString(Component);
                    res.render(docTemplate, {
                        "user": user,
                        react:html,
                        src: moduleSource,
                        docName: docName,
                        store: JSON.stringify(docInitData),
                        userData: JSON.stringify(user)

                });
                } catch(e) {
                    console.error('error:', e);
                    res.render('error', {message: 'Error in document', status:500} );
                }

            } else {
//            let error =   new Error(400,'Document not found');
                res.render('error', {message: 'Document not found', status:400} );
            }

        }, results);

    } catch(err) {
        console.error(err);
        res.render('error', {message: 'Error in document', status:500} );

    }
};

if (!Date.prototype.toLocalISOString) {
    (function() {

        function pad(number) {
            if (number < 10) {
                return '0' + number;
            }
            return number;
        }

        Date.prototype.toLocalISOString = function() {
            return this.getFullYear() +
                '' +
                '-' + pad(this.getMonth() + 1) +
                '-' + pad(this.getDate()) +
                'T' + pad(this.getHours()) +
                ':' + pad(this.getMinutes()) +
                ':' + pad(this.getSeconds()) ;
//                '.' + (this.getMilliseconds() / 1000).toFixed(3).slice(2, 5) ;
        };

    }());
}
