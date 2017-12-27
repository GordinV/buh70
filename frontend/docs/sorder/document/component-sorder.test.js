require('../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');


describe('doc test, Sorder', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Sorder = require('./index.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('../../../../test/fixture/doc-common-fixture'),
        libs = require('../../../../test/fixture/datalist-fixture'),
        model = require('../../../../models/raamatupidamine/arv'),
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

    let onChangeHandler = jest.fn();

    let doc = ReactTestUtils.renderIntoDocument(<Sorder userData={user}
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
            expect(doc.refs['select-kassaId']).toBeDefined();
            expect(doc.refs['select-asutusId']).toBeDefined();
            expect(doc.refs['input-arvnr']).toBeDefined();
            expect(doc.refs['input-dokument']).toBeDefined();
            expect(doc.refs['dokprop']).toBeDefined();
            expect(doc.refs['textarea-nimi']).toBeDefined();
            expect(doc.refs['textarea-aadress']).toBeDefined();
            expect(doc.refs['textarea-alus']).toBeDefined();
            expect(doc.refs['data-grid']).toBeDefined();
            expect(doc.refs['input-summa']).toBeDefined();
            expect(doc.refs['textarea-muud']).toBeDefined();
        });
    });

    it.skip('test doc-toolbar-events', (done) => {
        let docToolbar = doc.refs['doc-toolbar'];

        expect(docToolbar.btnEditClick).toBeDefined();
        docToolbar.btnEditClick();

        setTimeout(() => {
            let state = doc.state;
            expect(state).toBeDefined();
            expect(state.edited).toBeTruthy();
            expect(doc.refs['grid-toolbar-container']).toBeDefined();
            expect(doc.refs['grid-button-add']).toBeDefined();
            expect(doc.refs['grid-button-edit']).toBeDefined();
            expect(doc.refs['grid-button-delete']).toBeDefined();
            done();
        }, 1000);


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
            expect(doc.refs['summa']).toBeDefined();
            expect(doc.refs['konto']).toBeDefined();
            expect(doc.refs['tunnus']).toBeDefined();
            expect(doc.refs['project']).toBeDefined();
        });
    });

    it('select grid row test', () => {
        setTimeout(() => {
            let nomId = doc.refs['nomid'],
                konto = doc.refs['konto'],
                summa = doc.refs['summa'];

            expect(nomId).toBeDefined();
            expect(konto).toBeDefined();
            expect(summa).toBeDefined();

            doc.handleGridRowChange('nomid', 3);
            doc.handleGridRowChange('konto', '113');
            doc.handleGridRowInput('summa', 10);
            expect(doc.gridRowData['nomid']).toBe(3);
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
        })
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
                kassa: [],
                tunnus: [],
                project: [],
                nomenclature: []
            });

        })
    });

    it('test toolbar btnEdit', () => {
        setTimeout(() => {
            let docToolbar = doc.refs['doc-toolbar'];
            expect(docToolbar.btnEditClick).toBeDefined();
            if (!doc.state.edited) {
                docToolbar.btnEditClick();
                expect(doc.state.edited).toBeTruthy();
                // проверим чтоб резервная копия была
                expect(doc.backup).not.toBeNull();

                // will change data
                doc.handleInputChange('number', '9999');
                expect(doc.docData.number).toBe('9999');
            }
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

    it('test of onChange action', () => {
        setTimeout(() => {
            let input = doc.refs['input-number'],
                docToolbar = doc.refs['doc-toolbar'],
                number = input.state.value;

            expect(input).toBeDefined();
            expect(docToolbar.btnEditClick).toBeDefined();
            expect(input.props.onChange).toBeDefined();
            doc.handleInput('number', String('9999'));
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
        setTimeout(()=> {
            expect(doc.handlePageClick).toBeDefined();

        });
    });


});
