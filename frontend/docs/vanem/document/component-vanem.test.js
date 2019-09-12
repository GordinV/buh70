require('../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

describe('doc test, Vanem', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Doc = require('./index.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('../../../../test/fixture/doc-common-fixture'),
        libs = require('../../../../test/fixture/datalist-fixture'),
        model = require('../../../../models/lapsed/vanem'),
        data = [{
            row: dataRow,
            bpm: model.bpm,
            lapsed: [],
            gridConfig: model.returnData.gridConfig
        }];

    const user = require('../../../../test/fixture/userData');

    let initData = data[0].row;
    initData.gridData = data[0].lapsed;
    initData.gridConfig = data[0].gridConfig;

    let onChangeHandler = jest.fn();

    let doc = ReactTestUtils.renderIntoDocument(<Doc userData={user}
                                                      initData={initData}
                                                      docId={0}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it('should contain data', () => {

        setTimeout(() => {
            let data = doc.docData;
            expect(data.id).toBeDefined();
        }, 100);
    });

    it.skip('should contain objects in non-edited mode', () => {
        setTimeout(() => {
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
    });

    it.skip('test doc-toolbar-events', () => {
        setTimeout(() => {
            let docToolbar = doc.refs['doc-toolbar'];

            expect(docToolbar.btnAddClick).toBeDefined();
            docToolbar.btnAddClick();

            let state = doc.state;
            expect(state).toBeDefined();
            expect(state.edited).toBeTruthy();
            expect(doc.refs['grid-toolbar-container']).toBeDefined();
            expect(doc.refs['grid-button-add']).toBeDefined();
            expect(doc.refs['grid-button-edit']).toBeDefined();
            expect(doc.refs['grid-button-delete']).toBeDefined();
        }, 100);

    });

    it.skip('doc-toolbar btnAdd click event test (handleGridBtnClick(btnName, id))', () => {
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
            expect(doc.refs['kogus']).toBeDefined();
            expect(doc.refs['hind']).toBeDefined();
            expect(doc.refs['kbmta']).toBeDefined();
            expect(doc.refs['kbm']).toBeDefined();
            expect(doc.refs['summa']).toBeDefined();
        });
    });

    it.skip('select teenus test', () => {
        setTimeout(() => {
            let inputSelect = doc.refs['nomid'],
                inputHind = doc.refs['hind'];

            expect(inputSelect).toBeDefined();
            expect(inputHind).toBeDefined();

            let nomId = doc.libs.nomenclature[0].id;
            expect(nomId).toBeDefined();
            doc.handleGridRowChange('nomid', nomId);
            doc.handleGridRowInput('hind', 10);
            doc.handleGridRowInput('kogus', 1);
            expect(doc.gridRowData['nomid']).toBe(2);
            expect(doc.gridRowData['hind']).toBe(10);
            expect(doc.gridRowData['kogus']).toBe(1);
            expect(doc.gridRowData['kbm']).toBe(2);
            expect(doc.gridRowData['kbmta']).toBe(10);
            expect(doc.gridRowData['summa']).toBe(12);

        });

    });


    it.skip('test toolbar btnEdit', () => {
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

    it.skip('doc-toolbar btnCancel test', () => {
        setTimeout(() => {
            let docToolbar = doc.refs['doc-toolbar'];
            expect(docToolbar.btnCancelClick).toBeDefined();

            docToolbar.btnCancelClick();

            expect(doc.state).toBeDefined();
            expect(doc.state.edited).toBeFalsy();
            // резервная копия удалена
            expect(doc.backup).toBeNull();
        })
    });

    it.skip('test of onChange action', () => {
        setTimeout(()=> {
            let input = doc.refs['input-number'],
                docToolbar = doc.refs['doc-toolbar'],
                number = input.state.value;

            expect(input).toBeDefined();
            expect(docToolbar.btnEditClick).toBeDefined();
            doc.handleInputChange('number', '9999');
            // изменения вне режима редактирования не меняют состояния
            expect(doc.docData['number']).toBe(number);

            docToolbar.btnEditClick();

            // изменения должны примениться
            // изменения должны примениться
            doc.handleInputChange('number', '9999');
            expect(doc.docData['number']).toBe('9999');
        })
    });

    it('doc-toolbar docData restore test', () => {
        setTimeout(() => {
            let docToolbar = doc.refs['doc-toolbar'];

            //cancel
            docToolbar.btnCancelClick();
            expect(doc.docData.number).not.toBe(dataRow.number);
        });
    });


});
