require('./testdom')('<html><body></body></html>'); // создадим ДОМ

const ReactTestUtils = require('react-addons-test-utils');
const React = require('react');
const ReactDOM = require('react-dom');
const ReactDOMServer = require('react-dom/server');
const chai = require('chai');
var expect = chai.expect,
    btnClickResult = null;

const btnClick = ()=> {
    console.log('clicked');
    btnClickResult = 'Ok';
}

describe.skip('ReactTestUtils, sidebar', () => {
    const Sidebar = require('../frontend/components/sidebar/sidebar.jsx');
    const style = require('../frontend/components/sidebar/sidebar-styles');

    let shallowRenderer = ReactTestUtils.createRenderer();

    shallowRenderer.render(<Sidebar width="30%" toolbar={true}/>);

    var result = shallowRenderer.getRenderOutput();

    let component = ReactTestUtils.renderIntoDocument(<Sidebar width="30%" toolbar={true}/>);

    it('should have shallow rendering sidebar, type == "div', () => {
        expect(result.type).to.equal('div');
    });

    it ('should have childrens (2)(<div> <input/></div>)', ()=> {
        expect(result.props.children.length).to.equal(2);
    });

    it ('should have in children button ', ()=> {

        let button = component.refs['sidebar-button'];
        expect(button.type).to.equal('button');
    });

    it ('should on button click change width', ()=> {
        let componentWidth = component.state.width;
        let button = component.refs['sidebar-button'];
        ReactTestUtils.Simulate.click(button);
        let componentChangedWidth = component.state.width;
        expect(componentChangedWidth).to.not.equal('componentWidth');
    });

    it ('after btnClick event should change component show state (true -> false)', () => {
        let toolBar = component.refs['toolbar'];
        expect(component.state.show).to.equal(false);
    });

    it ('should have visibility hidden', ()=> {
        let toolbar = component.refs['content'];
        let visibility =  window.getComputedStyle(ReactDOM.findDOMNode(toolbar)).getPropertyValue("visibility");
        expect(visibility).to.be.equal('hidden');
    });

});
