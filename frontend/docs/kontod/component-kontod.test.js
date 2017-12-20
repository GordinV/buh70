require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');


describe('doc test, Kontod', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Kontod = require('./kontod.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('./../../../test/fixture/kontod-fixture'),
        model = require('./../../../models/libs/libraries/kontod'),
        data = [{dataRow}];
    const user = require('./../../../test/fixture/userData');



    let doc = ReactTestUtils.renderIntoDocument(<Kontod initData={data} userData = {user} docId = {0}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
        expect(doc.renderer).toBeDefined();
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
        expect(DocumentTemplate.refs['select-tyyp']).toBeDefined();
        expect(DocumentTemplate.refs['input-valid']).toBeDefined();
    });

});
