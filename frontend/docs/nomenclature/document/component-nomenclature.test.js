require('../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

describe('doc test,Nomenclature', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Nomenclature = require('./index.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('../../../../test/fixture/kontod-fixture'),
        model = require('../../../../models/libs/libraries/nomenclature'),
        data = [{dataRow}];

    const user = require('../../../../test/fixture/userData');


    let doc = ReactTestUtils.renderIntoDocument(<Nomenclature initData={data} userData={user} docId={0}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it('should contain objects in non-edited mode', () => {
        expect(doc.refs['document']).toBeDefined();
        const DocumentTemplate = doc.refs['document'];

        expect(DocumentTemplate.refs['form']).toBeDefined();
        expect(DocumentTemplate.refs['toolbar-container']).toBeDefined();
        expect(DocumentTemplate.refs['doc-toolbar']).toBeDefined();
        expect(DocumentTemplate.refs['input-kood']).toBeDefined();
        expect(DocumentTemplate.refs['input-nimetus']).toBeDefined();
        expect(DocumentTemplate.refs['textarea-muud']).toBeDefined();
        expect(DocumentTemplate.refs['select-dok']).toBeDefined();
        expect(DocumentTemplate.refs['input-hind']).toBeDefined();
        expect(DocumentTemplate.refs['select-valuuta']).toBeDefined();
        expect(DocumentTemplate.refs['input-kuurs']).toBeDefined();
        expect(DocumentTemplate.refs['select_konto_db']).toBeDefined();
        expect(DocumentTemplate.refs['select_konto_kr']).toBeDefined();
        expect(DocumentTemplate.refs['select_projekt']).toBeDefined();
        expect(DocumentTemplate.refs['select_tunnus']).toBeDefined();
    });

    it('should load all libs', (done) => {
        expect(doc.refs['document']).toBeDefined();
        const DocumentTemplate = doc.refs['document'];
        setTimeout(() => {
            expect(DocumentTemplate.libs['tunnus'].length).toBeGreaterThan(0);
            expect(DocumentTemplate.libs['kontod'].length).toBeGreaterThan(0);
            expect(DocumentTemplate.libs['project'].length).toBeGreaterThan(0);
            expect(DocumentTemplate.libs['document'].length).toBeGreaterThan(0);
            done();
        }, 3000);
    });


});
