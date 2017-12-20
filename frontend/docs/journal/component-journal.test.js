require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');


describe('doc test, Journal', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Journal = require('./journal.jsx');
//    const style = require('./input-text-styles');

    let dataRow = require('./../../../test/fixture/doc-journal-fixture'),
        libs = require('./../../../test/fixture/datalist-fixture'),
        model = require('./../../../models/raamatupidamine/journal'),
        data = [{
            row: dataRow,
            bpm: model.bpm,
            relations: [],
            details: dataRow.details,
            gridConfig: model.returnData.gridConfig
        }];

    const LIBRARIES = ['asutused', 'kontod', 'tunnus', 'project'];

//    requiredFields = dataRow.requiredFields;

    const user = require('./../../../test/fixture/userData');

    let initData = data[0].row;
    initData.gridData = data[0].details;
    initData.gridConfig = data[0].gridConfig;
    initData.relations = data[0].relations;

    let doc = ReactTestUtils.renderIntoDocument(<Journal userData={user}
                                                         initData={initData}
                                                         docId={0}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
    });

    it('should contain objects in non-edited mode', () => {
        setTimeout(() => {
            expect(doc.refs['toolbar-container']).toBeDefined();
            expect(doc.refs['doc-toolbar']).toBeDefined();
            expect(doc.refs['doc-common']).toBeDefined();
            expect(doc.refs['input-number']).toBeDefined();
            expect(doc.refs['input-kpv']).toBeDefined();
            expect(doc.refs['input-dok']).toBeDefined();
            expect(doc.refs['select-asutusid']).toBeDefined();
            expect(doc.refs['textarea-selg']).toBeDefined();
            expect(doc.refs['textarea-muud']).toBeDefined();
            expect(doc.refs['data-grid']).toBeDefined();
            expect(doc.refs['input-summa']).toBeDefined();
            expect(doc.refs['data-grid']).toBeDefined();
        },100);

    });

    it('doc-toolbar btnAdd click event test (handleGridBtnClick(btnName, id))', () => {
        setTimeout(()=> {
            let btnAdd = doc.refs['grid-button-add'];
            expect(btnAdd).toBeDefined();
            expect(doc.handleGridBtnClick).toBeDefined();
            doc.handleGridBtnClick('add');
            setTimeout(()=> {
                expect(doc.state.gridRowEdit).toBeTruthy();
                expect(doc.state.gridRowEvent).toBe('add');
                expect(doc.refs['modalpage-grid-row']).toBeDefined(); //открылось модальное окнос со строкой
            })

        })
    });

    it('select grid row test', () => {
        setTimeout(()=> {
            let container = doc.refs['grid-row-container'],
                db = doc.refs['deebet'],
                kr = doc.refs['kreedit'],
                summa = doc.refs['summa'];

            expect(db).toBeDefined();
            expect(kr).toBeDefined();
            expect(summa).toBeDefined();

            doc.handleGridRowChange('deebet', '111');
            doc.handleGridRowChange('kreedit', '113');
            doc.handleGridRowInput('summa', 10);
            expect(doc.gridRowData['deebet']).toBe('111');
            expect(doc.gridRowData['kreedit']).toBe('113');
            expect(doc.gridRowData['summa']).toBe(10);

        });

    });

    it('Grid row btnOk test', () => {
        setTimeout(()=> {
            expect(doc.modalPageClick).toBeDefined();
            doc.modalPageClick('Ok');
            expect(doc.state.gridRowEdit).toBeFalsy();
            // модальное окно редактирования должно исчезнуть
            expect(doc.refs['modalpage-grid-row']).not.toBeDefined();
            expect(doc.gridData.length).toBe(1);

        })
    });

    it('test recalcDocSumma', () => {
        setTimeout(()=> {
            expect(doc.recalcDocSumma).toBeDefined();

            doc.recalcDocSumma();
            expect(doc.docData.summa).toBe(99);

        })
    });


    it('gridRow ModalPage btnCancel click test', () => {
        setTimeout(()=> {
            let btnAdd = doc.refs['grid-button-add'];
            expect(btnAdd).toBeDefined();
            doc.handleGridBtnClick('add');
            doc.modalPageClick('Cancel');
            expect(doc.state.gridRowEdit).toBeFalsy();
            // модальное окно редактирования должно исчезнуть
            expect(doc.refs['modalpage-grid-row']).not.toBeDefined();
        })
    });

    it('grid btnDelete test', () => {
        setTimeout(()=> {
            let btnDel = doc.refs['grid-button-delete'];
            expect(btnDel).toBeDefined();
            expect(doc.gridData.length).toBe(1);
            doc.handleGridBtnClick('delete');
            expect(doc.gridData.length).toBe(0);
        })
    });

});
