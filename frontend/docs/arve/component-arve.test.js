require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');
const flux = require('fluxify');
let docStore = require('../../stores/doc_store.js');


describe('doc test, Arve', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Arve = require('./arve.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('./../../../test/fixture/doc-common-fixture'),
        libs = require('./../../../test/fixture/datalist-fixture'),
        model = require('./../../../models/raamatupidamine/arv'),
        data = {
            row: dataRow,
            bpm: model.bpm,
            relations: [],
            details: dataRow.details,
            gridConfig: model.returnData.gridConfig
        }


    flux.doAction('dataChange', dataRow);
    flux.doAction('docIdChange', dataRow.id);
    flux.doAction('detailsChange', dataRow.details); // данные грида

    let onChangeHandler = jest.fn();

    let doc = ReactTestUtils.renderIntoDocument(<Arve data={data} bpm={model.bpm}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it('should contain data about bpm', () => {
        let data = doc.docData;
        expect(data.bpm).toBeDefined();
    });

    it('should contain objects in non-edited mode', () => {
        expect(doc.refs['form']).toBeDefined();
        expect(doc.refs['toolbar-container']).toBeDefined();
        expect(doc.refs['doc-toolbar']).toBeDefined();
        expect(doc.refs['doc-common']).toBeDefined();
        expect(doc.refs['input-number']).toBeDefined();
        expect(doc.refs['input-kpv']).toBeDefined();
        expect(doc.refs['input-tahtaeg']).toBeDefined();
        expect(doc.refs['select-asutusid']).toBeDefined();
        expect(doc.refs['input-lisa']).toBeDefined();
        expect(doc.refs['dokprop-doklausid']).toBeDefined();
        expect(doc.refs['textarea-muud']).toBeDefined();
        expect(doc.refs['data-grid']).toBeDefined();
        expect(doc.refs['input-summa']).toBeDefined();
        expect(doc.refs['input-kbm']).toBeDefined();
        expect(doc.refs['data-grid']).toBeDefined();
    });

    it('test doc-toolbar-events', (done) => {
        let docToolbar = doc.refs['doc-toolbar'];

        expect(docToolbar.btnAddClick).toBeDefined();
        docToolbar.btnAddClick();

        setTimeout(() => {
            let state = doc.state;
            expect(state).toBeDefined();
            expect(state.edited).toBeTruthy();
            expect(doc.refs['grid-toolbar-container']).toBeDefined();
            expect(doc.refs['grid-button-add']).toBeDefined();
            expect(doc.refs['grid-button-edit']).toBeDefined();
            expect(doc.refs['grid-button-delete']).toBeDefined();
            done();
        },1000);

    });

    it('doc-toolbar btnAdd click event test (handleGridBtnClick(btnName, id))', () => {
        let btnAdd = doc.refs['grid-button-add'];
        expect(btnAdd).toBeDefined();
        doc.handleGridBtnClick('add');
        let state = doc.state;
        expect(state.gridRowEdit).toBeTruthy();
        expect(state.gridRowEvent).toBe('add');
        expect(doc.gridRowData.id).toContain('NEW');
        expect(doc.refs['modalpage-grid-row']).toBeDefined();
        expect(doc.refs['grid-row-container']).toBeDefined();
        expect(doc.refs['nomid']).toBeDefined();
        expect(doc.refs['kogus']).toBeDefined();
        expect(doc.refs['hind']).toBeDefined();
        expect(doc.refs['kbmta']).toBeDefined();
        expect(doc.refs['kbm']).toBeDefined();
        expect(doc.refs['summa']).toBeDefined();
    });

    it ('select teenus test', ()=> {

        let inputSelect = doc.refs['nomid'],
            inputHind = doc.refs['hind'];

        expect(inputSelect).toBeDefined();
        expect(inputHind).toBeDefined();

        doc.handleGridRowChange('nomid', 2)
        doc.handleGridRowInput('hind', 10);
        doc.handleGridRowInput('kogus', 1);
        expect(doc.gridRowData['nomid']).toBe(2);
        expect(doc.gridRowData['hind']).toBe(10);
        expect(doc.gridRowData['kogus']).toBe(1);
        expect(doc.gridRowData['kbm']).toBe(2);
        expect(doc.gridRowData['kbmta']).toBe(10);
        expect(doc.gridRowData['summa']).toBe(12);

    });

    it('Grid row btnOk test', () => {
        expect(doc.modalPageClick).toBeDefined();
        doc.modalPageClick('Ok');
        expect(doc.state.gridRowEdit).toBeFalsy();
        // модальное окно редактирования должно исчезнуть
        expect(doc.refs['modalpage-grid-row']).not.toBeDefined();
        expect(doc.gridData.length).toBe(3);
    });

    it('gridRow ModalPage btnCancel click test', () => {
        let btnAdd = doc.refs['grid-button-add'];
        expect(btnAdd).toBeDefined();
        doc.handleGridBtnClick('add');

        expect(doc.modalPageClick).toBeDefined();
        doc.modalPageClick('Cancel');
        expect(doc.state.gridRowEdit).toBeFalsy();
        // модальное окно редактирования должно исчезнуть
        expect(doc.refs['modalpage-grid-row']).not.toBeDefined();
    });

    it('grid btnDelete test', ()=> {
        let btnDel = doc.refs['grid-button-delete'];
        expect(btnDel).toBeDefined();
        expect(doc.gridData.length).toBe(3);
        doc.handleGridBtnClick('delete');
        expect(doc.gridData.length).toBe(2);
    });

    it('test recalcRowSumm', () => {
        let data = {
            kogus: 1,
            hind: 10,
            kbmta: 0,
            kbm: 0,
            summa: 0
        };

        doc.gridRowData = data;
        expect(doc.recalcRowSumm).toBeDefined();
        doc.recalcRowSumm();
        expect(doc.gridRowData.kbmta).toBe(10);
        expect(doc.gridRowData.kbm).toBe(2);
        expect(doc.gridRowData.summa).toBe(12);
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
                doc.handleInputChange('number', '9999');
                expect(doc.docData.number).toBe('9999');

                done();
            }, 1000);
        }
    });

    it('doc-toolbar btnCancel test', () => {
        let docToolbar = doc.refs['doc-toolbar'];
        expect(docToolbar.btnCancelClick).toBeDefined();

        docToolbar.btnCancelClick();

        setTimeout(() => {
            expect(doc.state).toBeDefined();
            expect(doc.state.edited).toBeFalsy();
            // резервная копия удалена
            expect(flux.docStore.backup.docData).toBeNull();
            expect(flux.docStore.backup.gridData).toBeNull();

//            done();
        },1000);
    });

    it('doc-toolbar docData restore test', () => {
        expect(doc.docData.number).not.toBe('9999');;
    });

    it('test of onChange action', (done) => {
        let input = doc.refs['input-number'],
            docToolbar = doc.refs['doc-toolbar'],
            number = input.state.value;

        expect(input).toBeDefined();
        expect(docToolbar.btnEditClick).toBeDefined();
        expect(input.props.onChange).toBeDefined();
        doc.handleInputChange('number', '9999');
        // изменения вне режима редактирования не меняют состояния
        expect(doc.docData['number']).toBe(number);

        docToolbar.btnEditClick();

        // изменения должны примениться
        setTimeout(() => {
            // изменения должны примениться
            doc.handleInputChange('number', '9999');
            expect(doc.docData['number']).toBe('9999');
            docToolbar.btnCancelClick();
            done();
        }, 1000);

    });

    it('should contain handlePageClick function', () => {
        expect(doc.handlePageClick).toBeDefined();
    });

});
