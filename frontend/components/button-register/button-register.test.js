require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const ReactDOM = require('react-dom');
const ReactDOMServer = require('react-dom/server');

let btnClickResult = null;

const btnClick = () => {
    btnClickResult = 'Ok';
}


describe('component test, button', () => {

    const Button = require('./button-register.jsx'),
        style = require('./button-register-styles');

    let component = ReactTestUtils.renderIntoDocument(<Button
        value="Test"
        disabled={false}
        show={true}
        width="30px"
        height="auto"
        onClick={btnClick}>,

    </Button>);

    let button = component.refs['button'];

    it('should be define', () => {
        expect(component).toBeDefined();
    });

    it('should have shallow rendering button, type == "button', () => {
        expect(button.type).toBe('submit'); // its button, but returned as submit ?
    });

    it('should on event click return Ok', () => {
        ReactTestUtils.Simulate.click(button);
        expect(btnClickResult).toEqual('Ok');
    });

    it('should have property show', () => {
        expect(component.props.show).toBe(true);
    });

    it('should have property disabled', () => {
        expect(component.props.disabled).toBe(false);
    });

    it('should have styles', () => {
        expect(button.style).toBeDefined()
        expect(button.style.display).toBe('inline');
    });

});
