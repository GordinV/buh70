require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

describe('components test, InputDateTime', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const InputDate = require('./index.jsx');
    const style = require('./input-datetime-styles');

    let data = require('./../../../test/fixture/doc-common-fixture'),
        now = new Date();

    let onChangeHandler = jest.fn();


    let component = ReactTestUtils.renderIntoDocument(<InputDate name = 'created'
                                                                 value={data.created}
                                                                 onChange = {onChangeHandler}
                                                                 disabled={true}
                                                                 readOnly={true}
                                                                 width="75%"/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });


    it('should call onChangeHandler', ()=> {
        let input = component.refs['input'];
        expect(input).toBeDefined();
        ReactTestUtils.Simulate.change(input, {"target": {"value": now}});
        let params = onChangeHandler.mock.calls[0];
        expect(params.length).toBe(2);
        expect(params[0]).toBe('created');
        expect(params[1]).toBe(now);
    });

    it('should change its readOnly state',() => {
        let state = component.state;
        expect(state.readOnly).toBeTruthy();
    });

});