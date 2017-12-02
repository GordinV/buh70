global.__base = 'c:/avpsoft/buh70/';

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const flux = require('fluxify');
let docStore = require('../../../stores/doc_store.js');
require(__base +  'test/testdom')('<html><body></body></html>'); // создадим ДОМ


describe('component test, doc-data-grid', () => {

    const DataGrid = require('./doc-data-grid.jsx'),
        style = require('./doc-data-grid-styles');

    let dataRow = require(__base + 'test/fixture/doc-common-fixture'),
        libs = require(__base +  'test/fixture/datalist-fixture'),
        model = require(__base +  '/models/raamatupidamine/arv'),
        data = {
            details: dataRow.details,
            gridConfig: model.returnData.gridConfig
        }

let handleGridRow = jest.fn();


const component = ReactTestUtils.renderIntoDocument(
    <div>
        <DataGrid source='details'
                  gridData={data.details}
                  gridColumns={data.gridConfig}
                  handleGridRow={handleGridRow}
                  readOnly={true}/>
    </div>);

//let table = component.refs['dataGridTable'];

it('should be define', () => {
    expect(component).toBeDefined();
});

/*
 it('test handleGridHeaderClick', () => {
 let header = component.refs['th-0'];

 ReactTestUtils.Simulate.click(header);

 expect(component.state.activeColumn).toBe('id');
 });

 it('test handleGridCellClick', () => {
 let row = component.refs['tr-1'];

 ReactTestUtils.Simulate.click(row);

 expect(component.state.activeRow).toBe(1);
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
 expect(style.width).toBe('50px');

 let displayProp = style.display;
 expect(displayProp).toBeDefined();
 expect(displayProp).toBe('none');

 header = component.refs['th-1'];
 style = header.style;
 displayProp = style.display;

 expect(displayProp).toBeDefined();
 expect(displayProp).toBe('');

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

 let image = ReactTestUtils.find(header,'image')
 expect(image).toBeDefined();

 })
 */

})
;
