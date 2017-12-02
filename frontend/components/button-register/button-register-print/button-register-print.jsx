'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'print';


class ButtonRegisterPrint extends React.PureComponent{
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
    }

    handleClick(e) {
        return this.props.onClick();
    }

    render() {
        return <Button
            ref="btnPrint"
            value='Print'
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={(e)=> this.handleClick(e)}>
            <img ref='image' src={styles.icons[ICON]}/>
        </Button>
    }
};
/*
ButtonRegisterPrint.propTypes = {
    onClick: PropTypes.func.isRequired
}
*/

ButtonRegisterPrint.defaultProps = {
    disabled: false,
    show: true
};

module.exports = ButtonRegisterPrint;