require('./../../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const flux = require('fluxify');
let docStore = require('../../../../stores/doc_store.js');


describe('component test, grid-cell', () => {

    const GridCell = require('./grid-cell.jsx');
//        style = require('./doc-data-grid-styles');


    let model = require('./../../../../../models/raamatupidamine/arv'),
        data = {
            gridConfig: model.returnData.gridConfig
        },
        cell = data.gridConfig[0];

    let handleGridRow = jest.fn();

    const component = ReactTestUtils.renderIntoDocument(
        <div>
            <table>
                <tbody>
                <tr>
                    <GridCell
                        cell={cell}
                    />
                </tr>
                </tbody>
            </table>
        </div>);

    it('should be define', () => {
        expect(component).toBeDefined();
    });

})
;
