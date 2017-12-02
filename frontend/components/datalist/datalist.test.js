require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');

describe('components test, datalist', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const DataList = require('./datalist.jsx');
    const style = require('./datalist-styles');

    let data = require('./../../../test/fixture/datalist-fixture');


    let component = ReactTestUtils.renderIntoDocument(<DataList data={data}
                                                                name="docsList"
                                                                bindDataField="kood"
                                                                value='code1'
                                                                onChangeAction='docsListChange'/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it('should have ul li', () => {
        expect(component.refs['datalist']).toBeDefined();
        expect(component.refs['datalist-ul']).toBeDefined();
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