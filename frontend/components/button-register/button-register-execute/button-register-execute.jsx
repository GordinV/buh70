'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'execute';


class ButtonRegisterExecute extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
        this.handleClick = this.handleClick.bind(this);
    }

    handleClick() {
        if (this.props.onClick) {
            this.props.onClick();
        }
    }

    render() {
        return <Button
            ref="btnExecute"
            value={this.props.value}
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={this.handleClick}>
            <img ref='image' src={styles.icons[ICON]}/>
        </Button>
    }
}

ButtonRegisterExecute.propTypes = {
    onClick: PropTypes.func.isRequired,
    value: PropTypes.string.isRequired
};


ButtonRegisterExecute.defaultProps = {
    disabled: false,
    show: true
};

module.exports = ButtonRegisterExecute;