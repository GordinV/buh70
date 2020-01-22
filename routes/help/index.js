'use strict';
const fs = require('fs');


exports.get = async (req, res) => {
    const docTypeId = req.params.documentType || ''; // параметр тип документа
        // создать объект
        let template = `help`;
        if (docTypeId) {
            template = `help/${docTypeId.toLowerCase()}`;
        }
    try {
        // вернуть отчет
        res.render(template, (err, html)=> {
            if (err) {
                console.error('no teplate, redirect to index:', err);
                res.render(`help/index`);

            } else {
                res.send(html);
            }
        });
    } catch (error) {
        console.error('help  error:', error);
        res.send({status: 500, result: 'Error'});

    }
};
