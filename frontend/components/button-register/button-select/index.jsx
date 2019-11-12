'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'select';


class ButtonSelect extends React.PureComponent{
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
    }

    handleClick(e) {
        return this.props.onClick('select');
    }

    render() {
        let value = this.props.value ? this.props.value: 'Valida';
        return <Button
            ref="btnSelect"
            value={value}
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={(e)=> this.handleClick(e)}>
            <img ref='image' src={styles.icons[ICON]}/>
        </Button>
    }
}

/*
ButtonRegisterPrint.propTypes = {
    onClick: PropTypes.func.isRequired
}
*/

ButtonSelect.defaultProps = {
    disabled: false,
    show: true
};

module.exports = ButtonSelect;