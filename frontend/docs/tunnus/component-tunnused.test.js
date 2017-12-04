require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const flux = require('fluxify');
let docStore = require('../../stores/doc_store.js');


describe('doc test, Tunnused', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Tunnused = require('./index.jsx');

    let dataRow = require('./../../../test/fixture/project-fixture'),
        model = require('./../../../models/libs/libraries/tunnus'),
        data = {
            row: dataRow,
        };


    let onChangeHandler = jest.fn();

    let doc = ReactTestUtils.renderIntoDocument(<Tunnused/>);

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
                // проверим чтоб резервная копия была
                expect(flux.docStore.backup.docData).not.toBeNull();
                expect(flux.docStore.backup.gridData).not.toBeNull();

                // will change data
                doc.handleInputChange('kood', '9999');
                expect(doc.docData.kood).toBe('9999');

                done();
            }, 1000);
        }
    });

    it.skip ('doc-toolbar btnCancel test', () => {
        let docToolbar = doc.refs['doc-toolbar'];
        expect(docToolbar.btnCancelClick).toBeDefined();

        docToolbar.btnCancelClick();

        setTimeout(() => {
            expect(doc.state).toBeDefined();
            expect(doc.state.edited).toBeFalsy();
            // резервная копия удалена
            expect(flux.docStore.backup.docData).toBeNull();
            expect(flux.docStore.backup.gridData).toBeNull();

        },1000);
    });

    it.skip ('doc-toolbar docData restore test', () => {
        expect(doc.docData.kood).not.toBe('9999');
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
        expect(doc.docData['kood']).toBe(kood);
        docToolbar.btnEditClick();

        // изменения должны примениться
        setTimeout(() => {
            // изменения должны примениться
//            input.value = '9999';
//            ReactTestUtils.Simulate.change(input);
            doc.handleInputChange('kood', '9999');
            expect(doc.docData['kood']).toBe('9999');
            docToolbar.btnCancelClick();
            done();
        }, 1000);

    });


});
