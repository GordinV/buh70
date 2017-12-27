require('../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');


describe('doc test, Documents', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Document = require('./index.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('../../../../test/fixture/document-fixture'),
        model = require('../../../../models/libs/libraries/document'),
        data = {
            row: dataRow,
        };

    const user = require('../../../../test/fixture/userData');

    let onChangeHandler = jest.fn();

    let doc = ReactTestUtils.renderIntoDocument(<Document initData={data} userData = {user} docId = {0}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it.skip('should contain objects in non-edited mode', () => {
        expect(doc.refs['form']).toBeDefined();
        expect(doc.refs['toolbar-container']).toBeDefined();
        expect(doc.refs['doc-toolbar']).toBeDefined();
        expect(doc.refs['input-kood']).toBeDefined();
        expect(doc.refs['input-nimetus']).toBeDefined();
        expect(doc.refs['textarea-muud']).toBeDefined();
        expect(doc.refs['select-type']).toBeDefined();
/*
        expect(doc.refs['select-module']).toBeDefined();
*/


    });

    it.skip('test doc-toolbar-events', (done) => {
        let docToolbar = doc.refs['doc-toolbar'];

        expect(docToolbar.btnAddClick).toBeDefined();
        docToolbar.btnAddClick();

        setTimeout(() => {
            let state = doc.state;
            expect(state).toBeDefined();
            expect(state.edited).toBeTruthy();
            done();
        }, 1000);

    });

    it.skip('test toolbar btnEdit', ()=> {
        let docToolbar = doc.refs['doc-toolbar'];
        expect(docToolbar.btnEditClick).toBeDefined();
        if (!doc.state.edited)  {
            docToolbar.btnEditClick();
            setTimeout(() => {
                expect(doc.state.edited).toBeTruthy();
                done();
            }, 1000);
        }
    });

    it.skip ('doc-toolbar btnCancel test', (done) => {
        let docToolbar = doc.refs['doc-toolbar'];
        expect(docToolbar.btnCancelClick).toBeDefined();

        docToolbar.btnCancelClick();

        setTimeout(() => {
            expect(doc.state).toBeDefined();
            expect(doc.state.edited).toBeFalsy();
            done();
        },1000);
    });

    it.skip('test of onChange action', (done) => {
        let input = doc.refs['input-kood'],
            docToolbar = doc.refs['doc-toolbar'],
            kood = input.state.value;

        expect(input).toBeDefined();
        expect(docToolbar.btnEditClick).toBeDefined();
        expect(input.props.onChange).toBeDefined();
        doc.handleInputChange('kood', '9999');
        // изменения вне режима редактирования не меняют состояния
        expect(doc.state.docData['kood']).toBe(kood);
        docToolbar.btnEditClick();

        // изменения должны примениться
        setTimeout(() => {
            // изменения должны примениться
//            input.value = '9999';
//            ReactTestUtils.Simulate.change(input);
            doc.handleInputChange('kood', '9999');
            expect(doc.state.docData['kood']).toBe('9999');
            docToolbar.btnCancelClick();
            done();
        }, 1000);

    });


});
