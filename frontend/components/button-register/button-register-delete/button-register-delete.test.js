require('./../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ
import ReactTestUtils from 'react-dom/test-utils';

//const ReactTestUtils = require('react-dom/test-utils');
const React = require('react'),
    fs = require('fs'),
    path = require('path');


let btnClickResult = null;

const btnClick = () => {
    btnClickResult = 'Ok';
}

//const button = component.refs['button'];

describe.only('component test, button', () => {

    const Button = require('./button-register-delete.jsx'),
        style = require('../button-register-styles');

    let component = ReactTestUtils.renderIntoDocument(<Button
        value="Delete"
        onClick={btnClick}>
    </Button>);

    let buttonDelete = component.refs['btnDelete'];
    let button = buttonDelete.refs['button'];

    it('should be define', () => {
        expect(component).toBeDefined();
    });

    it('should have property show, disabled (default', () => {
        expect(buttonDelete.props.show).toBe(true);
        expect(buttonDelete.props.disabled).toBe(false);
    });

    it('should exist children image', () => {
        let image = component.refs['image'];
        expect(image).toBeDefined();
    });

    it('should exist image file', () => {
        let image = component.refs['image'],
            publicPath = path.join(__dirname, '../../../../public/'),
            src = path.join(publicPath, style.icons.delete);


        let imageFile = fs.statSync(src);
        expect(imageFile.isFile()).toBe(true);

    });

});
