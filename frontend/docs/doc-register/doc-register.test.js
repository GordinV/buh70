require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const    React = require('react'),
    Register = require('./doc-register.jsx'),
    style = require('./doc-register-styles'),
    listData = require('./../../../test/fixture/datalist-fixture'),
    model = require('../../../models/docs_grid_config'),
    config = model.DOK.gridConfiguration,
    gridData = require('../../../test/fixture/dataGrid-fixture'),
    components = [
        {name: 'docsList', data: [{data: listData}], value: 'code2'},
        {name: 'docsGrid', data: [{data: gridData, columns: config}], value: 1}
    ];


describe('doc test, register', () => {

    const component = ReactTestUtils.renderIntoDocument(
        <Register id='grid'
                  components={components}/>
    );

    it('should be define', () => {
        expect(component).toBeDefined();
    });

    it('test for children components', () => {
        let components = [
            'parentDiv',
            'docContainer',
            'toolbar-menu',
            'toolbarContainer',
            'list-sidebar',
            'grid-sidebar',
            'modalpageFilter',
            'dataList',
            'dataGrid',
            'modalpageDelete',
            'modalpageInfo'
        ];
        components.forEach(comp => {
            expect(comp).toBeDefined();
        });
    });

    it ('test of list component in Register', () => {
        let List = component.refs['treeList'],
            data = [{data: listData}];
        expect(List).toBeDefined();
        expect(List.state.value).toBe('code2'); // value: 'code1'
        expect(List.state.index).toBe(1);
    });

    it.skip ('test of grid component in Register', () => {
        let Grid = component.refs['dataGrid'],
            data = [{data: gridData}],
            rowIndex = 1; // gridData[1].id = 2

        expect(Grid).toBeDefined();
        expect(Grid.state.activeRow).toBe(rowIndex); // value: 2
        expect(Grid.state.gridData).toEqual(data[0].data); // [{data: gridData, columns: config}]

    });

    it ('modalPageBtnClick && btnFilterClick test', ()=> {
        expect(component.modalPageBtnClick).toBeDefined();
        expect(component.btnFilterClick).toBeDefined();
        component.btnFilterClick(); // modalPage opened
        expect(component.state.getFilter).toBeTruthy();
        component.modalPageBtnClick('Cancel'); // modalpage closed
        expect(component.state.getFilter).toBeFalsy();
    });

    it ('modalPageDelBtnClick test ', () => {
        expect(component.modalPageDelBtnClick).toBeDefined();
        expect(component.btnDeleteClick).toBeDefined();
        component.btnDeleteClick(); // modalPage opened
        expect(component.state.getDeleteModalPage).toBeTruthy();
        component.modalPageDelBtnClick('Cancel'); // modalpage closed
        expect(component.state.getDeleteModalPage).toBeFalsy();

    })
})

