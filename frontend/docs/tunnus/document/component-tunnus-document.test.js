require('../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const user = require('../../../../test/fixture/userData');


describe('doc test, Tunnus', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Document = require('./index.jsx');

    let dataRow = require('../../../../test/fixture/project-fixture'),
        model = require('../../../../models/libs/libraries/tunnus'),
        data = [{
            row: dataRow,
        }];

    let doc = ReactTestUtils.renderIntoDocument(<Document initData={data}
                                                          docId = {187}
                                                          userData = {user}
    />);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it('should contain objects in non-edited mode', () => {
        expect(doc.refs['document']).toBeDefined();
        const DocumentTemplate = doc.refs['document'];
        expect(DocumentTemplate.refs['toolbar-container']).toBeDefined();
        expect(DocumentTemplate.refs['toolbar-container']).toBeDefined();
        expect(DocumentTemplate.refs['doc-toolbar']).toBeDefined();
        expect(DocumentTemplate.refs['input-kood']).toBeDefined();
        expect(DocumentTemplate.refs['input-nimetus']).toBeDefined();
        expect(DocumentTemplate.refs['textarea-muud']).toBeDefined();
    });


});
