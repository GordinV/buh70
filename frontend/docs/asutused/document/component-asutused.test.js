require('../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');



describe('doc test, Asutused', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Asutused = require('./index.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('../../../../test/fixture/asutused-fixture'),
        model = require('../../../../models/libs/libraries/asutused'),
        data = [{dataRow}];

    const user = require('../../../../test/fixture/userData');

    let doc = ReactTestUtils.renderIntoDocument(<Asutused initData={data} userData = {user} docId = {0}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it('should contain objects in non-edited mode', () => {
        expect(doc.refs['document']).toBeDefined();
        const DocumentTemplate = doc.refs['document'];

        expect(DocumentTemplate.refs['form']).toBeDefined();
        expect(DocumentTemplate.refs['toolbar-container']).toBeDefined();
        expect(DocumentTemplate.refs['doc-toolbar']).toBeDefined();
        expect(DocumentTemplate.refs['input-regkood']).toBeDefined();
        expect(DocumentTemplate.refs['input-nimetus']).toBeDefined();
        expect(DocumentTemplate.refs['input-omvorm']).toBeDefined();
        expect(DocumentTemplate.refs['textarea-aadress']).toBeDefined();
        expect(DocumentTemplate.refs['textarea-kontakt']).toBeDefined();
        expect(DocumentTemplate.refs['input-tel']).toBeDefined();
        expect(DocumentTemplate.refs['input-email']).toBeDefined();
        expect(DocumentTemplate.refs['textarea-muud']).toBeDefined();
        expect(DocumentTemplate.refs['textarea-mark']).toBeDefined();
    });

});
