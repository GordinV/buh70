require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

describe('components test, InputNumber', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const InputNumber = require('./input-number.jsx');
    const style = require('./input-number-styles');

    let data = require('./../../../test/fixture/doc-common-fixture');
    let onChangeHandler = jest.fn();


    let component = ReactTestUtils.renderIntoDocument(<InputNumber name = 'id'
                                                                 value={data.id}
                                                                 onChange = {onChangeHandler}
                                                                 readOnly={true}
                                                                 disabled={false}
                                                                 width="75%"/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it('should call onChangeHandler', ()=> {
        let input = component.refs['input'];
        expect(input).toBeDefined();
        ReactTestUtils.Simulate.change(input, {"target": {"value": 2}})
        let params = onChangeHandler.mock.calls[0];
        expect(params.length).toBe(2);
        expect(params[0]).toBe('id');
        expect(params[1]).toBe(2);
    });

    it('should have readOnly state true',()=> {
        expect(component.state.readOnly).toBeTruthy();
    })
})