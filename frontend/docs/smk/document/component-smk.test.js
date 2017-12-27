require('../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

describe('doc test, SMK', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Smk = require('../index.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('../../../../test/fixture/doc-vorder-fixture'),
        libs = require('../../../../test/fixture/datalist-fixture'),
        model = require('../../../../models/raamatupidamine/vorder'),
        data = [{
            row: dataRow,
            bpm: model.bpm,
            relations: [],
            details: dataRow.details,
            gridConfig: model.returnData.gridConfig
        }];


    const user = require('../../../../test/fixture/userData');

    let initData = data[0].row;
    initData.gridData = data[0].details;
    initData.gridConfig = data[0].gridConfig;
    initData.relations = data[0].relations;

    let doc = ReactTestUtils.renderIntoDocument(<Smk userData={user}
                                                     initData={initData}
                                                     docId={0}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it('should contain objects in non-edited mode', () => {
        setTimeout(() => {
            expect(doc.refs['form']).toBeDefined();
            expect(doc.refs['toolbar-container']).toBeDefined();
            expect(doc.refs['doc-toolbar']).toBeDefined();
            expect(doc.refs['doc-common']).toBeDefined();
            expect(doc.refs['input-number']).toBeDefined();
            expect(doc.refs['input-kpv']).toBeDefined();
            expect(doc.refs['select-aaId']).toBeDefined();
            expect(doc.refs['input-arvnr']).toBeDefined();
            expect(doc.refs['input-maksepaev']).toBeDefined();
            expect(doc.refs['dokprop']).toBeDefined();
            expect(doc.refs['input-viitenr']).toBeDefined();
            expect(doc.refs['textarea-selg']).toBeDefined();
            expect(doc.refs['data-grid']).toBeDefined();
            expect(doc.refs['input-summa']).toBeDefined();
            expect(doc.refs['textarea-muud']).toBeDefined();
        });
    });

    it('test doc-toolbar-events', () => {
        setTimeout(() => {
            let docToolbar = doc.refs['doc-toolbar'];

            expect(docToolbar.btnEditClick).toBeDefined();
            docToolbar.btnEditClick();
            let state = doc.state;
            expect(state).toBeDefined();
            expect(state.edited).toBeTruthy();
            expect(doc.refs['grid-toolbar-container']).toBeDefined();
            expect(doc.refs['grid-button-add']).toBeDefined();
            expect(doc.refs['grid-button-edit']).toBeDefined();
            expect(doc.refs['grid-button-delete']).toBeDefined();
        });

    });

    it('doc-toolbar btnAdd click event test (handleGridBtnClick(btnName, id))', () => {
        setTimeout(() => {
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
            expect(doc.refs['asutusid']).toBeDefined();
            expect(doc.refs['aa']).toBeDefined();
            expect(doc.refs['summa']).toBeDefined();
            expect(doc.refs['konto']).toBeDefined();
            expect(doc.refs['tunnus']).toBeDefined();
            expect(doc.refs['project']).toBeDefined();
        });
    });

    it('doc-toolbar btnCancel test', () => {
        setTimeout(() => {
            let docToolbar = doc.refs['doc-toolbar'];
            expect(docToolbar.btnCancelClick).toBeDefined();

            docToolbar.btnCancelClick();
            expect(doc.state).toBeDefined();
            expect(doc.state.edited).toBeFalsy();
            // резервная копия удалена
            expect(doc.backup).toBeNull();
            expect(doc.docData.number).not.toBe('9999');
        });
    });

    it('test toolbar btnEdit', () => {
        setTimeout(() => {
            let docToolbar = doc.refs['doc-toolbar'];
            expect(docToolbar.btnEditClick).toBeDefined();
            docToolbar.btnEditClick();
            expect(doc.state.edited).toBeTruthy();
            // проверим чтоб резервная копия была
            expect(doc.backup.docData).not.toBeNull();

            // will change data
            doc.handleInputChange('number', '9999');
            expect(doc.docData.number).toBe('9999');
        });
    });

    it('select grid row test', () => {
        setTimeout(() => {
            let nomId = doc.refs['nomid'],
                asutusId = doc.refs['asutusid'],
                aa = doc.refs['aa'],
                konto = doc.refs['konto'],
                summa = doc.refs['summa'];

            expect(nomId).toBeDefined();
            expect(asutusId).toBeDefined();
            expect(aa).toBeDefined();
            expect(konto).toBeDefined();
            expect(summa).toBeDefined();

            doc.handleGridRowChange('nomid', 3);
            doc.handleGridRowChange('asutusid', 1);
            doc.handleGridRowChange('aa', 'aa-test');
            doc.handleGridRowChange('konto', '113');
            doc.handleGridRowInput('summa', 10);
            expect(doc.gridRowData['nomid']).toBe(3);
            expect(doc.gridRowData['asutusid']).toBe(1);
            expect(doc.gridRowData['aa']).toBe('aa-test');
            expect(doc.gridRowData['konto']).toBe('113');
            expect(doc.gridRowData['summa']).toBe(10);

        });
    });

    it('Grid row btnOk test', () => {
        setTimeout(() => {
            expect(doc.modalPageClick).toBeDefined();
            doc.modalPageClick('Ok');
            expect(doc.state.gridRowEdit).toBeFalsy();
            // модальное окно редактирования должно исчезнуть
            expect(doc.refs['modalpage-grid-row']).not.toBeDefined();
            expect(doc.gridData.length).toBe(3);

        });
    });


    it('gridRow ModalPage btnCancel click test', () => {
        setTimeout(() => {
            let btnAdd = doc.refs['grid-button-add'];
            expect(btnAdd).toBeDefined();
            doc.handleGridBtnClick('add');

            expect(doc.modalPageClick).toBeDefined();
            doc.modalPageClick('Cancel');
            expect(doc.state.gridRowEdit).toBeFalsy();
            // модальное окно редактирования должно исчезнуть
            expect(doc.refs['modalpage-grid-row']).not.toBeDefined();

        });
    });

    it('grid btnDelete test', () => {
        setTimeout(() => {
            let btnDel = doc.refs['grid-button-delete'];
            expect(btnDel).toBeDefined();
            expect(doc.gridData.length).toBe(3);
            doc.handleGridBtnClick('delete');
            expect(doc.gridData.length).toBe(2);

        });
    });

    it('test recalcDocSumma', () => {
        setTimeout(() => {
            expect(doc.recalcDocSumma).toBeDefined();
            doc.recalcDocSumma();
            expect(doc.docData.summa).toBe(99);
        });
    });

    it('test for libs', () => {
        setTimeout(() => {
            expect(doc.createLibs).toBeDefined();
            let libs = doc.createLibs();
            expect(libs).toEqual({
                asutused: [],
                kontod: [],
                dokProps: [],
                tunnus: [],
                project: [],
                nomenclature: [],
                aa: []
            });

        });
    });

    it('test of onChange action', () => {
        setTimeout(() => {
            let input = doc.refs['input-number'],
                docToolbar = doc.refs['doc-toolbar'],
                number = input.state.value;

            expect(input).toBeDefined();
            expect(docToolbar.btnEditClick).toBeDefined();
            expect(input.props.onChange).toBeDefined();
            doc.handleInput('number', '9999');
            // изменения вне режима редактирования не меняют состояния
            expect(doc.docData['number']).toBe(number);
            docToolbar.btnEditClick();

            // изменения должны примениться
            doc.handleInput('number', '9999');
            expect(doc.docData['number']).toBe('9999');
            docToolbar.btnCancelClick();
        });
    });

    it('should contain handlePageClick function', () => {
        expect(doc.handlePageClick).toBeDefined();
    });


});
/**
 * Created by HP on 24.06.2017.
 */
