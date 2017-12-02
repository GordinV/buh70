require('./testdom')('<html><body></body></html>'); // создадим ДОМ

const ReactTestUtils = require('react-addons-test-utils');
const React = require('react');
const ReactDOM = require('react-dom');
const ReactDOMServer = require('react-dom/server');
const chai = require('chai');
var expect = chai.expect,
    btnClickResult = null;

const btnClick = () => {
    btnClickResult = 'Ok';
}

describe.skip('components test, datalist', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const DataList = require('../frontend/components/datalist/datalist.jsx');
    const style = require('../frontend/components/datalist/datalist-styles');

    let shallowRenderer = ReactTestUtils.createRenderer();
    let data = require('./fixture/datalist-fixture');

    console.log('data', data);


    shallowRenderer.render(<DataList data={data}
                                     name="docsList"
                                     bindDataField="kood"
                                     value='code1'
                                     onChangeAction='docsListChange'/>);

    let result = shallowRenderer.getRenderOutput();

    let component = ReactTestUtils.renderIntoDocument(<DataList data={data}
                                                                name="docsList"
                                                                bindDataField="kood"
                                                                value='code1'
                                                                onChangeAction='docsListChange'/>);


    let container = document.createElement('div');
    let instance = ReactDOM.render(<DataList data={data}
                                             name="docsList"
                                             bindDataField="kood"
                                             value='code1'
                                             onChangeAction='docsListChange'/>, container);

    it('should component type to be div', () => {
        expect(result.type).to.equal('div');
    });

    it('should have ul li', () => {
        expect(component.refs['datalist']).to.exist;
        expect(component.refs['datalist-ul']).to.exist;
        expect(component.refs['li-0']).to.exist;
    });

    it('should have value = "code1"', () => {
        let value = component.state.value;
        expect(value).to.be.equal('code1');
    });

    it('after click event should save li clicked index', () => {
        component.handleLiClick(1);
        let clickedIndex = component.state.index;
//        ReactTestUtils.Simulate.click(button);

        expect(clickedIndex).to.be.equal(1);
    });

/*
    it('click event ', () => {
        ReactTestUtils.Simulate.click(component.refs['il-2']);
        let clickedIndex = component.state.clicked;
        expect(clickedIndex).to.be.equal(2);
    });
*/

})