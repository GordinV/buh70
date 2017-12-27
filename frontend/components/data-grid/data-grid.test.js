require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');

describe('component test, data-grid', () => {

    const DataGrid = require('./data-grid.jsx'),
        style = require('./data-grid-styles'),
        model = require('../../../models/docs_grid_config'),
        config = model.DOK.gridConfiguration,
        data = require('../../../test/fixture/dataGrid-fixture'),
        handleClick = jest.fn(),
        handleDblClick = jest.fn(),
        handleHeaderClick = jest.fn();


    const component = ReactTestUtils.renderIntoDocument(<DataGrid
        gridData={data}
        gridColumns={config}
        onChangeAction='docsGridChange'
        onClick = {handleClick}
        onDblClick = {handleDblClick}
        onHeaderClick = {handleHeaderClick}
        url='api'/>);

    let table = component.refs['dataGridTable'];


    it('should be define', () => {
        expect(component).toBeDefined();
        expect(component.refs['dataGridTable']).toBeDefined();
        expect(component.refs['th-0']).toBeDefined();
        expect(component.refs['tr-0']).toBeDefined();
        expect(component.refs['td-0-0']).toBeDefined();
    });

    it('test handleGridHeaderClick', () => {
        let header = component.refs['th-0'];

        ReactTestUtils.Simulate.click(header);

        expect(component.state.activeColumn).toBe('id');
        expect(handleHeaderClick).toBeCalled();
    });

    it('test handleGridCellClick', () => {
        let row = component.refs['tr-1'];

        ReactTestUtils.Simulate.click(row);

        expect(component.state.activeRow).toBe(1);
        expect(handleClick).toBeCalled();
    });

    it('test handleDblClick', () => {
        let row = component.refs['tr-1'];

        ReactTestUtils.Simulate.doubleClick(row);

        expect(component.state.activeRow).toBe(1);
        expect(handleDblClick).toBeCalled();
    });

    it('test handleGridCellDblClick', () => {
        let row = component.refs['tr-1'];

        ReactTestUtils.Simulate.doubleClick(row);
        expect(component.state.activeRow).toBe(1);
    });

    it('test handleKeyPressed Down', () => {
        let activeRow = component.state.activeRow;
        let row = component.refs['tr-1'];
        ReactTestUtils.Simulate.keyDown(row,{key: "Down", keyCode: 40, which: 40});
        expect(component.state.activeRow).toBe(activeRow + 1);
    });

    it('test handleKeyPressed Up', () => {
        let activeRow = component.state.activeRow;
        let row = component.refs['tr-1'];

        ReactTestUtils.Simulate.keyDown(row,{key: "Up", keyCode: 38, which: 38});
        expect(component.state.activeRow).toBe(activeRow - 1);
    });

    it('test for column.width and show prop',() => {
        let header = component.refs['th-0'],
            style = header.style;

        expect(style).toBeDefined();
        expect(style.width).toBe('10%');


        let displayProp = style.display;
        expect(displayProp).toBeDefined();
        expect(displayProp).toBe('none');

        header = component.refs['th-1'];
        style = header.style;
        displayProp = style.display;

        expect(displayProp).toBeDefined();
        expect(displayProp).toBe('table-cell');


    });

    it.skip ('test active row in grid', () => {
        let row = component.refs['tr-0'];
        ReactTestUtils.Simulate.click(row);

        let activeRow = component.state.activeRow,
            styleTrBackgroundColor = row.style.backgroundColor;

        expect(styleTrBackgroundColor).toBeDefined();
        expect(styleTrBackgroundColor).toEqual(style.focused.backgroundColor);
    });

    it('test of header sort', () => {
        let header = component.refs['th-1'],
            sortDirect = component.state.sort.direction;
        ReactTestUtils.Simulate.click(header);
        expect(component.state.activeColumn).toBe(config[1].id);
        expect(sortDirect).toBe('asc');
        expect(component.state.activeColumn).toBe(component.state.sort.name);
        // should change direction
        ReactTestUtils.Simulate.click(header);
        expect(component.state.sort.direction).toBe('desc');
    });

    it.skip('Header image test',() => {
        let header = component.refs['th-1'];
//        let image = header.refs['image'];

        let image = ReactTestUtils.find(header,'image');
        expect(image).toBeDefined();

    })

});
