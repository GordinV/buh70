'use strict';
require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const ToolBar = require('./menu-toolbar.jsx');
const btnParams = {
    btnStart: {
        show: false
    },
    btnLogin: {
        show: true,
        disabled: false
    },
    btnAccount: {
        show: false,
        disabled: false
    },
    btnRekv: {
        show: false,
        disabled: false
    }

};


describe('components test, MenuToolbar', () => {
    let component = ReactTestUtils.renderIntoDocument(<ToolBar params={btnParams} userData={null}/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it('should exists all components', () => {
        expect(component.refs['btnStart']).toBeDefined();
        expect(component.refs['btnLogin']).toBeDefined();
        expect(component.refs['btnAccount']).toBeDefined();
        expect(component.refs['btnRekv']).toBeDefined();
    });

    it('should btnStart params show to be true', () => {
        expect(component.props.params.btnStart.show).toBeFalsy();
    });

    it('should btnLogin params show to be true', () => {
        expect(component.props.params.btnLogin.show).toBeTruthy();
    });

    it('should btnLogin userData to be null', () => {
        expect(component.state.logedId).toBeFalsy();
    });

    it('should btnAccount show to be false', () => {
        expect(component.props.params.btnAccount.show).toBeFalsy();
    });

    it('should btnRekv show to be false', () => {
        expect(component.props.params.btnRekv.show).toBeFalsy();
    });
});
