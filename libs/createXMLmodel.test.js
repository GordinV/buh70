const modelCreator = require('./createXMLmodel');
const fs = require('fs');

describe('XML model creation test', () => {

    it('should de defined', () => {
        expect(modelCreator).toBeDefined();
    });

    it('should create XML module', (done) => {
        //find if file exists
        let  modelForExport = 'raamatupidamine/arv';
        let xmlFile = __dirname + './../models/'+ modelForExport + '.xml';

        console.log('xmlFile',xmlFile);

        // if exists -> delete
        if (fs.existsSync(xmlFile)) {
            console.log('file exists, deleting it');
            fs.unlinkSync(xmlFile);
        }
        //calling function to generate model
        modelCreator(modelForExport,(err, xmlFile) => {
            expect(err).toBeNull();
            expect(xmlFile).toBeDefined();
            expect(fs.existsSync(xmlFile));
            done();
        });

    });
});