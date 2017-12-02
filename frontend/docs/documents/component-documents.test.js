require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

const userData = {};
const initData = {result: {data: [{id: 1}]}, gridConfig: [{id: "id", name: "id", width: "10%", show: false}]};

describe('class test, Documents', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Document = require('./documents.jsx');
//    const style = require('./input-text-styles');

    /*
        let dataRow = require('./../../../test/fixture/document-fixture'),
            model = require('./../../../models/libs/libraries/document'),
            data = {
                row: dataRow,
            }

        let onChangeHandler = jest.fn();
    */


    let doc = ReactTestUtils.renderIntoDocument(<Document initData={initData}
                                                          userData={userData}
                                                          docTypeId='TUNNUS'
                                                          render={renderer}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
        expect(doc.refs['dataGrid']);
        expect(doc.refs['modalpageFilter']);
        expect(doc.refs['toolbarContainer']);
        expect(doc.refs['filterToolbarContainer']);

    });

    it('test of clickHandle', () => {
        expect(doc.clickHandler).toBeDefined()
        doc.clickHandler(null, 0, null);
        expect(doc.state.value).toBe(1);
    });

    it('test of headerClickHandler', () => {
        const sortBy = {column: 'id', direction: 'asc'};
        expect(doc.headerClickHandler).toBeDefined()
        try {
            doc.headerClickHandler(sortBy);
        } catch (e) {
            console.error(e);
        }
        expect(doc.state.sortBy).toEqual(sortBy);
    });

    it('test of btnFilterClick', () => {
        expect(doc.btnFilterClick).toBeDefined();
        expect(doc.state.getFilter).toBeFalsy(); // init state
        try {
            doc.btnFilterClick();
        } catch (e) {
            console.error(e);
        }
        expect(doc.state.getFilter).toBeTruthy();
    });

    it('test of btnAddClick', () => {
        expect(doc.btnAddClick).toBeDefined();
    });

    it('test of btnEditClick', () => {
        expect(doc.btnEditClick).toBeDefined();
    });

    it('test of btnDeleteClick', () => {
        expect(doc.btnDeleteClick).toBeDefined();
    });

    it('test of btnPrintClick', () => {
        expect(doc.btnPrintClick).toBeDefined();
    });

    it('test of filterDataHandler', () => {
        const filterData = [{name: "id", type: 'number', value: 1}];
        expect(doc.filterDataHandler).toBeDefined();
        doc.filterDataHandler(filterData);
        expect(doc.filterData).toEqual(filterData);
    });

    it.skip('test of modalPageBtnClick', (done) => {
        expect(doc.modalPageBtnClick).toBeDefined();
        doc.modalPageBtnClick('Ok');
        try {
            expect(doc.state.sqlWhere).toEqual(' where id = 1');
        } catch (e) {
            console.error(e);
        }
    });

    it('test of getFilterString', () => {
        expect(doc.getFilterString).toBeDefined();
        let result = doc.getFilterString();
        expect(result).toEqual('id:1; ');
    });

    it('test of prepareParamsForToolbar', () => {
        const buttonParams = {
            show: expect.any(Boolean),
            disabled: expect.any(Boolean)
        };

        const desiredParameters = {
            btnAdd: buttonParams,
            btnEdit: buttonParams,
            btnDelete: buttonParams,
            btnPrint: buttonParams
        };

        const parametrid = doc.prepareParamsForToolbar();
        expect(parametrid).toMatchObject(desiredParameters);
    });

    it('test of fetchData()', async() => {
        expect(doc.fetchData).toBeDefined();
        await doc.fetchData();
//        expect(doc.fetchData).resolves.toBe(true);
    });

    it ('test of btnStartClickHanler', ()=> {
        expect(doc.btnStartClickHanler).toBeDefined();
        expect(doc.state.hasStartMenuVisible).toBeFalsy();
        doc.btnStartClickHanler();
        expect(doc.state.hasStartMenuVisible).toBeTruthy();
        expect(doc.refs['startMenu']).toBeDefined();
    })

    it ('test of startMenuClickHandler', ()=> {
        expect(doc.startMenuClickHandler).toBeDefined();
        expect(doc.state.hasStartMenuVisible).toBeTruthy(); // предварительное значение истина, т.е. меню открыто
        let value = doc.startMenuData[0].kood;
        doc.startMenuClickHandler(value);
        expect(doc.state.hasStartMenuVisible).toBeFalsy(); //  меню спрятано
    });
});

function renderer() {
    return (<div>test</div>)
}
