require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');

describe('components test, Select', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Select = require('./select-data.jsx');
//    const style = require('./input-text-styles');

    let data = require('./../../../test/fixture/doc-common-fixture'),
        libs = require('./../../../test/fixture/datalist-fixture');

    let onChangeHandler = jest.fn();


    let component = ReactTestUtils.renderIntoDocument(<Select className='ui-c2'
                                                              title="Asutus"
                                                              name='asutusid'
                                                              data ={libs}
                                                              libs="asutused"
                                                              value={0}
                                                              onChange={onChangeHandler}
                                                              defaultValue={data.asutus}
                                                              placeholder='Asutus'
                                                              readOnly={true}/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });
/*
    it('should have input, select and button', () => {
        expect(component.refs['input']).toBeDefined();
        expect(component.refs['select']).toBeDefined();
        expect(component.refs['button']).toBeDefined();
    });

    it('should be libs data to be loaded',()=> {
        let data = component.state.data;
        expect(data).toEqual(libs);
    })

    it('should have children (options)', () => {
        expect(component.refs['option-0']).toBeDefined();
    });

    it('should change value', () => {
        let option = component.refs['option-1'];
        ReactTestUtils.Simulate.change(component.refs['select'], {"target": {"value": 2}});
        let params = onChangeHandler.mock.calls[0];
        expect(params.length).toBe(2);
        expect(params[0]).toBe('asutusid');
        expect(params[1]).toBe(2);
    });

    it('should have readOnly state true', () => {
        expect(component.state.readOnly).toBeTruthy();
    });
*/

})
