require('../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

describe('doc test, Project', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Project = require('./index.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('../../../../test/fixture/project-fixture'),
        model = require('../../../../models/libs/libraries/project'),
        data = [{
            row: dataRow,
        }];
    const user = require('../../../../test/fixture/userData');


    let doc = ReactTestUtils.renderIntoDocument(<Project initData={data} userData = {user} docId = {0}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it('should contain all objects', () => {
        expect(doc.refs['document']).toBeDefined();
        const DocumentTemplate = doc.refs['document'];

        expect(DocumentTemplate.refs['form']).toBeDefined();
        expect(DocumentTemplate.refs['toolbar-container']).toBeDefined();
        expect(DocumentTemplate.refs['doc-toolbar']).toBeDefined();
        expect(DocumentTemplate.refs['input-kood']).toBeDefined();
        expect(DocumentTemplate.refs['input-nimetus']).toBeDefined();
        expect(DocumentTemplate.refs['textarea-muud']).toBeDefined();
    });
});
