require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');

describe('components test, Tree', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Tree = require('./tree.jsx');
    const style = require('./tree-styles');

    let data = require('./../../../test/fixture/datalist-fixture');


    let component = ReactTestUtils.renderIntoDocument(<Tree data={data}
                                                                name="docsList"
                                                                bindDataField="kood"
                                                                value='code1'
                                                                onChangeAction='docsListChange'/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it('should have ul li', () => {
        expect(component.refs['tree']).toBeDefined();
        expect(component.refs['tree-ul']).toBeDefined();
        expect(component.refs['li-0']).toBeDefined();
    });

    it('should have value = "code1"', () => {
        let value = component.state.value;
        expect(value).toBe('code1');
    });

    it('after click event should save li clicked index', () => {
        let li = component.refs['li-1'];
        expect(li).toBeDefined();

        ReactTestUtils.Simulate.click(li);

        expect(component.state.index).toBe(1);
        expect(component.state.value).toBe('code2');
    });

})