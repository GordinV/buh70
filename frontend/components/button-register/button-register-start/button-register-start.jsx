'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'start';

class ButtonRegisterStart extends React.PureComponent{
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
    }

    handleClick(e) {
        return this.props.onClick('start');
    }

    render() {
        return <Button
            value = ''
            ref="btnStart"
            style={styles.button}
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={(e) => this.handleClick(e)}>
            <img ref="image" src={styles.icons[ICON]}/>
        </Button>
    }
}

ButtonRegisterStart.defaultProps = {
    disabled: false,
    show: true
};

module.exports = ButtonRegisterStart;