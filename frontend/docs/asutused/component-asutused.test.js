require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');
const flux = require('fluxify');
let docStore = require('../../stores/doc_store.js');


describe('doc test, Asutused', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Asutused = require('./asutused.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('./../../../test/fixture/asutused-fixture'),
        model = require('./../../../models/libs/libraries/asutused'),
        data = {
            row: dataRow,
        }


    let onChangeHandler = jest.fn();

    let doc = ReactTestUtils.renderIntoDocument(<Asutused data={data}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it('should contain objects in non-edited mode', () => {
        expect(doc.refs['form']).toBeDefined();
        expect(doc.refs['toolbar-container']).toBeDefined();
        expect(doc.refs['doc-toolbar']).toBeDefined();
        expect(doc.refs['input-regkood']).toBeDefined();
        expect(doc.refs['input-nimetus']).toBeDefined();
        expect(doc.refs['input-omvorm']).toBeDefined();
        expect(doc.refs['textarea-aadress']).toBeDefined();
        expect(doc.refs['textarea-kontakt']).toBeDefined();
        expect(doc.refs['input-tel']).toBeDefined();
        expect(doc.refs['input-email']).toBeDefined();
        expect(doc.refs['textarea-muud']).toBeDefined();
        expect(doc.refs['textarea-mark']).toBeDefined();
    });

    it('test doc-toolbar-events', (done) => {
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

    it('test toolbar btnEdit', ()=> {
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
                doc.handleInputChange('regkood', '9999');
                expect(doc.docData.regkood).toBe('9999');

                done();
            }, 1000);
        }
    });

    it ('doc-toolbar btnCancel test', () => {
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

    it ('doc-toolbar docData restore test', () => {
        expect(doc.docData.regkood).not.toBe('9999');;
    });


    it('test of onChange action', (done) => {
        let input = doc.refs['input-regkood'],
            docToolbar = doc.refs['doc-toolbar'],
            regkood = input.state.value;

        expect(input).toBeDefined();
        expect(docToolbar.btnEditClick).toBeDefined();
        expect(input.props.onChange).toBeDefined();
        doc.handleInputChange('regkood', '9999');
        // изменения вне режима редактирования не меняют состояния
        expect(doc.docData['regkood']).toBe(regkood);
        docToolbar.btnEditClick();

        // изменения должны примениться
        setTimeout(() => {
            // изменения должны примениться
//            input.value = '9999';
//            ReactTestUtils.Simulate.change(input);
            doc.handleInputChange('regkood', '9999');
            expect(doc.docData['regkood']).toBe('9999');
            docToolbar.btnCancelClick();
            done();
        }, 1000);

    });


});
