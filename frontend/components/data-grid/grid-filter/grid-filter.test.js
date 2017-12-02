require('./../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react'),
    GridFilter = require('./grid-filter.jsx'),
    style = require('./grid-filter-styles'),
    model = require('./../../../../models/docs_grid_config'),
    config = model.DOK.gridConfiguration,
    data = require('./../../../../test/fixture/grid-filter-fixture');

describe('component test, grid-filter', () => {

    const component = ReactTestUtils.renderIntoDocument(<GridFilter
        data={data}
        gridConfig={config}
        />);

    it('should be define', () => {
        expect(component).toBeDefined();
    });

    it('should contain children elements', ()=> {
        config.forEach(row => {
            let filterComponent = component.refs[row.id];
            expect(filterComponent).toBeDefined();
        })
    });

    it('test of the filter component state', () => {
        let stateData = component.state.data;

        expect(stateData).toEqual(data);
    })
});
