require('./../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react'),
    fs = require('fs'),
    path = require('path');

let  btnClickResult = null;

const btnClick = jest.fn();

describe.only('component test, buttonExecute', () => {

    const Button = require('./button-register-execute.jsx'),
        style = require('../button-register-styles');

    let component = ReactTestUtils.renderIntoDocument(<Button
        value="Execute"
        onClick={btnClick}>
    </Button>);

    let buttonExecute = component.refs['btnExecute'];
    let button = buttonExecute.refs['button'];

    it ('should be define', () => {
        expect(component).toBeDefined();
    });

    it('should have property show, disabled (default', () => {
        expect(buttonExecute.props.show).toBe(true);
        expect(buttonExecute.props.disabled).toBe(false);
    });

    it('should exist children image', () => {
        let image = component.refs['image'];
        expect(image).toBeDefined();
    });

    it('should exist image file', () => {
        let image = component.refs['image'],
            publicPath = path.join(__dirname, '../../../../public/'),
            src = path.join(publicPath, style.icons.execute);

        let imageFile = fs.statSync(src);
        expect(imageFile.isFile()).toBe(true);
    });

    it.skip('should onClick be called',()=> {
        let buttonExecute = component.refs['btnExecute'];
        expect(buttonExecute).toBeDefined();
        ReactTestUtils.Simulate.click(buttonExecute);
        expect(btnClick).toHaveBeenCalled();
    })

});
