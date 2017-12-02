require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

describe('components test, TextArea', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const TextArea = require('./text-area.jsx');
    const style = require('./text-area-styles');

    let data = require('./../../../test/fixture/doc-common-fixture');
    let onChangeHandler = jest.fn();


    let component = ReactTestUtils.renderIntoDocument(<TextArea name = 'textArea'
                                                                 value={data.lastupdate}
                                                                 onChange = {onChangeHandler}
                                                                 disabled='true'
                                                                 width="75%"/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });


    it('should call onChangeHandler', ()=> {
        let input = component.refs['input'];
        expect(input).toBeDefined();
        ReactTestUtils.Simulate.change(input, {"target": {"value": "text"}})
        let params = onChangeHandler.mock.calls[0];
        expect(params.length).toBe(2);
        expect(params[0]).toBe('textArea');
        expect(params[1]).toBe('text');
    })

})