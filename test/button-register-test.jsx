require('./testdom')('<html><body></body></html>'); // создадим ДОМ

const ReactTestUtils = require('react-addons-test-utils');
const React = require('react');
const ReactDOM = require('react-dom');
const ReactDOMServer = require('react-dom/server');
const chai = require('chai');
var expect = chai.expect,
    btnClickResult = null;

const btnClick = ()=> {
    console.log('button-register clicked');
    btnClickResult = 'Ok';
}

describe.skip('ReactTestUtils, button-register', () => {
    const DocButton = require('../frontend/components/button-register.jsx'),
        className = 'gridToolbar',
        value = 'Add';

    var shallowRenderer = ReactTestUtils.createRenderer();

    shallowRenderer.render(<DocButton onClick={btnClick}
                                      className = {className}
                                      value = {value}/>);

    var result = shallowRenderer.getRenderOutput();

    it('should have shallow rendering button-register, type == "input', () => {
        expect(result.type).to.equal('input');
    });

    it ('will check for props value',()=> {
        expect(result.props.value).to.equal(value);
        expect(result.props.onClick).to.exist;
    });

    it ('will Simulate onClick',()=> {
        let container = document.createElement('div');
        let docButton = require('../frontend/components/doc-button.jsx'),
            instance = ReactDOM.render(<docButton value = "Add" onClick={btnClick}/>, container)

        let node = ReactDOM.findDOMNode(instance);
        ReactTestUtils.Simulate.click(node);
        expect(btnClickResult).to.equal('Ok');
    });
});
